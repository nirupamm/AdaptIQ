from django.contrib import admin
from .models import Question, QuizSession, UserAnswer, UserSession, KidMode

@admin.register(Question)
class QuestionAdmin(admin.ModelAdmin):
    list_display = ('id', 'question_text', 'category', 'difficulty', 'is_active', 'created_at')
    list_filter = ('category', 'difficulty', 'is_active')
    search_fields = ('question_text', 'correct_answer', 'category')
    ordering = ('-created_at',)

@admin.register(QuizSession)
class QuizSessionAdmin(admin.ModelAdmin):
    list_display = (
        'id',
        'user',
        'category',
        'current_difficulty',
        'total_questions_answered',
        'total_score',
        'is_active',
        'created_at',
    )
    list_filter = ('category', 'current_difficulty', 'is_active', 'created_at')
    search_fields = ('user__username', 'user__email', 'category')
    ordering = ('-created_at',)

@admin.register(UserAnswer)
class UserAnswerAdmin(admin.ModelAdmin):
    list_display = (
        'id',
        'user',
        'question',
        'selected_answer',
        'is_correct',
        'points_earned',
        'difficulty_at_time',
        'answered_at',
    )
    list_filter = ('is_correct', 'difficulty_at_time', 'answered_at')
    search_fields = ('user__username', 'question__question_text', 'selected_answer')
    ordering = ('-answered_at',)

@admin.register(UserSession)
class UserSessionAdmin(admin.ModelAdmin):
    list_display = (
        'id',
        'user',
        'quiz_session',
        'movement_warnings',
        'is_cheating_detected',
        'camera_feed_active',
        'session_start',
        'session_end',
    )
    list_filter = ('is_cheating_detected', 'camera_feed_active', 'session_start')
    search_fields = ('user__username', 'user__email')
    ordering = ('-session_start',)

@admin.register(KidMode)
class KidModeAdmin(admin.ModelAdmin):
    list_display = (
        'id',
        'user',
        'is_enabled',
        'max_difficulty',
        'time_limit_per_question',
    )
    list_filter = ('is_enabled', 'max_difficulty')
    search_fields = ('user__username', 'user__email')