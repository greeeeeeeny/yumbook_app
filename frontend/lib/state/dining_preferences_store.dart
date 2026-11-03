import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:yumbook_app/models/dining_preferences.dart';
import 'package:yumbook_app/services/django_account_api.dart';

/// 다이닝 선호 스토어. 백엔드(`/api/account/dining-preferences/`)로 영속화한다.
class DiningPreferencesStore extends ChangeNotifier {
  DiningPreferencesStore._();
  static final DiningPreferencesStore instance = DiningPreferencesStore._();

  final DjangoAccountApi _api = DjangoAccountApi();

  DiningPreferences _preferences = const DiningPreferences();
  bool _isLoading = false;
  bool _isSaving = false;
  bool _hasLoaded = false;
  Object? _lastError;

  DiningPreferences get preferences => _preferences;
  bool get isLoading => _isLoading;
  bool get isSaving => _isSaving;
  Object? get lastError => _lastError;
  bool get hasError => _lastError != null;

  String? _token() =>
      Supabase.instance.client.auth.currentSession?.accessToken;

  /// 화면 진입 시 1회 로드(빌드 중 호출 안전하게 microtask로 예약).
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
      _preferences = await _api.fetchDiningPreferences(accessToken: token);
      _hasLoaded = true;
    } catch (error) {
      _lastError = error;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// 백엔드에 PATCH 저장. 실패 시 예외를 던져 화면이 에러를 표시/재시도하게 한다.
  Future<void> save(DiningPreferences preferences) async {
    final token = _token();
    if (token == null) {
      _preferences = preferences;
      notifyListeners();
      throw StateError('No Supabase session — sign in to save preferences.');
    }

    _isSaving = true;
    _lastError = null;
    notifyListeners();

    try {
      _preferences = await _api.updateDiningPreferences(
        preferences: preferences,
        accessToken: token,
      );
      _hasLoaded = true;
    } catch (error) {
      _lastError = error;
      rethrow;
    } finally {
      _isSaving = false;
      notifyListeners();
    }
  }

  void clear() {
    _preferences = const DiningPreferences();
    _hasLoaded = false;
    _isLoading = false;
    _isSaving = false;
    _lastError = null;
    notifyListeners();
  }
}
