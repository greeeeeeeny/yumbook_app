import 'package:yumbook_app/models/restaurant_policy.dart';

class ReservationPaymentSnapshot {
  final double serviceFeePerGuest; // 플랫폼 정책
  final double depositAmount; // “실제 결제된 deposit 총액”(계산 후 저장)
  final String currency; // ex. USD
  final double processingFeeRate; // ex. 0.04
  final RestaurantPolicy policySnapshot; // 예약 시점의 식당 정책 스냅샷

  const ReservationPaymentSnapshot({
    required this.serviceFeePerGuest,
    required this.depositAmount,
    required this.currency,
    required this.processingFeeRate,
    required this.policySnapshot,
  });

  double totalPaid(int partySize) => (serviceFeePerGuest * partySize) + depositAmount;
}