import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:mocktail/mocktail.dart';
import 'package:yumbook_app/models/dining_preferences.dart';
import 'package:yumbook_app/models/notification_settings.dart';
import 'package:yumbook_app/models/user_profile.dart';
import 'package:yumbook_app/services/django_account_api.dart';
import 'package:yumbook_app/services/django_reservation_api.dart';

class _MockClient extends Mock implements http.Client {}

class _FakeUri extends Fake implements Uri {}

void main() {
  setUpAll(() {
    registerFallbackValue(_FakeUri());
  });

  late _MockClient client;
  late DjangoAccountApi api;

  setUp(() {
    client = _MockClient();
    api = DjangoAccountApi(client: client, baseUrl: 'http://test.local/');
  });

  test('fetchProfile: avatar_url → profileImagePath 매핑', () async {
    when(() => client.get(any(), headers: any(named: 'headers'))).thenAnswer(
      (_) async => http.Response(
        jsonEncode({
          'name': 'Amy',
          'date_of_birth': 'Jan 1, 1991',
          'mobile_number': '010-1010-1010',
          'email': 'amy@example.com',
          'avatar_url': 'assets/images/profile/avatar_1.png',
        }),
        200,
      ),
    );

    final profile = await api.fetchProfile(accessToken: 'tok');

    expect(profile.name, 'Amy');
    expect(profile.email, 'amy@example.com');
    expect(profile.mobileNumber, '010-1010-1010');
    expect(profile.profileImagePath, 'assets/images/profile/avatar_1.png');

    final captured = verify(
      () => client.get(captureAny(), headers: any(named: 'headers')),
    ).captured;
    expect((captured.single as Uri).path, '/api/account/profile/');
  });

  test('fetchProfile: 빈 avatar_url 은 null 로 매핑', () async {
    when(() => client.get(any(), headers: any(named: 'headers'))).thenAnswer(
      (_) async => http.Response(jsonEncode({'name': 'A', 'avatar_url': ''}), 200),
    );

    final profile = await api.fetchProfile(accessToken: 'tok');
    expect(profile.profileImagePath, isNull);
  });

  test('updateProfile: PATCH 본문에 snake_case + avatar_url 포함', () async {
    when(
      () => client.patch(
        any(),
        headers: any(named: 'headers'),
        body: any(named: 'body'),
      ),
    ).thenAnswer(
      (_) async => http.Response(
        jsonEncode({
          'name': 'Amy Kim',
          'date_of_birth': 'Jan 1, 1991',
          'mobile_number': '010',
          'email': 'amy@example.com',
          'avatar_url': 'assets/images/profile/avatar_2.png',
        }),
        200,
      ),
    );

    final updated = await api.updateProfile(
      profile: const UserProfile(
        name: 'Amy Kim',
        dateOfBirth: 'Jan 1, 1991',
        mobileNumber: '010',
        email: 'amy@example.com',
        profileImagePath: 'assets/images/profile/avatar_2.png',
      ),
      accessToken: 'tok',
    );

    expect(updated.name, 'Amy Kim');
    expect(updated.profileImagePath, 'assets/images/profile/avatar_2.png');

    final captured = verify(
      () => client.patch(
        any(),
        headers: any(named: 'headers'),
        body: captureAny(named: 'body'),
      ),
    ).captured;
    final sent = jsonDecode(captured.single as String) as Map<String, dynamic>;
    expect(sent['name'], 'Amy Kim');
    expect(sent['mobile_number'], '010');
    expect(sent['avatar_url'], 'assets/images/profile/avatar_2.png');
  });

  test('비-200 응답이면 DjangoApiException', () async {
    when(() => client.get(any(), headers: any(named: 'headers')))
        .thenAnswer((_) async => http.Response('{"detail":"x"}', 401));

    expect(
      () => api.fetchProfile(accessToken: 'tok'),
      throwsA(isA<DjangoApiException>()),
    );
  });

  // ---- Dining preferences ----

  test('fetchDiningPreferences: snake_case 리스트 → 모델 매핑', () async {
    when(() => client.get(any(), headers: any(named: 'headers'))).thenAnswer(
      (_) async => http.Response(
        jsonEncode({
          'favorite_cuisines': ['Korean', 'Italian'],
          'dining_styles': ['Casual dining'],
          'dietary_restrictions': ['Gluten-free'],
          'additional_notes': 'No spicy food',
        }),
        200,
      ),
    );

    final prefs = await api.fetchDiningPreferences(accessToken: 'tok');

    expect(prefs.favoriteCuisines, ['Korean', 'Italian']);
    expect(prefs.diningStyles, ['Casual dining']);
    expect(prefs.dietaryRestrictions, ['Gluten-free']);
    expect(prefs.additionalNotes, 'No spicy food');

    final captured = verify(
      () => client.get(captureAny(), headers: any(named: 'headers')),
    ).captured;
    expect((captured.single as Uri).path, '/api/account/dining-preferences/');
  });

  test('updateDiningPreferences: PATCH 본문 snake_case 직렬화', () async {
    when(
      () => client.patch(
        any(),
        headers: any(named: 'headers'),
        body: any(named: 'body'),
      ),
    ).thenAnswer(
      (_) async => http.Response(
        jsonEncode({
          'favorite_cuisines': ['Japanese'],
          'dining_styles': <String>[],
          'dietary_restrictions': ['Vegan'],
          'additional_notes': 'No nuts',
        }),
        200,
      ),
    );

    final updated = await api.updateDiningPreferences(
      preferences: const DiningPreferences(
        favoriteCuisines: ['Japanese'],
        dietaryRestrictions: ['Vegan'],
        additionalNotes: 'No nuts',
      ),
      accessToken: 'tok',
    );

    expect(updated.favoriteCuisines, ['Japanese']);
    expect(updated.dietaryRestrictions, ['Vegan']);

    final captured = verify(
      () => client.patch(
        any(),
        headers: any(named: 'headers'),
        body: captureAny(named: 'body'),
      ),
    ).captured;
    final sent = jsonDecode(captured.single as String) as Map<String, dynamic>;
    expect(sent['favorite_cuisines'], ['Japanese']);
    expect(sent['dietary_restrictions'], ['Vegan']);
    expect(sent['additional_notes'], 'No nuts');
  });

  // ---- Notification settings ----

  test('fetchNotificationSettings: push/email 불리언 매핑', () async {
    when(() => client.get(any(), headers: any(named: 'headers'))).thenAnswer(
      (_) async => http.Response(
        jsonEncode({'push_enabled': false, 'email_enabled': true}),
        200,
      ),
    );

    final settings = await api.fetchNotificationSettings(accessToken: 'tok');

    expect(settings.pushEnabled, isFalse);
    expect(settings.emailEnabled, isTrue);

    final captured = verify(
      () => client.get(captureAny(), headers: any(named: 'headers')),
    ).captured;
    expect(
      (captured.single as Uri).path,
      '/api/account/notification-settings/',
    );
  });

  test('updateNotificationSettings: PATCH 본문 snake_case 직렬화', () async {
    when(
      () => client.patch(
        any(),
        headers: any(named: 'headers'),
        body: any(named: 'body'),
      ),
    ).thenAnswer(
      (_) async => http.Response(
        jsonEncode({'push_enabled': false, 'email_enabled': false}),
        200,
      ),
    );

    final updated = await api.updateNotificationSettings(
      settings: const NotificationSettings(
        pushEnabled: false,
        emailEnabled: false,
      ),
      accessToken: 'tok',
    );

    expect(updated.pushEnabled, isFalse);
    expect(updated.emailEnabled, isFalse);

    final captured = verify(
      () => client.patch(
        any(),
        headers: any(named: 'headers'),
        body: captureAny(named: 'body'),
      ),
    ).captured;
    final sent = jsonDecode(captured.single as String) as Map<String, dynamic>;
    expect(sent['push_enabled'], isFalse);
    expect(sent['email_enabled'], isFalse);
  });
}
