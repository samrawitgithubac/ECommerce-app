import 'package:flutter/material.dart';

import '../../../../core/widgets/language_toggle.dart';

class CoverPage extends StatefulWidget {
  const CoverPage({super.key});

  @override
  State<CoverPage> createState() => _CoverPageState();
}

class _CoverPageState extends State<CoverPage> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );
    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.elasticOut),
    );
    _controller.forward();
    _navigateToSignIn();
  }

  void _navigateToSignIn() async {
    await Future.delayed(const Duration(seconds: 3));
    if (mounted) {
      Navigator.pushNamed(context, '/sign_in_page');
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF3F51F3), Color(0xFF6C63FF), Color(0xFF3F51F3)],
          ),
        ),
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: ScaleTransition(
            scale: _scaleAnimation,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.15),
                        blurRadius: 30,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: const Text(
                    'ECOM',
                    style: TextStyle(
                      fontFamily: 'CaveatBrush',
                      fontSize: 80,
                      color: Color(0xFF3F51F3),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Your Premium Shop',
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 18,
                    fontWeight: FontWeight.w400,
                    color: Colors.white70,
                    letterSpacing: 2,
                  ),
                ),
                const SizedBox(height: 32),
                const LanguageToggle(),
                const SizedBox(height: 24),
                SizedBox(
                  width: 32,
                  height: 32,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.5,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white.withOpacity(0.7)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
