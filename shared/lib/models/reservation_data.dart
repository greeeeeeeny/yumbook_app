import 'package:intl/intl.dart';
import 'package:yumbook_app/models/reservation_payment_snapshot.dart';

enum ReservationChangeStatus {
  none,
  pending,
  approved,
  rejected,
}

class ReservationChangeRequest {
  final DateTime requestedDate;
  final DateTime requestedTime;
  final int requestedPartySize;
  final DateTime requestedAt;
  final ReservationChangeStatus status;

  const ReservationChangeRequest({
    required this.requestedDate,
    required this.requestedTime,
    required this.requestedPartySize,
    required this.requestedAt,
    required this.status,
  });

  ReservationChangeRequest copyWith({
    DateTime? requestedDate,
    DateTime? requestedTime,
    int? requestedPartySize,
    DateTime? requestedAt,
    ReservationChangeStatus? status,
  }) {
    return ReservationChangeRequest(
      requestedDate: requestedDate ?? this.requestedDate,
      requestedTime: requestedTime ?? this.requestedTime,
      requestedPartySize: requestedPartySize ?? this.requestedPartySize,
      requestedAt: requestedAt ?? this.requestedAt,
      status: status ?? this.status,
    );
  }
}

class ReservationData {
  final DateTime date;
  final DateTime time;
  final int partySize;

  final String restaurantName;
  final String? restaurantId;

  final String guestName;
  final String? seatType;
  final String confirmationCode;

  final String? paymentMethodId;
  final String? paymentMethodLabel;

  final ReservationPaymentSnapshot? paymentSnapshot;

  /// ✅ 변경 요청 상태
  final ReservationChangeRequest? pendingChange;

  const ReservationData({
    required this.restaurantName,
    this.restaurantId,
    required this.date,
    required this.time,
    required this.partySize,
    required this.guestName,
    this.seatType,
    this.confirmationCode = 'Yumbook-B-00001',
    this.paymentMethodId,
    this.paymentMethodLabel,
    this.paymentSnapshot,
    this.pendingChange,
  });

  ReservationData copyWith({
    DateTime? date,
    DateTime? time,
    int? partySize,
    String? restaurantName,
    String? restaurantId,
    String? guestName,
    String? seatType,
    String? confirmationCode,
    ReservationPaymentSnapshot? paymentSnapshot,
    String? paymentMethodId,
    String? paymentMethodLabel,

    /// ✅ 추가
    ReservationChangeRequest? pendingChange,

    /// ✅ pendingChange를 null로 지우고 싶을 때 구분용
    bool clearPendingChange = false,
  }) {
    return ReservationData(
      restaurantName: restaurantName ?? this.restaurantName,
      restaurantId: restaurantId ?? this.restaurantId,
      date: date ?? this.date,
      time: time ?? this.time,
      partySize: partySize ?? this.partySize,
      guestName: guestName ?? this.guestName,
      seatType: seatType ?? this.seatType,
      confirmationCode: confirmationCode ?? this.confirmationCode,
      paymentMethodId: paymentMethodId ?? this.paymentMethodId,
      paymentMethodLabel: paymentMethodLabel ?? this.paymentMethodLabel,
      paymentSnapshot: paymentSnapshot ?? this.paymentSnapshot,
      pendingChange: clearPendingChange
          ? null
          : (pendingChange ?? this.pendingChange),
    );
  }
}

extension ReservationDataFormat on ReservationData {
  String get formattedDate => DateFormat('MMM d, yyyy').format(date);
  String get formattedTime => DateFormat('h:mm a').format(time);
}