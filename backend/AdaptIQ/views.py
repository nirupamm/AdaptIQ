from rest_framework import status
from rest_framework.decorators import api_view, permission_classes
from rest_framework.permissions import IsAuthenticated
from rest_framework.response import Response
from django.shortcuts import get_object_or_404
from .models import Question, QuizSession, UserAnswer, KidMode
from .serializers import QuestionSerializer, QuizSessionSerializer, UserAnswerSerializer, KidModeSerializer
import random
import html
from django.contrib.auth.models import User
from django.contrib.auth import authenticate
from rest_framework_simplejwt.tokens import RefreshToken
from django.contrib.auth.models import User
from django.contrib.auth import authenticate
from rest_framework_simplejwt.tokens import RefreshToken
from django.db.models import Q

# Global storage for testing (in production, use database)
quiz_sessions = {}


def decode_text(text):
    """Decode HTML entities from question/answer text."""
    if not isinstance(text, str):
        return text
    return html.unescape(text).strip()

@api_view(['POST'])
# @permission_classes([IsAuthenticated])  # Commented out for testing
def start_quiz(request):
    """Start a new quiz session"""
    try:
        category = request.data.get('category')
        
        if not category:
            return Response({'error': 'Category is required'}, status=status.HTTP_400_BAD_REQUEST)
        
        # Get a random medium difficulty question to start
        requested_difficulty = 'medium'
        question = get_random_question(category, requested_difficulty)
        
        if not question:
            return Response({'error': 'No questions available for this category'}, status=status.HTTP_404_NOT_FOUND)
        
        # For testing without authentication, create a mock session ID
        session_id = random.randint(1000, 9999)
        
        # Initialize session state for AI tracking
        quiz_sessions[session_id] = {
            'category': category,
            'current_difficulty': 'medium',
            'consecutive_correct': 0,
            'consecutive_incorrect': 0,
            'total_score': 0,
            'total_questions_answered': 0,
            'max_questions': 10  # Set limit to 10 questions for testing
        }
        
        # Prepare answers (shuffle them)
        all_answers = [
            decode_text(question.correct_answer),
            *[decode_text(answer) for answer in question.incorrect_answers],
        ]
        random.shuffle(all_answers)
        
        return Response({
            'quiz_session_id': session_id,
            'question': {
                'id': question.id,
                'question_text': decode_text(question.question_text),
                'category': question.category,
                'difficulty': question.difficulty,
                'answers': all_answers
            },
            'current_difficulty': question.difficulty,
            'difficulty_debug': {
                'requested_difficulty': requested_difficulty,
                'served_difficulty': question.difficulty,
                'fallback_used': question.difficulty != requested_difficulty
            }
        })
    except Exception as e:
        return Response({'error': f'Server error: {str(e)}'}, status=status.HTTP_500_INTERNAL_SERVER_ERROR)

