import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:yumbook_app/models/transaction_model.dart';
import 'package:yumbook_app/services/django_reservation_api.dart';

/// 거래 내역 API 클라이언트(읽기 전용).
/// - GET /api/transactions/           → 본인 거래 목록(최신순)
/// - GET /api/transactions/<id>/      → 단일 거래
class DjangoTransactionApi {
  DjangoTransactionApi({http.Client? client, String? baseUrl})
    : _client = client ?? http.Client(),
      _baseUrl = _normalizeBaseUrl(
        baseUrl ?? DjangoReservationApi.defaultBaseUrl,
      );

  final http.Client _client;
  final String _baseUrl;

  Future<List<TransactionModel>> fetchTransactions({
    required String accessToken,
    String? status,
    String? type,
    int? reservationId,
  }) async {
    final params = <String, String>{};
    if (status != null && status.isNotEmpty) params['status'] = status;
    if (type != null && type.isNotEmpty) params['transaction_type'] = type;
    if (reservationId != null) params['reservation'] = reservationId.toString();

    final response = await _client.get(
      _uri('/api/transactions/', queryParameters: params.isEmpty ? null : params),
      headers: _headers(accessToken),
    );
    final decoded = _decode(response);
    if (response.statusCode != 200) {
      throw DjangoApiException(response.statusCode, decoded.toString());
    }
    return (decoded as List<dynamic>)
        .map((e) => TransactionModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<TransactionModel> fetchTransaction({
    required int id,
    required String accessToken,
  }) async {
    final response = await _client.get(
      _uri('/api/transactions/$id/'),
      headers: _headers(accessToken),
    );
    final decoded = _decode(response);
    if (response.statusCode != 200) {
      throw DjangoApiException(response.statusCode, decoded.toString());
    }
    return TransactionModel.fromJson(decoded as Map<String, dynamic>);
  }

  Uri _uri(String path, {Map<String, String>? queryParameters}) {
    return Uri.parse(
      '$_baseUrl$path',
    ).replace(queryParameters: queryParameters);
  }

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
