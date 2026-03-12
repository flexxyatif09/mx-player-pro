import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:async';
import 'home_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});
  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with TickerProviderStateMixin {
  late AnimationController _logoCtrl;
  late AnimationController _textCtrl;
  late Animation<double> _logoScale;
  late Animation<double> _logoOpacity;
  late Animation<double> _textOpacity;
  late Animation<Offset> _textSlide;

  @override
  void initState() {
    super.initState();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);

    _logoCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 1000));
    _textCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 700));

    _logoScale = Tween<double>(begin: 0.3, end: 1.0).animate(
        CurvedAnimation(parent: _logoCtrl, curve: Curves.elasticOut));
    _logoOpacity = Tween<double>(begin: 0, end: 1).animate(
        CurvedAnimation(parent: _logoCtrl, curve: const Interval(0, 0.5)));
    _textOpacity = Tween<double>(begin: 0, end: 1).animate(_textCtrl);
    _textSlide = Tween<Offset>(begin: const Offset(0, 0.4), end: Offset.zero).animate(
        CurvedAnimation(parent: _textCtrl, curve: Curves.easeOutCubic));

    _start();
  }

  void _start() async {
    await _logoCtrl.forward();
    await Future.delayed(const Duration(milliseconds: 150));
    await _textCtrl.forward();
    await Future.delayed(const Duration(milliseconds: 900));
    if (mounted) {
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
      Navigator.of(context).pushReplacement(
        PageRouteBuilder(
          pageBuilder: (_, __, ___) => const HomeScreen(),
          transitionsBuilder: (_, anim, __, child) => FadeTransition(opacity: anim, child: child),
          transitionDuration: const Duration(milliseconds: 400),
        ),
      );
    }
  }

  @override
  void dispose() {
    _logoCtrl.dispose();
    _textCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Container(
        decoration: const BoxDecoration(
          gradient: RadialGradient(
            center: Alignment.center,
            radius: 1.4,
            colors: [Color(0xFF0A0A1F), Colors.black],
          ),
        ),
        child: Center(
          child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            AnimatedBuilder(
              animation: _logoCtrl,
              builder: (_, __) => Opacity(
                opacity: _logoOpacity.value,
                child: Transform.scale(
                  scale: _logoScale.value,
                  child: Container(
                    width: 100, height: 100,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: const LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [Color(0xFFCC0000), Color(0xFF550000)],
                      ),
                      border: Border.all(color: const Color(0xFFFF2222), width: 2.5),
                      boxShadow: [BoxShadow(color: Colors.red.withOpacity(0.5), blurRadius: 30, spreadRadius: 5)],
                    ),
                    child: const Center(
                      child: Text('FX',
                        style: TextStyle(color: Colors.white, fontSize: 36, fontWeight: FontWeight.w900, letterSpacing: -1),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),
            AnimatedBuilder(
              animation: _textCtrl,
              builder: (_, __) => Opacity(
                opacity: _textOpacity.value,
                child: SlideTransition(
                  position: _textSlide,
                  child: Column(children: [
                    const Text('FlexX Player',
                      style: TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.w800, letterSpacing: 1.2)),
                    const SizedBox(height: 6),
                    Text('Professional Video Player',
                      style: TextStyle(color: Colors.white.withOpacity(0.45), fontSize: 12, letterSpacing: 2.5)),
                  ]),
                ),
              ),
            ),
            const SizedBox(height: 80),
            AnimatedBuilder(
              animation: _textCtrl,
              builder: (_, __) => Opacity(
                opacity: _textOpacity.value,
                child: SizedBox(
                  width: 100,
                  child: LinearProgressIndicator(
                    backgroundColor: Colors.white10,
                    valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFFCC0000)),
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            ),
          ]),
        ),
      ),
    );
  }
}
