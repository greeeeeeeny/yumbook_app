// lib/screens/profile_update_screen.dart
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:yumbook_app/models/reservation_data.dart';
import 'package:yumbook_app/data/phone_codes.dart';
import 'package:yumbook_app/data/countries.dart' as country_data;
import 'booking/complete_reservation_screen.dart';

import 'package:yumbook_app/state/reservation_store.dart';


class ProfileUpdateScreen extends StatefulWidget {
  final ReservationData data;

  const ProfileUpdateScreen({super.key, required this.data});

  @override
  State<ProfileUpdateScreen> createState() => _ProfileUpdateScreenState();
}

class _ProfileUpdateScreenState extends State<ProfileUpdateScreen> {
  // -------------------------
  // Controllers / Form
  // -------------------------
  final _formKey = GlobalKey<FormState>();
  final _firstNameCtrl = TextEditingController();
  final _lastNameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _zipCtrl = TextEditingController();

  // -------------------------
  // Country selections
  // -------------------------
  PhoneCountry? _selectedPhoneCountry;
  String? _residenceCountry; // Country of residence

  // -------------------------
  // Phone validation message
  // -------------------------
  bool? _isPhoneValid; // null = not checked yet

  // -------------------------
  // Countdown timer (10 min)
  // -------------------------
  static const int _initialSeconds = 10 * 60;
  int _remainingSeconds = _initialSeconds;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _selectedPhoneCountry = kPhoneCountries.firstWhere(
        (c) => c.isoCode == 'US',
        orElse: () => kPhoneCountries.first,
      );

      _residenceCountry = null;

