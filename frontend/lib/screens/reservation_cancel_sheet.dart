import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'package:yumbook_app/models/reservation_data.dart';

/// ✅ 취소/환불 계산에 필요한 결제/정책 정보
/// - 추후 RestaurantPolicy / ReservationData에 붙으면 여기 값은 reservation에서 읽도록 변경 가능
class PaymentBreakdown {
  final double serviceFeePerGuest;
  final double depositPerGuest;
  final double processingRate;
  final bool restaurantFailedToConfirm;

  /// 식당별 정책
  final int freeCancelDays; // 예: 30, 7, 3, 1
  final double refundRateAfterWindow; // 예: 1.0
  final double refundRateWithinWindow; // 예: 0.0
  final double noShowRefundRate; // 예: 0.0

  const PaymentBreakdown({
    this.serviceFeePerGuest = 20,
    this.depositPerGuest = 30,
    this.processingRate = 0.04,
    this.restaurantFailedToConfirm = false,
    this.freeCancelDays = 30,
    this.refundRateAfterWindow = 1.0,
    this.refundRateWithinWindow = 0.0,
    this.noShowRefundRate = 0.0,
  });
}

class CancelComputation {
  final double totalPaid;
  final double totalDeducted;
  final double refundAmount;
  final bool refundable;
  final String message;

  const CancelComputation({
    required this.totalPaid,
    required this.totalDeducted,
    required this.refundAmount,
    required this.refundable,
    required this.message,
  });
}

class ReservationCancelSheet extends StatefulWidget {
  final ReservationData reservation;
  final PaymentBreakdown payment;

  /// 취소 확정 시 호출 (reason 포함)
  final Future<void> Function(String reason) onConfirmCancel;

  const ReservationCancelSheet({
    super.key,
    required this.reservation,
    required this.payment,
    required this.onConfirmCancel,
  });

  static Future<void> show(
    BuildContext context, {
    required ReservationData reservation,
    required PaymentBreakdown payment,
    required Future<void> Function(String reason) onConfirmCancel,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => ReservationCancelSheet(
        reservation: reservation,
        payment: payment,
        onConfirmCancel: onConfirmCancel,
      ),
    );
  }

  @override
  State<ReservationCancelSheet> createState() => _ReservationCancelSheetState();
}

class _ReservationCancelSheetState extends State<ReservationCancelSheet> {
  static const _orange = Color(0xFFD45425);
  static const _border = Color(0xFFE5E5EA);
  static const _textDark = Color(0xFF383838);

  final _reasonCtrl = TextEditingController();
  bool _policyOpen = true;
  bool _submitting = false;

  @override
  void dispose() {
    _reasonCtrl.dispose();
    super.dispose();
  }

  CancelComputation _compute() {
    final r = widget.reservation;
    final p = widget.payment;

    final guests = r.partySize;
    final serviceFee = p.serviceFeePerGuest * guests;
    final deposit = p.depositPerGuest * guests;
    final totalPaid = serviceFee + deposit;

    final now = DateTime.now();
    final reservedDate = DateTime(r.date.year, r.date.month, r.date.day);
    final today = DateTime(now.year, now.month, now.day);
    final diffDays = reservedDate.difference(today).inDays;

    // ✅ 레스토랑 미확정 / 레스토랑 사유 취소
    if (p.restaurantFailedToConfirm) {
      final refundableBase = deposit;
      final processingFee = refundableBase * p.processingRate;
      final refund =
          (refundableBase - processingFee).clamp(0, double.infinity).toDouble();

      return CancelComputation(
        totalPaid: totalPaid,
        totalDeducted: serviceFee + processingFee,
        refundAmount: refund,
        refundable: refund > 0,
        message:
            'The restaurant deposit is refundable. A processing fee may be deducted.',
      );
    }

    // ✅ 고객 취소
    // 서비스피는 항상 비환불
    final withinWindow = diffDays <= p.freeCancelDays;

    final depositRefundRate =
        withinWindow ? p.refundRateWithinWindow : p.refundRateAfterWindow;

    final refundableDeposit = deposit * depositRefundRate;
    final processingFee = refundableDeposit * p.processingRate;
    final refund =
        (refundableDeposit - processingFee).clamp(0, double.infinity).toDouble();

    final deducted = serviceFee + (deposit - refundableDeposit) + processingFee;

    String message;
    if (withinWindow && depositRefundRate == 0) {
      message =
          'Cancellations within ${p.freeCancelDays} days are non-refundable for the deposit. Service fee is non-refundable.';
    } else if (withinWindow && depositRefundRate > 0 && depositRefundRate < 1) {
      final percent = (depositRefundRate * 100).round();
      message =
          'Within ${p.freeCancelDays} days, $percent% of the deposit may be refunded. Service fee is non-refundable.';
    } else if (!withinWindow && depositRefundRate >= 1) {
      message =
          'The deposit is refundable before ${p.freeCancelDays} days. A processing fee may be deducted. Service fee is non-refundable.';
    } else {
      message =
          'A cancellation fee may apply depending on the restaurant policy. Service fee is non-refundable.';
    }

    return CancelComputation(
      totalPaid: totalPaid,
      totalDeducted: deducted,
      refundAmount: refund,
      refundable: refund > 0,
      message: message,
    );
  }

