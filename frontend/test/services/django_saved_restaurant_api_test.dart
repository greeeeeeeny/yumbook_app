import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:mocktail/mocktail.dart';
import 'package:yumbook_app/services/django_reservation_api.dart';
import 'package:yumbook_app/services/django_saved_restaurant_api.dart';

class _MockClient extends Mock implements http.Client {}

class _FakeUri extends Fake implements Uri {}

void main() {
  setUpAll(() {
    registerFallbackValue(_FakeUri());
  });

  late _MockClient client;
  late DjangoSavedRestaurantApi api;

  setUp(() {
    client = _MockClient();
    api = DjangoSavedRestaurantApi(client: client, baseUrl: 'http://test.local/');
  });

  test('fetchSaved: 저장 식당 목록을 Restaurant 리스트로 매핑', () async {
    when(() => client.get(any(), headers: any(named: 'headers'))).thenAnswer(
      (_) async => http.Response(
        jsonEncode([
          {'id': 1, 'name': 'Cafe Um'},
          {'id': 2, 'name': '1993 Gogi'},
        ]),
        200,
      ),
    );

    final list = await api.fetchSaved(accessToken: 'tok');

    expect(list, hasLength(2));
    expect(list.first.id, '1');
    expect(list.first.name, 'Cafe Um');

    final captured = verify(
      () => client.get(captureAny(), headers: any(named: 'headers')),
    ).captured;
    expect((captured.single as Uri).path, '/api/saved-restaurants/');
  });

  test('save: restaurant id를 body로 POST 하고 Restaurant 반환', () async {
    when(
      () => client.post(
        any(),
        headers: any(named: 'headers'),
        body: any(named: 'body'),
      ),
    ).thenAnswer(
      (_) async => http.Response(jsonEncode({'id': 7, 'name': 'On Body'}), 201),
    );

    final saved = await api.save(restaurantId: '7', accessToken: 'tok');

    expect(saved.id, '7');
    final captured = verify(
      () => client.post(
        any(),
        headers: any(named: 'headers'),
        body: captureAny(named: 'body'),
      ),
    ).captured;
    expect(jsonDecode(captured.single as String), {'restaurant': 7});
  });

  test('save: 이미 저장돼 있으면(200) 도 성공으로 처리', () async {
    when(
      () => client.post(
        any(),
        headers: any(named: 'headers'),
        body: any(named: 'body'),
      ),
    ).thenAnswer(
      (_) async => http.Response(jsonEncode({'id': 7, 'name': 'On Body'}), 200),
    );

    final saved = await api.save(restaurantId: '7', accessToken: 'tok');
    expect(saved.id, '7');
  });

  test('unsave: restaurant_id 경로로 DELETE (204)', () async {
    when(() => client.delete(any(), headers: any(named: 'headers')))
        .thenAnswer((_) async => http.Response('', 204));

    await api.unsave(restaurantId: '7', accessToken: 'tok');

    final captured = verify(
      () => client.delete(captureAny(), headers: any(named: 'headers')),
    ).captured;
    expect((captured.single as Uri).path, '/api/saved-restaurants/7/');
  });

  test('비-2xx 응답이면 DjangoApiException', () async {
    when(() => client.get(any(), headers: any(named: 'headers')))
        .thenAnswer((_) async => http.Response('{"detail":"x"}', 401));

    expect(
      () => api.fetchSaved(accessToken: 'tok'),
      throwsA(isA<DjangoApiException>()),
    );
  });
}
