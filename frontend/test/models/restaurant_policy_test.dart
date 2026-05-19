import 'package:flutter_test/flutter_test.dart';
import 'package:yumbook_app/models/restaurant_policy.dart';

void main() {
  group('RestaurantPolicy.defaultPolicy', () {
    test('보증금 없음 + 30일 무료 취소 + 100% 환불 정책', () {
      const p = RestaurantPolicy.defaultPolicy;

      expect(p.depositType, 'none');
      expect(p.depositAmount, 0);
      expect(p.freeCancelDays, 30);
      expect(p.refundWithinWindowRate, 1.0);
      expect(p.refundOutsideWindowRate, 0.0);
      expect(p.noShowRefundRate, 0.0);
      expect(p.restaurantCancelRefundRate, 1.0);
    });
  });
}
