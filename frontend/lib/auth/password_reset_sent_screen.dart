import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class PasswordResetSentScreen extends StatefulWidget {
  final String email;

  const PasswordResetSentScreen({
    super.key,
    required this.email,
  });

  @override
  State<PasswordResetSentScreen> createState() => _PasswordResetSentScreenState();
}

class _PasswordResetSentScreenState extends State<PasswordResetSentScreen> {
  static const Color _brandOrange = Color(0xFFD45425);
  static const Color _textDark = Color(0xFF111111);
  static const Color _textGray = Color(0xFF6E6E6E);
  late final TapGestureRecognizer _mailRecognizer;

  @override
  void initState() {
    super.initState();
    _mailRecognizer = TapGestureRecognizer()
      ..onTap = () {
        _openUrl('mailto:yumbook.help@gmail.com');
      };
  }

  @override
  void dispose() {
    _mailRecognizer.dispose();
    super.dispose();
  }

  Future<void> _openUrl(String url) async {
    final uri = Uri.parse(url);
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  Future<void> _openInbox() async {
    await _openUrl('mailto:${widget.email}');
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
              const SizedBox(height: 18),
              Image.asset(
                'assets/images/auth/password_reset_mailbox.png',
                width: 220,
                height: 180,
                fit: BoxFit.contain,
                errorBuilder: (_, __, ___) => const Icon(
                  Icons.mark_email_read_outlined,
                  size: 130,
                  color: _brandOrange,
                ),
              ),
              const SizedBox(height: 22),
              const Text(
                'Password Reset Sent',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: _textDark,
                  fontSize: 28,
                  fontWeight: FontWeight.w700,
                  fontFamily: 'Pretendard',
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'Please check your email in a few minutes.\nWe’ve sent you an email containing password\nrecovery link.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: _textGray,
                  fontSize: 16,
                  fontWeight: FontWeight.w400,
                  fontFamily: 'Pretendard',
                  height: 1.35,
                ),
              ),
              const SizedBox(height: 28),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed:  null, //
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _brandOrange,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Check your email inbox',
                        style: TextStyle(
                          fontFamily: 'Pretendard',
                          fontSize: 17,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      SizedBox(width: 8),
                      Icon(Icons.mail_outline_rounded, size: 18),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 28),
              Text.rich(
                TextSpan(
                  children: [
                    const TextSpan(
                      text: 'Didn’t receive the email?\nContact us at ',
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