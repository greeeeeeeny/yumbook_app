import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'package:yumbook_app/models/reservation_data.dart';
import 'package:yumbook_app/state/reservation_store.dart';

class ReservationEditScreen extends StatefulWidget {
  final ReservationData reservation;

  const ReservationEditScreen({super.key, required this.reservation});

  @override
  State<ReservationEditScreen> createState() => _ReservationEditScreenState();
}

class _ReservationEditScreenState extends State<ReservationEditScreen> {
  static const _orange = Color(0xFFD45425);
  static const _border = Color(0xFFE5E5EA);
  static const _textDark = Color(0xFF383838);

  late DateTime _date;
  late TimeOfDay _time;
  late int _partySize;

  bool _saving = false;
  bool _checkedEditWindow = false;

  @override
  void initState() {
    super.initState();
    _date = widget.reservation.date;
    _time = TimeOfDay.fromDateTime(widget.reservation.time);
    _partySize = widget.reservation.partySize;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _guardEditWindow();
    });
  }

  DateTime _reservationDateTimeOfOriginal() {
    final d = widget.reservation.date;
    final t = widget.reservation.time;
    return DateTime(d.year, d.month, d.day, t.hour, t.minute);
  }

  bool _canEditReservation() {
    final reservationDateTime = _reservationDateTimeOfOriginal();
    final hoursLeft = reservationDateTime.difference(DateTime.now()).inHours;
    return hoursLeft >= 24;
  }

  Future<void> _guardEditWindow() async {
    if (_checkedEditWindow) return;
    _checkedEditWindow = true;

    if (_canEditReservation()) return;
    if (!mounted) return;

    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: const Text(
          'Unable to edit',
          style: TextStyle(
            fontFamily: 'Pretendard',
            fontWeight: FontWeight.w700,
            color: _textDark,
          ),
        ),
        content: const Text(
          'Reservations cannot be changed within 24 hours of the scheduled time.',
          style: TextStyle(
            fontFamily: 'Pretendard',
            fontWeight: FontWeight.w500,
            color: Color(0xFF6E6E6E),
            height: 1.4,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'OK',
              style: TextStyle(
                color: _orange,
                fontFamily: 'Pretendard',
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );

    if (mounted) {
      Navigator.pop(context);
    }
  }

  String _dateText() => DateFormat('MMM d, yyyy').format(_date);

  String _timeText() => DateFormat(
        'h:mm a',
      ).format(DateTime(2000, 1, 1, _time.hour, _time.minute));

  Future<void> _pickDate() async {
    if (!_canEditReservation()) {
      _showEditBlockedSnackBar();
      return;
    }

    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            dialogBackgroundColor: Colors.white,
            colorScheme: Theme.of(context).colorScheme.copyWith(
              primary: _orange,
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: _textDark,
            ),
            datePickerTheme: const DatePickerThemeData(
              backgroundColor: Colors.white,
              surfaceTintColor: Colors.white,
              headerBackgroundColor: Colors.white,
              headerForegroundColor: _textDark,
              dayForegroundColor: WidgetStatePropertyAll(_textDark),
              todayForegroundColor: WidgetStatePropertyAll(_orange),
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() => _date = picked);
    }
  }

  Future<void> _pickTime() async {
    if (!_canEditReservation()) {
      _showEditBlockedSnackBar();
      return;
    }

    final picked = await showTimePicker(
      context: context,
      initialTime: _time,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            dialogBackgroundColor: Colors.white,
            colorScheme: Theme.of(context).colorScheme.copyWith(
              primary: _orange,
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: _textDark,
            ),
            timePickerTheme: const TimePickerThemeData(
              backgroundColor: Colors.white,
              dialBackgroundColor: Color(0xFFF8F8F8),
              hourMinuteColor: Colors.white,
              hourMinuteTextColor: _textDark,
              dayPeriodColor: Colors.white,
              dayPeriodTextColor: _textDark,
              dialHandColor: _orange,
              dialTextColor: _textDark,
              entryModeIconColor: _textDark,
              helpTextStyle: TextStyle(
                fontFamily: 'Pretendard',
                fontWeight: FontWeight.w600,
                color: _textDark,
              ),
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() => _time = picked);
    }
  }

  void _showEditBlockedSnackBar() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'Changes are available up to 24 hours before the reservation time.',
          style: TextStyle(
            fontFamily: 'Pretendard',
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }

  Future<void> _submitChange() async {
    if (_saving) return;

    if (!_canEditReservation()) {
      _showEditBlockedSnackBar();
      return;
    }

    setState(() => _saving = true);

    try {
      final store = ReservationStore.instance;

      final newDateTime = DateTime(
        _date.year,
        _date.month,
        _date.day,
        _time.hour,
        _time.minute,
      );

      // 현재는 기존 updateReservation 호출
      // 다음 단계에서 requestReservationChange(...) 구조로 바꾸는 것을 추천
      store.requestReservationChange(
        widget.reservation,
        newDate: _date,
        newTime: newDateTime,
        newPartySize: _partySize,
      );

      if (!mounted) return;
      Navigator.pop(context, true);
    } finally {
      if (mounted) {
        setState(() => _saving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final canEdit = _canEditReservation();

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.arrow_back_ios_new, size: 18),
                  ),
                  const Expanded(
                    child: Text(
                      'Reservation details',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 16,
                        fontFamily: 'Pretendard',
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const SizedBox(width: 44),
                ],
              ),

              const SizedBox(height: 12),

              Text(
                widget.reservation.restaurantName,
                style: const TextStyle(
                  fontSize: 20,
                  fontFamily: 'Pretendard',
                  fontWeight: FontWeight.w700,
                  color: _textDark,
                ),
              ),

              const SizedBox(height: 14),

              if (!canEdit)
                Container(
                  width: double.infinity,
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFCE9E7),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        Icons.error_outline,
                        size: 18,
                        color: Color(0xFFBF331B),
                      ),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Reservations cannot be changed within 24 hours of the scheduled time.',
                          style: TextStyle(
                            fontSize: 12,
                            fontFamily: 'Pretendard',
                            fontWeight: FontWeight.w600,
                            color: Color(0xFFBF331B),
                            height: 1.35,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  border: Border.all(color: _border),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Booking Details',
                      style: TextStyle(
                        fontSize: 16,
                        fontFamily: 'Pretendard',
                        fontWeight: FontWeight.w700,
                        color: _textDark,
                      ),
                    ),
                    const SizedBox(height: 14),

                    _RowField(
                      label: 'Date',
                      value: _dateText(),
                      enabled: canEdit,
                      onTap: _pickDate,
                    ),
                    const SizedBox(height: 10),

                    _RowField(
                      label: 'Time',
                      value: _timeText(),
                      enabled: canEdit,
                      onTap: _pickTime,
                    ),
                    const SizedBox(height: 14),

                    const Text(
                      'Party Size',
                      style: TextStyle(
                        fontSize: 13,
                        fontFamily: 'Pretendard',
                        fontWeight: FontWeight.w600,
                        color: _textDark,
                      ),
                    ),
                    const SizedBox(height: 8),

                    Row(
                      children: [
                        _RoundIconBtn(
                          icon: Icons.remove,
                          enabled: canEdit,
                          onTap: () => setState(() {
                            if (_partySize > 1) _partySize--;
                          }),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          '$_partySize',
                          style: const TextStyle(
                            fontSize: 16,
                            fontFamily: 'Pretendard',
                            fontWeight: FontWeight.w700,
                            color: _textDark,
                          ),
                        ),
                        const SizedBox(width: 12),
                        _RoundIconBtn(
                          icon: Icons.add,
                          enabled: canEdit,
                          onTap: () => setState(() {
                            if (_partySize < 20) _partySize++;
                          }),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const Spacer(),

              GestureDetector(
                onTap: (!canEdit || _saving) ? null : _submitChange,
                behavior: HitTestBehavior.opaque,
                child: Opacity(
                  opacity: (!canEdit || _saving) ? 0.7 : 1,
                  child: Container(
                    height: 46,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: (!canEdit || _saving)
                          ? const Color(0xFFBDBDBD)
                          : _orange,
                      borderRadius: BorderRadius.circular(100),
                    ),
                    child: Text(
                      _saving ? 'SAVING...' : 'REQUEST CHANGE',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontFamily: 'Pretendard',
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.4,
                      ),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}

class _RowField extends StatelessWidget {
  final String label;
  final String value;
  final bool enabled;
  final VoidCallback onTap;

  const _RowField({
    required this.label,
    required this.value,
    required this.enabled,
    required this.onTap,
  });

  static const _border = Color(0xFFE5E5EA);
  static const _textDark = Color(0xFF383838);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: enabled ? onTap : null,
      child: Opacity(
        opacity: enabled ? 1 : 0.6,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            border: Border.all(color: _border),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 13,
                  fontFamily: 'Pretendard',
                  fontWeight: FontWeight.w600,
                  color: _textDark,
                ),
              ),
              const Spacer(),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 13,
                  fontFamily: 'Pretendard',
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF6E6E6E),
                ),
              ),
              const SizedBox(width: 6),
              const Icon(
                Icons.chevron_right,
                size: 18,
                color: Color(0xFF8E8E93),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RoundIconBtn extends StatelessWidget {
  final IconData icon;
  final bool enabled;
  final VoidCallback onTap;

  const _RoundIconBtn({
    required this.icon,
    required this.enabled,
    required this.onTap,
  });

  static const _border = Color(0xFFE5E5EA);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: enabled ? onTap : null,
      behavior: HitTestBehavior.opaque,
      child: Opacity(
        opacity: enabled ? 1 : 0.6,
        child: Container(
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            border: Border.all(color: _border),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, size: 18, color: const Color(0xFF383838)),
        ),
      ),
    );
  }
}