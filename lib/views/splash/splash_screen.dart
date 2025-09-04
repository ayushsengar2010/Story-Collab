import 'package:collabwrite/core/constants/assets.dart';
import 'package:collabwrite/services/auth_service.dart';
import 'package:collabwrite/views/home/home_screen.dart';
import 'package:collabwrite/views/login/login_screen.dart'; // Updated to LoginScreen
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter/foundation.dart'; // For kDebugMode

class SplashScreen extends StatefulWidget {
  final Future<void> Function() onInitializationComplete;

  const SplashScreen({Key? key, required this.onInitializationComplete})
      : super(key: key);

  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;
  final AuthService _authService = AuthService();

  @override
  void initState() {
    super.initState();

    // Initialize animation controller
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    );

    // Define fade-in and fade-out animation
    _animation = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween<double>(begin: 0.0, end: 1.0)
            .chain(CurveTween(curve: Curves.easeIn)),
        weight: 40,
      ),
      TweenSequenceItem(
        tween: ConstantTween<double>(1.0),
        weight: 20,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.0, end: 0.0)
            .chain(CurveTween(curve: Curves.easeOut)),
        weight: 40,
      ),
    ]).animate(_controller);

    // Start animation
    _controller.forward();

    // Navigate after animation completes
    _controller.addStatusListener((status) async {
      if (status == AnimationStatus.completed) {
        if (!mounted) return;

        try {
          // Call the provided initialization callback
          await widget.onInitializationComplete();

          // Check login status
          bool loggedIn = await _authService.isLoggedIn();
          if (kDebugMode) {
            print("SplashScreen: User logged in: $loggedIn");
            if (loggedIn) {
              final userId = await _authService.getCurrentUserId();
              print("SplashScreen: User ID: $userId");
            }
          }

          if (loggedIn) {
            // Navigate to HomeScreen if logged in
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(builder: (context) => const HomeScreen()),
            );
          } else {
            // Navigate to LoginScreen if not logged in
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(builder: (context) => const LoginScreen()),
            );
          }
        } catch (e) {
          if (kDebugMode) {
            print("SplashScreen: Error during initialization: $e");
          }
          // Fallback to LoginScreen on error
          if (mounted) {
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(builder: (context) => const LoginScreen()),
            );
          }
        }
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Center(
        child: FadeTransition(
          opacity: _animation,
          child: SvgPicture.asset(
            AppAssets.logo,
            width: 200,
            height: 200,
          ),
        ),
      ),
    );
  }
}
