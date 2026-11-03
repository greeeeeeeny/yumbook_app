import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:mocktail/mocktail.dart';
import 'package:yumbook_app/services/django_payment_method_api.dart';
import 'package:yumbook_app/services/django_reservation_api.dart';
import 'package:yumbook_app/state/payment_method_store.dart';

class _MockClient extends Mock implements http.Client {}

class _FakeUri extends Fake implements Uri {}

void main() {
  setUpAll(() {
    registerFallbackValue(_FakeUri());
  });

  late _MockClient client;
  late DjangoPaymentMethodApi api;

  setUp(() {
    client = _MockClient();
    api = DjangoPaymentMethodApi(client: client, baseUrl: 'http://test.local/');
  });

  test('fetchMethods: 결제수단 목록 매핑', () async {
    when(() => client.get(any(), headers: any(named: 'headers'))).thenAnswer(
      (_) async => http.Response(
        jsonEncode([
          {
            'id': 1,
            'brand': 'Visa',
            'last4': '4242',
            'holder_name': 'Amy',
            'expiry': '12/27',
            'is_default': true,
          },
        ]),
        200,
      ),
    );

    final list = await api.fetchMethods(accessToken: 'tok');

    expect(list, hasLength(1));
    expect(list.first.id, '1');
    expect(list.first.brand, 'Visa');
    expect(list.first.last4, '4242');
    expect(list.first.expiry, '12/27');
    expect(list.first.isDefault, isTrue);

    final captured = verify(
      () => client.get(captureAny(), headers: any(named: 'headers')),
    ).captured;
    expect((captured.single as Uri).path, '/api/payment-methods/');
  });

  test('create: POST 하고 모델 반환', () async {
    when(
      () => client.post(
        any(),
        headers: any(named: 'headers'),
        body: any(named: 'body'),
      ),
    ).thenAnswer(
      (_) async => http.Response(
        jsonEncode({
          'id': 9,
          'brand': 'MasterCard',
          'last4': '9918',
          'holder_name': 'Amy',
          'expiry': '09/26',
          'is_default': true,
        }),
        201,
      ),
    );

    final saved = await api.create(
      method: const PaymentMethodModel(
        id: '',
        brand: 'MasterCard',
        last4: '9918',
        holderName: 'Amy',
        expiry: '09 / 26',
      ),
      accessToken: 'tok',
    );

    expect(saved.id, '9');
    expect(saved.last4, '9918');
  });

  test('보안: create 본문에 카드번호/CVV 등 민감 필드가 없다', () async {
    when(
      () => client.post(
        any(),
        headers: any(named: 'headers'),
        body: any(named: 'body'),
      ),
    ).thenAnswer(
      (_) async => http.Response(
        jsonEncode({
          'id': 9,
          'brand': 'Visa',
          'last4': '4242',
          'holder_name': 'Amy',
          'expiry': '12/27',
          'is_default': false,
        }),
        201,
      ),
    );

    await api.create(
      method: const PaymentMethodModel(
        id: '',
        brand: 'Visa',
        last4: '4242',
        holderName: 'Amy',
        expiry: '12/27',
      ),
      accessToken: 'tok',
    );

    final captured = verify(
      () => client.post(
        any(),
        headers: any(named: 'headers'),
        body: captureAny(named: 'body'),
      ),
    ).captured;
    final sent = jsonDecode(captured.single as String) as Map<String, dynamic>;

    // 안전 필드만 전송된다.
    expect(sent.keys.toSet(), {
      'brand',
      'last4',
      'holder_name',
      'expiry',
      'is_default',
    });
    // 민감 키는 절대 포함되지 않는다.
    for (final forbidden in [
      'card_number',
      'cardnumber',
      'number',
      'pan',
      'cvv',
      'cvc',
      'security_code',
    ]) {
      expect(sent.containsKey(forbidden), isFalse, reason: forbidden);
    }
  });

  test('update: PATCH /<id>/', () async {
    when(
      () => client.patch(
        any(),
        headers: any(named: 'headers'),
        body: any(named: 'body'),
      ),
    ).thenAnswer(
      (_) async => http.Response(
        jsonEncode({
          'id': 9,
          'brand': 'Visa',
          'last4': '4242',
          'holder_name': 'Amy Kim',
          'expiry': '12/27',
          'is_default': false,
        }),
        200,
      ),
    );

    final updated = await api.update(
      id: '9',
      method: const PaymentMethodModel(
        id: '9',
        brand: 'Visa',
        last4: '4242',
        holderName: 'Amy Kim',
        expiry: '12/27',
      ),
      accessToken: 'tok',
    );

    expect(updated.holderName, 'Amy Kim');
    final captured = verify(
      () => client.patch(
        captureAny(),
        headers: any(named: 'headers'),
        body: any(named: 'body'),
      ),
    ).captured;
    expect((captured.single as Uri).path, '/api/payment-methods/9/');
  });

  test('delete: DELETE /<id>/ (204)', () async {
    when(() => client.delete(any(), headers: any(named: 'headers')))
        .thenAnswer((_) async => http.Response('', 204));

    await api.delete(id: '9', accessToken: 'tok');

    final captured = verify(
      () => client.delete(captureAny(), headers: any(named: 'headers')),
    ).captured;
    expect((captured.single as Uri).path, '/api/payment-methods/9/');
  });

  test('setDefault: POST /<id>/set-default/', () async {
    when(() => client.post(any(), headers: any(named: 'headers'))).thenAnswer(
      (_) async => http.Response(
        jsonEncode({
          'id': 9,
          'brand': 'Visa',
          'last4': '4242',
          'holder_name': 'Amy',
          'expiry': '12/27',
          'is_default': true,
        }),
        200,
      ),
    );

    final result = await api.setDefault(id: '9', accessToken: 'tok');

    expect(result.isDefault, isTrue);
    final captured = verify(
      () => client.post(captureAny(), headers: any(named: 'headers')),
    ).captured;
    expect((captured.single as Uri).path, '/api/payment-methods/9/set-default/');
  });

  test('비-2xx 응답이면 DjangoApiException', () async {
    when(() => client.get(any(), headers: any(named: 'headers')))
        .thenAnswer((_) async => http.Response('{"detail":"x"}', 401));

    expect(
      () => api.fetchMethods(accessToken: 'tok'),
      throwsA(isA<DjangoApiException>()),
    );
  });
}
