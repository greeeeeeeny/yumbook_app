import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:yumbook_app/models/food_record.dart';
import 'package:yumbook_app/services/django_reservation_api.dart';

class DjangoFoodRecordApi {
  DjangoFoodRecordApi({http.Client? client, String? baseUrl})
    : _client = client ?? http.Client(),
      _baseUrl = _normalizeBaseUrl(
        baseUrl ?? DjangoReservationApi.defaultBaseUrl,
      );

  final http.Client _client;
  final String _baseUrl;

  Future<List<FoodRecord>> fetchRecords({
    String? accessToken,
    bool mine = false,
    int? restaurantId,
    String? userId,
    String? query,
    String? ordering,
  }) async {
    final params = <String, String>{};
    if (mine) params['mine'] = '1';
    if (restaurantId != null) params['restaurant'] = restaurantId.toString();
    if (userId != null && userId.isNotEmpty) params['user'] = userId;
    if (query != null && query.isNotEmpty) params['q'] = query;
    if (ordering != null && ordering.isNotEmpty) params['ordering'] = ordering;

    final response = await _client.get(
      _uri('/api/food-records/', queryParameters: params.isEmpty ? null : params),
      headers: _headers(accessToken),
    );

    final decoded = _decode(response);
    if (response.statusCode != 200) {
      throw DjangoApiException(response.statusCode, decoded.toString());
    }

    return (decoded as List<dynamic>)
        .map((item) => foodRecordFromJson(item as Map<String, dynamic>))
        .toList();
  }

  Future<FoodRecord> fetchRecord({
    required int id,
    String? accessToken,
  }) async {
    final response = await _client.get(
      _uri('/api/food-records/$id/'),
      headers: _headers(accessToken),
    );

    final decoded = _decode(response);
    if (response.statusCode != 200) {
      throw DjangoApiException(response.statusCode, decoded.toString());
    }

    return foodRecordFromJson(decoded as Map<String, dynamic>);
  }

  Future<FoodRecord> createRecord({
    required FoodRecord record,
    required String accessToken,
  }) async {
    final response = await _client.post(
      _uri('/api/food-records/'),
      headers: _headers(accessToken),
      body: jsonEncode(foodRecordToJson(record)),
    );

    final decoded = _decode(response);
    if (response.statusCode != 201) {
      throw DjangoApiException(response.statusCode, decoded.toString());
    }

    return foodRecordFromJson(decoded as Map<String, dynamic>);
  }

  Future<FoodRecord> updateRecord({
    required int id,
    required FoodRecord record,
    required String accessToken,
  }) async {
    final response = await _client.put(
      _uri('/api/food-records/$id/'),
      headers: _headers(accessToken),
      body: jsonEncode(foodRecordToJson(record)),
    );

    final decoded = _decode(response);
    if (response.statusCode != 200) {
      throw DjangoApiException(response.statusCode, decoded.toString());
    }

    return foodRecordFromJson(decoded as Map<String, dynamic>);
  }

  Future<void> deleteRecord({
    required int id,
    required String accessToken,
  }) async {
    final response = await _client.delete(
      _uri('/api/food-records/$id/'),
      headers: _headers(accessToken),
    );

    if (response.statusCode != 204) {
      final decoded = _decode(response);
      throw DjangoApiException(response.statusCode, decoded.toString());
    }
  }

  Map<String, dynamic> foodRecordToJson(FoodRecord r) {
    return {
      if (r.restaurantId != null) 'restaurant': r.restaurantId,
      'restaurant_name': r.restaurantName,
      'menu_name': r.menuName,
      'rating': r.rating.toString(),
      'review': r.review,
      if (r.price != null) 'price': r.price.toString(),
      'tags': r.tags,
      if (r.visitedAt != null) 'visited_at': _dateToJson(r.visitedAt!),
      'is_public': r.isPublic,
      'images': r.images
          .map((img) => {'image_url': img.imageUrl, 'order': img.order})
          .toList(),
    };
  }

  FoodRecord foodRecordFromJson(Map<String, dynamic> json) {
    return FoodRecord(
      id: json['id'] as int?,
      userId: json['user'] as String? ?? json['user_id'] as String?,
      restaurantId: json['restaurant'] as int?,
      restaurantName: json['restaurant_name'] as String? ?? '',
      menuName: json['menu_name'] as String? ?? '',
      rating: _parseDouble(json['rating']) ?? 0,
      review: json['review'] as String? ?? '',
      price: _parseDouble(json['price']),
      tags: _parseStringList(json['tags']),
      visitedAt: _dateFromJson(json['visited_at'] as String?),
      isPublic: json['is_public'] as bool? ?? true,
      images: _parseImages(json['images']),
      createdAt: _dateTimeFromJson(json['created_at'] as String?),
      updatedAt: _dateTimeFromJson(json['updated_at'] as String?),
    );
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
      'Content-Type': 'application/json',
      if (accessToken != null && accessToken.isNotEmpty)
        'Authorization': 'Bearer $accessToken',
    };
  }

  static double? _parseDouble(Object? value) {
    if (value == null) return null;
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value);
    return null;
  }

  static List<String> _parseStringList(Object? value) {
    if (value is List) {
      return value.map((e) => e.toString()).toList();
    }
    return const [];
  }

  static List<FoodRecordImage> _parseImages(Object? value) {
    if (value is! List) return const [];
    return value
        .whereType<Map<String, dynamic>>()
        .map(
          (item) => FoodRecordImage(
            id: item['id'] as int?,
            imageUrl: item['image_url'] as String? ?? '',
            order: item['order'] as int? ?? 0,
          ),
        )
        .toList();
  }

  static String _dateToJson(DateTime value) {
    return [
      value.year.toString().padLeft(4, '0'),
      value.month.toString().padLeft(2, '0'),
      value.day.toString().padLeft(2, '0'),
    ].join('-');
  }

  static DateTime? _dateFromJson(String? value) {
    if (value == null || value.isEmpty) return null;
    return DateTime.tryParse(value);
  }

  static DateTime? _dateTimeFromJson(String? value) {
    if (value == null || value.isEmpty) return null;
    return DateTime.tryParse(value);
  }
}
