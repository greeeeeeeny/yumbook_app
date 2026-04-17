import 'package:flutter/material.dart';
import 'package:yumbook_app/screens/root_shell.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:yumbook_app/state/user_profile_store.dart';

import 'package:yumbook_app/services/supabase/supabase_auth_service.dart';

class CreateAccountScreen extends StatefulWidget {
  final String email;

  const CreateAccountScreen({
    super.key,
    required this.email,
  });

  @override
  State<CreateAccountScreen> createState() => _CreateAccountScreenState();
}

class _CreateAccountScreenState extends State<CreateAccountScreen> {
  static const Color _brandOrange = Color(0xFFD45425);
  static const Color _textDark = Color(0xFF111111);
  static const Color _placeholderGray = Color(0xFFB4B4B4);
  static const Color _fieldBorder = Color(0xFF383838);

  final TextEditingController _userNameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();

  bool _passwordHidden = true;
  bool _confirmPasswordHidden = true;
  bool _isSaving = false;

  @override
  void dispose() {
    _userNameController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

 Future<void> _handleCreateAccount() async {
  final userName = _userNameController.text.trim();
  final password = _passwordController.text.trim();
  final confirmPassword = _confirmPasswordController.text.trim();

  if (userName.isEmpty || password.isEmpty || confirmPassword.isEmpty) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'Please complete all fields.',
          style: TextStyle(fontFamily: 'Pretendard'),
        ),
      ),
    );
    return;
  }

  if (password != confirmPassword) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'Passwords do not match.',
          style: TextStyle(fontFamily: 'Pretendard'),
        ),
      ),
    );
    return;
  }

  setState(() => _isSaving = true);

  try {
    await SupabaseAuthService.completeSignUp(
      email: widget.email,
      password: password,
      userName: userName,
    );

    final currentUser = SupabaseAuthService.currentUser;

    UserProfileStore.instance.updateName(userName);
    UserProfileStore.instance.updateEmail(
      currentUser?.email ?? widget.email,
    );

    if (!mounted) return;

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const RootShell()),
      (route) => false,
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
          'Create account failed: $e',
          style: const TextStyle(fontFamily: 'Pretendard'),
        ),
      ),
    );
  } finally {
    if (mounted) {
      setState(() => _isSaving = false);
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
              _AccountTextField(
                controller: _userNameController,
                hintText: 'User Name',
              ),
              const SizedBox(height: 16),
              _AccountTextField(
                controller: _passwordController,
                hintText: 'Password',
                obscureText: _passwordHidden,
                suffix: IconButton(
                  onPressed: () {
                    setState(() => _passwordHidden = !_passwordHidden);
                  },
                  icon: Icon(
                    _passwordHidden
                        ? Icons.visibility_off_outlined
                        : Icons.visibility_outlined,
                    color: _placeholderGray,
                    size: 20,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              _AccountTextField(
                controller: _confirmPasswordController,
                hintText: 'Confirm Password',
                obscureText: _confirmPasswordHidden,
                suffix: IconButton(
                  onPressed: () {
                    setState(
                      () => _confirmPasswordHidden = !_confirmPasswordHidden,
                    );
                  },
                  icon: Icon(
                    _confirmPasswordHidden
                        ? Icons.visibility_off_outlined
                        : Icons.visibility_outlined,
                    color: _placeholderGray,
                    size: 20,
                  ),
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: _isSaving ? null : _handleCreateAccount,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _brandOrange,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                  child: _isSaving
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.2,
                            color: Colors.white,
                          ),
                        )
                      : const Text(
                          'Create Account',
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w600,
                            fontFamily: 'Pretendard',
                          ),
                        ),
                ),
              ),
              const SizedBox(height: 18),
              const Text.rich(
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
              const Spacer(),
              const Padding(
                padding: EdgeInsets.only(bottom: 18),
                child: Text.rich(
                  TextSpan(
                    children: [
                      TextSpan(
                        text: 'By creating an account,\nyou agree to our ',
                        style: TextStyle(
                          color: Color(0xFF6E6E6E),
                          fontSize: 14,
                          fontWeight: FontWeight.w400,
                          fontFamily: 'Pretendard',
                          height: 1.45,
                        ),
                      ),
                      TextSpan(
                        text: 'Term Sheet, Privacy Policy',
                        style: TextStyle(
                          color: Color(0xFF111111),
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

class _AccountTextField extends StatelessWidget {
  final TextEditingController controller;
  final String hintText;
  final bool obscureText;
  final Widget? suffix;

  const _AccountTextField({
    required this.controller,
    required this.hintText,
    this.obscureText = false,
    this.suffix,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 48,
      child: TextField(
        controller: controller,
        obscureText: obscureText,
        style: const TextStyle(
          color: Color(0xFF111111),
          fontSize: 17,
          fontWeight: FontWeight.w500,
          fontFamily: 'Pretendard',
        ),
        decoration: InputDecoration(
          hintText: hintText,
          hintStyle: const TextStyle(
            color: Color(0xFFB4B4B4),
            fontSize: 17,
            fontWeight: FontWeight.w400,
            fontFamily: 'Pretendard',
          ),
          suffixIcon: suffix,
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(999),
            borderSide: const BorderSide(color: Color(0xFF383838), width: 1),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(999),
            borderSide: const BorderSide(color: Color(0xFF383838), width: 1.2),
          ),
        ),
      ),
    );
  }
}