import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'package:yumbook_app/models/restaurant.dart';
import 'package:yumbook_app/models/reservation_data.dart';
import 'package:yumbook_app/state/reservation_store.dart';
import 'package:yumbook_app/state/restaurant_cache.dart';

import 'package:yumbook_app/screens/reservation_edit_screen.dart';
import 'package:yumbook_app/screens/reservation_cancel_sheet.dart';

class ReservationDetailsScreen extends StatefulWidget {
  final ReservationData reservation;

  const ReservationDetailsScreen({super.key, required this.reservation});

  @override
  State<ReservationDetailsScreen> createState() =>
      _ReservationDetailsScreenState();
}

class _ReservationDetailsScreenState extends State<ReservationDetailsScreen> {
  static const _orange = Color(0xFFD45425);
  static const _border = Color(0xFFE5E5EA);
  static const _textDark = Color(0xFF383838);

  bool _handledApprovedBanner = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _handleApprovedIfNeeded();
  }

  void _handleApprovedIfNeeded() {
    if (_handledApprovedBanner) return;

    final store = ReservationStore.instance;
    final current = _currentReservation(store);
    if (current == null) return;

    final status = current.pendingChange?.status;
    if (status != ReservationChangeStatus.approved) return;

    _handledApprovedBanner = true;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Your reservation has been updated.',
            style: TextStyle(
              fontFamily: 'Pretendard',
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      );

      store.clearReservationChange(current.confirmationCode);

      if (mounted) {
        setState(() {});
      }
    });
  }

  ReservationData? _currentReservation(ReservationStore store) {
    try {
      return store.reservations.firstWhere(
        (r) => r.confirmationCode == widget.reservation.confirmationCode,
      );
    } catch (_) {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final store = ReservationStore.instance;
    final reservation = _currentReservation(store) ?? widget.reservation;

    final dateText = DateFormat('MMM d, yyyy').format(reservation.date);
    final timeText = DateFormat('h:mm a').format(reservation.time);
    final confirmation = reservation.confirmationCode;

    final pendingChange = reservation.pendingChange;
    final changeStatus = pendingChange?.status;
    final canEdit = store.canEditReservation(reservation);

    final requestedDateText = pendingChange != null
        ? DateFormat('MMM d, yyyy').format(pendingChange.requestedDate)
        : '';
    final requestedTimeText = pendingChange != null
        ? DateFormat('h:mm a').format(pendingChange.requestedTime)
        : '';

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.arrow_back_ios_new, size: 18),
                  ),
                  const Expanded(
                    child: Text(
                      'Reservations',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 16,
                        fontFamily: 'Pretendard',
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const SizedBox(width: 44),
                ],
              ),

              const SizedBox(height: 10),

              const Text(
                'Reservation details',
                style: TextStyle(
                  fontSize: 22,
                  fontFamily: 'Pretendard',
                  fontWeight: FontWeight.w700,
                  color: _textDark,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Confirmation: $confirmation',
                style: const TextStyle(
                  fontSize: 12,
                  fontFamily: 'Pretendard',
                  fontWeight: FontWeight.w400,
                  color: Color(0xFF6E6E6E),
                ),
              ),

              const SizedBox(height: 14),

              if (changeStatus == ReservationChangeStatus.pending)
                _StatusBox(
                  icon: Icons.schedule_outlined,
                  bg: const Color(0xFFFFF4E8),
                  iconColor: const Color(0xFFBF6A02),
                  textColor: const Color(0xFF8A5300),
                  title: 'Awaiting restaurant confirmation',
                  body:
                      'Your change request has been submitted. Your original reservation is still active until the restaurant confirms the update.',
                ),

              if (changeStatus == ReservationChangeStatus.rejected)
                _StatusBox(
                  icon: Icons.error_outline,
                  bg: const Color(0xFFFCE9E7),
                  iconColor: const Color(0xFFBF331B),
                  textColor: const Color(0xFFBF331B),
                  title: 'Change request not confirmed',
                  body:
                      'The restaurant could not confirm your requested change. Your original reservation remains active.',
                ),

              if (changeStatus == ReservationChangeStatus.pending ||
                  changeStatus == ReservationChangeStatus.rejected)
                const SizedBox(height: 12),

              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  border: Border.all(color: _border),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: _DetailsTextBlock(
                        title: reservation.restaurantName,
                        line1:
                            '${reservation.partySize} guests for ${reservation.guestName}',
                        line2: reservation.seatType ?? '—',
                        line3: '$dateText at $timeText',
                      ),
                    ),
                    const SizedBox(width: 10),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: _ReservationThumbnail(
                        restaurantId: reservation.restaurantId,
                        size: 78,
                      ),
                    ),
                  ],
                ),
              ),

              if (changeStatus == ReservationChangeStatus.pending ||
                  changeStatus == ReservationChangeStatus.rejected)
                const SizedBox(height: 12),

              if (changeStatus == ReservationChangeStatus.pending ||
                  changeStatus == ReservationChangeStatus.rejected)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFAFAFA),
                    border: Border.all(color: _border),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        changeStatus == ReservationChangeStatus.pending
                            ? 'Requested change'
                            : 'Requested change (not confirmed)',
                        style: const TextStyle(
                          fontSize: 14,
                          fontFamily: 'Pretendard',
                          fontWeight: FontWeight.w700,
                          color: _textDark,
                        ),
                      ),
                      const SizedBox(height: 10),
                      _requestRow('Date', requestedDateText),
                      const SizedBox(height: 8),
                      _requestRow('Time', requestedTimeText),
                      const SizedBox(height: 8),
                      _requestRow(
                        'Party Size',
                        '${pendingChange?.requestedPartySize ?? reservation.partySize}',
                      ),
                    ],
                  ),
                ),

              const SizedBox(height: 14),

              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  border: Border.all(color: _border),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Cancellation policy',
                      style: TextStyle(
                        fontSize: 14,
                        fontFamily: 'Pretendard',
                        fontWeight: FontWeight.w600,
                        color: _textDark,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Your reservation can be canceled at any time before the scheduled reservation time.\n'
                      'If your plans change, please cancel at least 24 hours in advance so the restaurant can plan accordingly.',
                      style: TextStyle(
                        fontSize: 13,
                        fontFamily: 'Pretendard',
                        fontWeight: FontWeight.w400,
                        height: 1.35,
                        color: Color(0xFF6E6E6E),
                      ),
                    ),
                  ],
                ),
              ),

              if (!canEdit) ...[
                const SizedBox(height: 12),
                const _StatusBox(
                  icon: Icons.lock_clock_outlined,
                  bg: Color(0xFFFCE9E7),
                  iconColor: Color(0xFFBF331B),
                  textColor: Color(0xFFBF331B),
                  title: 'Editing unavailable',
                  body:
                      'Reservations cannot be changed within 24 hours of the scheduled time.',
                ),
              ],

              const Spacer(),

              Row(
                children: [
                  Expanded(
                    child: _PillButton(
                      label: 'Cancel',
                      bg: const Color(0xFFE5E5EA),
                      fg: const Color(0xFF6E6E6E),
                      onTap: () async {
                        await ReservationCancelSheet.show(
                          context,
                          reservation: reservation,
                          payment: const PaymentBreakdown(
                            serviceFeePerGuest: 20,
                            depositPerGuest: 30,
                            processingRate: 0.04,
                            restaurantFailedToConfirm: false,
                            freeCancelDays: 30,
                            refundRateAfterWindow: 1.0,
                            refundRateWithinWindow: 0.0,
                            noShowRefundRate: 0.0,
                          ),
                          onConfirmCancel: (reason) async {
                            final messenger = ScaffoldMessenger.of(context);
                            try {
                              await ReservationStore.instance.cancelReservation(
                                reservation,
                                reason: reason,
                              );
                              if (!context.mounted) return;
                              Navigator.pop(context);
                            } catch (error) {
                              messenger.showSnackBar(
                                SnackBar(
                                  content: Text('Failed to cancel: $error'),
                                ),
                              );
                            }
                          },
                        );
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _PillButton(
                      label: changeStatus == ReservationChangeStatus.pending
                          ? 'Pending'
                          : 'Edit',
                      bg: (canEdit &&
                              changeStatus != ReservationChangeStatus.pending)
                          ? _orange
                          : const Color(0xFFBDBDBD),
                      fg: Colors.white,
                      onTap: (!canEdit ||
                              changeStatus == ReservationChangeStatus.pending)
                          ? null
                          : () async {
                              await Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => ReservationEditScreen(
                                    reservation: reservation,
                                  ),
                                ),
                              );
                              if (mounted) {
                                setState(() {});
                              }
                            },
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _requestRow(String label, String value) {
    return Row(
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            fontFamily: 'Pretendard',
            fontWeight: FontWeight.w600,
            color: _textDark,
          ),
        ),
        const Spacer(),
        Text(
          value,
          style: const TextStyle(
            fontSize: 12,
            fontFamily: 'Pretendard',
            fontWeight: FontWeight.w600,
            color: Color(0xFF6E6E6E),
          ),
        ),
      ],
    );
  }
}

