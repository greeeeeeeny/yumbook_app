enum TransactionType {
  reservation,
  refund,
  failed,
}

class TransactionModel {
  final String id;
  final TransactionType type;
  final String title;
  final String subtitle;
  final String cardBrand;
  final String cardLast4;
  final String trailingText;
  final DateTime createdAt;

  const TransactionModel({
    required this.id,
    required this.type,
    required this.title,
    required this.subtitle,
    required this.cardBrand,
    required this.cardLast4,
    required this.trailingText,
    required this.createdAt,
  });
}