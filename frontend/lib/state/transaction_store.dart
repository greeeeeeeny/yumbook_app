import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:yumbook_app/models/transaction_model.dart';
import 'package:yumbook_app/services/django_transaction_api.dart';

/// 거래 내역 스토어. 백엔드(`/api/transactions/`)에서 최신순으로 로드한다.
class TransactionStore extends ChangeNotifier {
  TransactionStore._();
  static final TransactionStore instance = TransactionStore._();

  final DjangoTransactionApi _api = DjangoTransactionApi();

  final List<TransactionModel> _items = [];
  bool _isLoading = false;
  bool _hasLoaded = false;
  Object? _lastError;

  List<TransactionModel> get items => List.unmodifiable(_items);
  bool get isLoading => _isLoading;
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
      _items.clear();
      _hasLoaded = true;
      _lastError = null;
      notifyListeners();
      return;
    }

    _isLoading = true;
    _lastError = null;
    notifyListeners();

    try {
      // 백엔드가 -created_at 으로 정렬해 최신순으로 내려준다.
      final loaded = await _api.fetchTransactions(accessToken: token);
      _items
        ..clear()
        ..addAll(loaded);
      _hasLoaded = true;
    } catch (error) {
      _lastError = error;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void clear() {
    _items.clear();
    _hasLoaded = false;
    _isLoading = false;
    _lastError = null;
    notifyListeners();
  }
}