/// 예약 식당 썸네일. 백엔드에서 식당 이미지를 조회해 표시(없으면 플레이스홀더).
class _ReservationThumbnail extends StatelessWidget {
  final String? restaurantId;
  final double size;

  const _ReservationThumbnail({required this.restaurantId, required this.size});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Restaurant?>(
      future: RestaurantCache.instance.getById(restaurantId),
      builder: (context, snapshot) {
        final url = snapshot.data?.imagePath ?? '';
        return Container(
          width: size,
          height: size,
          color: const Color(0xFFD5EAF7),
          child: url.isNotEmpty
              ? Image.network(
                  url,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                )
              : const SizedBox.shrink(),
        );
      },
    );
  }
}

class _DetailsTextBlock extends StatelessWidget {
  final String title;
  final String line1;
  final String line2;
  final String line3;

  const _DetailsTextBlock({
    required this.title,
    required this.line1,
    required this.line2,
    required this.line3,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            color: Color(0xFF383838),
            fontSize: 18,
            fontFamily: 'Pretendard',
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 10),
        _iconLine(Icons.group_outlined, line1),
        const SizedBox(height: 8),
        _iconLine(Icons.chair_alt_outlined, line2),
        const SizedBox(height: 8),
        _iconLine(Icons.access_time, line3),
      ],
    );
  }

  Widget _iconLine(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 18, color: const Color(0xFF303030)),
        const SizedBox(width: 7),
        Expanded(
          child: Text(
            text,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Color(0xFF303030),
              fontSize: 15,
              fontFamily: 'Pretendard',
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }
}

class _StatusBox extends StatelessWidget {
  final IconData icon;
  final Color bg;
  final Color iconColor;
  final Color textColor;
  final String title;
  final String body;

  const _StatusBox({
    required this.icon,
    required this.bg,
    required this.iconColor,
    required this.textColor,
    required this.title,
    required this.body,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: iconColor),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 12,
                    fontFamily: 'Pretendard',
                    fontWeight: FontWeight.w700,
                    color: textColor,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  body,
                  style: TextStyle(
                    fontSize: 12,
                    fontFamily: 'Pretendard',
                    fontWeight: FontWeight.w500,
                    height: 1.35,
                    color: textColor,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PillButton extends StatelessWidget {
  final String label;
  final Color bg;
  final Color fg;
  final VoidCallback? onTap;

  const _PillButton({
    required this.label,
    required this.bg,
    required this.fg,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Opacity(
        opacity: onTap == null ? 0.7 : 1,
        child: Container(
          height: 44,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(100),
          ),
          child: Text(
            label,
            style: TextStyle(
              color: fg,
              fontSize: 14,
              fontFamily: 'Pretendard',
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }
}