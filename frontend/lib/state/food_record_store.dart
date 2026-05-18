import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:yumbook_app/models/food_record.dart';
import 'package:yumbook_app/services/django_food_record_api.dart';

/// FoodRecord 캐시. 공개 피드와 내 기록은 따로 보관하여 서로 덮어쓰지 않게 함.
class FoodRecordStore extends ChangeNotifier {
  FoodRecordStore._();
  static final FoodRecordStore instance = FoodRecordStore._();

  final List<FoodRecord> _publicRecords = [];
  final List<FoodRecord> _myRecords = [];
  final DjangoFoodRecordApi _api = DjangoFoodRecordApi();
  bool _isLoadingPublic = false;
  bool _isLoadingMine = false;
  Object? _lastError;

  List<FoodRecord> get publicRecords => List.unmodifiable(_publicRecords);
  List<FoodRecord> get myRecords => List.unmodifiable(_myRecords);
  bool get isLoadingPublic => _isLoadingPublic;
  bool get isLoadingMine => _isLoadingMine;
  Object? get lastError => _lastError;

  /// 공개 피드 (비로그인도 호출 가능).
  Future<void> loadPublicFeed({
    int? restaurantId,
    String? userId,
    String? query,
    String? ordering,
  }) async {
    _isLoadingPublic = true;
    _lastError = null;
    notifyListeners();

    try {
      final loaded = await _api.fetchRecords(
        accessToken: _currentAccessToken(),
        mine: false,
        restaurantId: restaurantId,
        userId: userId,
        query: query,
        ordering: ordering,
      );
      _publicRecords
        ..clear()
        ..addAll(loaded);
    } catch (error) {
      _lastError = error;
      rethrow;
    } finally {
      _isLoadingPublic = false;
      notifyListeners();
    }
  }

  /// 내 기록 (로그인 필수).
  Future<void> loadMyFeed({
    int? restaurantId,
    String? query,
    String? ordering,
  }) async {
    final token = _currentAccessToken();
    if (token == null) {
      throw StateError('No Supabase session — sign in to load your records.');
    }

    _isLoadingMine = true;
    _lastError = null;
    notifyListeners();

    try {
      final loaded = await _api.fetchRecords(
        accessToken: token,
        mine: true,
        restaurantId: restaurantId,
        query: query,
        ordering: ordering,
      );
      _myRecords
        ..clear()
        ..addAll(loaded);
    } catch (error) {
      _lastError = error;
      rethrow;
    } finally {
      _isLoadingMine = false;
      notifyListeners();
    }
  }

  Future<FoodRecord> createRecord(FoodRecord record) async {
    final token = _currentAccessToken();
    if (token == null) {
      throw StateError(
        'No Supabase session — sign in before creating a record.',
      );
    }

    final saved = await _api.createRecord(record: record, accessToken: token);
    _myRecords.insert(0, saved);
    if (saved.isPublic) {
      _publicRecords.insert(0, saved);
    }
    notifyListeners();
    return saved;
  }

  Future<FoodRecord> updateRecord(FoodRecord record) async {
    final id = record.id;
    if (id == null) {
      throw ArgumentError('FoodRecord.id is required for update.');
    }
    final token = _currentAccessToken();
    if (token == null) {
      throw StateError(
        'No Supabase session — sign in before updating a record.',
      );
    }

    final saved = await _api.updateRecord(
      id: id,
      record: record,
      accessToken: token,
    );

    _replaceOrInsert(_myRecords, saved);
    if (saved.isPublic) {
      _replaceOrInsert(_publicRecords, saved);
    } else {
      _publicRecords.removeWhere((r) => r.id == saved.id);
    }
    notifyListeners();
    return saved;
  }

  Future<void> deleteRecord(int id) async {
    final token = _currentAccessToken();
    if (token == null) {
      throw StateError(
        'No Supabase session — sign in before deleting a record.',
      );
    }

    await _api.deleteRecord(id: id, accessToken: token);
    _myRecords.removeWhere((r) => r.id == id);
    _publicRecords.removeWhere((r) => r.id == id);
    notifyListeners();
  }

  FoodRecord? findById(int id) {
    for (final list in [_myRecords, _publicRecords]) {
      for (final r in list) {
        if (r.id == id) return r;
      }
    }
    return null;
  }

  void clear() {
    if (_publicRecords.isEmpty && _myRecords.isEmpty && _lastError == null) {
      return;
    }
    _publicRecords.clear();
    _myRecords.clear();
    _lastError = null;
    notifyListeners();
  }

  static void _replaceOrInsert(List<FoodRecord> list, FoodRecord record) {
    final index = list.indexWhere((r) => r.id == record.id);
    if (index >= 0) {
      list[index] = record;
    } else {
      list.insert(0, record);
    }
  }

  String? _currentAccessToken() {
    return Supabase.instance.client.auth.currentSession?.accessToken;
  }
}
