import 'package:flutter/material.dart';
import 'kid_quiz_screen.dart';

class KidModeScreen extends StatelessWidget {
  const KidModeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F4FF),
      body: Stack(
        children: [
          Positioned(
            top: -40,
            right: -20,
            child: _buildBubble(const Color(0xFFE1BEE7), 120),
          ),
          Positioned(
            top: 180,
            left: -30,
            child: _buildBubble(const Color(0xFFFFE0B2), 100),
          ),
          Positioned(
            bottom: 120,
            right: -25,
            child: _buildBubble(const Color(0xFFBBDEFB), 110),
          ),
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  _buildHeroCard(),
                  const SizedBox(height: 20),
                  _buildFeaturesCard(),
                  const SizedBox(height: 24),
                  _buildTitle(),
                  const SizedBox(height: 16),
                  _buildKidCategoryButton(
                    context,
                    'computer',
                    '🖥️ Computers',
                    const Color(0xFF42A5F5),
                  ),
                  const SizedBox(height: 14),
                  _buildKidCategoryButton(
                    context,
                    'maths',
                    '🔢 Math',
                    const Color(0xFF66BB6A),
                  ),
                  const SizedBox(height: 14),
                  _buildKidCategoryButton(
                    context,
                    'sports',
                    '⚽ Sports',
                    const Color(0xFFFFA726),
                  ),
                  const SizedBox(height: 22),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () {
                        Navigator.pop(context);
                      },
                      icon: const Icon(Icons.arrow_back_rounded),
                      label: const Text('Back to Normal Mode'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFF5E35B1),
                        side: BorderSide(
                          color: Colors.deepPurple.withOpacity(0.18),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(18),
                        ),
                        backgroundColor: Colors.white.withOpacity(0.9),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeroCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 14,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(18),
            decoration: const BoxDecoration(
              color: Color(0xFFF3E5F5),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.sentiment_very_satisfied_rounded,
              size: 54,
              color: Color(0xFF8E24AA),
            ),
          ),
          const SizedBox(height: 14),
          const Text(
            '🎮 Let’s Play & Learn!',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 30,
              fontWeight: FontWeight.bold,
              color: Color(0xFF7B1FA2),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            'Fun learning made simple for kids!',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 17,
              color: Colors.grey.shade700,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeaturesCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(26),
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
          const Text(
            '🌟 What’s Special:',
            style: TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.bold,
              color: Color(0xFF7B1FA2),
            ),
          ),
          const SizedBox(height: 16),
          _buildFeatureItem(
            iconBg: const Color(0xFFF3E5F5),
            iconColor: const Color(0xFF8E24AA),
            emoji: '🎯',
            title: 'Easy Questions',
            description: 'Perfect for learning step by step!',
          ),
          _buildFeatureItem(
            iconBg: const Color(0xFFFFF3E0),
            iconColor: const Color(0xFFFB8C00),
            emoji: '⏰',
            title: '30 Second Timer',
            description: 'Fast, fun, and exciting!',
          ),
          _buildFeatureItem(
            iconBg: const Color(0xFFE3F2FD),
            iconColor: const Color(0xFF1E88E5),
            emoji: '🎨',
            title: 'Big Colorful Buttons',
            description: 'Easy to tap and play!',
          ),
          _buildFeatureItem(
            iconBg: const Color(0xFFE8F5E9),
            iconColor: const Color(0xFF43A047),
            emoji: '🏆',
            title: 'Earn Stars',
            description: 'Do your best and collect rewards!',
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureItem({
    required Color iconBg,
    required Color iconColor,
    required String emoji,
    required String title,
    required String description,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 9),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 54,
            height: 54,
            decoration: BoxDecoration(
              color: iconBg,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(Icons.star_rounded, color: iconColor, size: 26),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$emoji $title',
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF7B1FA2),
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  description,
                  style: TextStyle(
                    fontSize: 15,
                    color: Colors.grey.shade700,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTitle() {
    return const Text(
      'Choose Your Topic:',
      textAlign: TextAlign.center,
      style: TextStyle(
        fontSize: 28,
        fontWeight: FontWeight.bold,
        color: Color(0xFF6A1B9A),
      ),
    );
  }

  Widget _buildKidCategoryButton(
    BuildContext context,
    String category,
    String displayName,
    Color color,
  ) {
    return SizedBox(
      width: double.infinity,
      height: 82,
      child: ElevatedButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => KidQuizScreen(category: category),
            ),
          );
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: Colors.white,
          elevation: 4,
          shadowColor: color.withOpacity(0.35),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
        ),
        child: Text(
          displayName,
          style: const TextStyle(fontSize: 25, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  Widget _buildBubble(Color color, double size) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color.withOpacity(0.35),
        shape: BoxShape.circle,
      ),
    );
  }
}
