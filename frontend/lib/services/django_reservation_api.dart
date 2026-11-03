import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:yumbook_app/models/reservation_data.dart';

class DjangoApiException implements Exception {
  final int statusCode;
  final String message;

  const DjangoApiException(this.statusCode, this.message);

  @override
  String toString() => 'DjangoApiException($statusCode): $message';
}

class DjangoReservationApi {
  DjangoReservationApi({http.Client? client, String? baseUrl})
    : _client = client ?? http.Client(),
      _baseUrl = _normalizeBaseUrl(baseUrl ?? defaultBaseUrl);

  final http.Client _client;
  final String _baseUrl;

  static String get defaultBaseUrl {
    const configured = String.fromEnvironment('DJANGO_API_BASE_URL');
    if (configured.isNotEmpty) return configured;

    if (kIsWeb) {
      final current = Uri.base;
      if (current.host.endsWith('.app.github.dev')) {
        final backendHost = current.host.replaceFirst(
          RegExp(r'-\d+\.app\.github\.dev$'),
          '-8000.app.github.dev',
        );
        return '${current.scheme}://$backendHost';
      }
      return 'http://localhost:8000';
    }

    if (defaultTargetPlatform == TargetPlatform.android) {
      return 'http://10.0.2.2:8000';
    }

    return 'http://127.0.0.1:8000';
  }

  Future<List<ReservationData>> fetchReservations({
    required String accessToken,
  }) async {
    final response = await _client.get(
      _uri('/api/reservations/'),
      headers: _authHeaders(accessToken),
    );

    final decoded = _decode(response);
    if (response.statusCode != 200) {
      throw DjangoApiException(response.statusCode, decoded.toString());
    }

    return (decoded as List<dynamic>)
        .map((item) => reservationFromJson(item as Map<String, dynamic>))
        .toList();
  }

  Future<ReservationData> createReservation({
    required ReservationData reservation,
    required String accessToken,
  }) async {
    final response = await _client.post(
      _uri('/api/reservations/'),
      headers: _authHeaders(accessToken),
      body: jsonEncode(reservationToJson(reservation)),
    );

    final decoded = _decode(response);
    if (response.statusCode != 201) {
      throw DjangoApiException(response.statusCode, decoded.toString());
    }

    return reservationFromJson(decoded as Map<String, dynamic>);
  }

  /// POST /api/reservations/{id}/cancel/
  Future<ReservationData> cancelReservation({
    required int id,
    required String accessToken,
    String reason = '',
  }) async {
    return _lifecycle(
      path: '/api/reservations/$id/cancel/',
      accessToken: accessToken,
      body: {'reason': reason},
    );
  }

  /// POST /api/reservations/{id}/request-change/  (201)
  Future<ReservationData> requestChange({
    required int id,
    required DateTime date,
    required DateTime time,
    required int partySize,
    required String accessToken,
  }) async {
    return _lifecycle(
      path: '/api/reservations/$id/request-change/',
      accessToken: accessToken,
      body: {
        'requested_date': _dateToJson(date),
        'requested_time': _timeToJson(time),
        'requested_party_size': partySize,
      },
      expectStatus: 201,
    );
  }

  /// POST /api/reservations/{id}/approve-change/
  Future<ReservationData> approveChange({
    required int id,
    required String accessToken,
  }) async {
    return _lifecycle(
      path: '/api/reservations/$id/approve-change/',
      accessToken: accessToken,
    );
  }

  /// POST /api/reservations/{id}/reject-change/
  Future<ReservationData> rejectChange({
    required int id,
    required String accessToken,
  }) async {
    return _lifecycle(
      path: '/api/reservations/$id/reject-change/',
      accessToken: accessToken,
    );
  }

  Future<ReservationData> _lifecycle({
    required String path,
    required String accessToken,
    Map<String, dynamic>? body,
    int expectStatus = 200,
  }) async {
    final response = await _client.post(
      _uri(path),
      headers: _authHeaders(accessToken),
      body: jsonEncode(body ?? const {}),
    );

    final decoded = _decode(response);
    if (response.statusCode != expectStatus) {
      throw DjangoApiException(response.statusCode, decoded.toString());
    }

    return reservationFromJson(decoded as Map<String, dynamic>);
  }

  Map<String, dynamic> reservationToJson(ReservationData reservation) {
    return {
      'restaurant_id': reservation.restaurantId,
      'restaurant_name': reservation.restaurantName,
      'date': _dateToJson(reservation.date),
      'time': _timeToJson(reservation.time),
      'party_size': reservation.partySize,
      'guest_name': reservation.guestName,
      'seat_type': reservation.seatType,
    };
  }

  ReservationData reservationFromJson(Map<String, dynamic> json) {
    return ReservationData(
      id: json['id'] as int?,
      restaurantName: json['restaurant_name'] as String? ?? '',
      restaurantId: json['restaurant_id'] as String?,
      date: _dateFromJson(json['date'] as String),
      time: _timeFromJson(json['time'] as String),
      partySize: json['party_size'] as int? ?? 1,
      guestName: json['guest_name'] as String? ?? '',
      seatType: json['seat_type'] as String?,
      confirmationCode:
          json['confirmation_code'] as String? ?? 'Yumbook-B-00001',
      status: json['status'] as String? ?? 'confirmed',
      pendingChange: _pendingChangeFromJson(
        json['pending_change'] as Map<String, dynamic>?,
      ),
    );
  }

  ReservationChangeRequest? _pendingChangeFromJson(Map<String, dynamic>? json) {
    if (json == null) return null;
    return ReservationChangeRequest(
      requestedDate: _dateFromJson(json['requested_date'] as String),
      requestedTime: _timeFromJson(json['requested_time'] as String),
      requestedPartySize: json['requested_party_size'] as int? ?? 1,
      requestedAt:
          DateTime.tryParse(json['requested_at'] as String? ?? '') ??
          DateTime.fromMillisecondsSinceEpoch(0),
      status: _changeStatusFromString(json['status'] as String?),
    );
  }

  ReservationChangeStatus _changeStatusFromString(String? value) {
    switch (value) {
      case 'pending':
        return ReservationChangeStatus.pending;
      case 'approved':
        return ReservationChangeStatus.approved;
      case 'rejected':
        return ReservationChangeStatus.rejected;
      default:
        return ReservationChangeStatus.none;
    }
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

  static Map<String, String> _authHeaders(String accessToken) {
    return {
      'Accept': 'application/json',
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $accessToken',
    };
  }

  String _dateToJson(DateTime value) {
    return [
      value.year.toString().padLeft(4, '0'),
      value.month.toString().padLeft(2, '0'),
      value.day.toString().padLeft(2, '0'),
    ].join('-');
  }

  String _timeToJson(DateTime value) {
    return [
      value.hour.toString().padLeft(2, '0'),
      value.minute.toString().padLeft(2, '0'),
      '00',
    ].join(':');
  }

  DateTime _dateFromJson(String value) {
    return DateTime.parse(value);
  }

  DateTime _timeFromJson(String value) {
    final parts = value.split(':');
    return DateTime(
      1970,
      1,
      1,
      int.parse(parts[0]),
      int.parse(parts[1]),
      parts.length > 2 ? int.parse(parts[2].split('.').first) : 0,
    );
  }
}
