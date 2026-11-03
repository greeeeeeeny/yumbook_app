import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:yumbook_app/models/user_profile.dart';
import 'package:yumbook_app/services/django_account_api.dart';

/// 사용자 프로필 스토어. 백엔드(`/api/account/profile/`)로 영속화한다.
class UserProfileStore extends ChangeNotifier {
  UserProfileStore._();
  static final UserProfileStore instance = UserProfileStore._();

  final DjangoAccountApi _api = DjangoAccountApi();

  UserProfile _profile = UserProfile.empty;
  bool _isLoading = false;
  bool _isSaving = false;
  bool _hasLoaded = false;
  Object? _lastError;

  UserProfile get profile => _profile;
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
      _profile = await _api.fetchProfile(accessToken: token);
      _hasLoaded = true;
    } catch (error) {
      _lastError = error;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// 백엔드에 PATCH 저장. 실패 시 예외를 던져 화면이 에러를 표시하게 한다.
  Future<void> updateProfile(UserProfile profile) async {
    final token = _token();
    if (token == null) {
      _profile = profile;
      notifyListeners();
      throw StateError('No Supabase session — sign in to save your profile.');
    }

    _isSaving = true;
    _lastError = null;
    notifyListeners();

    try {
      _profile = await _api.updateProfile(profile: profile, accessToken: token);
      _hasLoaded = true;
    } catch (error) {
      _lastError = error;
      rethrow;
    } finally {
      _isSaving = false;
      notifyListeners();
    }
  }

  // --- 로컬 캐시 시드용 setter (가입/로그인 시 표시값 선반영; 영속화는 updateProfile) ---

  void updateName(String value) {
    _profile = _profile.copyWith(name: value);
    notifyListeners();
  }

  void updateDateOfBirth(String value) {
    _profile = _profile.copyWith(dateOfBirth: value);
    notifyListeners();
  }

  void updateMobileNumber(String value) {
    _profile = _profile.copyWith(mobileNumber: value);
    notifyListeners();
  }

  void updateEmail(String value) {
    _profile = _profile.copyWith(email: value);
    notifyListeners();
  }

  void updateProfileImagePath(String? value) {
    _profile = _profile.copyWith(
      profileImagePath: value,
      clearProfileImage: value == null,
    );
    notifyListeners();
  }

  void clear() {
    _profile = UserProfile.empty;
    _hasLoaded = false;
    _isLoading = false;
    _isSaving = false;
    _lastError = null;
    notifyListeners();
  }
}
