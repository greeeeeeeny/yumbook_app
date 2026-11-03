import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:yumbook_app/models/restaurant.dart';
import 'package:yumbook_app/services/django_restaurant_api.dart';

/// 예약 카드/상세에서 식당 정보를 백엔드(`/api/restaurants/{id}/`)로 조회하기 위한
/// 경량 캐시. 동일 id 중복 요청을 합치고 결과(실패 포함)를 캐싱한다.
class RestaurantCache {
  RestaurantCache._();
  static final RestaurantCache instance = RestaurantCache._();

  final DjangoRestaurantApi _api = DjangoRestaurantApi();
  final Map<String, Restaurant?> _cache = {};
  final Map<String, Future<Restaurant?>> _inflight = {};

  Future<Restaurant?> getById(String? id) {
    if (id == null || id.trim().isEmpty) {
      return Future.value(null);
    }
    if (_cache.containsKey(id)) {
      return Future.value(_cache[id]);
    }
    final existing = _inflight[id];
    if (existing != null) return existing;

    final token = Supabase.instance.client.auth.currentSession?.accessToken;
    final future = _api
        .fetchRestaurant(id: id, accessToken: token)
        .then<Restaurant?>((r) {
          _cache[id] = r;
          _inflight.remove(id);
          return r;
        })
        .catchError((_) {
          // 백엔드에 없는 id(예: 레거시/외부 id)는 null로 캐싱하고 UI는 플레이스홀더 처리.
          _cache[id] = null;
          _inflight.remove(id);
          return null;
        });

    _inflight[id] = future;
    return future;
  }

  void clear() {
    _cache.clear();
    _inflight.clear();
  }
}
