import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:yumbook_frontend/screens/auth/sign_in_welcome_screen.dart';
import 'package:yumbook_frontend/screens/root_shell.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  static const Color _brandOrange = Color(0xFFD45425);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _bootstrap();
    });
  }

  Future<void> _bootstrap() async {
    try {
      await Future.delayed(const Duration(seconds: 2));

      if (!mounted) return;

      final session = Supabase.instance.client.auth.currentSession;

      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) =>
              session != null ? const RootShell() : const SignInWelcomeScreen(),
        ),
      );
    } catch (e, stack) {
      debugPrint('Splash bootstrap error: $e');
      debugPrintStack(stackTrace: stack);

      if (!mounted) return;

      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => const SignInWelcomeScreen(),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _brandOrange,
      body: const SafeArea(
        child: Center(
          child: _YumbookLogoBlock(),
        ),
      ),
    );
  }
}

class _YumbookLogoBlock extends StatelessWidget {
  const _YumbookLogoBlock();

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Image.asset(
          'assets/icons/yumbook_logo_white.png',
          width: 52,
          height: 30,
          fit: BoxFit.contain,
          errorBuilder: (context, error, stackTrace) {
            return const Icon(
              Icons.restaurant_menu,
              color: Colors.white,
              size: 32,
            );
          },
        ),
        const SizedBox(width: 12),
        const Text(
          'Yumbook',
          style: TextStyle(
            color: Colors.white,
            fontSize: 28,
            fontWeight: FontWeight.w700,
            fontFamily: 'Pretendard',
            height: 1.0,
          ),
        ),
      ],
    );
  }
}