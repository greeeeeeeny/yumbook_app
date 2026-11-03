import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:mocktail/mocktail.dart';
import 'package:yumbook_app/models/transaction_model.dart';
import 'package:yumbook_app/services/django_reservation_api.dart';
import 'package:yumbook_app/services/django_transaction_api.dart';

class _MockClient extends Mock implements http.Client {}

class _FakeUri extends Fake implements Uri {}

void main() {
  setUpAll(() {
    registerFallbackValue(_FakeUri());
  });

  late _MockClient client;
  late DjangoTransactionApi api;

  setUp(() {
    client = _MockClient();
    api = DjangoTransactionApi(client: client, baseUrl: 'http://test.local/');
  });

  test('fetchTransactions: 목록 파싱 + 필드 매핑', () async {
    when(() => client.get(any(), headers: any(named: 'headers'))).thenAnswer(
      (_) async => http.Response(
        jsonEncode([
          {
            'id': 12,
            'type': 'refund',
            'title': 'Deposit Refund',
            'subtitle': '1993 Gogi',
            'amount': '30.55',
            'card_brand': 'MasterCard',
            'card_last4': '9918',
            'trailing_text': '+ 30.55 \$',
            'status': 'completed',
            'created_at': '2026-01-17T10:00:00Z',
          },
        ]),
        200,
      ),
    );

    final list = await api.fetchTransactions(accessToken: 'tok');

    expect(list, hasLength(1));
    final tx = list.first;
    expect(tx.id, '12');
    expect(tx.type, TransactionType.refund);
    expect(tx.title, 'Deposit Refund');
    expect(tx.subtitle, '1993 Gogi');
    expect(tx.amount, 30.55);
    expect(tx.cardBrand, 'MasterCard');
    expect(tx.cardLast4, '9918');
    expect(tx.trailingText, '+ 30.55 \$');
    expect(tx.status, 'completed');
    expect(tx.createdAt.year, 2026);

    final captured = verify(
      () => client.get(captureAny(), headers: any(named: 'headers')),
    ).captured;
    expect((captured.single as Uri).path, '/api/transactions/');
  });

  test('status/type 매핑: failed / payment(→reservation) / 누락(→reservation)', () async {
    when(() => client.get(any(), headers: any(named: 'headers'))).thenAnswer(
      (_) async => http.Response(
        jsonEncode([
          {'id': 1, 'type': 'failed', 'title': 'Auth Failed', 'status': 'failed'},
          {'id': 2, 'type': 'payment', 'title': 'Fee', 'status': 'completed'},
          {'id': 3, 'title': 'No type', 'status': 'pending'},
        ]),
        200,
      ),
    );

    final list = await api.fetchTransactions(accessToken: 'tok');

    expect(list[0].type, TransactionType.failed);
    expect(list[0].status, 'failed');
    // 'payment'와 type 누락은 모두 reservation 으로 매핑된다.
    expect(list[1].type, TransactionType.reservation);
    expect(list[2].type, TransactionType.reservation);
  });

  test('빈 응답이면 빈 리스트', () async {
    when(() => client.get(any(), headers: any(named: 'headers')))
        .thenAnswer((_) async => http.Response('[]', 200));

    final list = await api.fetchTransactions(accessToken: 'tok');
    expect(list, isEmpty);
  });

  test('fetchTransaction: 단일 거래 매핑', () async {
    when(() => client.get(any(), headers: any(named: 'headers'))).thenAnswer(
      (_) async => http.Response(
        jsonEncode({
          'id': 7,
          'type': 'reservation',
          'title': 'Reservation Deposit',
          'trailing_text': '- 20 \$',
          'status': 'completed',
          'created_at': '2026-01-15T00:00:00Z',
        }),
        200,
      ),
    );

    final tx = await api.fetchTransaction(id: 7, accessToken: 'tok');
    expect(tx.id, '7');
    expect(tx.type, TransactionType.reservation);

    final captured = verify(
      () => client.get(captureAny(), headers: any(named: 'headers')),
    ).captured;
    expect((captured.single as Uri).path, '/api/transactions/7/');
  });

  test('비-200 응답이면 DjangoApiException', () async {
    when(() => client.get(any(), headers: any(named: 'headers')))
        .thenAnswer((_) async => http.Response('{"detail":"x"}', 401));

    expect(
      () => api.fetchTransactions(accessToken: 'tok'),
      throwsA(isA<DjangoApiException>()),
    );
  });
}
