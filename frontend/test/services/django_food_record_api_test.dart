import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:mocktail/mocktail.dart';
import 'package:yumbook_app/models/food_record.dart';
import 'package:yumbook_app/services/django_food_record_api.dart';
import 'package:yumbook_app/services/django_reservation_api.dart';

class _MockClient extends Mock implements http.Client {}

class _FakeUri extends Fake implements Uri {}

void main() {
  setUpAll(() {
    registerFallbackValue(_FakeUri());
  });

  late _MockClient client;
  late DjangoFoodRecordApi api;

  setUp(() {
    client = _MockClient();
    api = DjangoFoodRecordApi(
      client: client,
      baseUrl: 'http://test.local',
    );
  });

  group('foodRecordFromJson', () {
    test('백엔드 응답을 FoodRecord로 매핑한다', () {
      final json = <String, dynamic>{
        'id': 11,
        'user': 'uid-abc',
        'restaurant': 5,
        'restaurant_name': '온바디',
        'menu_name': '파스타',
        'rating': '4.5',
        'review': '맛있음',
        'price': '13000',
        'tags': ['저녁', '데이트'],
        'visited_at': '2026-05-18',
        'is_public': true,
        'images': [
          {'id': 1, 'image_url': 'https://x/1.jpg', 'order': 0},
          {'id': 2, 'image_url': 'https://x/2.jpg', 'order': 1},
        ],
        'created_at': '2026-05-18T10:00:00Z',
        'updated_at': '2026-05-18T11:00:00Z',
      };

      final r = api.foodRecordFromJson(json);

      expect(r.id, 11);
      expect(r.userId, 'uid-abc');
      expect(r.restaurantId, 5);
      expect(r.rating, 4.5);
      expect(r.price, 13000);
      expect(r.tags, ['저녁', '데이트']);
      expect(r.images, hasLength(2));
      expect(r.images.first.imageUrl, 'https://x/1.jpg');
      expect(r.visitedAt, DateTime(2026, 5, 18));
      expect(r.createdAt, isNotNull);
    });

    test('null/누락 필드를 안전한 기본값으로 처리', () {
      final r = api.foodRecordFromJson({'id': 1, 'rating': 3});

      expect(r.restaurantName, '');
      expect(r.menuName, '');
      expect(r.tags, isEmpty);
      expect(r.images, isEmpty);
      expect(r.isPublic, isTrue);
      expect(r.visitedAt, isNull);
    });
  });

  group('foodRecordToJson', () {
    test('null 필드는 페이로드에서 생략', () {
      const record = FoodRecord(rating: 4.0, menuName: '파스타');

      final body = api.foodRecordToJson(record);

      expect(body.containsKey('restaurant'), isFalse);
      expect(body.containsKey('price'), isFalse);
      expect(body.containsKey('visited_at'), isFalse);
      expect(body['rating'], '4.0');
      expect(body['menu_name'], '파스타');
      expect(body['is_public'], true);
    });

    test('visited_at 은 yyyy-MM-dd 형식', () {
      final record = FoodRecord(
        rating: 4.0,
        visitedAt: DateTime(2026, 1, 3),
      );

      final body = api.foodRecordToJson(record);

      expect(body['visited_at'], '2026-01-03');
    });
  });

  group('fetchRecords', () {
    test('mine=true 면 ?mine=1 쿼리를 보낸다', () async {
      when(() => client.get(any(), headers: any(named: 'headers')))
          .thenAnswer((_) async => http.Response('[]', 200));

      await api.fetchRecords(mine: true, accessToken: 'tok');

      final captured = verify(
        () => client.get(captureAny(), headers: any(named: 'headers')),
      ).captured;
      final uri = captured.single as Uri;

      expect(uri.path, '/api/food-records/');
      expect(uri.queryParameters['mine'], '1');
    });

    test('accessToken을 Authorization 헤더에 동봉', () async {
      when(() => client.get(any(), headers: any(named: 'headers')))
          .thenAnswer((_) async => http.Response('[]', 200));

      await api.fetchRecords(accessToken: 'tok-xyz');

      final captured = verify(
        () => client.get(any(), headers: captureAny(named: 'headers')),
      ).captured;
      final headers = captured.single as Map<String, String>;

      expect(headers['Authorization'], 'Bearer tok-xyz');
    });

    test('비-200 응답이면 DjangoApiException 던짐', () async {
      when(() => client.get(any(), headers: any(named: 'headers')))
          .thenAnswer((_) async => http.Response('{"detail":"nope"}', 500));

      expect(
        () => api.fetchRecords(),
        throwsA(isA<DjangoApiException>()),
      );
    });
  });

  group('createRecord', () {
    test('성공 시 응답 본문을 FoodRecord로 반환', () async {
      when(
        () => client.post(
          any(),
          headers: any(named: 'headers'),
          body: any(named: 'body'),
        ),
      ).thenAnswer(
        (_) async => http.Response.bytes(
          utf8.encode(jsonEncode({'id': 99, 'rating': '5', 'menu_name': '스테이크'})),
          201,
        ),
      );

      const record = FoodRecord(rating: 5, menuName: '스테이크');
      final result = await api.createRecord(record: record, accessToken: 'tok');

      expect(result.id, 99);
      expect(result.menuName, '스테이크');
    });
  });

  group('deleteRecord', () {
    test('204 No Content 면 정상 종료', () async {
      when(() => client.delete(any(), headers: any(named: 'headers')))
          .thenAnswer((_) async => http.Response('', 204));

      await expectLater(
        api.deleteRecord(id: 1, accessToken: 'tok'),
        completes,
      );
    });

    test('비-204 면 예외', () async {
      when(() => client.delete(any(), headers: any(named: 'headers')))
          .thenAnswer((_) async => http.Response('{"detail":"x"}', 403));

      expect(
        () => api.deleteRecord(id: 1, accessToken: 'tok'),
        throwsA(isA<DjangoApiException>()),
      );
    });
  });
}