  String _money(double v) => NumberFormat.simpleCurrency(name: 'USD').format(v);

  @override
  Widget build(BuildContext context) {
    final comp = _compute();
    final r = widget.reservation;
    final p = widget.payment;

    final dateText = DateFormat('MMM d, yyyy').format(r.date);
    final timeText = DateFormat('h:mm a').format(r.time);
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Container(
        color: Colors.black.withOpacity(0.25),
        child: Align(
          alignment: Alignment.bottomCenter,
          child: Padding(
            padding: EdgeInsets.only(bottom: bottomInset),
            child: SafeArea(
              top: false,
              child: Container(
                width: double.infinity,
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
                ),
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        children: [
                          const Spacer(),
                          const Text(
                            'Cancel',
                            style: TextStyle(
                              fontSize: 14,
                              fontFamily: 'Pretendard',
                              fontWeight: FontWeight.w600,
                              color: _textDark,
                            ),
                          ),
                          const Spacer(),
                          IconButton(
                            onPressed: () => Navigator.pop(context),
                            icon: const Icon(Icons.close, size: 18),
                          ),
                        ],
                      ),

                      const SizedBox(height: 4),

                      Text(
                        r.restaurantName,
                        style: const TextStyle(
                          fontSize: 18,
                          fontFamily: 'Pretendard',
                          fontWeight: FontWeight.w700,
                          color: _textDark,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        '$dateText at $timeText',
                        style: const TextStyle(
                          fontSize: 12,
                          fontFamily: 'Pretendard',
                          fontWeight: FontWeight.w500,
                          color: Color(0xFF6E6E6E),
                        ),
                      ),

                      const SizedBox(height: 14),

                      Container(
                        width: double.infinity,
                        decoration: BoxDecoration(
                          border: Border.all(color: _border),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Column(
                          children: [
                            InkWell(
                              onTap: () => setState(() => _policyOpen = !_policyOpen),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 14,
                                  vertical: 12,
                                ),
                                child: Row(
                                  children: [
                                    const Text(
                                      'Cancellation & Refund\nPolicy',
                                      style: TextStyle(
                                        fontSize: 13,
                                        fontFamily: 'Pretendard',
                                        fontWeight: FontWeight.w700,
                                        color: _textDark,
                                        height: 1.1,
                                      ),
                                    ),
                                    const Spacer(),
                                    Icon(
                                      _policyOpen
                                          ? Icons.expand_less
                                          : Icons.expand_more,
                                      size: 20,
                                      color: const Color(0xFF8E8E93),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            if (_policyOpen) ...[
                              const Divider(height: 1, color: _border),
                              Padding(
                                padding: const EdgeInsets.all(14),
                                child: Text(
                                  '• Service fee is non-refundable.\n'
                                  '• Deposit refundability depends on the restaurant policy.\n'
                                  '• Cancellations within ${p.freeCancelDays} days may have limited or no deposit refund.\n'
                                  '• A payment processing fee (e.g., ~${(p.processingRate * 100).round()}%) may be deducted.\n'
                                  '• Refunds are typically processed to the original payment method within 7–10 business days.',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontFamily: 'Pretendard',
                                    fontWeight: FontWeight.w400,
                                    height: 1.35,
                                    color: Color(0xFF6E6E6E),
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),

                      const SizedBox(height: 10),

                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFCE9E7),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Padding(
                              padding: EdgeInsets.only(top: 1),
                              child: Icon(
                                Icons.error_outline,
                                size: 18,
                                color: Color(0xFFBF331B),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                comp.message,
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontFamily: 'Pretendard',
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFFBF331B),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 12),

                      _amountRow('Total Amount Paid', _money(comp.totalPaid)),
                      const SizedBox(height: 6),
                      _amountRow(
                        'Total Deducted',
                        '- ${_money(comp.totalDeducted)}',
                        valueColor: const Color(0xFF6E6E6E),
                      ),
                      const SizedBox(height: 6),

                      const Divider(height: 20, color: _border),

                      Row(
                        children: [
                          const Text(
                            'Refund Amount',
                            style: TextStyle(
                              fontSize: 13,
                              fontFamily: 'Pretendard',
                              fontWeight: FontWeight.w700,
                              color: _textDark,
                            ),
                          ),
                          const Spacer(),
                          Text(
                            _money(comp.refundAmount),
                            style: const TextStyle(
                              fontSize: 14,
                              fontFamily: 'Pretendard',
                              fontWeight: FontWeight.w800,
                              color: Color(0xFFD13A2F),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 12),

                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          border: Border.all(color: _border),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: TextField(
                          controller: _reasonCtrl,
                          minLines: 1,
                          maxLines: 3,
                          decoration: const InputDecoration(
                            border: InputBorder.none,
                            hintText: 'Please enter the reason for cancellation',
                            hintStyle: TextStyle(
                              fontSize: 12,
                              fontFamily: 'Pretendard',
                              fontWeight: FontWeight.w500,
                              color: Color(0xFFB0B0B0),
                            ),
                          ),
                          style: const TextStyle(
                            fontSize: 12,
                            fontFamily: 'Pretendard',
                            fontWeight: FontWeight.w600,
                            color: _textDark,
                          ),
                        ),
                      ),

                      const SizedBox(height: 12),

                      Row(
                        children: [
                          Expanded(
                            child: _pillBtn(
                              label: 'Keep Reservation',
                              bg: const Color(0xFFE5E5EA),
                              fg: const Color(0xFF6E6E6E),
                              onTap: () => Navigator.pop(context),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: _pillBtn(
                              label: _submitting ? '...' : 'Confirm',
                              bg: _submitting ? const Color(0xFFBDBDBD) : _orange,
                              fg: Colors.white,
                              onTap: _submitting
                                  ? null
                                  : () async {
                                      setState(() => _submitting = true);
                                      try {
                                        await widget.onConfirmCancel(
                                          _reasonCtrl.text.trim(),
                                        );
                                        if (context.mounted) {
                                          Navigator.pop(context);
                                        }
                                      } finally {
                                        if (mounted) {
                                          setState(() => _submitting = false);
                                        }
                                      }
                                    },
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _amountRow(String label, String value, {Color valueColor = _textDark}) {
    return Row(
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            fontFamily: 'Pretendard',
            fontWeight: FontWeight.w600,
            color: _textDark,
          ),
        ),
        const Spacer(),
        Text(
          value,
          style: TextStyle(
            fontSize: 12,
            fontFamily: 'Pretendard',
            fontWeight: FontWeight.w700,
            color: valueColor,
          ),
        ),
      ],
    );
  }

  Widget _pillBtn({
    required String label,
    required Color bg,
    required Color fg,
    required VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Opacity(
        opacity: onTap == null ? 0.7 : 1,
        child: Container(
          height: 42,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(100),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontFamily: 'Pretendard',
              fontWeight: FontWeight.w700,
              color: fg,
            ),
          ),
        ),
      ),
    );
  }
}