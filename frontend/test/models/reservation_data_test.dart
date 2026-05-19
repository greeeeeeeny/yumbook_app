import 'package:flutter_test/flutter_test.dart';
import 'package:yumbook_app/models/reservation_data.dart';

void main() {
  group('ReservationData', () {
    final base = ReservationData(
      restaurantName: '온바디',
      date: DateTime(2026, 5, 19),
      time: DateTime(2026, 5, 19, 19, 30),
      partySize: 2,
      guestName: '홍길동',
    );

    test('기본 confirmationCode는 Yumbook-B-00001', () {
      expect(base.confirmationCode, 'Yumbook-B-00001');
    });

    test('formattedDate / formattedTime 출력 형식', () {
      expect(base.formattedDate, 'May 19, 2026');
      expect(base.formattedTime, '7:30 PM');
    });

    test('copyWith는 partySize만 바꿔도 나머지를 보존', () {
      final updated = base.copyWith(partySize: 4);

      expect(updated.partySize, 4);
      expect(updated.restaurantName, '온바디');
      expect(updated.guestName, '홍길동');
    });

    test('clearPendingChange=true 면 pendingChange를 null로', () {
      final withChange = base.copyWith(
        pendingChange: ReservationChangeRequest(
          requestedDate: DateTime(2026, 6, 1),
          requestedTime: DateTime(2026, 6, 1, 20, 0),
          requestedPartySize: 3,
          requestedAt: DateTime(2026, 5, 20),
          status: ReservationChangeStatus.pending,
        ),
      );
      expect(withChange.pendingChange, isNotNull);

      final cleared = withChange.copyWith(clearPendingChange: true);
      expect(cleared.pendingChange, isNull);
    });
  });

  group('ReservationChangeRequest', () {
    test('copyWith는 status만 변경 가능', () {
      final r = ReservationChangeRequest(
        requestedDate: DateTime(2026, 6, 1),
        requestedTime: DateTime(2026, 6, 1, 20, 0),
        requestedPartySize: 3,
        requestedAt: DateTime(2026, 5, 20),
        status: ReservationChangeStatus.pending,
      );

      final approved = r.copyWith(status: ReservationChangeStatus.approved);

      expect(approved.status, ReservationChangeStatus.approved);
      expect(approved.requestedPartySize, 3);
    });
  });
}
