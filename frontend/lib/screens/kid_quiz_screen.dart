import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/quiz_provider.dart';
import 'home_screen.dart';
import 'kid_results_screen.dart';

class KidQuizScreen extends StatefulWidget {
  final String category;

  const KidQuizScreen({super.key, required this.category});

  @override
  State<KidQuizScreen> createState() => _KidQuizScreenState();
}

class _KidQuizScreenState extends State<KidQuizScreen> {
  String? selectedAnswer;
  Timer? _timer;
  int _timeLeft = 30;
  bool _isTimeUp = false;
  int? _lastQuestionId;
  int? _activeTimerQuestionId;

  final List<Color> _optionColors = const [
    Color(0xFFFF8A80),
    Color(0xFF82B1FF),
    Color(0xFFB9F6CA),
    Color(0xFFFFE082),
  ];

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final quizProvider = Provider.of<QuizProvider>(context, listen: false);

      quizProvider.resetQuiz(); // important
      quizProvider.startQuiz(widget.category);
    });
  }

  @override
  void dispose() {
    _cancelTimer();
    super.dispose();
  }

  Future<void> _confirmQuitQuiz() async {
    final shouldQuit = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Quit Quiz?'),
        content: const Text(
          'Do you want to leave this quiz? Your progress will be lost.',
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Stay'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Quit'),
          ),
        ],
      ),
    );

    if (shouldQuit == true) {
      _cancelTimer();

      final quizProvider = Provider.of<QuizProvider>(context, listen: false);
      quizProvider.resetQuiz();

      if (!mounted) return;

      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const HomeScreen()),
        (route) => false,
      );
    }
  }

  void _cancelTimer() {
    _timer?.cancel();
    _timer = null;
    _activeTimerQuestionId = null;
  }

  void _startTimer(int questionId) {
    _cancelTimer();

    _activeTimerQuestionId = questionId;
    _timeLeft = 30;
    _isTimeUp = false;

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;

      final quizProvider = Provider.of<QuizProvider>(context, listen: false);

      if (_activeTimerQuestionId != quizProvider.currentQuestionId) {
        timer.cancel();
        return;
      }

      setState(() {
        if (_timeLeft > 0) {
          _timeLeft--;
        } else {
          _isTimeUp = true;
          timer.cancel();
          _submitAnswerAutomatically();
        }
      });
    });
  }

  void _submitAnswerAutomatically() {
    final quizProvider = Provider.of<QuizProvider>(context, listen: false);

    if (_activeTimerQuestionId != null &&
        _activeTimerQuestionId != quizProvider.currentQuestionId) {
      return;
    }

    _cancelTimer();

    if (selectedAnswer != null) {
      quizProvider.submitAnswer(selectedAnswer!);
      selectedAnswer = null;
    } else {
      final answers = quizProvider.currentQuestionAnswers;
      if (answers != null && answers.isNotEmpty) {
        quizProvider.submitAnswer(answers.first);
      }
    }
  }

  String _getCategoryDisplayName(String category) {
    switch (category.toLowerCase()) {
      case 'computer':
        return '🖥️ Computers';
      case 'maths':
        return '🔢 Math';
      case 'sports':
        return '⚽ Sports';
      default:
        return category;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFEFF7FF),
      body: Stack(
        children: [
          Positioned(
            top: -40,
            left: -20,
            child: _buildBubble(const Color(0xFFFFD54F), 120),
          ),
          Positioned(
            top: 90,
            right: -30,
            child: _buildBubble(const Color(0xFF80D8FF), 140),
          ),
          Positioned(
            bottom: 90,
            left: -30,
            child: _buildBubble(const Color(0xFFB9F6CA), 130),
          ),
          SafeArea(
            child: Consumer<QuizProvider>(
              builder: (context, quizProvider, child) {
                if (quizProvider.isLoading) {
                  return const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircularProgressIndicator(),
                        SizedBox(height: 18),
                        Text(
                          'Loading a fun question...',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF37474F),
                          ),
                        ),
                      ],
                    ),
                  );
                }

                if (quizProvider.error != null) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.sentiment_dissatisfied_rounded,
                            size: 80,
                            color: Colors.deepOrange,
                          ),
                          const SizedBox(height: 16),
                          const Text(
                            'Oops! Something went wrong',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF37474F),
                            ),
                          ),
                          const SizedBox(height: 10),
                          const Text(
                            'Let’s try again!',
                            style: TextStyle(
                              fontSize: 18,
                              color: Color(0xFF546E7A),
                            ),
                          ),
                          const SizedBox(height: 24),
                          ElevatedButton(
                            onPressed: () {
                              quizProvider.startQuiz(widget.category);
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.white,
                              foregroundColor: Colors.indigo,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 28,
                                vertical: 16,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(18),
                              ),
                            ),
                            child: const Text(
                              'Try Again',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                if (quizProvider.currentQuestion == null) {
                  _cancelTimer();
                  _lastQuestionId = null;

                  return KidResultsScreen(
                    category: widget.category,
                    finalScore: quizProvider.totalScore,
                    totalQuestions: quizProvider.questionHistory.length,
                    questionHistory: quizProvider.questionHistory,
                  );
                }

                if (_lastQuestionId != quizProvider.currentQuestionId) {
                  _lastQuestionId = quizProvider.currentQuestionId;
                  if (quizProvider.currentQuestionId != null) {
                    _startTimer(quizProvider.currentQuestionId!);
                  }
                }

                final int questionNumber =
                    quizProvider.totalQuestionsAnswered + 1;
                const int totalQuestionsForKidMode = 10;
                final double progress =
                    (questionNumber / totalQuestionsForKidMode).clamp(0.0, 1.0);

                return Padding(
                  padding: const EdgeInsets.all(18),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          IconButton(
                            onPressed: () {
                              Navigator.pop(context);
                            },
                            icon: const Icon(
                              Icons.arrow_back_rounded,
                              color: Color(0xFF5D4037),
                            ),
                          ),
                          const Text(
                            'Kid Quiz',
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF5D4037),
                            ),
                          ),
                          IconButton(
                            onPressed: _confirmQuitQuiz,
                            icon: const Icon(
                              Icons.close_rounded,
                              color: Color(0xFF5D4037),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      _buildTopBar(quizProvider),
                      const SizedBox(height: 14),
                      _buildProgressCard(
                        questionNumber,
                        progress,
                        _getCategoryDisplayName(widget.category),
                      ),
                      const SizedBox(height: 16),
                      _buildQuestionCard(
                        quizProvider.currentQuestion!['question_text'],
                      ),
                      const SizedBox(height: 14),
                      Expanded(
                        child: GridView.builder(
                          itemCount: (quizProvider.currentQuestionAnswers ?? [])
                              .length,
                          gridDelegate:
                              const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 2,
                                crossAxisSpacing: 14,
                                mainAxisSpacing: 14,
                                childAspectRatio: 1.0,
                              ),
                          itemBuilder: (context, index) {
                            final answer =
                                quizProvider.currentQuestionAnswers![index];
                            final color =
                                _optionColors[index % _optionColors.length];
                            return _buildKidAnswerGridButton(
                              answer,
                              color,
                              index,
                            );
                          },
                        ),
                      ),
                      if (selectedAnswer != null) ...[
                        const SizedBox(height: 6),
                        const Text(
                          'Nice choice! 😊',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF5D4037),
                          ),
                        ),
                        const SizedBox(height: 12),
                        SizedBox(
                          width: double.infinity,
                          height: 58,
                          child: ElevatedButton(
                            onPressed: _isTimeUp
                                ? null
                                : () {
                                    _cancelTimer();
                                    quizProvider.submitAnswer(selectedAnswer!);
                                    selectedAnswer = null;
                                  },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF43A047),
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(20),
                              ),
                              elevation: 4,
                            ),
                            child: const Text(
                              '🎯 Check My Answer!',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBubble(Color color, double size) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color.withOpacity(0.25),
        shape: BoxShape.circle,
      ),
    );
  }

  Widget _buildTopBar(QuizProvider quizProvider) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.95),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: _buildInfoChip(
              icon: Icons.timer_rounded,
              label: 'Time',
              value: '$_timeLeft s',
              color: _timeLeft <= 10 ? Colors.orange : Colors.green,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildInfoChip(
              icon: Icons.star_rounded,
              label: 'Score',
              value: '${quizProvider.totalScore}',
              color: Colors.purple,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoChip({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: color.withOpacity(0.25)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(width: 8),
          Column(
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 12,
                  color: Color(0xFF607D8B),
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                value,
                style: TextStyle(
                  color: color,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildProgressCard(
    int questionNumber,
    double progress,
    String categoryLabel,
  ) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.95),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Text(
            categoryLabel,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF5E35B1),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            'Question $questionNumber',
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Color(0xFF37474F),
            ),
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 12,
              backgroundColor: Colors.grey.shade200,
              valueColor: const AlwaysStoppedAnimation<Color>(
                Color(0xFF42A5F5),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuestionCard(String question) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 12,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Text(
        '🤔 $question',
        style: const TextStyle(
          fontSize: 23,
          fontWeight: FontWeight.w700,
          color: Color(0xFF4E342E),
          height: 1.35,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }

  Widget _buildKidAnswerGridButton(String answer, Color color, int index) {
    final bool isSelected = selectedAnswer == answer;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(26),
        onTap: _isTimeUp
            ? null
            : () {
                setState(() {
                  selectedAnswer = answer;
                });
              },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          decoration: BoxDecoration(
            color: isSelected ? color : color.withOpacity(0.92),
            borderRadius: BorderRadius.circular(26),
            border: Border.all(
              color: isSelected ? Colors.black26 : Colors.transparent,
              width: 2,
            ),
            boxShadow: [
              BoxShadow(
                color: color.withOpacity(isSelected ? 0.35 : 0.20),
                blurRadius: isSelected ? 12 : 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircleAvatar(
                radius: 20,
                backgroundColor: Colors.white.withOpacity(0.92),
                child: Text(
                  String.fromCharCode(65 + index),
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                    color: Color(0xFF37474F),
                  ),
                ),
              ),
              const SizedBox(height: 14),
              Expanded(
                child: Center(
                  child: Text(
                    isSelected ? '👉 $answer' : answer,
                    textAlign: TextAlign.center,
                    maxLines: 4,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: Colors.black87,
                      height: 1.2,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
