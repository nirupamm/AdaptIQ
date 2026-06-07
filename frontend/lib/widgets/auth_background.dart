import 'package:flutter/material.dart';

class AuthBackground extends StatelessWidget {
  final Widget child;

  const AuthBackground({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Gradient base
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.blue.shade50,
                  Colors.purple.shade50,
                  Colors.white,
                ],
              ),
            ),
          ),

          // 🔥 Background logo (NEW)
          Center(
            child: Opacity(
              opacity: 0.08, // subtle
              child: Image.asset('assets/images/adaptiq_logo.png', width: 250),
            ),
          ),

          // Decorative circles
          Positioned(
            top: -40,
            left: -30,
            child: _buildCircle(140, Colors.blue.withOpacity(0.12)),
          ),
          Positioned(
            top: 120,
            right: -40,
            child: _buildCircle(160, Colors.purple.withOpacity(0.10)),
          ),
          Positioned(
            bottom: 80,
            left: -20,
            child: _buildCircle(120, Colors.orange.withOpacity(0.10)),
          ),
          Positioned(
            bottom: -30,
            right: -10,
            child: _buildCircle(140, Colors.pink.withOpacity(0.08)),
          ),

          // Optional sparkle ✨
          Positioned(
            top: 110,
            left: 40,
            child: Icon(
              Icons.auto_awesome,
              color: Colors.amber.withOpacity(0.7),
              size: 24,
            ),
          ),

          SafeArea(child: child),
        ],
      ),
    );
  }

  Widget _buildCircle(double size, Color color) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(shape: BoxShape.circle, color: color),
    );
  }
}
