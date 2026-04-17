import 'package:flutter/foundation.dart';
import 'package:yumbook_app/models/transaction_model.dart';

class TransactionStore extends ChangeNotifier {
  TransactionStore._();
  static final TransactionStore instance = TransactionStore._();

  final List<TransactionModel> _items = [
    TransactionModel(
      id: 'tx_001',
      type: TransactionType.refund,
      title: 'Deposit Refund',
      subtitle: '1993 Gogi',
      cardBrand: 'MasterCard',
      cardLast4: '9918',
      trailingText: '+ 30.55 \$',
      createdAt: DateTime(2026, 1, 17),
    ),
    TransactionModel(
      id: 'tx_002',
      type: TransactionType.reservation,
      title: 'Reservation Deposit',
      subtitle: '1993 Gogi · Gangnam',
      cardBrand: 'MasterCard',
      cardLast4: '9918',
      trailingText: '- 30.55 \$',
      createdAt: DateTime(2026, 1, 15),
    ),
    TransactionModel(
      id: 'tx_003',
      type: TransactionType.reservation,
      title: 'Reservation Fee',
      subtitle: 'Yumbook Service',
      cardBrand: 'MasterCard',
      cardLast4: '9918',
      trailingText: '- 20 \$',
      createdAt: DateTime(2026, 1, 15),
    ),
    TransactionModel(
      id: 'tx_004',
      type: TransactionType.reservation,
      title: 'No-show Fee',
      subtitle: 'Reservation Policy',
      cardBrand: 'MasterCard',
      cardLast4: '9918',
      trailingText: '- 30 \$',
      createdAt: DateTime(2026, 1, 15),
    ),
    TransactionModel(
      id: 'tx_005',
      type: TransactionType.failed,
      title: 'Card Authorization Failed',
      subtitle: '',
      cardBrand: 'MasterCard',
      cardLast4: '9918',
      trailingText: 'Failed',
      createdAt: DateTime(2026, 1, 15),
    ),
  ];

  List<TransactionModel> get items => List.unmodifiable(_items);

  void addTransaction(TransactionModel item) {
    _items.insert(0, item);
    notifyListeners();
  }

  void clear() {
    _items.clear();
    notifyListeners();
  }
}