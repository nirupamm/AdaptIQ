from django.urls import path
from . import views
from django.urls import path, include


urlpatterns = [
    path('start-quiz/', views.start_quiz, name='start_quiz'),
    path('submit-answer/', views.submit_answer, name='submit_answer'),
    path('quiz-stats/', views.get_quiz_stats, name='quiz_stats'),

    path('dashboard-stats/', views.get_dashboard_stats, name='dashboard_stats'),  # ✅ ADD THIS

    path('register/', views.register_user),
    path('login/', views.login_user),

    # OpenCV endpoints
    path('start-camera-monitoring/', views.start_camera_monitoring, name='start_camera_monitoring'),
    path('stop-camera-monitoring/', views.stop_camera_monitoring, name='stop_camera_monitoring'),
    path('report-movement-violation/', views.report_movement_violation, name='report_movement_violation'),
]