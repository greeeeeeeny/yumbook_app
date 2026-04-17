import 'package:flutter/foundation.dart';

class PaymentMethodModel {
  final String id;
  final String brand;
  final String last4;
  final String holderName;
  final String expiry;

  const PaymentMethodModel({
    required this.id,
    required this.brand,
    required this.last4,
    required this.holderName,
    required this.expiry,
  });
}

class PaymentMethodStore extends ChangeNotifier {
  PaymentMethodStore._();
  static final PaymentMethodStore instance = PaymentMethodStore._();

  final List<PaymentMethodModel> _methods = [];

  List<PaymentMethodModel> get methods => List.unmodifiable(_methods);

  PaymentMethodModel? get primaryMethod =>
      _methods.isEmpty ? null : _methods.first;

  void addMethod(PaymentMethodModel method) {
    _methods.insert(0, method);
    notifyListeners();
  }

  void removeMethod(String id) {
    _methods.removeWhere((e) => e.id == id);
    notifyListeners();
  }

  void clear() {
    _methods.clear();
    notifyListeners();
  }
}