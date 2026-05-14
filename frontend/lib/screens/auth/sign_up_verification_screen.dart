import 'dart:async';
import 'package:flutter/material.dart';
import 'package:yumbook_app/screens/auth/create_account_screen.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:yumbook_app/services/supabase/supabase_auth_service.dart';
import 'package:flutter/services.dart';

class SignUpVerificationScreen extends StatefulWidget {
  final String email;

  const SignUpVerificationScreen({
    super.key,
    required this.email,
  });

  @override
  State<SignUpVerificationScreen> createState() =>
      _SignUpVerificationScreenState();
}

class _SignUpVerificationScreenState extends State<SignUpVerificationScreen> {
  static const Color _brandOrange = Color(0xFFD45425);
  static const Color _textDark = Color(0xFF111111);

  final List<TextEditingController> _controllers =
      List.generate(8, (_) => TextEditingController());

  final List<FocusNode> _focusNodes = List.generate(8, (_) => FocusNode());

  Timer? _timer;
  int _remainingSeconds = 300;
  bool _isVerifying = false;

  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  @override
  void dispose() {
    _timer?.cancel();
    for (final c in _controllers) {
      c.dispose();
    }
    for (final f in _focusNodes) {
      f.dispose();
    }
    super.dispose();
  }

  void _startTimer() {
    _timer?.cancel();

    setState(() {
      _remainingSeconds = 300;
    });

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;

      if (_remainingSeconds <= 0) {
        timer.cancel();
      } else {
        setState(() {
          _remainingSeconds--;
        });
      }
    });
  }

  String _formatTime(int totalSeconds) {
    final minutes = (totalSeconds ~/ 60).toString();
    final seconds = (totalSeconds % 60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  String get _enteredCode => _controllers.map((e) => e.text).join();

  String _maskEmail(String email) {
    final parts = email.split('@');
    if (parts.length != 2) return email;

    final local = parts.first;
    final domain = parts.last;

    if (local.length <= 3) {
      return '${local[0]}***@$domain';
    }

    return '${local.substring(0, 3)}*******@$domain';
  }

  void _clearAllBoxes() {
    for (final controller in _controllers) {
      controller.clear();
    }
    _focusNodes.first.requestFocus();
    setState(() {});
  }

Future<void> _handleResendCode() async {
  try {
    await SupabaseAuthService.sendSignUpOtp(email: widget.email);

    _clearAllBoxes();
    _startTimer();

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'Verification code sent again.',
          style: TextStyle(fontFamily: 'Pretendard'),
        ),
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
          'Failed to resend code: $e',
          style: const TextStyle(fontFamily: 'Pretendard'),
        ),
      ),
    );
  }
}


  Future<void> _handleVerify() async {
    if (_remainingSeconds == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'The code has expired. Please send it again.',
            style: TextStyle(fontFamily: 'Pretendard'),
          ),
        ),
      );
      return;
    }

    if (_enteredCode.length != 8) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Please enter the 8-digit verification code.',
            style: TextStyle(fontFamily: 'Pretendard'),
          ),
        ),
      );
      return;
    }


    setState(() => _isVerifying = true);

    try {
      await SupabaseAuthService.verifyEmailOtp(
        email: widget.email,
        token: _enteredCode,
      );

      if (!mounted) return;

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => CreateAccountScreen(email: widget.email),
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
            'Verification failed: $e',
            style: const TextStyle(fontFamily: 'Pretendard'),
          ),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isVerifying = false);
      }
    }
  }

  Widget _buildCodeBox(int index) {
    return SizedBox(
      width: 48,
      height: 64,
      child: TextField(
        controller: _controllers[index],
        focusNode: _focusNodes[index],
        maxLength: 1,
        inputFormatters: [
          FilteringTextInputFormatter.digitsOnly,
        ],
        keyboardType: TextInputType.number,
        textAlign: TextAlign.center,
        style: const TextStyle(
          color: _textDark,
          fontSize: 24,
          fontWeight: FontWeight.w600,
          fontFamily: 'Pretendard',
        ),
        decoration: InputDecoration(
          counterText: '',
          contentPadding: EdgeInsets.zero,
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: _brandOrange, width: 1),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: _brandOrange, width: 1.4),
          ),
        ),
        onChanged: (value) {
          if (value.isNotEmpty && index < _controllers.length - 1) {
            _focusNodes[index + 1].requestFocus();
          } else if (value.isEmpty && index > 0) {
            _focusNodes[index - 1].requestFocus();
          }
          setState(() {});
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final maskedEmail = _maskEmail(widget.email);

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
                onPressed: () => Navigator.pop(context),
                icon: const Icon(
                  Icons.arrow_back_ios_new_rounded,
                  size: 22,
                  color: Color(0xFF383838),
                ),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
              const SizedBox(height: 58),

              const Center(
                child: Text(
                  'Enter Your\nVerification Code',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: _textDark,
                    fontSize: 28,
                    fontWeight: FontWeight.w700,
                    fontFamily: 'Pretendard',
                    height: 1.3,
                  ),
                ),
              ),

              const SizedBox(height: 34),

                Wrap(
                  alignment: WrapAlignment.center,
                  spacing: 8,
                  runSpacing: 8,
                  children: List.generate(_controllers.length, (index) {
                    return _buildCodeBox(index);
                  }),
                ),

              const SizedBox(height: 20),

              Text(
                _formatTime(_remainingSeconds),
                style: const TextStyle(
                  color: _brandOrange,
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  fontFamily: 'Pretendard',
                ),
              ),

              const SizedBox(height: 16),

              Text.rich(
                TextSpan(
                  children: [
                    const TextSpan(
                      text: 'We’ve sent verification code to your email\n',
                      style: TextStyle(
                        color: _textDark,
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        fontFamily: 'Pretendard',
                        height: 1.45,
                      ),
                    ),
                    TextSpan(
                      text: maskedEmail,
                      style: const TextStyle(
                        color: _brandOrange,
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        fontFamily: 'Pretendard',
                      ),
                    ),
                    const TextSpan(
                      text: '.\nYou can check your inbox.',
                      style: TextStyle(
                        color: _textDark,
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        fontFamily: 'Pretendard',
                        height: 1.45,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 28),

              GestureDetector(
                onTap: () async => await _handleResendCode(),
                child: const Text(
                  'Didn’t receive the code? Send again',
                  style: TextStyle(
                    color: _brandOrange,
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    fontFamily: 'Pretendard',
                    decoration: TextDecoration.underline,
                  ),
                ),
              ),

              const SizedBox(height: 36),

              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: _isVerifying ? null : _handleVerify,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _brandOrange,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                  child: _isVerifying
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.2,
                            color: Colors.white,
                          ),
                        )
                      : const Text(
                          'Verify',
                          style: TextStyle(
                            fontFamily: 'Pretendard',
                            fontSize: 17,
                            fontWeight: FontWeight.w600,
                          ),
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