import 'package:flutter/foundation.dart';
import 'package:yumbook_app/models/reservation_data.dart';

class NotifyRequest {
  final String restaurantId;
  final String restaurantName;
  final DateTime date; // 날짜(yyyy-mm-dd 의미)
  final DateTime time; // 시간만 쓰지만 DateTime으로 통일
  final int partySize;

  NotifyRequest({
    required this.restaurantId,
    required this.restaurantName,
    required this.date,
    required this.time,
    required this.partySize,
  });
}

class ReservationStore extends ChangeNotifier {
  ReservationStore._();
  static final ReservationStore instance = ReservationStore._();

  final List<ReservationData> _reservations = [];
  final List<NotifyRequest> _notifyRequests = [];

  List<ReservationData> get reservations => List.unmodifiable(_reservations);
  List<NotifyRequest> get notifyRequests => List.unmodifiable(_notifyRequests);

  /// ✅ 디버그용: Upcoming 테스트 예약 1개 생성
  void addMockReservation() {
    final now = DateTime.now();

    final mock = ReservationData(
      restaurantName: 'Cafe Um (Mock)',
      restaurantId: 'cafe_um_mock',
      date: DateTime(now.year, now.month, now.day + 3),
      time: DateTime(now.year, now.month, now.day, 19, 0),
      partySize: 2,
      guestName: 'Youri',
      seatType: 'Table',
      confirmationCode: 'YB-${now.millisecondsSinceEpoch}',
      paymentSnapshot: null,
      pendingChange: null,
    );

    addReservation(mock);
  }

  void addReservation(ReservationData data) {
    _reservations.insert(0, data);
    notifyListeners();
  }

  void removeReservationByConfirmation(String confirmationCode) {
    _reservations.removeWhere((r) => r.confirmationCode == confirmationCode);
    notifyListeners();
  }

  void addNotifyRequest(NotifyRequest req) {
    _notifyRequests.insert(0, req);
    notifyListeners();
  }

  void removeNotifyRequest(NotifyRequest req) {
    _notifyRequests.remove(req);
    notifyListeners();
  }

  /// ✅ 예약 취소: confirmationCode 기준으로 삭제
  void cancelReservation(ReservationData reservation) {
    removeReservationByConfirmation(reservation.confirmationCode);
  }

  /// ✅ 예약 변경 가능 여부
  /// 예약 시각 기준 24시간 이상 남아 있어야 변경 가능
  bool canEditReservation(ReservationData reservation) {
    final hoursLeft =
        _reservationDateTime(reservation).difference(DateTime.now()).inHours;
    return hoursLeft >= 24;
  }

  /// ✅ 기존 방식 유지: 즉시 예약 변경
  /// 지금은 호환용으로 남겨두고, 실제 UX는 requestReservationChange 사용 권장
  void updateReservation(
    ReservationData reservation, {
    DateTime? newDate,
    DateTime? newTime,
    int? newPartySize,
  }) {
    final idx = _reservations.indexWhere(
      (r) => r.confirmationCode == reservation.confirmationCode,
    );
    if (idx == -1) return;

    final current = _reservations[idx];

    if (!canEditReservation(current)) return;

    final updated = current.copyWith(
      date: newDate,
      time: newTime,
      partySize: newPartySize,
    );

    _reservations[idx] = updated;
    notifyListeners();
  }

  /// ✅ 권장 방식: 변경 요청 저장
  /// 실제 예약값은 바로 바꾸지 않고 pendingChange에 저장
  void requestReservationChange(
    ReservationData reservation, {
    required DateTime newDate,
    required DateTime newTime,
    required int newPartySize,
  }) {
    final idx = _reservations.indexWhere(
      (r) => r.confirmationCode == reservation.confirmationCode,
    );
    if (idx == -1) return;

    final current = _reservations[idx];

    if (!canEditReservation(current)) return;

    _reservations[idx] = current.copyWith(
      pendingChange: ReservationChangeRequest(
        requestedDate: newDate,
        requestedTime: newTime,
        requestedPartySize: newPartySize,
        requestedAt: DateTime.now(),
        status: ReservationChangeStatus.pending,
      ),
    );

    notifyListeners();
  }

  /// ✅ 식당 승인 시: 실제 예약값 반영
  void approveReservationChange(String confirmationCode) {
    final idx = _reservations.indexWhere(
      (r) => r.confirmationCode == confirmationCode,
    );
    if (idx == -1) return;

    final current = _reservations[idx];
    final pending = current.pendingChange;
    if (pending == null) return;

    _reservations[idx] = current.copyWith(
      date: pending.requestedDate,
      time: pending.requestedTime,
      partySize: pending.requestedPartySize,
      pendingChange: pending.copyWith(
        status: ReservationChangeStatus.approved,
      ),
    );

    notifyListeners();
  }

  /// ✅ 식당 거절 시: 예약 원본은 유지, 상태만 rejected 처리
  void rejectReservationChange(String confirmationCode) {
    final idx = _reservations.indexWhere(
      (r) => r.confirmationCode == confirmationCode,
    );
    if (idx == -1) return;

    final current = _reservations[idx];
    final pending = current.pendingChange;
    if (pending == null) return;

    _reservations[idx] = current.copyWith(
      pendingChange: pending.copyWith(
        status: ReservationChangeStatus.rejected,
      ),
    );

    notifyListeners();
  }

  /// ✅ 상태 정리용
  /// approved/rejected 문구를 보여준 뒤 pending 정보를 지우고 싶을 때 사용
  void clearReservationChange(String confirmationCode) {
    final idx = _reservations.indexWhere(
      (r) => r.confirmationCode == confirmationCode,
    );
    if (idx == -1) return;

    final current = _reservations[idx];

    _reservations[idx] = current.copyWith(
      clearPendingChange: true,
    );

    notifyListeners();
  }

  // 편의: Upcoming/Past 분리
  List<ReservationData> upcoming(DateTime now) {
    return _reservations
        .where((r) => _reservationDateTime(r).isAfter(now))
        .toList()
      ..sort(
        (a, b) => _reservationDateTime(a).compareTo(_reservationDateTime(b)),
      );
  }

  List<ReservationData> past(DateTime now) {
    return _reservations
        .where((r) => !_reservationDateTime(r).isAfter(now))
        .toList()
      ..sort(
        (a, b) => _reservationDateTime(b).compareTo(_reservationDateTime(a)),
      );
  }

  DateTime reservationDateTime(ReservationData r) {
    return DateTime(
      r.date.year,
      r.date.month,
      r.date.day,
      r.time.hour,
      r.time.minute,
    );
  }

  DateTime _reservationDateTime(ReservationData r) {
    return DateTime(
      r.date.year,
      r.date.month,
      r.date.day,
      r.time.hour,
      r.time.minute,
    );
  }
}