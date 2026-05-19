import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:mocktail/mocktail.dart';
import 'package:yumbook_app/models/reservation_data.dart';
import 'package:yumbook_app/services/django_reservation_api.dart';

class _MockClient extends Mock implements http.Client {}

class _FakeUri extends Fake implements Uri {}

void main() {
  setUpAll(() {
    registerFallbackValue(_FakeUri());
  });

  late _MockClient client;
  late DjangoReservationApi api;

  setUp(() {
    client = _MockClient();
    api = DjangoReservationApi(
      client: client,
      baseUrl: 'http://test.local',
    );
  });

  group('reservationToJson / reservationFromJson', () {
    test('date / time을 yyyy-MM-dd / HH:mm:ss 로 직렬화', () {
      final r = ReservationData(
        restaurantName: '온바디',
        date: DateTime(2026, 5, 19),
        time: DateTime(2026, 5, 19, 19, 30),
        partySize: 2,
        guestName: '홍길동',
        seatType: 'window',
      );

      final body = api.reservationToJson(r);

      expect(body['date'], '2026-05-19');
      expect(body['time'], '19:30:00');
      expect(body['party_size'], 2);
      expect(body['guest_name'], '홍길동');
      expect(body['seat_type'], 'window');
    });

    test('백엔드 응답을 ReservationData로 역직렬화 (confirmation_code 보존)', () {
      final r = api.reservationFromJson({
        'restaurant_name': '온바디',
        'date': '2026-05-19',
        'time': '19:30:00',
        'party_size': 4,
        'guest_name': '길동',
        'confirmation_code': 'Yumbook-B-AB12CD34',
      });

      expect(r.restaurantName, '온바디');
      expect(r.partySize, 4);
      expect(r.confirmationCode, 'Yumbook-B-AB12CD34');
      expect(r.date, DateTime(2026, 5, 19));
      expect(r.time.hour, 19);
      expect(r.time.minute, 30);
    });

    test('confirmation_code 누락 시 기본값 사용', () {
      final r = api.reservationFromJson({
        'restaurant_name': '온바디',
        'date': '2026-05-19',
        'time': '19:30:00',
      });

      expect(r.confirmationCode, 'Yumbook-B-00001');
      expect(r.partySize, 1);
      expect(r.guestName, '');
    });
  });

  group('fetchReservations', () {
    test('200 응답을 List로 반환', () async {
      when(() => client.get(any(), headers: any(named: 'headers')))
          .thenAnswer(
        (_) async => http.Response.bytes(
          utf8.encode(jsonEncode([
            {
              'restaurant_name': 'A',
              'date': '2026-05-20',
              'time': '18:00:00',
              'party_size': 2,
              'guest_name': '갑',
            },
          ])),
          200,
        ),
      );

      final list = await api.fetchReservations(accessToken: 'tok');

      expect(list, hasLength(1));
      expect(list.first.restaurantName, 'A');
    });

    test('Bearer 토큰을 헤더에 동봉', () async {
      when(() => client.get(any(), headers: any(named: 'headers')))
          .thenAnswer((_) async => http.Response('[]', 200));

      await api.fetchReservations(accessToken: 'secret');

      final captured = verify(
        () => client.get(any(), headers: captureAny(named: 'headers')),
      ).captured;
      final headers = captured.single as Map<String, String>;

      expect(headers['Authorization'], 'Bearer secret');
      expect(headers['Content-Type'], 'application/json');
    });

    test('비-200 응답이면 DjangoApiException', () async {
      when(() => client.get(any(), headers: any(named: 'headers')))
          .thenAnswer((_) async => http.Response('{"detail":"x"}', 401));

      expect(
        () => api.fetchReservations(accessToken: 'tok'),
        throwsA(isA<DjangoApiException>()),
      );
    });
  });

  test('DjangoApiException toString 포맷 확인', () {
    const e = DjangoApiException(404, 'not found');
    expect(e.toString(), 'DjangoApiException(404): not found');
  });
}