      _startTimer();
      _phoneCtrl.addListener(_revalidatePhone);
    }

  @override
  void dispose() {
    _timer?.cancel();
    _firstNameCtrl.dispose();
    _lastNameCtrl.dispose();
    _phoneCtrl.removeListener(_revalidatePhone);
    _phoneCtrl.dispose();
    _zipCtrl.dispose();
    super.dispose();
  }

  // -------------------------
  // Timer
  // -------------------------
  void _startTimer() {
    _timer?.cancel();
    _remainingSeconds = _initialSeconds;

    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) return;
      if (_remainingSeconds <= 0) {
        t.cancel();
        setState(() {});
        // Optional: show timeout message
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Reservation hold expired. Please start again.')),
        );
        // You may want to pop back automatically:
        // Navigator.pop(context);
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

  // -------------------------
  // Phone validation (basic, per dial code)
  // NOTE: For production-grade validation by country, integrate libphonenumber.
  // -------------------------
  String _digitsOnly(String s) => s.replaceAll(RegExp(r'\D'), '');

  void _revalidatePhone() {
    final digits = _digitsOnly(_phoneCtrl.text);
    if (digits.isEmpty) {
      setState(() => _isPhoneValid = null);
      return;
    }

    // Very simple rules by dial code (good enough for MVP UI feedback)
    // KR +82: usually 9~11 digits (excluding country code). We'll accept 9~11.
    // US/CA +1: 10 digits
    // JP +81: 9~10 digits
    // GB +44: 9~10 digits
    // CN +86: 11 digits
      final dial = _selectedPhoneCountry?.dialCode ?? '';

      bool ok;
      if (dial == '+82') {
        ok = digits.length >= 9 && digits.length <= 11;
      } else if (dial == '+1') {
        ok = digits.length == 10;
      } else if (dial == '+81') {
        ok = digits.length >= 9 && digits.length <= 10;
      } else if (dial == '+44') {
        ok = digits.length >= 9 && digits.length <= 10;
      } else if (dial == '+86') {
        ok = digits.length == 11;
      } else {
        ok = digits.length >= 6 && digits.length <= 14;
      }

      setState(() => _isPhoneValid = ok);
    }

  // -------------------------
  // Actions
  // -------------------------
  void _onUpdateProfile() {
    if (_remainingSeconds <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Reservation hold expired. Please start again.')),
      );
      return;
    }

    if (_formKey.currentState?.validate() != true) return;

    if (_isPhoneValid == false) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid phone number.')),
      );
      return;
    }

    final updated = ReservationData(
      restaurantName: widget.data.restaurantName,
      restaurantId: widget.data.restaurantId,
      date: widget.data.date,
      time: widget.data.time,
      partySize: widget.data.partySize,
      guestName: '${_firstNameCtrl.text.trim()} ${_lastNameCtrl.text.trim()}',
      seatType: widget.data.seatType,
      confirmationCode: widget.data.confirmationCode,
      paymentSnapshot: widget.data.paymentSnapshot,
      pendingChange: widget.data.pendingChange,
    );

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CompleteReservationScreen(data: updated),
      ),
    );
  }

  // -------------------------
  // UI helpers
  // -------------------------
  InputDecoration _inputDeco({
    String? hint,
    Widget? suffix,
  }) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: Color(0xFFB4B4B4)),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: Color(0xFFD9D9D9)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: Color(0xFFD9D9D9)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: Color(0xFFD45425)),
      ),
      suffixIcon: suffix,
    );
  }

  Widget _label(String text) => Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: Text(text, style: const TextStyle(fontSize: 16, color: Color(0xFF1E1E1E))),
      );

  // -------------------------
  // Build
  // -------------------------
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,

      // ✅ AppBar: back button + centered Confirm
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Confirm',
          style: TextStyle(color: Colors.black, fontSize: 20, fontWeight: FontWeight.w600),
        ),
      ),

      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              // Holding timer
              _buildTimerSection(),
              const Divider(height: 1, color: Color(0xFFE5E5E5)),

              // Reservation summary
              _buildReservationSummary(),
              const Divider(height: 1, color: Color(0xFFE5E5E5)),

              // Profile fields
              _buildProfileFields(),

              const SizedBox(height: 20),

              // Update profile button
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFD45425),
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                    onPressed: _onUpdateProfile,
                    child: const Text(
                      'Update profile',
                      style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 28),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTimerSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 14),
      child: Center(
        child: Text.rich(
          TextSpan(
            children: [
              const TextSpan(text: 'Holding reservation for ', style: TextStyle(fontSize: 16)),
              TextSpan(
                text: _mmss,
                style: TextStyle(
                  color: _remainingSeconds <= 60 ? const Color(0xFFBF331B) : const Color(0xFFBF331B),
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildReservationSummary() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        children: [
          // Left text
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // TODO: replace with real restaurant name from data if you have it
                const Text('1993 Gogi', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700)),
                const SizedBox(height: 6),
                const Text('Reservation', style: TextStyle(color: Color(0xFF6E6E6E), fontSize: 16)),
                const SizedBox(height: 14),
                Text(
                  '${widget.data.formattedDate} at ${widget.data.formattedTime} for ${widget.data.partySize}',
                  style: const TextStyle(color: Color(0xFF1E1E1E), fontSize: 16),
                ),
              ],
            ),
          ),

          // Right image
          Container(
            width: 88,
            height: 88,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              image: const DecorationImage(
                image: NetworkImage("https://placehold.co/104x139"),
                fit: BoxFit.cover,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileFields() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 18, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Your profile', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 6),
          const Text('Please complete your profile', style: TextStyle(color: Color(0xFF6E6E6E))),
          const SizedBox(height: 18),

          // First name
          _label('First name'),
          TextFormField(
            controller: _firstNameCtrl,
            textInputAction: TextInputAction.next,
            decoration: _inputDeco(hint: ''),
            validator: (v) => (v ?? '').trim().isEmpty ? 'Please enter your first name.' : null,
          ),
          const SizedBox(height: 16),

          // Last name
          _label('Last name'),
          TextFormField(
            controller: _lastNameCtrl,
            textInputAction: TextInputAction.next,
            decoration: _inputDeco(hint: ''),
            validator: (v) => (v ?? '').trim().isEmpty ? 'Please enter your last name.' : null,
          ),
          const SizedBox(height: 18),

          // Phone country code + phone number (as per your Figma)
          _label('Phone country code'),
          DropdownButtonFormField<PhoneCountry>(
            initialValue: _selectedPhoneCountry,
            isExpanded: true,
            decoration: _inputDeco(hint: 'Select'),
            items: kPhoneCountries
                .map((country) => DropdownMenuItem<PhoneCountry>(
            value: country,
            child: Text('${country.name} ${country.dialCode}'),
            ))
            .toList(),
            onChanged: (v) {
              setState(() {
                _selectedPhoneCountry = v;
                _revalidatePhone();
              });
            },
          ),
          const SizedBox(height: 14),

          _label('Phone number'),
          TextFormField(
            controller: _phoneCtrl,
            keyboardType: TextInputType.phone,
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'[0-9+\-\s]')),
              LengthLimitingTextInputFormatter(20),
            ],
            decoration: _inputDeco(hint: '').copyWith(
              prefixText: '${_selectedPhoneCountry?.dialCode ?? ''} ',
              prefixStyle: const TextStyle(color: Color(0xFF1E1E1E)),
            ),
            validator: (v) {
              final digits = _digitsOnly(v ?? '');
              if (digits.isEmpty) return 'Please enter your phone number.';
              // If user typed phone only, we validate by dial-code rules (basic)
              if (_isPhoneValid == false) return 'Please enter a valid phone number.';
              return null;
            },
          ),
          const SizedBox(height: 6),

          // "This number is valid" status
          Builder(
            builder: (_) {
              if (_isPhoneValid == null) return const SizedBox.shrink();
              final ok = _isPhoneValid == true;
              return Text(
                ok ? 'This number is valid' : 'This number is not valid',
                style: TextStyle(
                  color: ok ? const Color(0xFF2C4A38) : const Color(0xFFBF331B),
                  fontSize: 14,
                ),
              );
            },
          ),

          const SizedBox(height: 18),

          // Country of residence
          _label('Country of residence'),
          DropdownButtonFormField<String>(
            initialValue: _residenceCountry,
            isExpanded: true,
            decoration: _inputDeco(hint: 'Select'),
            items: country_data.kCountries
                .map((c) => DropdownMenuItem<String>(
                      value: c,
                      child: Text(c),
                    ))
                .toList(),
            onChanged: (v) => setState(() => _residenceCountry = v),
            validator: (_) => _residenceCountry == null ? 'Please select a country of residence.' : null,
          ),

          const SizedBox(height: 14),

          // ZIP/Postal code
          _label('ZIP/Postal code'),
          TextFormField(
            controller: _zipCtrl,
            textInputAction: TextInputAction.done,
            decoration: _inputDeco(hint: 'ZIP/Postal code'),
            validator: (v) => (v ?? '').trim().isEmpty ? 'Please enter your ZIP/Postal code.' : null,
          ),
        ],
      ),
    );
  }
}