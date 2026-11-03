import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:yumbook_app/services/django_payment_method_api.dart';

class PaymentMethodModel {
  final String id;
  final String brand;
  final String last4;
  final String holderName;
  final String expiry; // 표시용 "MM/YY"
  final bool isDefault;

  const PaymentMethodModel({
    required this.id,
    required this.brand,
    required this.last4,
    required this.holderName,
    required this.expiry,
    this.isDefault = false,
  });

  /// 보안: 전체 카드번호/CVV/CVC 등 민감정보는 다루지 않는다.
  /// 안전한 표시 필드만 직렬화한다(brand/last4/holder_name/expiry/is_default).
  factory PaymentMethodModel.fromJson(Map<String, dynamic> json) {
    return PaymentMethodModel(
      id: json['id'].toString(),
      brand: json['brand'] as String? ?? '',
      last4: json['last4'] as String? ?? '',
      holderName: json['holder_name'] as String? ?? '',
      expiry: json['expiry'] as String? ?? '',
      isDefault: json['is_default'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'brand': brand,
      'last4': last4,
      'holder_name': holderName,
      'expiry': expiry,
      'is_default': isDefault,
    };
  }
}

/// 결제수단 스토어. 백엔드(`/api/payment-methods/`)로 영속화한다.
/// 보안: 카드번호/CVV는 절대 전송/저장하지 않으며 안전 필드만 사용한다.
class PaymentMethodStore extends ChangeNotifier {
  PaymentMethodStore._();
  static final PaymentMethodStore instance = PaymentMethodStore._();

  final DjangoPaymentMethodApi _api = DjangoPaymentMethodApi();

  final List<PaymentMethodModel> _methods = [];
  bool _isLoading = false;
  bool _isSaving = false;
  bool _hasLoaded = false;
  Object? _lastError;

  List<PaymentMethodModel> get methods => List.unmodifiable(_methods);
  bool get isLoading => _isLoading;
  bool get isSaving => _isSaving;
  Object? get lastError => _lastError;
  bool get hasError => _lastError != null;

  /// 기본 카드(없으면 첫 번째). 백엔드 정렬상 기본 카드가 맨 앞이다.
  PaymentMethodModel? get primaryMethod {
    if (_methods.isEmpty) return null;
    return _methods.firstWhere(
      (m) => m.isDefault,
      orElse: () => _methods.first,
    );
  }

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
      final list = await _api.fetchMethods(accessToken: token);
      _methods
        ..clear()
        ..addAll(list);
      _hasLoaded = true;
    } catch (error) {
      _lastError = error;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// 새 카드 저장(POST). 성공 시 서버가 부여한 모델을 목록에 반영한다.
  Future<PaymentMethodModel> addMethod(PaymentMethodModel method) async {
    final token = _token();
    if (token == null) {
      throw StateError('No Supabase session — sign in to add a card.');
    }

    _isSaving = true;
    _lastError = null;
    notifyListeners();

    try {
      final saved = await _api.create(method: method, accessToken: token);
      // 기본 카드가 바뀌었을 수 있으니 목록을 다시 로드해 정합성을 맞춘다.
      await _reload(token);
      return saved;
    } catch (error) {
      _lastError = error;
      rethrow;
    } finally {
      _isSaving = false;
      notifyListeners();
    }
  }

  /// 삭제(DELETE). 낙관적 제거 후 실패 시 롤백.
  Future<void> removeMethod(String id) async {
    final token = _token();
    if (token == null) return;

    final index = _methods.indexWhere((m) => m.id == id);
    final PaymentMethodModel? removed =
        index >= 0 ? _methods.removeAt(index) : null;
    notifyListeners();

    try {
      await _api.delete(id: id, accessToken: token);
      _lastError = null;
      // 기본 카드 승격 등 서버 상태를 반영.
      await _reload(token);
    } catch (error) {
      if (removed != null) {
        _methods.insert(index.clamp(0, _methods.length), removed);
      }
      _lastError = error;
      notifyListeners();
    }
  }

  /// 기본 카드 지정(POST /set-default/).
  Future<void> setDefault(String id) async {
    final token = _token();
    if (token == null) return;

    _isSaving = true;
    _lastError = null;
    notifyListeners();

    try {
      await _api.setDefault(id: id, accessToken: token);
      await _reload(token);
    } catch (error) {
      _lastError = error;
    } finally {
      _isSaving = false;
      notifyListeners();
    }
  }

  Future<void> _reload(String token) async {
    final list = await _api.fetchMethods(accessToken: token);
    _methods
      ..clear()
      ..addAll(list);
    _hasLoaded = true;
  }

  void clear() {
    _methods.clear();
    _hasLoaded = false;
    _isLoading = false;
    _isSaving = false;
    _lastError = null;
    notifyListeners();
  }
}