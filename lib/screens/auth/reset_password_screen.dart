import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:yumbook_app/screens/auth/password_reset_sent_screen.dart';

import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:yumbook_app/services/supabase/supabase_auth_service.dart';

class ResetPasswordScreen extends StatefulWidget {
  final String initialEmail;

  const ResetPasswordScreen({
    super.key,
    this.initialEmail = '',
  });

  @override
  State<ResetPasswordScreen> createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends State<ResetPasswordScreen> {
  static const Color _brandOrange = Color(0xFFD45425);
  static const Color _textDark = Color(0xFF111111);
  static const Color _textGray = Color(0xFF6E6E6E);
  static const Color _border = Color(0xFF383838);
  static const Color _placeholderGray = Color(0xFFB4B4B4);

  late final TextEditingController _emailController;
  late final TapGestureRecognizer _mailRecognizer;

  @override
  void initState() {
    super.initState();
    _emailController = TextEditingController(text: widget.initialEmail);
    _mailRecognizer = TapGestureRecognizer()
      ..onTap = () {
        _openUrl('mailto:yumbook.help@gmail.com');
      };
  }

  @override
  void dispose() {
    _emailController.dispose();
    _mailRecognizer.dispose();
    super.dispose();
  }

  Future<void> _openUrl(String url) async {
    final uri = Uri.parse(url);
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  Future<void> _handleResetPassword() async {
  final email = _emailController.text.trim();

  if (email.isEmpty) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'Please enter your email address.',
          style: TextStyle(fontFamily: 'Pretendard'),
        ),
      ),
    );
    return;
  }

 try {
  await SupabaseAuthService.sendPasswordReset(email: email);

  if (!mounted) return;
  Navigator.push(
    context,
    MaterialPageRoute(
      builder: (_) => PasswordResetSentScreen(email: email),
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
          'Failed to send reset email: $e',
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
                    color: _border,
                  ),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ),
              const SizedBox(height: 10),
              Image.asset(
                'assets/images/auth/reset_password_lock.png',
                width: 180,
                height: 180,
                fit: BoxFit.contain,
                errorBuilder: (_, __, ___) => const Icon(
                  Icons.lock_reset_rounded,
                  size: 120,
                  color: _brandOrange,
                ),
              ),
              const SizedBox(height: 22),
              const Text(
                'Reset Password',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: _textDark,
                  fontSize: 28,
                  fontWeight: FontWeight.w700,
                  fontFamily: 'Pretendard',
                ),
              ),
              const SizedBox(height: 10),
              const Text(
                'Enter your email to reset your password.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: _textGray,
                  fontSize: 16,
                  fontWeight: FontWeight.w400,
                  fontFamily: 'Pretendard',
                ),
              ),
              const SizedBox(height: 28),
              SizedBox(
                height: 48,
                child: TextField(
                  controller: _emailController,
                  style: const TextStyle(
                    fontFamily: 'Pretendard',
                    fontSize: 16,
                    color: _textDark,
                  ),
                  decoration: InputDecoration(
                    hintText: 'Enter your email address',
                    hintStyle: const TextStyle(
                      color: _placeholderGray,
                      fontFamily: 'Pretendard',
                      fontSize: 16,
                    ),
                    prefixIcon: const Icon(
                      Icons.mail_outline_rounded,
                      color: _border,
                      size: 20,
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(999),
                      borderSide: const BorderSide(color: _border, width: 1),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(999),
                      borderSide: const BorderSide(color: _border, width: 1.2),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: _handleResetPassword,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _brandOrange,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                  child: const Text(
                    'Reset Password',
                    style: TextStyle(
                      fontFamily: 'Pretendard',
                      fontSize: 17,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Text.rich(
                TextSpan(
                  children: [
                    const TextSpan(
                      text: 'Don’t remember your email?\nContact us at ',
                      style: TextStyle(
                        color: _textGray,
                        fontSize: 16,
                        fontFamily: 'Pretendard',
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                    TextSpan(
                      text: 'yumbook.help@gmail.com',
                      recognizer: _mailRecognizer,
                      style: const TextStyle(
                        color: _brandOrange,
                        fontSize: 16,
                        fontFamily: 'Pretendard',
                        fontWeight: FontWeight.w400,
                        decoration: TextDecoration.underline,
                      ),
                    ),
                  ],
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}