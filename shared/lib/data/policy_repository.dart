import 'package:yumbook_app/models/restaurant_policy.dart';

class PolicyRepository {
  PolicyRepository._();
  static final instance = PolicyRepository._();

  // ✅ 지금은 mock. 나중에 GET /restaurants/{id}/policy 로 교체
  final Map<String, RestaurantPolicy> _mockByRestaurantId = {
    'r1': const RestaurantPolicy(
      depositType: 'perGuest',
      depositAmount: 40, // guest당 $40
      freeCancelDays: 30,
      refundWithinWindowRate: 1.0,
      refundOutsideWindowRate: 0.0,
      noShowRefundRate: 0.0,
      restaurantCancelRefundRate: 1.0,
    ),
    'r2': const RestaurantPolicy(
      depositType: 'fixed',
      depositAmount: 80, // 전체 $80
      freeCancelDays: 7,
      refundWithinWindowRate: 0.5,
      refundOutsideWindowRate: 0.0,
      noShowRefundRate: 0.0,
      restaurantCancelRefundRate: 1.0,
    ),
  };

  Future<RestaurantPolicy> fetchPolicy(String? restaurantId) async {
    // mock라 딜레이만 살짝
    await Future.delayed(const Duration(milliseconds: 150));
    if (restaurantId == null) return RestaurantPolicy.defaultPolicy;
    return _mockByRestaurantId[restaurantId] ?? RestaurantPolicy.defaultPolicy;
  }
}