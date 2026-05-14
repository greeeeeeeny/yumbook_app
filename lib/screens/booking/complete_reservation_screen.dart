import 'dart:async';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:flutter_svg/flutter_svg.dart';

import 'package:yumbook_app/models/reservation_data.dart';
import 'package:yumbook_app/screens/booking/reservation_details_screen.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:yumbook_app/state/reservation_store.dart';

class CompleteReservationScreen extends StatefulWidget {
  final ReservationData data;

  const CompleteReservationScreen({super.key, required this.data});

  @override
  State<CompleteReservationScreen> createState() =>
      _CompleteReservationScreenState();
}

class _CompleteReservationScreenState extends State<CompleteReservationScreen> {
  // -------------------------
  // Countdown (10 min)
  // -------------------------
  static const int _initialSeconds = 10 * 60;
  int _remainingSeconds = _initialSeconds;
  Timer? _timer;

  // -------------------------
  // Checkboxes
  // -------------------------
  bool _agreeTexts = false;
  bool _consentMarketing = false;
  bool _isSubmitting = false;

  bool get _canComplete =>
      _agreeTexts &&
      _consentMarketing &&
      _remainingSeconds > 0 &&
      !_isSubmitting;

  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _startTimer() {
    _timer?.cancel();
    _remainingSeconds = _initialSeconds;

    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) return;

