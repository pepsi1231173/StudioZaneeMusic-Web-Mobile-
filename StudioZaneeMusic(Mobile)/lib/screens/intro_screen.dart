import 'dart:async';
import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import 'package:duanbai3/screens/login_screen.dart';

class IntroScreen extends StatefulWidget {
  const IntroScreen({super.key});

  @override
  State<IntroScreen> createState() => _IntroScreenState();
}

class _IntroScreenState extends State<IntroScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;
  double _loadingBarPos = -0.4;

  @override
  void initState() {
    super.initState();

    // 🎬 Hiệu ứng fade-out khi chuyển sang LoginScreen
    _fadeController =
        AnimationController(vsync: this, duration: const Duration(milliseconds: 800));
    _fadeAnimation = Tween<double>(begin: 1, end: 0).animate(_fadeController);

    // ⚡ Thanh loading di chuyển mượt
    Timer.periodic(const Duration(milliseconds: 25), (timer) {
      setState(() {
        _loadingBarPos += 0.01;
        if (_loadingBarPos > 1.0) _loadingBarPos = -0.4;
      });
    });

    // ⏳ Sau 3 giây -> fade out -> sang LoginScreen
    Timer(const Duration(seconds: 3), () async {
      await _fadeController.forward();
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const LoginScreen()),
      );
    });
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          // 🌆 Ảnh nền
          Image.asset('assets/images/BACKROUND.jpg', fit: BoxFit.cover),

          // 🌑 Lớp overlay tối cho nổi logo và chữ
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.black.withOpacity(0.8),
                  Colors.black.withOpacity(0.3),
                ],
                begin: Alignment.bottomCenter,
                end: Alignment.topCenter,
              ),
            ),
          ),

          // 🌟 Logo + Slogan + Thanh loading
          FadeTransition(
            opacity: _fadeAnimation,
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // 🔥 Logo hiệu ứng "Fire Neon"
                  Shimmer.fromColors(
                    baseColor: Colors.deepOrangeAccent.shade100,
                    highlightColor: Colors.yellowAccent,
                    period: const Duration(seconds: 3),
                    child: Image.asset(
                      'assets/images/logo5.png',
                      height: screenHeight * 0.4,
                      fit: BoxFit.contain,
                    ),
                  ),
                  const SizedBox(height: 25),

                  // 🎵 Slogan ánh sáng vàng cam
                  Text(
                    "Nơi âm nhạc thăng hoa cùng bạn",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.grey[300],
                      fontStyle: FontStyle.italic,
                      letterSpacing: 1,
                      fontWeight: FontWeight.w400,
                      shadows: [
                        Shadow(
                          color: Colors.black.withOpacity(0.8),
                          blurRadius: 8,
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 60),

                  // 💫 Thanh loading ánh lửa
                  Container(
                    width: 160,
                    height: 6,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: FractionallySizedBox(
                      alignment: Alignment(-1 + 2 * _loadingBarPos, 0),
                      widthFactor: 0.4,
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [
                              Colors.deepOrangeAccent,
                              Colors.yellowAccent,
                            ],
                          ),
                          borderRadius: BorderRadius.circular(4),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.orangeAccent.withOpacity(0.7),
                              blurRadius: 12,
                              spreadRadius: 2,
                            ),
                          ],
                        ),
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
}