@api_view(['POST'])
# @permission_classes([IsAuthenticated])  # Commented out for testing
def submit_answer(request):
    """Submit an answer and get next question using proper AI logic"""
    try:
        quiz_session_id = request.data.get('quiz_session_id')
        question_id = request.data.get('question_id')
        selected_answer = request.data.get('selected_answer')
        
        if not all([quiz_session_id, question_id, selected_answer]):
            return Response({'error': 'Missing required fields'}, status=status.HTTP_400_BAD_REQUEST)
        
        # Get the question
        try:
            question = Question.objects.get(id=question_id)
        except Question.DoesNotExist:
            return Response({'error': 'Question not found'}, status=status.HTTP_404_NOT_FOUND)
        
        # Check if answer is correct
        is_correct = selected_answer == question.correct_answer
        
        # Get session state
        if quiz_session_id not in quiz_sessions:
            return Response({'error': 'Invalid session ID'}, status=status.HTTP_400_BAD_REQUEST)
        
        session = quiz_sessions[quiz_session_id]
        session['total_questions_answered'] += 1
        
        # Apply AI logic
        previous_difficulty = session['current_difficulty']
        if is_correct:
            session['consecutive_correct'] += 1
            session['consecutive_incorrect'] = 0
            
            # Calculate points based on current difficulty
            difficulty_points = {'easy': 5, 'medium': 10, 'hard': 20}
            points_earned = difficulty_points.get(session['current_difficulty'], 10)
            session['total_score'] += points_earned
            
            # Rule: If 2 consecutive correct, increase difficulty
            if session['consecutive_correct'] >= 2:
                if session['current_difficulty'] == 'easy':
                    session['current_difficulty'] = 'medium'
                    session['consecutive_correct'] = 0  # Reset counter after difficulty change
                elif session['current_difficulty'] == 'medium':
                    session['current_difficulty'] = 'hard'
                    session['consecutive_correct'] = 0  # Reset counter after difficulty change
                # If already 'hard', stay 'hard' (no further increase)
        else:
            session['consecutive_incorrect'] += 1
            session['consecutive_correct'] = 0
            points_earned = 0
            
            # Rule: If 2 consecutive incorrect, decrease difficulty
            if session['consecutive_incorrect'] >= 2:
                if session['current_difficulty'] == 'hard':
                    session['current_difficulty'] = 'medium'
                    session['consecutive_incorrect'] = 0  # Reset counter after difficulty change
                elif session['current_difficulty'] == 'medium':
                    session['current_difficulty'] = 'easy'
                    session['consecutive_incorrect'] = 0  # Reset counter after difficulty change
                # If already 'easy', stay 'easy' (no further decrease)
        
        # Track whether AI rule changed difficulty this turn
        ai_changed_difficulty = previous_difficulty != session['current_difficulty']
        ai_target_difficulty = session['current_difficulty']

        # Check if quiz is complete (reached max questions)
        if session['total_questions_answered'] >= session['max_questions']:
            next_question_data = None
            served_difficulty = None
            fallback_used = False
        else:
            next_question = get_random_question(question.category, ai_target_difficulty)
            if next_question:
                all_answers = [next_question.correct_answer] + next_question.incorrect_answers
                all_answers = [decode_text(answer) for answer in all_answers]
                random.shuffle(all_answers)
                next_question_data = {
                    'id': next_question.id,
                    'question_text': decode_text(next_question.question_text),
                    'category': next_question.category,
                    'difficulty': next_question.difficulty,
                    'answers': all_answers
                }
                served_difficulty = next_question.difficulty
                fallback_used = served_difficulty != ai_target_difficulty
                # Keep session/UI aligned with the actual next question difficulty.
                session['current_difficulty'] = served_difficulty
            else:
                next_question_data = None
                served_difficulty = None
                fallback_used = False
        
        return Response({
            'is_correct': is_correct,
            'correct_answer': decode_text(question.correct_answer),
            'points_earned': points_earned,
            'total_score': session['total_score'],
            'current_difficulty': session['current_difficulty'],
            'questions_answered': session['total_questions_answered'],
            'max_questions': session['max_questions'],
            'next_question': next_question_data,
            'difficulty_debug': {
                'previous_difficulty': previous_difficulty,
                'ai_target_difficulty': ai_target_difficulty,
                'served_difficulty': served_difficulty,
                'ai_changed_difficulty': ai_changed_difficulty,
                'fallback_used': fallback_used
            }
        })
    except Exception as e:
        return Response({'error': f'Server error: {str(e)}'}, status=status.HTTP_500_INTERNAL_SERVER_ERROR)

@api_view(['GET'])
# @permission_classes([IsAuthenticated])  # Commented out for testing
def get_quiz_stats(request):
    """Get quiz statistics"""
    try:
        total_questions = Question.objects.count()
        total_sessions = len(quiz_sessions)
        
        return Response({
            'total_questions': total_questions,
            'total_sessions': total_sessions,
            'categories': ['computer', 'maths', 'sports'],
            'difficulties': ['easy', 'medium', 'hard']
        })
    except Exception as e:
        return Response({'error': f'Server error: {str(e)}'}, status=status.HTTP_500_INTERNAL_SERVER_ERROR)

@api_view(['POST'])
# @permission_classes([IsAuthenticated])  # Commented out for testing
def report_movement_violation(request):
    """Report a movement violation from OpenCV monitoring"""
    try:
        violation_type = request.data.get('violation_type')
        reason = request.data.get('reason')
        quiz_session_id = request.data.get('quiz_session_id')
        
        if not all([violation_type, reason, quiz_session_id]):
            return Response({'error': 'Missing required fields'}, status=status.HTTP_400_BAD_REQUEST)
        
        # Log the violation (in production, save to database)
        print(f"Movement violation: {violation_type} - {reason} (Session: {quiz_session_id})")
        
        return Response({
            'status': 'violation_logged',
            'violation_type': violation_type,
            'reason': reason,
            'session_id': quiz_session_id
        })
    except Exception as e:
        return Response({'error': f'Server error: {str(e)}'}, status=status.HTTP_500_INTERNAL_SERVER_ERROR)

