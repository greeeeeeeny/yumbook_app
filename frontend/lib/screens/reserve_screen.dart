import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'package:yumbook_app/themes/app_spacing.dart';
import 'package:yumbook_app/models/restaurant.dart';
import 'package:yumbook_app/models/reservation_data.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:yumbook_app/state/reservation_store.dart';
import 'package:yumbook_app/state/restaurant_cache.dart';

import 'package:yumbook_app/screens/root_shell.dart';
import 'package:yumbook_app/screens/reservation_details_screen.dart';

enum _ReserveTab { upcoming, past, notify }

class ReserveScreen extends StatefulWidget {
  const ReserveScreen({super.key});

  @override
  State<ReserveScreen> createState() => _ReserveScreenState();
}

class _ReserveScreenState extends State<ReserveScreen> {
  _ReserveTab _tab = _ReserveTab.upcoming;

  bool _loadedReservations = false;

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadReservationsFromServer();
    });
  }

  Future<void> _loadReservationsFromServer() async {
    if (_loadedReservations) return;
    _loadedReservations = true;

    if (Supabase.instance.client.auth.currentSession == null) return;

    try {
      await ReservationStore.instance.loadReservations();
    } catch (e) {
      debugPrint('Failed to load reservations from Django: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final store = ReservationStore.instance;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: AnimatedBuilder(
          animation: store,
          builder: (context, _) {
            final now = DateTime.now();
            final upcoming = store.upcoming(now);
            final past = store.past(now);
            final notify = store.notifyRequests;

            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 15),
              child: Column(
                children: [
                  const SizedBox(height: AppSpacing.xl),
                  const Text(
                    'Reservations',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.black,
                      fontSize: 18,
                      fontFamily: 'Pretendard',
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Segmented control
                  _SegmentedTabs(
                    value: _tab,
                    onChanged: (v) => setState(() => _tab = v),
                  ),

                  const SizedBox(height: 14),

                  Expanded(
                    child: Builder(
                      builder: (_) {
                        switch (_tab) {
                          case _ReserveTab.upcoming:
                            if (store.isLoading) {
                              return const Center(
                                child: CircularProgressIndicator(),
                              );
                            }
                            if (upcoming.isEmpty) {
                              return _EmptyUpcoming(
                                onSearchNow: () {
                                  rootShellKey.currentState?.goToTab(
                                    1,
                                  ); // Explore가 index 1 이니까
                                },
                              );
                            }
                            return _ReservationList(
                              items: upcoming,
                              onTapCard: (r) {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => ReservationDetailsScreen(
                                      reservation: r,
                                    ),
                                  ),
                                );
                              },
                            );

                          case _ReserveTab.past:
                            if (past.isEmpty) {
                              return _SimpleEmpty(
                                icon: Icons.history,
                                title: 'No past bookings',
                                body:
                                    'Your completed reservations will appear here.',
                              );
                            }
                            return _ReservationList(
                              items: past,
                              onTapCard: (_) {},
                            );

                          case _ReserveTab.notify:
                            if (notify.isEmpty) {
                              return _SimpleEmpty(
                                icon: Icons.notifications_none,
                                title: 'No notifications',
                                body:
                                    'When you request a notify for a time slot, it will show up here.',
                              );
                            }
                            return _NotifyList(items: notify);
                        }
                      },
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

class _SegmentedTabs extends StatelessWidget {
  final _ReserveTab value;
  final ValueChanged<_ReserveTab> onChanged;

  const _SegmentedTabs({required this.value, required this.onChanged});

  static const _bg = Color(0x1E767680);

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 36,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: _bg,
        borderRadius: BorderRadius.circular(100),
      ),
      child: Row(
        children: [
          Expanded(child: _segBtn('Upcoming', _ReserveTab.upcoming)),
          Expanded(child: _segBtn('Past', _ReserveTab.past)),
          Expanded(child: _segBtn('Notify', _ReserveTab.notify)),
        ],
      ),
    );
  }

  Widget _segBtn(String label, _ReserveTab tab) {
    final selected = value == tab;
    return GestureDetector(
      onTap: () => onChanged(tab),
      behavior: HitTestBehavior.opaque,
      child: Container(
        alignment: Alignment.center,
        decoration: selected
            ? BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x0F000000),
                    blurRadius: 20,
                    offset: Offset(0, 2),
                  ),
                ],
              )
            : null,
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: Colors.black,
            fontSize: 14,
            fontFamily: 'SF Pro',
            fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
            height: 1.29,
            letterSpacing: -0.08,
          ),
        ),
      ),
    );
  }
}

class _EmptyUpcoming extends StatelessWidget {
  final VoidCallback onSearchNow;

  const _EmptyUpcoming({required this.onSearchNow});

