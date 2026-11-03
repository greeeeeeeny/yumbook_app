import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:yumbook_app/models/restaurant.dart';
import 'package:yumbook_app/services/django_reservation_api.dart';

/// 저장(북마크) 식당 API 클라이언트.
/// - GET    /api/saved-restaurants/            → 저장한 식당 전체(Restaurant)
/// - POST   /api/saved-restaurants/            → {restaurant: <id>} 저장(멱등)
/// - DELETE /api/saved-restaurants/<id>/       → restaurant_id로 저장 해제
class DjangoSavedRestaurantApi {
  DjangoSavedRestaurantApi({http.Client? client, String? baseUrl})
    : _client = client ?? http.Client(),
      _baseUrl = _normalizeBaseUrl(
        baseUrl ?? DjangoReservationApi.defaultBaseUrl,
      );

  final http.Client _client;
  final String _baseUrl;

  Future<List<Restaurant>> fetchSaved({required String accessToken}) async {
    final response = await _client.get(
      _uri('/api/saved-restaurants/'),
      headers: _headers(accessToken),
    );

    final decoded = _decode(response);
    if (response.statusCode != 200) {
      throw DjangoApiException(response.statusCode, decoded.toString());
    }

    return (decoded as List<dynamic>)
        .map((item) => Restaurant.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  Future<Restaurant> save({
    required String restaurantId,
    required String accessToken,
  }) async {
    final response = await _client.post(
      _uri('/api/saved-restaurants/'),
      headers: _headers(accessToken),
      body: jsonEncode({'restaurant': int.tryParse(restaurantId) ?? restaurantId}),
    );

    final decoded = _decode(response);
    // 신규 저장은 201, 이미 저장돼 있으면 200.
    if (response.statusCode != 200 && response.statusCode != 201) {
      throw DjangoApiException(response.statusCode, decoded.toString());
    }

    return Restaurant.fromJson(decoded as Map<String, dynamic>);
  }

  Future<void> unsave({
    required String restaurantId,
    required String accessToken,
  }) async {
    final response = await _client.delete(
      _uri('/api/saved-restaurants/$restaurantId/'),
      headers: _headers(accessToken),
    );

    if (response.statusCode != 204) {
      final decoded = _decode(response);
      throw DjangoApiException(response.statusCode, decoded.toString());
    }
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
