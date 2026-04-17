import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:yumbook_app/screens/auth/reset_password_screen.dart';
import 'package:yumbook_app/screens/auth/sign_up_email_screen.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:yumbook_app/services/supabase/supabase_auth_service.dart';
import 'package:yumbook_app/state/user_profile_store.dart';
import 'package:yumbook_app/screens/root_shell.dart';

class EmailSignInScreen extends StatefulWidget {
  const EmailSignInScreen({super.key});

  @override
  State<EmailSignInScreen> createState() => _EmailSignInScreenState();
}

class _EmailSignInScreenState extends State<EmailSignInScreen> {
  static const Color _brandOrange = Color(0xFFD45425);
  static const Color _textDark = Color(0xFF111111);
  static const Color _textGray = Color(0xFF6E6E6E);
  static const Color _lineGray = Color(0xFFE5E5E5);
  static const Color _placeholderGray = Color(0xFFB4B4B4);
  static const Color _fieldBorder = Color(0xFF5B5B5B);

  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  late final TapGestureRecognizer _termsRecognizer;
  late final TapGestureRecognizer _privacyRecognizer;

  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _termsRecognizer = TapGestureRecognizer()
      ..onTap = () {
        _openUrl('https://www.yumbook.io/terms-conditions');
      };
    _privacyRecognizer = TapGestureRecognizer()
      ..onTap = () {
        _openUrl('https://www.yumbook.io/privacy-policy');
      };

    _loadSavedEmail();
  }

  Future<void> _loadSavedEmail() async {}

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _termsRecognizer.dispose();
    _privacyRecognizer.dispose();
    super.dispose();
  }

  Future<void> _openUrl(String url) async {
    final uri = Uri.parse(url);
    final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);

    if (!ok && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Unable to open the link.',
            style: TextStyle(fontFamily: 'Pretendard'),
          ),
        ),
      );
    }
  }

Future<void> _handleContinue() async {
  final email = _emailController.text.trim();
  final password = _passwordController.text.trim();

  if (email.isEmpty || password.isEmpty) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'Please enter your email and password.',
          style: TextStyle(fontFamily: 'Pretendard'),
        ),
      ),
    );
    return;
  }

  setState(() => _isLoading = true);

  try {
    await SupabaseAuthService.signIn(
      email: email,
      password: password,
    );

    UserProfileStore.instance.updateEmail(email);

    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const RootShell()),
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
  } catch (_) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'Login failed. Please try again.',
          style: TextStyle(fontFamily: 'Pretendard'),
        ),
      ),
    );
  } finally {
    if (mounted) {
      setState(() => _isLoading = false);
    }
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
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 6),
              IconButton(
                onPressed: () {
                  Navigator.pop(context);
                },
                icon: const Icon(
                  Icons.arrow_back_ios_new_rounded,
                  size: 22,
                  color: Color(0xFF383838),
                ),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
              const SizedBox(height: 30),
              const Text(
                'Welcome back,',
                style: TextStyle(
                  color: _textDark,
                  fontSize: 28,
                  fontWeight: FontWeight.w700,
                  fontFamily: 'Pretendard',
                  height: 1.2,
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'To sign in to an account in the application,\nenter your email and password.',
                style: TextStyle(
                  color: _textGray,
                  fontSize: 16,
                  fontWeight: FontWeight.w400,
                  fontFamily: 'Pretendard',
                  height: 1.35,
                ),
              ),
              const SizedBox(height: 26),
              _AuthTextField(
                controller: _emailController,
                hintText: 'E-mail',
                prefix: const Icon(
                  Icons.mail_outline_rounded,
                  color: _fieldBorder,
                  size: 20,
                ),
              ),
              const SizedBox(height: 18),
              _AuthTextField(
                controller: _passwordController,
                hintText: 'Password',
                obscureText: true,
                prefix: const Icon(
                  Icons.lock_outline_rounded,
                  color: _fieldBorder,
                  size: 20,
                ),
              ),
              const SizedBox(height: 22),
              Center(
                child: GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ResetPasswordScreen(
                          initialEmail: _emailController.text.trim(),
                        ),
                      ),
                    );
                  },
                  child: const Text(
                    'Forgot password?',
                    style: TextStyle(
                      color: _brandOrange,
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      fontFamily: 'Pretendard',
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 30),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _handleContinue,
                  style: ElevatedButton.styleFrom(
                    elevation: 0,
                    backgroundColor: _brandOrange,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(999),
                    ),
                    textStyle: const TextStyle(
                      fontFamily: 'Pretendard',
                      fontSize: 17,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.2,
                            color: Colors.white,
                          ),
                        )
                      : const Text('Continue'),
                ),
              ),
              const SizedBox(height: 28),
              Row(
                children: const [
                  Expanded(child: Divider(color: _lineGray, thickness: 1)),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 10),
                    child: Text(
                      'Don’t have an account yet?',
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
              const SizedBox(height: 24),
              _GrayButton(
                text: 'Create an account',
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const SignUpEmailScreen(),
                    ),
                  );
                },
              ),
              const SizedBox(height: 15),
              _GrayButton(
                text: 'Sign in with Google',
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
                text: 'Sign in with Apple',
                leading: const Icon(
                  Icons.apple,
                  size: 20,
                  color: Colors.black,
                ),
                onTap: () {},
              ),
              const Spacer(),
              Center(
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 18),
                  child: Text.rich(
                    TextSpan(
                      children: [
                        const TextSpan(
                          text:
                              'By clicking “Continue”, I have read and agree\nwith the ',
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
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AuthTextField extends StatelessWidget {
  final TextEditingController controller;
  final String hintText;
  final Widget prefix;
  final bool obscureText;

  const _AuthTextField({
    required this.controller,
    required this.hintText,
    required this.prefix,
    this.obscureText = false,
  });

  static const Color _border = Color(0xFF5B5B5B);
  static const Color _hint = Color(0xFFB4B4B4);

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 60,
      child: TextField(
        controller: controller,
        obscureText: obscureText,
        style: const TextStyle(
          fontSize: 17,
          fontWeight: FontWeight.w500,
          fontFamily: 'Pretendard',
          color: Color(0xFF111111),
        ),
        decoration: InputDecoration(
          hintText: hintText,
          hintStyle: const TextStyle(
            color: _hint,
            fontSize: 17,
            fontWeight: FontWeight.w600,
            fontFamily: 'Pretendard',
          ),
          prefixIcon: Padding(
            padding: const EdgeInsets.only(left: 18, right: 12),
            child: prefix,
          ),
          prefixIconConstraints: const BoxConstraints(
            minWidth: 50,
            minHeight: 20,
          ),
          contentPadding: const EdgeInsets.symmetric(vertical: 18),
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

  static const Color _bg = Color(0xFFE5E5E5);
  static const Color _text = Color(0xFF111111);

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 48,
      child: ElevatedButton(
        onPressed: onTap,
        style: ElevatedButton.styleFrom(
          backgroundColor: _bg,
          foregroundColor: _text,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(999),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 18),
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            if (leading != null)
              Align(
                alignment: Alignment.centerLeft,
                child: leading!,
              ),
            Text(
              text,
              style: const TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w600,
                fontFamily: 'Pretendard',
                color: _text,
              ),
            ),
          ],
        ),
      ),
    );
  }
}