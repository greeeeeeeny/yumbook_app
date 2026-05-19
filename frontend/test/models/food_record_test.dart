import 'package:flutter_test/flutter_test.dart';
import 'package:yumbook_app/models/food_record.dart';

void main() {
  group('FoodRecord', () {
    test('기본 생성자가 빈 필드에 안전한 기본값을 채운다', () {
      const record = FoodRecord(rating: 4.5);

      expect(record.rating, 4.5);
      expect(record.restaurantName, '');
      expect(record.menuName, '');
      expect(record.review, '');
      expect(record.tags, isEmpty);
      expect(record.images, isEmpty);
      expect(record.isPublic, isTrue);
      expect(record.visitedAt, isNull);
      expect(record.price, isNull);
    });

    test('copyWith는 지정한 필드만 갱신한다', () {
      const original = FoodRecord(
        rating: 3.0,
        menuName: '파스타',
        restaurantName: '원본 식당',
        review: '괜찮음',
      );

      final updated = original.copyWith(rating: 5.0, review: '훌륭함');

      expect(updated.rating, 5.0);
      expect(updated.review, '훌륭함');
      expect(updated.menuName, '파스타');
      expect(updated.restaurantName, '원본 식당');
    });

    test('clearRestaurant=true 면 restaurantId를 null로 만든다', () {
      const original = FoodRecord(rating: 4.0, restaurantId: 42);

      final cleared = original.copyWith(clearRestaurant: true);

      expect(cleared.restaurantId, isNull);
    });

    test('clearPrice=true 면 price를 null로 만든다', () {
      const original = FoodRecord(rating: 4.0, price: 12000);

      final cleared = original.copyWith(clearPrice: true);

      expect(cleared.price, isNull);
    });

    test('clearVisitedAt=true 면 visitedAt을 null로 만든다', () {
      final original = FoodRecord(
        rating: 4.0,
        visitedAt: DateTime(2026, 5, 1),
      );

      final cleared = original.copyWith(clearVisitedAt: true);

      expect(cleared.visitedAt, isNull);
    });

    test('formattedVisitedAt 은 yyyy-MM-dd 포맷을 반환', () {
      final record = FoodRecord(
        rating: 4.0,
        visitedAt: DateTime(2026, 5, 19),
      );

      expect(record.formattedVisitedAt, '2026-05-19');
    });

    test('formattedVisitedAt 은 visitedAt이 없으면 빈 문자열', () {
      const record = FoodRecord(rating: 4.0);

      expect(record.formattedVisitedAt, '');
    });
  });

  group('FoodRecordImage', () {
    test('copyWith는 order만 바꿔도 imageUrl을 보존', () {
      const img = FoodRecordImage(imageUrl: 'https://x/y.jpg', order: 0);

      final updated = img.copyWith(order: 2);

      expect(updated.imageUrl, 'https://x/y.jpg');
      expect(updated.order, 2);
    });
  });
}
