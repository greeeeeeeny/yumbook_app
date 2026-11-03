import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:mocktail/mocktail.dart';
import 'package:yumbook_app/services/django_restaurant_api.dart';
import 'package:yumbook_app/services/django_reservation_api.dart';

class _MockClient extends Mock implements http.Client {}

class _FakeUri extends Fake implements Uri {}

void main() {
  setUpAll(() {
    registerFallbackValue(_FakeUri());
  });

  late _MockClient client;
  late DjangoRestaurantApi api;

  setUp(() {
    client = _MockClient();
    api = DjangoRestaurantApi(
      client: client,
      baseUrl: 'http://test.local/',
    );
  });

  test('searchRestaurants: q/location/category 쿼리 파라미터 동봉', () async {
    when(() => client.get(any(), headers: any(named: 'headers')))
        .thenAnswer((_) async => http.Response('[]', 200));

    await api.searchRestaurants(
      query: '파스타',
      location: '강남',
      category: '양식',
      region: 'hongdae',
    );

    final captured = verify(
      () => client.get(captureAny(), headers: any(named: 'headers')),
    ).captured;
    final uri = captured.single as Uri;

    expect(uri.path, '/api/restaurants/');
    expect(uri.queryParameters['q'], '파스타');
    expect(uri.queryParameters['location'], '강남');
    expect(uri.queryParameters['category'], '양식');
    expect(uri.queryParameters['region'], 'hongdae');
  });

  test('region 파라미터만 단독으로 전달된다', () async {
    when(() => client.get(any(), headers: any(named: 'headers')))
        .thenAnswer((_) async => http.Response('[]', 200));

    await api.searchRestaurants(region: 'insadong');

    final captured = verify(
      () => client.get(captureAny(), headers: any(named: 'headers')),
    ).captured;
    final uri = captured.single as Uri;

    expect(uri.queryParameters, {'region': 'insadong'});
  });

  test('빈 파라미터는 query string에 포함되지 않는다', () async {
    when(() => client.get(any(), headers: any(named: 'headers')))
        .thenAnswer((_) async => http.Response('[]', 200));

    await api.searchRestaurants();

    final captured = verify(
      () => client.get(captureAny(), headers: any(named: 'headers')),
    ).captured;
    final uri = captured.single as Uri;

    expect(uri.queryParameters, isEmpty);
  });

  test('searchRestaurants는 Restaurant 리스트로 매핑', () async {
    when(() => client.get(any(), headers: any(named: 'headers'))).thenAnswer(
      (_) async => http.Response(
        jsonEncode([
          {'id': 1, 'name': 'A', 'rating': 4.0},
          {'id': 2, 'name': 'B', 'rating': '3.5'},
        ]),
        200,
      ),
    );

    final list = await api.searchRestaurants();

    expect(list, hasLength(2));
    expect(list[0].id, '1');
    expect(list[1].rating, 3.5);
  });

  test('fetchRestaurant: 단일 식당 매핑', () async {
    when(() => client.get(any(), headers: any(named: 'headers'))).thenAnswer(
      (_) async => http.Response.bytes(
        utf8.encode(jsonEncode({'id': 7, 'name': '온바디', 'rating': 4.2})),
        200,
      ),
    );

    final r = await api.fetchRestaurant(id: '7');

    expect(r.id, '7');
    expect(r.name, '온바디');
    expect(r.rating, 4.2);
  });

  test('비-200 응답이면 DjangoApiException', () async {
    when(() => client.get(any(), headers: any(named: 'headers')))
        .thenAnswer((_) async => http.Response('{"detail":"x"}', 404));

    expect(
      () => api.fetchRestaurant(id: '999'),
      throwsA(isA<DjangoApiException>()),
    );
  });
}
