import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:async';
import '../providers/quiz_provider.dart';
import 'results_screen.dart';
import 'home_screen.dart';

class QuizScreen extends StatefulWidget {
  final String category;

  const QuizScreen({super.key, required this.category});

  @override
  _QuizScreenState createState() => _QuizScreenState();
}

class _QuizScreenState extends State<QuizScreen> {
  String? selectedAnswer;
  Timer? _timer;
  int _timeLeft = 30;
  bool _isTimeUp = false;
  int? _lastQuestionId;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<QuizProvider>(
        context,
        listen: false,
      ).startQuiz(widget.category);
    });
  }

  Future<void> _confirmQuitQuiz() async {
    final shouldQuit = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Quit Quiz?'),
        content: const Text(
          'Are you sure you want to quit? Your current progress will be lost.',
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
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
      _timer?.cancel();
      _timer = null;

      final quizProvider = Provider.of<QuizProvider>(context, listen: false);
      quizProvider.resetQuiz();

      if (!mounted) return;

      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const HomeScreen()),
        (route) => false,
      );
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _timer = null;
    super.dispose();
  }

  void _startTimer() {
    _timer?.cancel();
    _timeLeft = 30;
    _isTimeUp = false;

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;
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
    if (selectedAnswer != null) {
      quizProvider.submitAnswer(selectedAnswer!);
      selectedAnswer = null;
      return;
    }

    final answers = quizProvider.currentQuestionAnswers;
    if (answers != null && answers.isNotEmpty) {
      quizProvider.submitAnswer(answers.first);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('${_getCategoryDisplayName(widget.category)} Quiz'),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.black87,
        actions: [
          IconButton(
            icon: const Icon(Icons.close_rounded),
            tooltip: 'Quit Quiz',
            onPressed: _confirmQuitQuiz,
          ),
        ],
      ),
      body: Consumer<QuizProvider>(
        builder: (context, quizProvider, child) {
          if (quizProvider.isLoading) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Loading question...'),
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
                      Icons.error_outline,
                      size: 70,
                      color: Colors.red,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Something went wrong',
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      quizProvider.error!,
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey[700]),
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: () => quizProvider.startQuiz(widget.category),
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              ),
            );
          }

          if (quizProvider.currentQuestion == null) {
            _timer?.cancel();
            _timer = null;
            _lastQuestionId = null;

            if (quizProvider.isCheatingDetected) {
              return _buildCheatingDetectedScreen(quizProvider);
            }

            return ResultsScreen(
              category: widget.category,
              finalScore: quizProvider.totalScore,
              totalQuestions: quizProvider.questionHistory.length,
              questionHistory: quizProvider.questionHistory,
            );
          }

          if (_lastQuestionId != quizProvider.currentQuestionId) {
            _lastQuestionId = quizProvider.currentQuestionId;
            _startTimer();
          }

          return Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Colors.blue.shade50, Colors.white],
              ),
            ),
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildTopStats(quizProvider),

                    if (quizProvider.isMonitoring) ...[
                      const SizedBox(height: 14),
                      _buildMonitoringStatus(quizProvider),
                    ],

                    const SizedBox(height: 18),

                    Text(
                      'Question ${quizProvider.totalQuestionsAnswered + 1}',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                        fontWeight: FontWeight.w600,
                      ),
                    ),

                    const SizedBox(height: 10),

                    _buildQuestionCard(quizProvider),

                    const SizedBox(height: 18),

                    Expanded(
                      child: ListView(
                        children: (quizProvider.currentQuestionAnswers ?? [])
                            .map((answer) => _buildAnswerButton(answer))
                            .toList(),
                      ),
                    ),

                    const SizedBox(height: 12),

                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton(
                        onPressed: (_isTimeUp || selectedAnswer == null)
                            ? null
                            : () {
                                _timer?.cancel();
                                _timer = null;
                                quizProvider.submitAnswer(selectedAnswer!);
                                selectedAnswer = null;
                              },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue,
                          foregroundColor: Colors.white,
                          disabledBackgroundColor: Colors.grey.shade300,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        child: Text(
                          selectedAnswer == null
                              ? 'Select an Answer'
                              : 'Submit Answer',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 10),

                    if (quizProvider.isMonitoring)
                      _buildTestWarningButton(quizProvider),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildTopStats(QuizProvider quizProvider) {
    return Row(
      children: [
        Expanded(
          child: _buildStatChip(
            icon: Icons.stars_rounded,
            label: 'Score',
            value: '${quizProvider.totalScore}',
            color: Colors.blue,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _buildStatChip(
            icon: Icons.timer_outlined,
            label: 'Time',
            value: '$_timeLeft s',
            color: _timeLeft <= 10 ? Colors.red : Colors.green,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _buildStatChip(
            icon: Icons.trending_up,
            label: 'Difficulty',
            value: quizProvider.currentDifficulty.toUpperCase(),
            color: _getDifficultyColor(quizProvider.currentDifficulty),
          ),
        ),
      ],
    );
  }

  Widget _buildStatChip({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.25)),
      ),
      child: Column(
        children: [
          Icon(icon, size: 20, color: color),
          const SizedBox(height: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: Colors.grey[700],
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 13,
              color: color,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuestionCard(QuizProvider quizProvider) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Text(
        quizProvider.currentQuestion!['question_text'],
        style: const TextStyle(
          fontSize: 20,
          height: 1.4,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildAnswerButton(String answer) {
    final bool isSelected = selectedAnswer == answer;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      margin: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: isSelected ? Colors.blue : Colors.white,
        borderRadius: BorderRadius.circular(16),
        elevation: isSelected ? 4 : 1,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () {
            setState(() {
              selectedAnswer = answer;
            });
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isSelected ? Colors.blue : Colors.grey.shade300,
                width: 1.5,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  isSelected
                      ? Icons.radio_button_checked
                      : Icons.radio_button_off,
                  color: isSelected ? Colors.white : Colors.grey.shade500,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    answer,
                    style: TextStyle(
                      fontSize: 15,
                      color: isSelected ? Colors.white : Colors.black87,
                      fontWeight: isSelected
                          ? FontWeight.w600
                          : FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Color _getDifficultyColor(String difficulty) {
    switch (difficulty.toLowerCase()) {
      case 'easy':
        return Colors.green;
      case 'medium':
        return Colors.orange;
      case 'hard':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  Widget _buildMonitoringStatus(QuizProvider quizProvider) {
    final bool hasWarning = quizProvider.lastWarning != null;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: hasWarning
            ? Colors.red.withOpacity(0.08)
            : Colors.orange.withOpacity(0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: hasWarning
              ? Colors.red.withOpacity(0.25)
              : Colors.orange.withOpacity(0.25),
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Icon(
                Icons.camera_alt_rounded,
                color: hasWarning ? Colors.red : Colors.orange,
                size: 20,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'AI Monitoring Active',
                  style: TextStyle(
                    color: hasWarning ? Colors.red[800] : Colors.orange[800],
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: hasWarning ? Colors.red : Colors.orange,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${quizProvider.warningCount}/${quizProvider.maxWarnings}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          if (quizProvider.lastWarning != null) ...[
            const SizedBox(height: 10),
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                quizProvider.lastWarning!,
                style: TextStyle(
                  color: Colors.red[800],
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
          if (quizProvider.monitoringStatus != null) ...[
            const SizedBox(height: 6),
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                quizProvider.monitoringStatus!,
                style: TextStyle(color: Colors.grey[700], fontSize: 12),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildTestWarningButton(QuizProvider quizProvider) {
    return OutlinedButton.icon(
      onPressed: () {
        if (quizProvider.monitoringService != null &&
            quizProvider.quizSessionId != null) {
          quizProvider.monitoringService!.addTestWarning(
            'Test warning triggered',
            quizProvider.quizSessionId!,
          );
        }
      },
      icon: const Icon(Icons.bug_report_outlined),
      label: const Text('Trigger Test Warning'),
      style: OutlinedButton.styleFrom(
        foregroundColor: Colors.deepPurple,
        side: BorderSide(color: Colors.deepPurple.withOpacity(0.4)),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
    );
  }

  Widget _buildCheatingDetectedScreen(QuizProvider quizProvider) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Colors.red.shade50, Colors.white],
        ),
      ),
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 450),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.block_rounded, size: 90, color: Colors.red),
                const SizedBox(height: 20),
                Text(
                  'Quiz Terminated',
                  style: TextStyle(
                    fontSize: 30,
                    fontWeight: FontWeight.bold,
                    color: Colors.red[800],
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Maximum warnings exceeded.\nYou are forced to leave the quiz.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 18,
                    color: Colors.grey[700],
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 28),
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(18),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      Text(
                        'Warning Limit Exceeded',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.red[800],
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'You exceeded the maximum number of warnings during the quiz. '
                        'For this reason, you have been forced to leave the quiz.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 15,
                          color: Colors.grey[700],
                          height: 1.5,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 28),
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: () {
                      quizProvider.resetQuiz();
                      Navigator.of(context).pushAndRemoveUntil(
                        MaterialPageRoute(builder: (_) => const HomeScreen()),
                        (route) => false,
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: const Text(
                      'Go Home',
                      style: TextStyle(fontSize: 18),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _getCategoryDisplayName(String category) {
    switch (category.toLowerCase()) {
      case 'computer':
        return 'Science: Computers';
      case 'maths':
        return 'Mathematics';
      case 'sports':
        return 'Sports';
      default:
        return category;
    }
  }
}
