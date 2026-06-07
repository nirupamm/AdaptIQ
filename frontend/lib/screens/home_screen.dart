import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../services/api_service.dart';
import 'login_screen.dart';
import 'quiz_screen.dart';
import 'kid_mode_screen.dart';
import 'opencv_test_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String _displayName = 'User';
  Map<String, dynamic>? stats;
  bool isLoadingStats = true;

  @override
  void initState() {
    super.initState();
    _loadDisplayName();
    _loadStats();
  }

  Future<void> _loadDisplayName() async {
    final name = await AuthService.getUsername();
    if (!mounted) return;
    setState(() {
      _displayName = (name != null && name.trim().isNotEmpty) ? name : 'User';
    });
  }

  Future<void> _loadStats() async {
    try {
      final data = await ApiService.getDashboardStats();

      if (!mounted) return;

      setState(() {
        stats = data;
        isLoadingStats = false;
      });
    } catch (e) {
      debugPrint('Error loading stats: $e');

      if (!mounted) return;

      setState(() {
        isLoadingStats = false;
      });
    }
  }

  Future<void> _confirmLogout() async {
    final shouldLogout = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Logout'),
        content: const Text('Are you sure you want to logout?'),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Logout'),
          ),
        ],
      ),
    );

    if (shouldLogout == true) {
      await AuthService.logout();

      if (!mounted) return;

      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const LoginScreen()),
        (route) => false,
      );
    }
  }

  String _formatCategory(String? category) {
    if (category == null || category.trim().isEmpty || category == 'N/A') {
      return 'N/A';
    }

    switch (category.toLowerCase()) {
      case 'computer':
        return 'Computers';
      case 'maths':
        return 'Mathematics';
      case 'sports':
        return 'Sports';
      default:
        return category[0].toUpperCase() + category.substring(1);
    }
  }

  IconData _categoryIcon(String? category) {
    switch ((category ?? '').toLowerCase()) {
      case 'computer':
        return Icons.computer_rounded;
      case 'maths':
        return Icons.calculate_rounded;
      case 'sports':
        return Icons.sports_soccer_rounded;
      default:
        return Icons.school_rounded;
    }
  }

  void _showCategoryPicker() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 30),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 50,
                height: 5,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
              const SizedBox(height: 18),
              const Text(
                'Choose a Subject',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 18),
              _buildCategoryTile(
                'Computers',
                'computer',
                Icons.computer_rounded,
                Colors.blue,
              ),
              const SizedBox(height: 12),
              _buildCategoryTile(
                'Mathematics',
                'maths',
                Icons.calculate_rounded,
                Colors.green,
              ),
              const SizedBox(height: 12),
              _buildCategoryTile(
                'Sports',
                'sports',
                Icons.sports_soccer_rounded,
                Colors.orange,
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildCategoryTile(
    String title,
    String category,
    IconData icon,
    Color color,
  ) {
    return Material(
      color: color.withOpacity(0.10),
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: () async {
          Navigator.pop(context);

          await Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => QuizScreen(category: category)),
          );

          await _loadStats();
        },
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
          child: Row(
            children: [
              CircleAvatar(
                radius: 24,
                backgroundColor: color.withOpacity(0.18),
                child: Icon(icon, color: color),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const Icon(Icons.arrow_forward_ios_rounded, size: 18),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 19,
          fontWeight: FontWeight.bold,
          color: Color(0xFF3E2C7B),
        ),
      ),
    );
  }

  Widget _buildInfoCard({
    required Widget child,
    EdgeInsets padding = const EdgeInsets.all(18),
  }) {
    return Container(
      width: double.infinity,
      padding: padding,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.96),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: child,
    );
  }

  @override
  Widget build(BuildContext context) {
    final String bestSubject = _formatCategory(stats?['best_subject']);
    final String lastPlayed = _formatCategory(stats?['last_played']);
    final int totalScore = stats?['total_score'] ?? 0;
    final int totalQuizzes = stats?['total_quizzes'] ?? 0;
    final int bestScore = stats?['best_score'] ?? 0;

    return Scaffold(
      appBar: AppBar(
        title: const Text('AdaptIQ'),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.black87,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout_rounded),
            onPressed: _confirmLogout,
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadStats,
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Colors.blue.shade50,
                Colors.purple.shade50,
                Colors.white,
              ],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
          child: SafeArea(
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Welcome back, $_displayName 👋',
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF3E2C7B),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Ready for another smart quiz session?',
                    style: TextStyle(color: Colors.grey.shade700, fontSize: 15),
                  ),
                  const SizedBox(height: 20),

                  _buildInfoCard(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      children: [
                        Opacity(
                          opacity: 0.90,
                          child: Image.asset(
                            'assets/images/adaptiq_logo.png',
                            height: 82,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: _StatCard(
                                icon: Icons.star_rounded,
                                label: 'Score',
                                value: isLoadingStats ? '...' : '$totalScore',
                                color: Colors.amber,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _StatCard(
                                icon: Icons.quiz_rounded,
                                label: 'Quizzes',
                                value: isLoadingStats ? '...' : '$totalQuizzes',
                                color: Colors.blue,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _StatCard(
                                icon: Icons.track_changes_rounded,
                                label: 'Best',
                                value: isLoadingStats ? '...' : '$bestScore',
                                color: Colors.green,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 18),

                  _buildSectionTitle('Your Performance'),
                  _buildInfoCard(
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: Colors.blue.withOpacity(0.10),
                            borderRadius: BorderRadius.circular(18),
                          ),
                          child: Icon(
                            _categoryIcon(stats?['best_subject']),
                            color: Colors.blue,
                            size: 34,
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Best Subject',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey.shade600,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                bestSubject,
                                style: const TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF3E2C7B),
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Best Score: $bestScore',
                                style: const TextStyle(
                                  fontSize: 16,
                                  color: Colors.teal,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Icon(
                          Icons.emoji_events_rounded,
                          color: Colors.amber,
                          size: 38,
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 18),

                  _buildInfoCard(
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.deepPurple.withOpacity(0.10),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: const Icon(
                            Icons.history_rounded,
                            color: Colors.deepPurple,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Last Played',
                                style: TextStyle(
                                  color: Colors.grey.shade600,
                                  fontSize: 13,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                lastPlayed,
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 22),

                  _buildSectionTitle('Quick Actions'),
                  SizedBox(
                    width: double.infinity,
                    height: 60,
                    child: ElevatedButton.icon(
                      onPressed: _showCategoryPicker,
                      icon: const Icon(
                        Icons.play_circle_fill_rounded,
                        size: 28,
                      ),
                      label: const Text(
                        'Start Quiz',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF8E5AF7),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(22),
                        ),
                        elevation: 5,
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  SizedBox(
                    width: double.infinity,
                    height: 60,
                    child: ElevatedButton.icon(
                      onPressed: () async {
                        await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const KidModeScreen(),
                          ),
                        );
                        await _loadStats();
                      },
                      icon: const Icon(Icons.sports_esports_rounded, size: 28),
                      label: const Text(
                        'Kid Mode',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF4FC3F7),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(22),
                        ),
                        elevation: 5,
                      ),
                    ),
                  ),

                  const SizedBox(height: 22),

                  _buildSectionTitle('Learning Insights'),
                  Row(
                    children: [
                      Expanded(
                        child: _buildInfoCard(
                          child: Column(
                            children: [
                              const Icon(
                                Icons.local_fire_department_rounded,
                                color: Colors.orange,
                                size: 32,
                              ),
                              const SizedBox(height: 8),
                              const Text(
                                'Current Streak',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Colors.grey,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                totalQuizzes > 0 ? 'Active' : '0',
                                style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF3E2C7B),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildInfoCard(
                          child: Column(
                            children: [
                              const Icon(
                                Icons.analytics_rounded,
                                color: Colors.teal,
                                size: 32,
                              ),
                              const SizedBox(height: 8),
                              const Text(
                                'Progress',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Colors.grey,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                totalScore > 0 ? 'Improving' : 'Starting',
                                style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF3E2C7B),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 22),

                  _buildSectionTitle('Recent Activity'),
                  _buildInfoCard(
                    child: Column(
                      children: [
                        _RecentActivityRow(
                          icon: _categoryIcon(stats?['last_played']),
                          title: 'Last Played Quiz',
                          subtitle: lastPlayed,
                        ),
                        const Divider(height: 22),
                        _RecentActivityRow(
                          icon: _categoryIcon(stats?['best_subject']),
                          title: 'Strongest Category',
                          subtitle: bestSubject,
                        ),
                        const Divider(height: 22),
                        _RecentActivityRow(
                          icon: Icons.scoreboard_rounded,
                          title: 'Highest Recorded Score',
                          subtitle: '$bestScore points',
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 22),

                  _buildSectionTitle('Achievement'),
                  _buildInfoCard(
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: Colors.amber.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(18),
                          ),
                          child: const Icon(
                            Icons.workspace_premium_rounded,
                            color: Colors.amber,
                            size: 34,
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Keep going!',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF3E2C7B),
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                totalQuizzes > 0
                                    ? 'You have completed $totalQuizzes quiz sessions so far.'
                                    : 'Start your first quiz to unlock progress and achievements.',
                                style: TextStyle(
                                  color: Colors.grey.shade700,
                                  height: 1.35,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 22),

                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => OpenCVTestScreen()),
                        );
                      },
                      icon: const Icon(Icons.camera_alt_rounded),
                      label: const Text('Test Face Detection'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFF5E35B1),
                        side: BorderSide(
                          color: Colors.deepPurple.withOpacity(0.25),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(18),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _StatCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.10),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(
            label,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 11,
              color: Colors.grey,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

class _RecentActivityRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;

  const _RecentActivityRow({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        CircleAvatar(
          backgroundColor: Colors.deepPurple.withOpacity(0.10),
          child: Icon(icon, color: const Color(0xFF5E35B1)),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: TextStyle(color: Colors.grey.shade600)),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
