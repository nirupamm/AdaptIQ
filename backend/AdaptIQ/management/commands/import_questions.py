import requests
import json
import time
import html
from django.core.management.base import BaseCommand
from AdaptIQ.models import Question

class Command(BaseCommand):
    help = 'Import questions from Open Trivia Database API'

    def add_arguments(self, parser):
        parser.add_argument(
            '--amount',
            type=int,
            default=10,
            help='Number of questions per difficulty level'
        )

    def handle(self, *args, **options):
        amount = options['amount']
        
        # Your exact API configuration
        categories = [
            {'key': 'computer', 'id': 18, 'name': 'Science: Computers'},
            {'key': 'maths', 'id': 19, 'name': 'Science: Mathematics'},
            {'key': 'sports', 'id': 21, 'name': 'Sports'}
        ]
        
        difficulties = ['easy', 'medium', 'hard']
        
        self.stdout.write(self.style.SUCCESS('Starting question import...'))
        
        total_imported = 0
        
        for category in categories:
            self.stdout.write(f'Importing {category["name"]} questions...')
            
            for difficulty in difficulties:
                self.stdout.write(f'  Importing {difficulty} questions...')
                
                # Add delay to avoid rate limiting
                time.sleep(2)
                
                # Fetch questions from API
                questions = self.fetch_questions(category['id'], difficulty, amount)
                
                if questions:
                    imported_count = self.save_questions(questions, category['key'], difficulty)
                    total_imported += imported_count
                    self.stdout.write(f'    Imported {imported_count} {difficulty} questions')
                else:
                    self.stdout.write(self.style.WARNING(f'    No {difficulty} questions found'))
        
        self.stdout.write(self.style.SUCCESS(f'Import completed! Total questions imported: {total_imported}'))

    def fetch_questions(self, category_id, difficulty, amount):
        """Fetch questions from Open Trivia Database API"""
        url = 'https://opentdb.com/api.php'
        params = {
            'amount': amount,
            'category': category_id,
            'difficulty': difficulty,
            'type': 'multiple'
        }
        
        try:
            self.stdout.write(f'    Fetching: {url}?amount={amount}&category={category_id}&difficulty={difficulty}&type=multiple')
            
            response = requests.get(url, params=params, timeout=30)
            response.raise_for_status()
            data = response.json()
            
            if data['response_code'] == 0:
                self.stdout.write(f'    Found {len(data["results"])} questions')
                return data['results']
            elif data['response_code'] == 1:
                self.stdout.write(self.style.WARNING(f'    No results found for category {category_id}, difficulty {difficulty}'))
                return []
            else:
                self.stdout.write(self.style.WARNING(f'    API Error: {data["response_code"]}'))
                return []
                
        except requests.exceptions.Timeout:
            self.stdout.write(self.style.ERROR(f'    Request timeout for category {category_id}, difficulty {difficulty}'))
            return []
        except requests.exceptions.HTTPError as e:
            if e.response.status_code == 429:
                self.stdout.write(self.style.ERROR(f'    Rate limit exceeded. Waiting 10 seconds...'))
                time.sleep(10)
                return self.fetch_questions(category_id, difficulty, amount)  # Retry
            else:
                self.stdout.write(self.style.ERROR(f'    HTTP Error: {e}'))
                return []
        except requests.RequestException as e:
            self.stdout.write(self.style.ERROR(f'    Request failed: {e}'))
            return []

    def save_questions(self, questions, category, difficulty):
        """Save questions to database"""
        imported_count = 0
        
        for question_data in questions:
            try:
                decoded_question_text = html.unescape(question_data['question']).strip()
                decoded_correct_answer = html.unescape(question_data['correct_answer']).strip()
                decoded_incorrect_answers = [
                    html.unescape(answer).strip()
                    for answer in question_data['incorrect_answers']
                ]

                # Check if question already exists
                existing_question = Question.objects.filter(
                    question_text=decoded_question_text
                ).first()
                
                if existing_question:
                    continue  # Skip if already exists
                
                # Create new question
                question = Question.objects.create(
                    question_text=decoded_question_text,
                    category=category,
                    difficulty=difficulty,
                    correct_answer=decoded_correct_answer,
                    incorrect_answers=decoded_incorrect_answers,
                    is_active=True
                )
                
                imported_count += 1
                
            except Exception as e:
                self.stdout.write(self.style.ERROR(f'    Error saving question: {e}'))
                continue
        
        return imported_count
    