      if (_remainingSeconds <= 0) {
        t.cancel();
        setState(() {});
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Reservation hold expired. Please start again.'),
          ),
        );
        return;
      }

      setState(() => _remainingSeconds--);
    });
  }

  String get _mmss {
    final m = (_remainingSeconds ~/ 60).toString().padLeft(2, '0');
    final s = (_remainingSeconds % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  Future<void> _openUrl(String url) async {
    final uri = Uri.parse(url);
    final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!ok && mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Unable to open the link.')));
    }
  }

  Future<void> _onComplete() async {
    if (!_canComplete) return;

    final session = Supabase.instance.client.auth.currentSession;
    if (session == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please log in before booking.')),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final saved = await ReservationStore.instance.createReservation(
        widget.data,
      );

      if (!mounted) return;

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Reservation confirmed.')));

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => ReservationDetailsScreen(data: saved),
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to confirm reservation: $e')),
      );
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  // -------------------------
  // Styling helpers
  // -------------------------
  TextStyle get _muted14 =>
      const TextStyle(color: Color(0xFF6E6E6E), fontSize: 14);
  TextStyle get _title18 => const TextStyle(
    color: Color(0xFF1E1E1E),
    fontSize: 18,
    fontWeight: FontWeight.w600,
  );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,

      // ✅ profile_update_screen.dart 와 일관되게 AppBar 사용
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,

        // 왼쪽: 뒤로가기 아이콘 + Cancel 텍스트 (두번째 이미지 느낌)
        leadingWidth: 92,
        leading: InkWell(
          onTap: () => Navigator.pop(context),
          borderRadius: BorderRadius.circular(24),
          child: Padding(
            padding: const EdgeInsets.only(left: 6),
            child: Row(
              children: const [
                Icon(Icons.arrow_back, color: Colors.black),
                SizedBox(width: 4),
                Text(
                  'Cancel',
                  style: TextStyle(color: Colors.black, fontSize: 16),
                ),
              ],
            ),
          ),
        ),

        title: const Text(
          'Confirm',
          style: TextStyle(
            color: Colors.black,
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),

      body: SafeArea(
        child: ListView(
          children: [
            _timerBar(),
            const Divider(height: 1, color: Color(0xFFE5E5E5)),

            _titleSection(),
            _reservationCard(),
            _agreements(),

            const SizedBox(height: 16),

            _cancellationPolicy(),

            const SizedBox(height: 18),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _canComplete ? _onComplete : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFD45425),
                    disabledBackgroundColor: const Color(
                      0xFFD45425,
                    ).withValues(alpha: 0.35),
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: _isSubmitting
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Colors.white,
                            ),
                          ),
                        )
                      : const Text(
                          'Complete reservation',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                ),
              ),
            ),

            const SizedBox(height: 10),

            _footerTerms(),

            const SizedBox(height: 18),
          ],
        ),
      ),
    );
  }

  Widget _timerBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 14),
      child: Center(
        child: Text.rich(
          TextSpan(
            children: [
              const TextSpan(
                text: 'Holding reservation for ',
                style: TextStyle(color: Color(0xFF383838), fontSize: 16),
              ),
              TextSpan(
                text: _mmss,
                style: const TextStyle(
                  color: Color(0xFFBF331B),
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _titleSection() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 18, 16, 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Complete your reservation', style: _title18),
          const SizedBox(height: 8),
          Text(
            'We’re holding your selection as you complete your reservation.',
            style: const TextStyle(color: Color(0xFF6E6E6E), fontSize: 16),
          ),
        ],
      ),
    );
  }

  Widget _reservationCard() {
    final seatType = widget.data.seatType; // ✅ optional

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: ShapeDecoration(
          shape: RoundedRectangleBorder(
            side: const BorderSide(width: 1, color: Color(0xFFE5E5EA)),
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // LEFT (text + svg rows)
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.data.restaurantName, // ✅ 하드코딩 제거
                    style: const TextStyle(
                      color: Color(0xFF383838),
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 12),

                  _svgRow(
                    'assets/icons/party.svg',
                    '${widget.data.partySize} guests for ${widget.data.guestName}', // ✅ 하드코딩 제거
                  ),
                  const SizedBox(height: 10),

                  // ✅ seatType optional: 값 있을 때만 표시
                  if (seatType != null && seatType.trim().isNotEmpty) ...[
                    _svgRow('assets/icons/table.svg', seatType.trim()),
                    const SizedBox(height: 10),
                  ],

                  _svgRow(
                    'assets/icons/time.svg',
                    '${widget.data.formattedDate} at ${widget.data.formattedTime}',
                  ),
                ],
              ),
            ),

            const SizedBox(width: 12),

            // RIGHT (small image)
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.network(
                "https://placehold.co/104x139", // TODO: 나중에 restaurant imageUrl로 서버, 스토리지 URL연결
                width: 64,
                height: 64,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => Container(
                  width: 64,
                  height: 64,
                  color: const Color(0xFFEDEDED),
                  alignment: Alignment.center,
                  child: const Icon(
                    Icons.image_not_supported,
                    size: 18,
                    color: Color(0xFF9E9E9E),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _svgRow(String assetPath, String text) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SvgPicture.asset(
          assetPath,
          width: 18,
          height: 18,
          // ✅ 색이 이미 SVG 안에 들어있으면 colorFilter 제거
          colorFilter: const ColorFilter.mode(
            Color(0xFF6E6E6E),
            BlendMode.srcIn,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(
              color: Color(0xFF303030),
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }

  Widget _agreements() {
    // ✅ 체크박스 2개 + 텍스트 (두번째 이미지처럼)
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
      child: Column(
        children: [
          _checkboxRow(
            value: _agreeTexts,
            onChanged: (v) => setState(() => _agreeTexts = v ?? false),
            text:
                'I agree to receive text messages from yumbook related to this reservation.',
          ),
          const SizedBox(height: 10),
          _checkboxRow(
            value: _consentMarketing,
            onChanged: (v) => setState(() => _consentMarketing = v ?? false),
            text:
                'I consent to share contact and guest information about myself or someone who has provided consent,\n'
                'for the business to send marketing communications about offers, promotions, or other information.\n'
                'I can withdraw my consent at any time directly with the business.',
          ),
        ],
      ),
    );
  }

  Widget _checkboxRow({
    required bool value,
    required ValueChanged<bool?> onChanged,
    required String text,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Checkbox(
          value: value,
          onChanged: onChanged,
          activeColor: Colors.black,
          side: const BorderSide(color: Color(0xFFB4B4B4)),
          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
        ),
        const SizedBox(width: 6),
        Expanded(child: Text(text, style: _muted14)),
      ],
    );
  }

  Widget _cancellationPolicy() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Cancellation policy',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          Text(
            'Your reservation can be canceled at any time before the scheduled reservation time should your plans change.\n'
            'However, we kindly ask that you cancel at least 24 hours in advance so the restaurant can plan accordingly.',
            style: _muted14,
          ),
        ],
      ),
    );
  }

  Widget _footerTerms() {
    // ✅ 문장 일부를 링크로(underline + tap)
    // URL은 유리님이 원하는 실제 정책 URL로 바꿔주세요.
    const cancellationUrl = 'https://www.yumbook.io/refund-policy';
    const termsUrl = 'https://www.yumbook.io/terms-conditions';
    const privacyUrl = 'https://www.yumbook.io/privacy-policy';

    // "Terms of Use and Privacy Policy"를 2개로 나누어 각각 링크 처리
    final baseStyle = const TextStyle(
      color: Color(0xFF6E6E6E),
      fontSize: 12,
      height: 1.35,
    );
    final linkStyle = const TextStyle(
      color: Color(0xFF6E6E6E),
      fontSize: 12,
      height: 1.35,
      decoration: TextDecoration.underline,
      fontWeight: FontWeight.w600,
    );

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 6, 16, 0),
      child: Text.rich(
        TextSpan(
          style: baseStyle,
          children: [
            const TextSpan(
              text:
                  'By completing your reservation, you acknowledge that you have ',
            ),

            TextSpan(
              text: 'read the restaurant’s cancellation policy',
              style: linkStyle,
              recognizer: TapGestureRecognizer()
                ..onTap = () => _openUrl(cancellationUrl),
            ),

            const TextSpan(text: ' and agree to the '),

            TextSpan(
              text: 'Terms of Use',
              style: linkStyle,
              recognizer: TapGestureRecognizer()
                ..onTap = () => _openUrl(termsUrl),
            ),

            const TextSpan(text: ' and '),

            TextSpan(
              text: 'Privacy Policy',
              style: linkStyle,
              recognizer: TapGestureRecognizer()
                ..onTap = () => _openUrl(privacyUrl),
            ),

            const TextSpan(
              text: '.\nStandard text message and data rates may apply.\n',
            ),
            const TextSpan(
              text:
                  'You can opt out of receiving messages at any time by texting “END.”',
            ),
          ],
        ),
      ),
    );
  }
}
