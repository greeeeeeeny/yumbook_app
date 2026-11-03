import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:yumbook_app/models/restaurant.dart';
import 'package:yumbook_app/services/django_saved_restaurant_api.dart';

/// 저장(북마크) 식당 스토어. 백엔드(`/api/saved-restaurants/`)로 영속화한다.
///
/// 화면 호환을 위해 기존 메서드 시그니처(userId 포함)를 유지한다.
/// 단, 소유자는 백엔드가 Supabase 토큰으로 결정하므로 userId 인자는 무시된다.
class SavedRestaurantsStore extends ChangeNotifier {
  SavedRestaurantsStore._();
  static final SavedRestaurantsStore instance = SavedRestaurantsStore._();

  final DjangoSavedRestaurantApi _api = DjangoSavedRestaurantApi();

  final List<Restaurant> _saved = [];
  final Set<String> _savedIds = <String>{};
  bool _isLoading = false;
  bool _hasLoaded = false;
  Object? _lastError;

  List<Restaurant> get saved => List.unmodifiable(_saved);
  bool get isLoading => _isLoading;
  Object? get lastError => _lastError;
  bool get hasError => _lastError != null;

  String? _token() =>
      Supabase.instance.client.auth.currentSession?.accessToken;

  /// 화면 진입 시 1회 로드. 빌드 중 호출돼도 안전하도록 microtask로 예약한다.
  void ensureLoaded() {
    if (_hasLoaded || _isLoading) return;
    Future.microtask(load);
  }

  Future<void> load() async {
    final token = _token();
    if (token == null) {
      _saved.clear();
      _savedIds.clear();
      _hasLoaded = true;
      _lastError = null;
      notifyListeners();
      return;
    }

    _isLoading = true;
    _lastError = null;
    notifyListeners();

    try {
      final list = await _api.fetchSaved(accessToken: token);
      _saved
        ..clear()
        ..addAll(list);
      _savedIds
        ..clear()
        ..addAll(list.map((r) => r.id));
      _hasLoaded = true;
    } catch (error) {
      _lastError = error;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  bool isSaved({required String userId, required String restaurantId}) {
    return _savedIds.contains(restaurantId);
  }

  Future<void> toggleSaved({
    required String userId,
    required String restaurantId,
  }) async {
    if (_savedIds.contains(restaurantId)) {
      await removeSaved(userId: userId, restaurantId: restaurantId);
    } else {
      await _save(restaurantId);
    }
  }

  Future<void> _save(String restaurantId) async {
    final token = _token();
    if (token == null) return;

    // 낙관적 업데이트(별표 즉시 반영) 후 실패 시 롤백.
    _savedIds.add(restaurantId);
    notifyListeners();

    try {
      final saved = await _api.save(
        restaurantId: restaurantId,
        accessToken: token,
      );
      if (!_saved.any((r) => r.id == saved.id)) {
        _saved.insert(0, saved);
      }
      _savedIds.add(saved.id);
      _lastError = null;
    } catch (error) {
      _savedIds.remove(restaurantId);
      _lastError = error;
    } finally {
      notifyListeners();
    }
  }

  Future<void> removeSaved({
    required String userId,
    required String restaurantId,
  }) async {
    final token = _token();
    if (token == null) return;

    final removedIndex = _saved.indexWhere((r) => r.id == restaurantId);
    final Restaurant? removed =
        removedIndex >= 0 ? _saved.removeAt(removedIndex) : null;
    _savedIds.remove(restaurantId);
    notifyListeners();

    try {
      await _api.unsave(restaurantId: restaurantId, accessToken: token);
      _lastError = null;
    } catch (error) {
      // 롤백
      if (removed != null) {
        _saved.insert(removedIndex.clamp(0, _saved.length), removed);
      }
      _savedIds.add(restaurantId);
      _lastError = error;
    } finally {
      notifyListeners();
    }
  }

  /// 하위호환: 화면은 getSavedRestaurants(userId)로 목록을 읽는다.
  List<Restaurant> getSavedRestaurants(String userId) => saved;

  int savedCount(String userId) => _saved.length;

  void clear() {
    _saved.clear();
    _savedIds.clear();
    _hasLoaded = false;
    _isLoading = false;
    _lastError = null;
    notifyListeners();
  }
}
