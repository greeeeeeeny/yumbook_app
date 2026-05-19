import 'package:flutter_test/flutter_test.dart';
import 'package:yumbook_app/models/restaurant.dart';

void main() {
  group('Restaurant.fromJson', () {
    test('백엔드 응답의 필수 필드를 매핑한다', () {
      final json = <String, dynamic>{
        'id': 7,
        'name': '온바디 식당',
        'location': '서울 강남구',
        'description': '편안한 분위기',
        'image_url': 'https://x/img.png',
        'tags': ['파스타', '와인'],
        'raw_category': '양식',
        'lat': 37.5,
        'lng': 127.05,
        'rating': 4.3,
        'review_count': 12,
      };

      final r = Restaurant.fromJson(json);

      expect(r.id, '7');
      expect(r.name, '온바디 식당');
      expect(r.location, '서울 강남구');
      expect(r.tags, ['파스타', '와인']);
      expect(r.rawCategory, '양식');
      expect(r.lat, 37.5);
      expect(r.lng, 127.05);
      expect(r.rating, 4.3);
      expect(r.reviewCount, 12);
    });

    test('rating이 문자열로 와도 double로 파싱한다', () {
      final r = Restaurant.fromJson({
        'id': 1,
        'name': 'x',
        'rating': '4.7',
        'lat': '37.5',
      });

      expect(r.rating, 4.7);
      expect(r.lat, 37.5);
    });

    test('null/누락 필드를 안전한 기본값으로 처리', () {
      final r = Restaurant.fromJson({'id': 99});

      expect(r.id, '99');
      expect(r.name, '');
      expect(r.location, '');
      expect(r.description, '');
      expect(r.imagePath, '');
      expect(r.tags, isEmpty);
      expect(r.rating, 0);
      expect(r.reviewCount, 0);
      expect(r.lat, isNull);
      expect(r.lng, isNull);
    });

    test('tags가 List가 아니면 빈 리스트로 fallback', () {
      final r = Restaurant.fromJson({'id': 1, 'tags': 'not-a-list'});

      expect(r.tags, isEmpty);
    });
  });
}
