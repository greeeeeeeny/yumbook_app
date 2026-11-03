import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:yumbook_app/models/dining_preferences.dart';
import 'package:yumbook_app/models/notification_settings.dart';
import 'package:yumbook_app/models/user_profile.dart';
import 'package:yumbook_app/services/django_reservation_api.dart';

/// 계정(account) 영역 API 클라이언트.
/// 프로필 / 다이닝 선호 / 알림 설정 싱글톤 엔드포인트를 다룬다(모두 GET/PATCH).
class DjangoAccountApi {
  DjangoAccountApi({http.Client? client, String? baseUrl})
    : _client = client ?? http.Client(),
      _baseUrl = _normalizeBaseUrl(
        baseUrl ?? DjangoReservationApi.defaultBaseUrl,
      );

  final http.Client _client;
  final String _baseUrl;

  // ---- Profile ----

  Future<UserProfile> fetchProfile({required String accessToken}) async {
    final response = await _client.get(
      _uri('/api/account/profile/'),
      headers: _headers(accessToken),
    );
    final decoded = _decode(response);
    if (response.statusCode != 200) {
      throw DjangoApiException(response.statusCode, decoded.toString());
    }
    return UserProfile.fromJson(decoded as Map<String, dynamic>);
  }

  Future<UserProfile> updateProfile({
    required UserProfile profile,
    required String accessToken,
  }) async {
    final response = await _client.patch(
      _uri('/api/account/profile/'),
      headers: _headers(accessToken),
      body: jsonEncode(profile.toJson()),
    );
    final decoded = _decode(response);
    if (response.statusCode != 200) {
      throw DjangoApiException(response.statusCode, decoded.toString());
    }
    return UserProfile.fromJson(decoded as Map<String, dynamic>);
  }

  // ---- Dining preferences ----

  Future<DiningPreferences> fetchDiningPreferences({
    required String accessToken,
  }) async {
    final response = await _client.get(
      _uri('/api/account/dining-preferences/'),
      headers: _headers(accessToken),
    );
    final decoded = _decode(response);
    if (response.statusCode != 200) {
      throw DjangoApiException(response.statusCode, decoded.toString());
    }
    return DiningPreferences.fromJson(decoded as Map<String, dynamic>);
  }

  Future<DiningPreferences> updateDiningPreferences({
    required DiningPreferences preferences,
    required String accessToken,
  }) async {
    final response = await _client.patch(
      _uri('/api/account/dining-preferences/'),
      headers: _headers(accessToken),
      body: jsonEncode(preferences.toJson()),
    );
    final decoded = _decode(response);
    if (response.statusCode != 200) {
      throw DjangoApiException(response.statusCode, decoded.toString());
    }
    return DiningPreferences.fromJson(decoded as Map<String, dynamic>);
  }

  // ---- Notification settings ----

  Future<NotificationSettings> fetchNotificationSettings({
    required String accessToken,
  }) async {
    final response = await _client.get(
      _uri('/api/account/notification-settings/'),
      headers: _headers(accessToken),
    );
    final decoded = _decode(response);
    if (response.statusCode != 200) {
      throw DjangoApiException(response.statusCode, decoded.toString());
    }
    return NotificationSettings.fromJson(decoded as Map<String, dynamic>);
  }

  Future<NotificationSettings> updateNotificationSettings({
    required NotificationSettings settings,
    required String accessToken,
  }) async {
    final response = await _client.patch(
      _uri('/api/account/notification-settings/'),
      headers: _headers(accessToken),
      body: jsonEncode(settings.toJson()),
    );
    final decoded = _decode(response);
    if (response.statusCode != 200) {
      throw DjangoApiException(response.statusCode, decoded.toString());
    }
    return NotificationSettings.fromJson(decoded as Map<String, dynamic>);
  }

  // ---- shared helpers ----

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
