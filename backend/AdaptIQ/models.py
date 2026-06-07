from django.db import models
from django.contrib.auth.models import User
from django.utils import timezone
from datetime import timedelta

REST_FRAMEWORK = {
    'DEFAULT_AUTHENTICATION_CLASSES': (
        'rest_framework_simplejwt.authentication.JWTAuthentication',
    ),
}

SIMPLE_JWT = {
    'ACCESS_TOKEN_LIFETIME': timedelta(days=1),
}

class Question(models.Model):
    question_text = models.TextField()
    category = models.CharField(max_length=100)
    difficulty = models.CharField(max_length=10)  # easy, medium, hard
    correct_answer = models.CharField(max_length=255)
    incorrect_answers = models.JSONField()  # Store as list of strings
    api_question_id = models.IntegerField(unique=True, null=True, blank=True)  # Store API question ID
    created_at = models.DateTimeField(auto_now_add=True)
    is_active = models.BooleanField(default=True)
    
    def __str__(self):
        return f"{self.question_text[:50]}... ({self.category} - {self.difficulty})"
    
    class Meta:
        ordering = ['-created_at']

class QuizSession(models.Model):
    user = models.ForeignKey(User, on_delete=models.CASCADE)
    category = models.CharField(max_length=100)  # computer, maths, sports
    current_difficulty = models.CharField(max_length=10, default='medium')  # easy, medium, hard
    consecutive_correct = models.IntegerField(default=0)
    consecutive_incorrect = models.IntegerField(default=0)
    total_questions_answered = models.IntegerField(default=0)
    total_score = models.IntegerField(default=0)
    is_active = models.BooleanField(default=True)
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)
    
    def update_difficulty(self, is_correct):
        """Rule-based AI: Update difficulty based on user performance"""
        self.total_questions_answered += 1
        
        if is_correct:
            self.consecutive_correct += 1
            self.consecutive_incorrect = 0
            self.total_score += self.get_points_for_current_difficulty()
            
            # Rule: If 2 consecutive correct, increase difficulty
            if self.consecutive_correct >= 2:
                if self.current_difficulty == 'easy':
                    self.current_difficulty = 'medium'
                    self.consecutive_correct = 0  # Reset counter after difficulty change
                elif self.current_difficulty == 'medium':
                    self.current_difficulty = 'hard'
                    self.consecutive_correct = 0  # Reset counter after difficulty change
                # If already 'hard', stay 'hard' (no further increase)
        else:
            self.consecutive_incorrect += 1
            self.consecutive_correct = 0
            
            # Rule: If 2 consecutive incorrect, decrease difficulty
            if self.consecutive_incorrect >= 2:
                if self.current_difficulty == 'hard':
                    self.current_difficulty = 'medium'
                    self.consecutive_incorrect = 0  # Reset counter after difficulty change
                elif self.current_difficulty == 'medium':
                    self.current_difficulty = 'easy'
                    self.consecutive_incorrect = 0  # Reset counter after difficulty change
                # If already 'easy', stay 'easy' (no further decrease)
        
        self.save()
    
    def get_points_for_current_difficulty(self):
        """Calculate points based on current difficulty"""
        difficulty_points = {
            'easy': 5,
            'medium': 10,
            'hard': 20
        }
        return difficulty_points.get(self.current_difficulty, 10)
    
    def force_quit_due_to_cheating(self):
        """Force quit the quiz due to cheating detection"""
        self.is_active = False
        self.save()
        return {
            'status': 'terminated',
            'reason': 'cheating_detected'
        }
    
    def __str__(self):
        return f"{self.user.username} - {self.category} - {self.current_difficulty} - Score: {self.total_score}"

class UserAnswer(models.Model):
    user = models.ForeignKey(User, on_delete=models.CASCADE)
    question = models.ForeignKey(Question, on_delete=models.CASCADE)
    quiz_session = models.ForeignKey(QuizSession, on_delete=models.CASCADE, related_name='user_answers')
    selected_answer = models.CharField(max_length=255)
    is_correct = models.BooleanField()
    points_earned = models.IntegerField()
    difficulty_at_time = models.CharField(max_length=10)  # Store difficulty when answered
    answered_at = models.DateTimeField(auto_now_add=True)
    
    def __str__(self):
        return f"{self.user.username} - {self.question.question_text[:30]} - {'Correct' if self.is_correct else 'Incorrect'}"

class UserSession(models.Model):
    user = models.ForeignKey(User, on_delete=models.CASCADE)
    quiz_session = models.ForeignKey(QuizSession, on_delete=models.CASCADE, null=True, blank=True)
    session_start = models.DateTimeField(auto_now_add=True)
    session_end = models.DateTimeField(null=True, blank=True)
    
    # OpenCV tracking
    movement_warnings = models.IntegerField(default=0)
    max_warnings = models.IntegerField(default=2)  # 2 warnings allowed
    is_cheating_detected = models.BooleanField(default=False)
    camera_feed_active = models.BooleanField(default=False)
    
    # Warning details
    warning_history = models.JSONField(default=list)  # Store warning timestamps and reasons
    
    def add_warning(self, warning_type, reason):
        """Add a warning and check if quiz should be terminated"""
        self.movement_warnings += 1
        
        warning_data = {
            'timestamp': timezone.now().isoformat(),
            'type': warning_type,  # 'looking_away', 'left_frame'
            'reason': reason,
            'warning_number': self.movement_warnings
        }
        
        self.warning_history.append(warning_data)
        
        # Check if this is the 3rd warning (force quit)
        if self.movement_warnings >= 3:
            self.is_cheating_detected = True
            self.session_end = timezone.now()
            if self.quiz_session:
                self.quiz_session.is_active = False
                self.quiz_session.save()
        
        self.save()
        return self.movement_warnings >= 3  # Returns True if should force quit
    
    def reset_warnings(self):
        """Reset warnings (for new quiz session)"""
        self.movement_warnings = 0
        self.is_cheating_detected = False
        self.warning_history = []
        self.save()
    
    def __str__(self):
        return f"{self.user.username} - Warnings: {self.movement_warnings}/3"

class KidMode(models.Model):
    user = models.OneToOneField(User, on_delete=models.CASCADE)
    is_enabled = models.BooleanField(default=False)
    parent_pin = models.CharField(max_length=4, blank=True)  # 4-digit PIN
    max_difficulty = models.CharField(max_length=10, default='medium')  # Limit difficulty in kid mode
    time_limit_per_question = models.IntegerField(default=60)  # seconds
    
    def __str__(self):
        return f"{self.user.username} - Kid Mode: {'Enabled' if self.is_enabled else 'Disabled'}" 