  static const _orange = Color(0xFFD45425);

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.only(top: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.calendar_today_outlined,
              size: 22,
              color: Colors.black54,
            ),
            const SizedBox(height: 12),
            const Text(
              'No upcoming bookings',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.black,
                fontSize: 18,
                fontFamily: 'Pretendard',
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 10),
            const Text(
              'Let YumBook guide your next dining experience.\nSearch restaurants and events near you.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.black,
                fontSize: 14,
                fontFamily: 'Pretendard',
                fontWeight: FontWeight.w400,
                height: 1.35,
              ),
            ),
            const SizedBox(height: 14),
            Center(
              child: IntrinsicWidth(
                child: GestureDetector(
                  onTap: onSearchNow,
                  child: Container(
                    height: 36, // 피그마 느낌이면 34~40 사이 추천
                    padding: const EdgeInsets.symmetric(horizontal: 28),
                    decoration: BoxDecoration(
                      color: _orange,
                      borderRadius: BorderRadius.circular(18),
                    ),
                    alignment: Alignment.center,
                    child: const Text(
                      'Search now',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontFamily: 'Pretendard',
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ReservationList extends StatelessWidget {
  final List<ReservationData> items;
  final ValueChanged<ReservationData> onTapCard;

  const _ReservationList({required this.items, required this.onTapCard});

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.only(top: 2, bottom: 16),
      itemCount: items.length,
      separatorBuilder: (context, index) => const SizedBox(height: 12),
      itemBuilder: (context, i) {
        final r = items[i];
        return _ReservationCard(
          reservation: r,
          onTap: () => onTapCard(r),
        );
      },
    );
  }
}

class _ReservationCard extends StatelessWidget {
  final ReservationData reservation;
  final VoidCallback onTap;

  const _ReservationCard({
    required this.reservation,
    required this.onTap,
  });

  static const _border = Color(0xFFE5E5EA);

  String _dateTimeText() {
    final d = DateFormat('MMM d, yyyy').format(reservation.date);
    final t = DateFormat('h:mm a').format(reservation.time);
    return '$d at $t';
  }

  @override
  Widget build(BuildContext context) {
    // 식당 정보(위치/이미지)는 백엔드에서 조회한다(mock 제거).
    return FutureBuilder<Restaurant?>(
      future: RestaurantCache.instance.getById(reservation.restaurantId),
      builder: (context, snapshot) {
        final restaurant = snapshot.data;
        final location = (restaurant?.location.trim().isNotEmpty ?? false)
            ? restaurant!.location
            : '—';
        final imageUrl = restaurant?.imagePath ?? '';

        return GestureDetector(
          onTap: onTap,
          behavior: HitTestBehavior.opaque,
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: Border.all(color: _border, width: 1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: _CardTextBlock(
                    title: reservation.restaurantName,
                    line1:
                        '${reservation.partySize} guests for ${reservation.guestName}',
                    line2: _dateTimeText(),
                    line3: location,
                  ),
                ),
                const SizedBox(width: 10),
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    width: 89,
                    height: 96,
                    color: const Color(0xFFD5EAF7),
                    child: imageUrl.isNotEmpty
                        ? Image.network(
                            imageUrl,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) =>
                                const SizedBox.shrink(),
                          )
                        : const SizedBox.shrink(),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _CardTextBlock extends StatelessWidget {
  final String title;
  final String line1;
  final String line2;
  final String line3;

  const _CardTextBlock({
    required this.title,
    required this.line1,
    required this.line2,
    required this.line3,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
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
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 10),
        _iconLine(Icons.group_outlined, line1),
        const SizedBox(height: 8),
        _iconLine(Icons.access_time, line2),
        const SizedBox(height: 8),
        _iconLine(Icons.location_on_outlined, line3),
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

class _NotifyList extends StatelessWidget {
  final List<NotifyRequest> items;

  const _NotifyList({required this.items});

  static const _border = Color(0xFFE5E5EA);

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.only(top: 2, bottom: 16),
      itemCount: items.length,
      separatorBuilder: (context, index) => const SizedBox(height: 12),
      itemBuilder: (context, i) {
        final n = items[i];

        final d = DateFormat('MMM d, yyyy').format(n.date);
        final t = DateFormat('h:mm a').format(n.time);

        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            border: Border.all(color: _border, width: 1),
            borderRadius: BorderRadius.circular(12),
            color: Colors.white,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                n.restaurantName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Color(0xFF383838),
                  fontSize: 18,
                  fontFamily: 'Pretendard',
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  const Icon(
                    Icons.notifications_none,
                    size: 18,
                    color: Color(0xFF303030),
                  ),
                  const SizedBox(width: 7),
                  Expanded(
                    child: Text(
                      'Notify request • $d • $t',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Color(0xFF303030),
                        fontSize: 16,
                        fontFamily: 'Pretendard',
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              const Text(
                'We’ll notify you if a table opens up.',
                style: TextStyle(
                  color: Color(0xFF6E6E6E),
                  fontSize: 13,
                  fontFamily: 'Pretendard',
                  fontWeight: FontWeight.w400,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _SimpleEmpty extends StatelessWidget {
  final IconData icon;
  final String title;
  final String body;

  const _SimpleEmpty({
    required this.icon,
    required this.title,
    required this.body,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.only(top: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 26, color: Colors.black45),
            const SizedBox(height: 12),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.black,
                fontSize: 18,
                fontFamily: 'Pretendard',
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              body,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.black,
                fontSize: 14,
                fontFamily: 'Pretendard',
                fontWeight: FontWeight.w400,
                height: 1.35,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
