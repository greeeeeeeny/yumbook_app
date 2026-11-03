import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:yumbook_app/models/region.dart';
import 'package:yumbook_app/models/restaurant.dart';
import 'package:yumbook_app/services/django_reservation_api.dart';

class DjangoRestaurantApi {
  DjangoRestaurantApi({http.Client? client, String? baseUrl})
    : _client = client ?? http.Client(),
      _baseUrl = _normalizeBaseUrl(
        baseUrl ?? DjangoReservationApi.defaultBaseUrl,
      );

  final http.Client _client;
  final String _baseUrl;

  Future<List<Restaurant>> searchRestaurants({
    String? query,
    String? location,
    String? category,
    String? region,
    String? cuisine,
    int? price,
    int? minPrice,
    int? maxPrice,
    String? bbox,
    String? ordering,
    String? accessToken,
  }) async {
    final params = <String, String>{};
    if (query != null && query.isNotEmpty) params['q'] = query;
    if (location != null && location.isNotEmpty) params['location'] = location;
    if (category != null && category.isNotEmpty) params['category'] = category;
    if (region != null && region.isNotEmpty) params['region'] = region;
    if (cuisine != null && cuisine.isNotEmpty) params['cuisine'] = cuisine;
    if (price != null) params['price'] = price.toString();
    if (minPrice != null) params['min_price'] = minPrice.toString();
    if (maxPrice != null) params['max_price'] = maxPrice.toString();
    if (bbox != null && bbox.isNotEmpty) params['bbox'] = bbox;
    if (ordering != null && ordering.isNotEmpty) params['ordering'] = ordering;

    final response = await _client.get(
      _uri('/api/restaurants/', queryParameters: params.isEmpty ? null : params),
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

  /// 활성 지역 목록을 백엔드(`/api/regions/`)에서 로드한다.
  Future<List<Region>> fetchRegions({String? accessToken}) async {
    final response = await _client.get(
      _uri('/api/regions/'),
      headers: _headers(accessToken),
    );

    final decoded = _decode(response);
    if (response.statusCode != 200) {
      throw DjangoApiException(response.statusCode, decoded.toString());
    }

    return (decoded as List<dynamic>)
        .map((item) => Region.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  Future<Restaurant> fetchRestaurant({
    required String id,
    String? accessToken,
  }) async {
    final response = await _client.get(
      _uri('/api/restaurants/$id/'),
      headers: _headers(accessToken),
    );

    final decoded = _decode(response);
    if (response.statusCode != 200) {
      throw DjangoApiException(response.statusCode, decoded.toString());
    }

    return Restaurant.fromJson(decoded as Map<String, dynamic>);
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

  static Map<String, String> _headers(String? accessToken) {
    return {
      'Accept': 'application/json',
      if (accessToken != null && accessToken.isNotEmpty)
        'Authorization': 'Bearer $accessToken',
    };
  }
}
