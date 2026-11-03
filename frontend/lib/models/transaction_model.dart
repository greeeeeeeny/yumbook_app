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

  // 백엔드 추가 필드(표시는 trailingText 사용; 분석/정렬용으로 보관).
  final double? amount;
  final String status;

  const TransactionModel({
    required this.id,
    required this.type,
    required this.title,
    required this.subtitle,
    required this.cardBrand,
    required this.cardLast4,
    required this.trailingText,
    required this.createdAt,
    this.amount,
    this.status = '',
  });

  /// 백엔드(`/api/transactions/`) 응답 → 모델.
  /// type 별칭(reservation/refund/failed/payment)을 UI enum으로 매핑한다.
  factory TransactionModel.fromJson(Map<String, dynamic> json) {
    return TransactionModel(
      id: json['id'].toString(),
      type: _typeFromString(
        (json['type'] ?? json['transaction_type']) as String?,
      ),
      title: json['title'] as String? ?? '',
      subtitle: json['subtitle'] as String? ?? json['description'] as String? ?? '',
      cardBrand: json['card_brand'] as String? ?? '',
      cardLast4: json['card_last4'] as String? ?? '',
      trailingText: json['trailing_text'] as String? ?? '',
      createdAt: _dateTimeFromJson(json['created_at'] as String?),
      amount: _toDouble(json['amount']),
      status: json['status'] as String? ?? '',
    );
  }

  static TransactionType _typeFromString(String? value) {
    switch (value) {
      case 'refund':
        return TransactionType.refund;
      case 'failed':
        return TransactionType.failed;
      // 'reservation', 'payment', null 등은 기본 reservation 으로 처리.
      default:
        return TransactionType.reservation;
    }
  }

  static double? _toDouble(Object? value) {
    if (value == null) return null;
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value);
    return null;
  }

  static DateTime _dateTimeFromJson(String? value) {
    if (value == null || value.isEmpty) {
      return DateTime.fromMillisecondsSinceEpoch(0);
    }
    return DateTime.tryParse(value) ?? DateTime.fromMillisecondsSinceEpoch(0);
  }
}
