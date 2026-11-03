import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:yumbook_app/models/reservation_data.dart';
import 'package:yumbook_app/services/django_reservation_api.dart';

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

/// 예약 스토어. 목록 조회/생성 및 생명주기(취소/변경요청/승인/거절)를
/// 모두 백엔드(`/api/reservations/`)로 위임한다. 인메모리 변경 로직은 없다.
class ReservationStore extends ChangeNotifier {
  ReservationStore._();
  static final ReservationStore instance = ReservationStore._();

  final List<ReservationData> _reservations = [];
  final List<NotifyRequest> _notifyRequests = [];
  final DjangoReservationApi _api = DjangoReservationApi();
  bool _isLoading = false;
  bool _isMutating = false;
  Object? _lastError;

  List<ReservationData> get reservations => List.unmodifiable(_reservations);
  List<NotifyRequest> get notifyRequests => List.unmodifiable(_notifyRequests);
  bool get isLoading => _isLoading;
  bool get isMutating => _isMutating;
  Object? get lastError => _lastError;

  Future<void> loadReservations() async {
    final token = _currentAccessToken();
    if (token == null) {
      throw StateError(
        'No Supabase session — sign in before loading reservations.',
      );
    }

    _isLoading = true;
    _lastError = null;
    notifyListeners();

    try {
      final loaded = await _api.fetchReservations(accessToken: token);
      _reservations
        ..clear()
        ..addAll(loaded);
    } catch (error) {
      _lastError = error;
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void addReservation(ReservationData data) {
    _reservations.insert(0, data);
    notifyListeners();
  }

  Future<ReservationData> createReservation(ReservationData data) async {
    final token = _requireToken('create a reservation');
    final saved = await _api.createReservation(
      reservation: data,
      accessToken: token,
    );
    addReservation(saved);
    return saved;
  }

  // ----- 생명주기 (백엔드 API) -----

  /// 예약 취소. POST /api/reservations/{id}/cancel/
  Future<void> cancelReservation(
    ReservationData reservation, {
    String reason = '',
  }) async {
    final token = _requireToken('cancel a reservation');
    final id = _requireId(reservation);

    await _runMutation(() async {
      final updated = await _api.cancelReservation(
        id: id,
        reason: reason,
        accessToken: token,
      );
      _replace(updated);
    });
  }

  /// 변경 요청 생성. POST /api/reservations/{id}/request-change/
  Future<void> requestReservationChange(
    ReservationData reservation, {
    required DateTime newDate,
    required DateTime newTime,
    required int newPartySize,
  }) async {
    final token = _requireToken('request a reservation change');
    final id = _requireId(reservation);

    await _runMutation(() async {
      final updated = await _api.requestChange(
        id: id,
        date: newDate,
        time: newTime,
        partySize: newPartySize,
        accessToken: token,
      );
      _replace(updated);
    });
  }

  /// 변경 승인(식당/관리자). POST /api/reservations/{id}/approve-change/
  Future<void> approveReservationChange(ReservationData reservation) async {
    final token = _requireToken('approve a change');
    final id = _requireId(reservation);

    await _runMutation(() async {
      final updated = await _api.approveChange(id: id, accessToken: token);
      _replace(updated);
    });
  }

  /// 변경 거절(식당/관리자). POST /api/reservations/{id}/reject-change/
  Future<void> rejectReservationChange(ReservationData reservation) async {
    final token = _requireToken('reject a change');
    final id = _requireId(reservation);

    await _runMutation(() async {
      final updated = await _api.rejectChange(id: id, accessToken: token);
      _replace(updated);
    });
  }

  /// 예약 시각 기준 24시간 이상 남아 있어야 변경 가능(서버에서도 동일하게 강제).
  bool canEditReservation(ReservationData reservation) {
    final hoursLeft = _reservationDateTime(
      reservation,
    ).difference(DateTime.now()).inHours;
    return hoursLeft >= 24;
  }

  /// 승인/거절 배너를 노출한 뒤 화면에서 pending 표시를 숨기기 위한 로컬 정리(서버 무관).
  void clearReservationChange(String confirmationCode) {
    final idx = _reservations.indexWhere(
      (r) => r.confirmationCode == confirmationCode,
    );
    if (idx == -1) return;
    _reservations[idx] = _reservations[idx].copyWith(clearPendingChange: true);
    notifyListeners();
  }

  // ----- Notify (waitlist) — 로컬 전용(백엔드 미구현) -----

  void addNotifyRequest(NotifyRequest req) {
    _notifyRequests.insert(0, req);
    notifyListeners();
  }

  void removeNotifyRequest(NotifyRequest req) {
    _notifyRequests.remove(req);
    notifyListeners();
  }

  // ----- 목록 분리 (취소/거절 제외) -----

  List<ReservationData> upcoming(DateTime now) {
    return _reservations
        .where((r) => !r.isCancelled && _reservationDateTime(r).isAfter(now))
        .toList()
      ..sort(
        (a, b) => _reservationDateTime(a).compareTo(_reservationDateTime(b)),
      );
  }

  List<ReservationData> past(DateTime now) {
    return _reservations
        .where((r) => !r.isCancelled && !_reservationDateTime(r).isAfter(now))
        .toList()
      ..sort(
        (a, b) => _reservationDateTime(b).compareTo(_reservationDateTime(a)),
      );
  }

  DateTime reservationDateTime(ReservationData r) => _reservationDateTime(r);

  // ----- helpers -----

  Future<void> _runMutation(Future<void> Function() action) async {
    _isMutating = true;
    _lastError = null;
    notifyListeners();
    try {
      await action();
    } catch (error) {
      _lastError = error;
      rethrow;
    } finally {
      _isMutating = false;
      notifyListeners();
    }
  }

  /// 서버가 돌려준 최신 예약으로 로컬 목록을 갱신한다(id 우선, 없으면 confirmationCode).
  void _replace(ReservationData updated) {
    int idx = -1;
    if (updated.id != null) {
      idx = _reservations.indexWhere((r) => r.id == updated.id);
    }
    if (idx == -1) {
      idx = _reservations.indexWhere(
        (r) => r.confirmationCode == updated.confirmationCode,
      );
    }
    if (idx == -1) {
      _reservations.insert(0, updated);
    } else {
      _reservations[idx] = updated;
    }
  }

  String _requireToken(String action) {
    final token = _currentAccessToken();
    if (token == null) {
      throw StateError('No Supabase session — sign in to $action.');
    }
    return token;
  }

  int _requireId(ReservationData reservation) {
    final id = reservation.id;
    if (id == null) {
      throw StateError('Reservation id is missing; reload reservations first.');
    }
    return id;
  }

  String? _currentAccessToken() {
    return Supabase.instance.client.auth.currentSession?.accessToken;
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
