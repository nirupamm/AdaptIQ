import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiService {
  // For web testing (Chrome)
  static const String baseUrl = 'http://100.64.219.154:8000/api/quiz';

  // For Android emulator, use: 'http://10.0.2.2:8000/api/quiz'
  // For physical device, use your computer's IP: 'http://192.168.42.157:8000/api/quiz'

  // Start a new quiz
  static Future<Map<String, dynamic>> startQuiz(String category) async {
    try {
      print('Starting quiz for category: $category');

      final response = await http.post(
        Uri.parse('$baseUrl/start-quiz/'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: json.encode({'category': category}),
      );

      print('Response status: ${response.statusCode}');
      print('Response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        print('Parsed data: $data');
        return data;
      } else {
        throw Exception(
          'Failed to start quiz: ${response.statusCode} - ${response.body}',
        );
      }
    } catch (e) {
      print('Error starting quiz: $e');
      throw Exception('Error starting quiz: $e');
    }
  }

  static Future<Map<String, dynamic>> getDashboardStats() async {
    final response = await http.get(
      Uri.parse('$baseUrl/dashboard-stats/'),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Failed to load dashboard stats');
    }
  }

  // Submit an answer
  static Future<Map<String, dynamic>> submitAnswer(
    int quizSessionId,
    int questionId,
    String selectedAnswer,
  ) async {
    try {
      print('Submitting answer: $selectedAnswer for question: $questionId');

      final response = await http.post(
        Uri.parse('$baseUrl/submit-answer/'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: json.encode({
          'quiz_session_id': quizSessionId,
          'question_id': questionId,
          'selected_answer': selectedAnswer,
        }),
      );

      print('Response status: ${response.statusCode}');
      print('Response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        print('Parsed data: $data');
        return data;
      } else {
        throw Exception(
          'Failed to submit answer: ${response.statusCode} - ${response.body}',
        );
      }
    } catch (e) {
      print('Error submitting answer: $e');
      throw Exception('Error submitting answer: $e');
    }
  }

  // Get quiz statistics
  static Future<Map<String, dynamic>> getQuizStats() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/quiz-stats/'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Failed to get stats: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error getting stats: $e');
    }
  }

  // Report movement violation
  static Future<Map<String, dynamic>> reportMovementViolation(
    String violationType,
    String reason,
    int quizSessionId,
  ) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/report-movement-violation/'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: json.encode({
          'violation_type': violationType,
          'reason': reason,
          'quiz_session_id': quizSessionId,
        }),
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Failed to report violation: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error reporting violation: $e');
    }
  }

  // Start camera monitoring
  static Future<void> startCameraMonitoring(int quizSessionId) async {
    try {
      await http.post(
        Uri.parse('$baseUrl/start-camera-monitoring/'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: json.encode({'quiz_session_id': quizSessionId}),
      );
    } catch (e) {
      print('Failed to start camera monitoring: $e');
    }
  }

  // Stop camera monitoring
  static Future<void> stopCameraMonitoring(int quizSessionId) async {
    try {
      await http.post(
        Uri.parse('$baseUrl/stop-camera-monitoring/'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: json.encode({'quiz_session_id': quizSessionId}),
      );
    } catch (e) {
      print('Failed to stop camera monitoring: $e');
    }
  }

  static Future<Map<String, dynamic>> login(
    String identifier,
    String password,
  ) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/login/'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: json.encode({'identifier': identifier, 'password': password}),
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception(json.decode(response.body)['error']);
      }
    } catch (e) {
      throw Exception('Login failed: $e');
    }
  }

  static Future<Map<String, dynamic>> register(
    String username,
    String email,
    String password,
  ) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/register/'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: json.encode({
          'username': username,
          'email': email,
          'password': password,
        }),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        return json.decode(response.body);
      } else {
        throw Exception(json.decode(response.body)['error']);
      }
    } catch (e) {
      throw Exception('Register failed: $e');
    }
  }
}
