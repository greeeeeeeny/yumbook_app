class RestaurantPolicy {
  final String depositType; // none / perGuest / fixed
  final double depositAmount; // perGuest면 guest당, fixed면 전체
  final int freeCancelDays; // ex. 30
  final double refundWithinWindowRate; // 1.0/0.5/0.0
  final double refundOutsideWindowRate; // 보통 0.0
  final double noShowRefundRate; // 보통 0.0
  final double restaurantCancelRefundRate; // 보통 1.0

  const RestaurantPolicy({
    required this.depositType,
    required this.depositAmount,
    required this.freeCancelDays,
    required this.refundWithinWindowRate,
    required this.refundOutsideWindowRate,
    required this.noShowRefundRate,
    required this.restaurantCancelRefundRate,
  });

  static const defaultPolicy = RestaurantPolicy(
    depositType: 'none',
    depositAmount: 0,
    freeCancelDays: 30,
    refundWithinWindowRate: 1.0,
    refundOutsideWindowRate: 0.0,
    noShowRefundRate: 0.0,
    restaurantCancelRefundRate: 1.0,
  );
}