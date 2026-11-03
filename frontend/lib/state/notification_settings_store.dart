import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:yumbook_app/models/notification_settings.dart';
import 'package:yumbook_app/services/django_account_api.dart';

/// 알림 설정 스토어. 백엔드(`/api/account/notification-settings/`)로 영속화한다.
/// 토글은 낙관적 업데이트 후 실패 시 롤백한다.
class NotificationSettingsStore extends ChangeNotifier {
  NotificationSettingsStore._();
  static final NotificationSettingsStore instance =
      NotificationSettingsStore._();

  final DjangoAccountApi _api = DjangoAccountApi();

  NotificationSettings _settings = const NotificationSettings();
  bool _isLoading = false;
  bool _isSaving = false;
  bool _hasLoaded = false;
  Object? _lastError;

  NotificationSettings get settings => _settings;
  bool get isLoading => _isLoading;
  bool get isSaving => _isSaving;
  Object? get lastError => _lastError;
  bool get hasError => _lastError != null;

  String? _token() =>
      Supabase.instance.client.auth.currentSession?.accessToken;

  void ensureLoaded() {
    if (_hasLoaded || _isLoading) return;
    Future.microtask(load);
  }

  Future<void> load() async {
    final token = _token();
    if (token == null) {
      _hasLoaded = true;
      notifyListeners();
      return;
    }

    _isLoading = true;
    _lastError = null;
    notifyListeners();

    try {
      _settings = await _api.fetchNotificationSettings(accessToken: token);
      _hasLoaded = true;
    } catch (error) {
      _lastError = error;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> setPushEnabled(bool value) =>
      _update(_settings.copyWith(pushEnabled: value));

  Future<void> setEmailEnabled(bool value) =>
      _update(_settings.copyWith(emailEnabled: value));

  Future<void> _update(NotificationSettings next) async {
    final token = _token();
    if (token == null) {
      _settings = next;
      notifyListeners();
      return;
    }

    // 낙관적 업데이트(스위치 즉시 반영), 실패 시 롤백.
    final previous = _settings;
    _settings = next;
    _isSaving = true;
    _lastError = null;
    notifyListeners();

    try {
      _settings = await _api.updateNotificationSettings(
        settings: next,
        accessToken: token,
      );
      _hasLoaded = true;
    } catch (error) {
      _settings = previous;
      _lastError = error;
    } finally {
      _isSaving = false;
      notifyListeners();
    }
  }

  void clear() {
    _settings = const NotificationSettings();
    _hasLoaded = false;
    _isLoading = false;
    _isSaving = false;
    _lastError = null;
    notifyListeners();
  }
}
