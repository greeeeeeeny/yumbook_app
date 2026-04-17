import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:yumbook_app/screens/auth/sign_up_verification_screen.dart';
import 'package:yumbook_app/services/local_auth_service.dart';
import 'package:yumbook_app/screens/auth/email_sign_in_screen.dart';

import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:yumbook_app/services/supabase/supabase_auth_service.dart';

class SignUpEmailScreen extends StatefulWidget {
  const SignUpEmailScreen({super.key});

  @override
  State<SignUpEmailScreen> createState() => _SignUpEmailScreenState();
}

class _SignUpEmailScreenState extends State<SignUpEmailScreen> {
  static const Color _brandOrange = Color(0xFFD45425);
  static const Color _textDark = Color(0xFF111111);
  static const Color _textGray = Color(0xFF6E6E6E);
  static const Color _lineGray = Color(0xFFE5E5E5);
  static const Color _placeholderGray = Color(0xFFB4B4B4);
  static const Color _fieldBorder = Color(0xFF5B5B5B);

  final TextEditingController _emailController = TextEditingController();

  late final TapGestureRecognizer _termsRecognizer;
  late final TapGestureRecognizer _privacyRecognizer;

  @override
  void initState() {
    super.initState();
    _termsRecognizer = TapGestureRecognizer()
      ..onTap = () => _openUrl('https://www.yumbook.io/terms-conditions');
    _privacyRecognizer = TapGestureRecognizer()
      ..onTap = () => _openUrl('https://www.yumbook.io/privacy-policy');
  }

  @override
  void dispose() {
    _emailController.dispose();
    _termsRecognizer.dispose();
    _privacyRecognizer.dispose();
    super.dispose();
  }

  Future<void> _openUrl(String url) async {
    final uri = Uri.parse(url);
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

Future<void> _handleContinue() async {
  final email = _emailController.text.trim();

  if (email.isEmpty) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'Please enter your email.',
          style: TextStyle(fontFamily: 'Pretendard'),
        ),
      ),
    );
    return;
  }

  try {
    await SupabaseAuthService.sendSignUpOtp(email: email);
    await LocalAuthService.savePendingSignUpEmail(email);

    if (!mounted) return;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => SignUpVerificationScreen(email: email),
      ),
    );
  } on AuthException catch (e) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          e.message,
          style: const TextStyle(fontFamily: 'Pretendard'),
        ),
      ),
    );
  } catch (e) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Failed to send verification code: $e',
          style: const TextStyle(fontFamily: 'Pretendard'),
        ),
      ),
    );
  }
}
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 30),
          child: Column(
            children: [
              const SizedBox(height: 6),
              Align(
                alignment: Alignment.centerLeft,
                child: IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(
                    Icons.arrow_back_ios_new_rounded,
                    size: 22,
                    color: Color(0xFF383838),
                  ),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ),
              const SizedBox(height: 60),
              const Text(
                'Create your Yumbook account',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: _textDark,
                  fontSize: 28,
                  fontWeight: FontWeight.w700,
                  fontFamily: 'Pretendard',
                ),
              ),
              const SizedBox(height: 28),
              _GrayButton(
                text: 'Continue with Google',
                leading: Image.asset(
                  'assets/icons/google_logo.png',
                  width: 18,
                  height: 18,
                  fit: BoxFit.contain,
                ),
                onTap: () {},
              ),
              const SizedBox(height: 15),
              _GrayButton(
                text: 'Continue with Apple',
                leading: const Icon(
                  Icons.apple,
                  size: 20,
                  color: Colors.black,
                ),
                onTap: () {},
              ),
              const SizedBox(height: 28),
              Row(
                children: const [
                  Expanded(child: Divider(color: _lineGray, thickness: 1)),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 10),
                    child: Text(
                      'Or sign up with email',
                      style: TextStyle(
                        color: _placeholderGray,
                        fontSize: 16,
                        fontWeight: FontWeight.w400,
                        fontFamily: 'Pretendard',
                      ),
                    ),
                  ),
                  Expanded(child: Divider(color: _lineGray, thickness: 1)),
                ],
              ),
              const SizedBox(height: 28),
              SizedBox(
                height: 60,
                child: TextField(
                  controller: _emailController,
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w500,
                    fontFamily: 'Pretendard',
                    color: _textDark,
                  ),
                  decoration: InputDecoration(
                    hintText: 'E-mail',
                    hintStyle: const TextStyle(
                      color: _placeholderGray,
                      fontSize: 17,
                      fontWeight: FontWeight.w600,
                      fontFamily: 'Pretendard',
                    ),
                    prefixIcon: const Padding(
                      padding: EdgeInsets.only(left: 18, right: 12),
                      child: Icon(
                        Icons.mail_outline_rounded,
                        color: _fieldBorder,
                        size: 20,
                      ),
                    ),
                    prefixIconConstraints: const BoxConstraints(
                      minWidth: 50,
                      minHeight: 20,
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(999),
                      borderSide: const BorderSide(color: _fieldBorder, width: 1),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(999),
                      borderSide: const BorderSide(color: _fieldBorder, width: 1.2),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: _handleContinue,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _brandOrange,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                  child: const Text(
                    'Continue',
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w600,
                      fontFamily: 'Pretendard',
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 18),
              GestureDetector(
                onTap: () {
                  Navigator.pushReplacement(
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
                        text: 'Already have an account? ',
                        style: TextStyle(
                          color: _placeholderGray,
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          fontFamily: 'Pretendard',
                        ),
                      ),
                      TextSpan(
                        text: 'Log In',
                        style: TextStyle(
                          color: _brandOrange,
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          fontFamily: 'Pretendard',
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const Spacer(),
              Padding(
                padding: const EdgeInsets.only(bottom: 18),
                child: Text.rich(
                  TextSpan(
                    children: [
                      const TextSpan(
                        text: 'By creating an account,\nyou agree to our ',
                        style: TextStyle(
                          color: _textGray,
                          fontSize: 14,
                          fontWeight: FontWeight.w400,
                          fontFamily: 'Pretendard',
                          height: 1.45,
                        ),
                      ),
                      TextSpan(
                        text: 'Term Sheet',
                        recognizer: _termsRecognizer,
                        style: const TextStyle(
                          color: _textDark,
                          fontSize: 14,
                          fontWeight: FontWeight.w400,
                          fontFamily: 'Pretendard',
                          decoration: TextDecoration.underline,
                        ),
                      ),
                      const TextSpan(text: ', '),
                      TextSpan(
                        text: 'Privacy Policy',
                        recognizer: _privacyRecognizer,
                        style: const TextStyle(
                          color: _textDark,
                          fontSize: 14,
                          fontWeight: FontWeight.w400,
                          fontFamily: 'Pretendard',
                          decoration: TextDecoration.underline,
                        ),
                      ),
                    ],
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _GrayButton extends StatelessWidget {
  final String text;
  final Widget? leading;
  final VoidCallback onTap;

  const _GrayButton({
    required this.text,
    this.leading,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 48,
      child: ElevatedButton(
        onPressed: onTap,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFFE5E5E5),
          foregroundColor: const Color(0xFF111111),
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(999),
          ),
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            if (leading != null)
              Align(alignment: Alignment.centerLeft, child: leading!),
            Text(
              text,
              style: const TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w600,
                fontFamily: 'Pretendard',
              ),
            ),
          ],
        ),
      ),
    );
  }
}