@api_view(['POST'])
# @permission_classes([IsAuthenticated])  # Commented out for testing
def start_camera_monitoring(request):
    """Start camera monitoring for a quiz session"""
    try:
        quiz_session_id = request.data.get('quiz_session_id')
        
        if not quiz_session_id:
            return Response({'error': 'Session ID required'}, status=status.HTTP_400_BAD_REQUEST)
        
        # Log monitoring start (in production, save to database)
        print(f"Camera monitoring started for session: {quiz_session_id}")
        
        return Response({
            'status': 'monitoring_started',
            'session_id': quiz_session_id
        })
    except Exception as e:
        return Response({'error': f'Server error: {str(e)}'}, status=status.HTTP_500_INTERNAL_SERVER_ERROR)

@api_view(['POST'])
# @permission_classes([IsAuthenticated])  # Commented out for testing
def stop_camera_monitoring(request):
    """Stop camera monitoring for a quiz session"""
    try:
        quiz_session_id = request.data.get('quiz_session_id')
        
        if not quiz_session_id:
            return Response({'error': 'Session ID required'}, status=status.HTTP_400_BAD_REQUEST)
        
        # Log monitoring stop (in production, save to database)
        print(f"Camera monitoring stopped for session: {quiz_session_id}")
        
        return Response({
            'status': 'monitoring_stopped',
            'session_id': quiz_session_id
        })
    except Exception as e:
        return Response({'error': f'Server error: {str(e)}'}, status=status.HTTP_500_INTERNAL_SERVER_ERROR)

def get_random_question(category, difficulty):
    """Get a random question for the given category and difficulty"""
    try:
        questions = Question.objects.filter(
            category=category,
            difficulty=difficulty,
            is_active=True
        )
        
        if questions.exists():
            return questions.order_by('?').first()
        else:
            # Fallback: try to get any question from the category
            questions = Question.objects.filter(
                category=category,
                is_active=True
            )
            if questions.exists():
                return questions.order_by('?').first()
            return None
    except Exception as e:
        print(f"Error getting random question: {e}")
        return None 
@api_view(['POST'])
def register_user(request):
    try:
        username = (request.data.get('username') or '').strip()
        email = (request.data.get('email') or '').strip().lower()
        password = request.data.get('password') or ''

        if not username or not email or not password:
            return Response(
                {'error': 'Username, email, and password are required'},
                status=400,
            )

        if User.objects.filter(username=username).exists():
            return Response({'error': 'Username already exists'}, status=400)

        if User.objects.filter(email=email).exists():
            return Response({'error': 'Email already exists'}, status=400)

        user = User.objects.create_user(
            username=username,
            email=email,
            password=password,
        )

        return Response({'message': 'User registered successfully'}, status=201)

    except Exception as e:
        return Response({'error': str(e)}, status=500)

@api_view(['GET'])
def get_dashboard_stats(request):
    try:
        total_quizzes = len(quiz_sessions)
        total_score = sum(session['total_score'] for session in quiz_sessions.values())

        category_scores = {}
        for session in quiz_sessions.values():
            cat = session['category']
            category_scores.setdefault(cat, []).append(session['total_score'])

        best_subject = "N/A"
        best_score = 0

        if category_scores:
            best_subject = max(
                category_scores,
                key=lambda c: sum(category_scores[c]) / len(category_scores[c])
            )
            best_score = int(
                sum(category_scores[best_subject]) / len(category_scores[best_subject])
            )

        last_played = list(quiz_sessions.values())[-1]['category'] if quiz_sessions else "N/A"

        return Response({
            "total_quizzes": total_quizzes,
            "total_score": total_score,
            "best_subject": best_subject,
            "best_score": best_score,
            "last_played": last_played,
        })
    except Exception as e:
        return Response({"error": str(e)}, status=500)


@api_view(['POST'])
def login_user(request):
    try:
        identifier = (request.data.get('identifier') or '').strip()
        password = request.data.get('password') or ''

        if not identifier or not password:
            return Response(
                {'error': 'Identifier and password are required'},
                status=400,
            )

        user = None

        # Login using email
        if '@' in identifier:
            try:
                matched_user = User.objects.get(email__iexact=identifier)
                user = authenticate(
                    request,
                    username=matched_user.username,
                    password=password,
                )
            except User.DoesNotExist:
                user = None
        else:
            # Login using username
            user = authenticate(
                request,
                username=identifier,
                password=password,
            )

        if user is None:
            return Response({'error': 'Invalid credentials'}, status=401)

        refresh = RefreshToken.for_user(user)

        return Response({
            'message': 'Login successful',
            'access': str(refresh.access_token),
            'refresh': str(refresh),
            'user': {
                'id': user.id,
                'username': user.username,
                'email': user.email,
            }
        })

    except Exception as e:
        return Response({'error': str(e)}, status=500)