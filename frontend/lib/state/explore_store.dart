import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:yumbook_app/models/restaurant.dart';
import 'package:yumbook_app/services/django_restaurant_api.dart';

/// Explore 화면 전용 식당 검색 스토어.
/// cuisine / price tier / bbox(지도 영역) / q(검색어) 필터를 백엔드에 위임한다.
class ExploreStore extends ChangeNotifier {
  ExploreStore._();
  static final ExploreStore instance = ExploreStore._();

  final DjangoRestaurantApi _api = DjangoRestaurantApi();

  List<Restaurant> _results = [];
  bool _isLoading = false;
  Object? _lastError;

  List<Restaurant> get results => List.unmodifiable(_results);
  bool get isLoading => _isLoading;
  Object? get lastError => _lastError;
  bool get hasError => _lastError != null;

  /// 필터로 식당을 검색한다.
  /// - [priceLevel]: 1~4 (₩~₩₩₩₩). null/0이면 가격 필터 미적용.
  /// - [cuisine]: 'Korean' 등. 'All'/빈값이면 미적용.
  /// - [bbox]: 'min_lng,min_lat,max_lng,max_lat'. null이면 지도 영역 필터 미적용.
  Future<void> search({
    String? query,
    String? cuisine,
    int? priceLevel,
    String? bbox,
    String? ordering,
  }) async {
    _isLoading = true;
    _lastError = null;
    notifyListeners();

    try {
      final token = Supabase.instance.client.auth.currentSession?.accessToken;
      _results = await _api.searchRestaurants(
        query: (query != null && query.isNotEmpty) ? query : null,
        cuisine: (cuisine != null && cuisine.isNotEmpty && cuisine != 'All')
            ? cuisine
            : null,
        price: (priceLevel != null && priceLevel > 0) ? priceLevel : null,
        bbox: (bbox != null && bbox.isNotEmpty) ? bbox : null,
        ordering: ordering,
        accessToken: token,
      );
    } catch (error) {
      _lastError = error;
      _results = const [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void clear() {
    _results = const [];
    _isLoading = false;
    _lastError = null;
    notifyListeners();
  }
}
