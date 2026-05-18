import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:yumbook_app/models/restaurant.dart';
import 'package:yumbook_app/services/django_restaurant_api.dart';

class RestaurantStore extends ChangeNotifier {
  RestaurantStore._();
  static final RestaurantStore instance = RestaurantStore._();

  final DjangoRestaurantApi _api = DjangoRestaurantApi();

  String _query = '';
  List<Restaurant> _results = [];
  bool _isLoading = false;
  Object? _lastError;
  Timer? _debounce;

  String get query => _query;
  List<Restaurant> get results => List.unmodifiable(_results);
  bool get isLoading => _isLoading;
  Object? get lastError => _lastError;

  /// 디바운스된 검색. 빈 입력은 최근 식당 전체 조회로 처리.
  void setQuery(String query) {
    _query = query;
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 250), () {
      _runSearch();
    });
  }

  Future<void> refresh() async {
    _debounce?.cancel();
    await _runSearch();
  }

  Future<void> _runSearch() async {
    _isLoading = true;
    _lastError = null;
    notifyListeners();

    try {
      final token = Supabase.instance.client.auth.currentSession?.accessToken;
      _results = await _api.searchRestaurants(
        query: _query.isEmpty ? null : _query,
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
    _debounce?.cancel();
    _query = '';
    _results = const [];
    _isLoading = false;
    _lastError = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }
}
