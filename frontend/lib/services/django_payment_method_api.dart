import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:yumbook_app/services/django_reservation_api.dart';
import 'package:yumbook_app/state/payment_method_store.dart';

/// 결제수단 API 클라이언트.
///
/// 보안: 전체 카드번호(PAN)/CVV/CVC/인증 시크릿은 절대 전송하지 않는다.
/// PaymentMethodModel.toJson()이 안전 필드(brand/last4/holder_name/expiry/is_default)만
/// 직렬화하므로 민감정보가 본문에 포함될 수 없다.
class DjangoPaymentMethodApi {
  DjangoPaymentMethodApi({http.Client? client, String? baseUrl})
    : _client = client ?? http.Client(),
      _baseUrl = _normalizeBaseUrl(
        baseUrl ?? DjangoReservationApi.defaultBaseUrl,
      );

  final http.Client _client;
  final String _baseUrl;

  Future<List<PaymentMethodModel>> fetchMethods({
    required String accessToken,
  }) async {
    final response = await _client.get(
      _uri('/api/payment-methods/'),
      headers: _headers(accessToken),
    );
    final decoded = _decode(response);
    if (response.statusCode != 200) {
      throw DjangoApiException(response.statusCode, decoded.toString());
    }
    return (decoded as List<dynamic>)
        .map((e) => PaymentMethodModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<PaymentMethodModel> create({
    required PaymentMethodModel method,
    required String accessToken,
  }) async {
    final response = await _client.post(
      _uri('/api/payment-methods/'),
      headers: _headers(accessToken),
      body: jsonEncode(method.toJson()),
    );
    final decoded = _decode(response);
    if (response.statusCode != 201) {
      throw DjangoApiException(response.statusCode, decoded.toString());
    }
    return PaymentMethodModel.fromJson(decoded as Map<String, dynamic>);
  }

  Future<PaymentMethodModel> update({
    required String id,
    required PaymentMethodModel method,
    required String accessToken,
  }) async {
    final response = await _client.patch(
      _uri('/api/payment-methods/$id/'),
      headers: _headers(accessToken),
      body: jsonEncode(method.toJson()),
    );
    final decoded = _decode(response);
    if (response.statusCode != 200) {
      throw DjangoApiException(response.statusCode, decoded.toString());
    }
    return PaymentMethodModel.fromJson(decoded as Map<String, dynamic>);
  }

  Future<void> delete({
    required String id,
    required String accessToken,
  }) async {
    final response = await _client.delete(
      _uri('/api/payment-methods/$id/'),
      headers: _headers(accessToken),
    );
    if (response.statusCode != 204) {
      final decoded = _decode(response);
      throw DjangoApiException(response.statusCode, decoded.toString());
    }
  }

  Future<PaymentMethodModel> setDefault({
    required String id,
    required String accessToken,
  }) async {
    final response = await _client.post(
      _uri('/api/payment-methods/$id/set-default/'),
      headers: _headers(accessToken),
    );
    final decoded = _decode(response);
    if (response.statusCode != 200) {
      throw DjangoApiException(response.statusCode, decoded.toString());
    }
    return PaymentMethodModel.fromJson(decoded as Map<String, dynamic>);
  }

  Uri _uri(String path) => Uri.parse('$_baseUrl$path');

  Object? _decode(http.Response response) {
    if (response.bodyBytes.isEmpty) return null;
    return jsonDecode(utf8.decode(response.bodyBytes));
  }

  static String _normalizeBaseUrl(String baseUrl) {
    return baseUrl.endsWith('/')
        ? baseUrl.substring(0, baseUrl.length - 1)
        : baseUrl;
  }

  static Map<String, String> _headers(String accessToken) {
    return {
      'Accept': 'application/json',
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $accessToken',
    };
  }
}
