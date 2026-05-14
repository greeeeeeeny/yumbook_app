import 'package:flutter/material.dart';
import 'package:yumbook_app/screens/auth/email_sign_in_screen.dart';

class SignInWelcomeScreen extends StatelessWidget {
  const SignInWelcomeScreen({super.key});

  static const Color _brandOrange = Color(0xFFD45425);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(
            child: Image.asset(
              'assets/images/auth/sign_in_bg.png',
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  color: Colors.grey.shade400,
                  alignment: Alignment.center,
                  child: const Text(
                    'Background image failed to load',
                    style: TextStyle(
                      color: Colors.black,
                      fontFamily: 'Pretendard',
                    ),
                  ),
                );
              },
            ),
          ),

          Positioned.fill(
            child: Container(
              color: Colors.black.withOpacity(0.35),
            ),
          ),

          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 31),
              child: Column(
                children: [

                  const SizedBox(height: 58),

                  SizedBox(
                    height: 44,
                    child: Center(
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Image.asset(
                            'assets/icons/yumbook_logo_white.png',
                            width: 33,
                            height: 19,
                            fit: BoxFit.contain,
                          ),
                          const SizedBox(width: 8),
                          const Text(
                            'Yumbook',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 24,
                              fontWeight: FontWeight.w600,
                              fontFamily: 'Pretendard',
                              height: 1.0,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 74),

                  const Text(
                    'Welcome to Yumbook',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 28,
                      fontWeight: FontWeight.w700,
                      fontFamily: 'Pretendard',
                      height: 1.2,
                    ),
                  ),

                  const SizedBox(height: 10),

                  const Text(
                    'Reserve Korea’s\nmost-loved restaurants',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.w400,
                      fontFamily: 'Pretendard',
                      height: 1.35,
                    ),
                  ),

                  const Spacer(),

                  _SocialButton(
                    label: 'Sign in with Apple',
                    backgroundColor: Colors.white,
                    textColor: Colors.black,
                    borderColor: Colors.white,
                    leading: const Icon(
                      Icons.apple,
                      color: Colors.black,
                      size: 21,
                    ),
                    onTap: () {
                      // TODO: Apple 로그인 연결
                    },
                  ),

                  const SizedBox(height: 12),

                  _SocialButton(
                    label: 'Sign in with Google',
                    backgroundColor: Colors.transparent,
                    textColor: Colors.white,
                    borderColor: Colors.white,
                    leading: Image.asset(
                      'assets/icons/google_logo.png',
                      width: 18,
                      height: 18,
                      fit: BoxFit.contain,
                    ),
                    onTap: () {
                      // TODO: Google 로그인 연결
                    },
                  ),

                  const SizedBox(height: 12),

                  _SocialButton(
                    label: 'Sign in with Email',
                    backgroundColor: Colors.transparent,
                    textColor: Colors.white,
                    borderColor: Colors.white,
                    leading: const Icon(
                      Icons.mail_outline_rounded,
                      color: Colors.white,
                      size: 20,
                    ),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const EmailSignInScreen(),
                        ),
                      );
                    },
                  ),

                  const SizedBox(height: 22),

                  GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const EmailSignInScreen(),
                        ),
                      );
                    },
                    child: const Text.rich(
                      TextSpan(
                        children: [
                          TextSpan(
                            text: 'Need an account? ',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w400,
                              fontFamily: 'Pretendard',
                            ),
                          ),
                          TextSpan(
                            text: 'Sign up →',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                              fontFamily: 'Pretendard',
                              decoration: TextDecoration.underline,
                              decorationColor: Colors.white,
                            ),
                          ),
                        ],
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),

                  const SizedBox(height: 28),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SocialButton extends StatelessWidget {
  final String label;
  final Color backgroundColor;
  final Color textColor;
  final Color borderColor;
  final Widget leading;
  final VoidCallback onTap;

  const _SocialButton({
    required this.label,
    required this.backgroundColor,
    required this.textColor,
    required this.borderColor,
    required this.leading,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 48,
      child: OutlinedButton(
        onPressed: onTap,
        style: OutlinedButton.styleFrom(
          backgroundColor: backgroundColor,
          side: BorderSide(color: borderColor, width: 1),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(999),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 20),
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            Align(
              alignment: Alignment.centerLeft,
              child: leading,
            ),
            Text(
              label,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: textColor,
                fontSize: 17,
                fontWeight: FontWeight.w600,
                fontFamily: 'Pretendard',
                height: 1.0,
              ),
            ),
          ],
        ),
      ),
    );
  }
}