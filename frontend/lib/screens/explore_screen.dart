import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';

import 'package:yumbook_app/models/restaurant.dart';
import 'package:yumbook_app/state/explore_store.dart';

/// 1) 가격 레벨
enum PriceLevel { any, w1, w2, w3, w4 }


extension PriceLevelX on PriceLevel {
  String get label {
    switch (this) {
      case PriceLevel.any:
        return '₩';
      case PriceLevel.w1:
        return '₩';
      case PriceLevel.w2:
        return '₩₩';
      case PriceLevel.w3:
        return '₩₩₩';
      case PriceLevel.w4:
        return '₩₩₩₩';
    }
  }
}

/// 2) 필터 상태(일단 UI용)
class ExploreFilters {
  DateTime date;
  TimeOfDay time;
  int partySize;
  PriceLevel price;
  String cuisine; // "All", "Italian"... (간단히 String)

  ExploreFilters({
    required this.date,
    required this.time,
    required this.partySize,
    required this.price,
    required this.cuisine,
  });

  ExploreFilters copyWith({
    DateTime? date,
    TimeOfDay? time,
    int? partySize,
    PriceLevel? price,
    String? cuisine,
  }) {
    return ExploreFilters(
      date: date ?? this.date,
      time: time ?? this.time,
      partySize: partySize ?? this.partySize,
      price: price ?? this.price,
      cuisine: cuisine ?? this.cuisine,
    );
  }
}

class ExploreScreen extends StatefulWidget {
  const ExploreScreen({super.key});

  @override
  State<ExploreScreen> createState() => _ExploreScreenState();
}

class _ExploreScreenState extends State<ExploreScreen> {
  String _locationLabel = 'Seoul';
  late ExploreFilters filters;
  GoogleMapController? _controller;

  LatLng _current = const LatLng(37.5665, 126.9780); // fallback: 서울시청
  bool _hasUserLocation = false;
  String _lastQuery = '';

  Set<Marker> _markers = {};
  final GlobalKey _cuisineChipKey = GlobalKey(); // ✅ 추가 (팝업메뉴 위치 계산용)
  
  BitmapDescriptor? _restaurantPin;

  Future<void> _preparePinsAndMarkers() async {
  _restaurantPin ??= await BitmapDescriptor.asset(
    const ImageConfiguration(size: Size(96, 96)),
    'assets/icons/restaurant_pin.png', // ✅ 실제 파일명(소문자)로 통일!
  );

  await _runSearch();
}

  /// 가격 티어 → 백엔드 price 파라미터(1~4). any면 null.
  int? _priceLevelValue(PriceLevel level) {
    switch (level) {
      case PriceLevel.any:
        return null;
      case PriceLevel.w1:
        return 1;
      case PriceLevel.w2:
        return 2;
      case PriceLevel.w3:
        return 3;
      case PriceLevel.w4:
        return 4;
    }
  }

  /// 현재 필터 + (선택적으로) 지도 영역으로 백엔드 검색을 실행한다.
  Future<void> _runSearch({bool useMapArea = false, String? query}) async {
    if (query != null) _lastQuery = query;

    String? bbox;
    if (useMapArea && _controller != null) {
      final b = await _controller!.getVisibleRegion();
      bbox =
          '${b.southwest.longitude},${b.southwest.latitude},'
          '${b.northeast.longitude},${b.northeast.latitude}';
    }

    await ExploreStore.instance.search(
      query: _lastQuery,
      cuisine: filters.cuisine == 'Cuisines' ? null : filters.cuisine,
      priceLevel: _priceLevelValue(filters.price),
      bbox: bbox,
    );

    _setMarkersFromResults();
  }

  // Cuisine 드롭다운(1번 이미지 오른쪽 메뉴 느낌)
  final List<String> cuisines = const [
  'All',
  'Korean',
  'Italian',
  'Japanese',
  'Chinese',
  'Mexican',
  'Spanish',
  'American',
  'BBQ',
  'Steakhouse',
  'European',
  'Asian',
  'Brunch',
  'Cafe',
  'Bar',
  'Vegan',
  'Fine Dining',
  'Fusion',
];

  // 검색 바텀시트에 보여줄 더미 리스트(나중에 "내 주변" 정렬로 교체)
  final List<_RestaurantListItem> nearbyMock = const [
    _RestaurantListItem(title: '1993 Gogi', subtitle: 'Reservation', imageUrl: null),
    _RestaurantListItem(title: 'Cafe Um', subtitle: 'Reservation', imageUrl: null),
    _RestaurantListItem(title: 'Rikak Museum Cafe', subtitle: 'Reservation', imageUrl: null),
  ];

  @override
  void initState() {
    super.initState();

    final now = DateTime.now();
    filters = ExploreFilters(
      date: now.add(const Duration(days: 1)), // Tomorrow 기본
      time: const TimeOfDay(hour: 19, minute: 0), // 7:00 PM
      partySize: 2,
      price: PriceLevel.any,
      cuisine: 'Cuisines',
    );

    _initLocation();
    _preparePinsAndMarkers();
  }

// ✅ 검색 결과(lat/lng 있는 식당)로 마커 생성
void _setMarkersFromResults() {
  if (_restaurantPin == null) return;

  final markers = <Marker>{};

  for (final r in ExploreStore.instance.results) {
    if (r.lat == null || r.lng == null) continue;

    markers.add(
      Marker(
        markerId: MarkerId(r.id),
        position: LatLng(r.lat!, r.lng!),
        icon: _restaurantPin!,
        anchor: const Offset(0.5, 1.0), // 핀 끝이 좌표로
        infoWindow: InfoWindow(
          title: r.name,
          snippet: r.rawCategory ?? r.location,
        ),
      ),
    );
  }

  if (mounted) setState(() => _markers = markers);
}

  String _dateLabel(DateTime d) {
    // UI용 간단 라벨 (Tomorrow / 날짜)
    final today = DateTime.now();
    final t0 = DateTime(today.year, today.month, today.day);
    final t1 = DateTime(d.year, d.month, d.day);
    final diff = t1.difference(t0).inDays;

    if (diff == 1) return 'Tomorrow';
    if (diff == 0) return 'Today';
    return '${d.month}/${d.day}';
  }

  String _timeLabel(TimeOfDay t) {
    final hour = t.hourOfPeriod == 0 ? 12 : t.hourOfPeriod;
    final mm = t.minute.toString().padLeft(2, '0');
    final ap = t.period == DayPeriod.am ? 'AM' : 'PM';
    return '$hour:$mm $ap';
  }

  Future<void> _openDateTimeGuestSheet() async {
    final result = await showModalBottomSheet<ExploreFilters>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
      ),
      builder: (_) => _DateTimeGuestSheet(initial: filters),
    );

    if (result != null) {
      setState(() => filters = result);
      _runSearch();
    }
  }

  Future<void> _openCuisineSheet() async {
    final selected = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
      ),
      builder: (_) => _CuisineSheet(
        items: cuisines,
        selected: filters.cuisine == 'Cuisines' ? 'All' : filters.cuisine,
      ),
    );

    if (selected != null) {
      setState(() => filters = filters.copyWith(cuisine: selected == 'All' ? 'Cuisines' : selected));
      _runSearch();
    }
  }

  Future<void> _openCuisineMenu() async {
    final keyCtx = _cuisineChipKey.currentContext;
    if (keyCtx == null) return;

    final box = keyCtx.findRenderObject() as RenderBox;
    final overlay = Overlay.of(context).context.findRenderObject() as RenderBox;

    final pos = box.localToGlobal(Offset.zero, ancestor: overlay);
    final rect = RelativeRect.fromRect(
      Rect.fromLTWH(pos.dx, pos.dy, box.size.width, box.size.height),
      Offset.zero & overlay.size,
    );

    final selected = await showMenu<String>(
      context: context,
      position: rect,
      color: Colors.white,
      elevation: 10,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      items: cuisines.map((c) {
        return PopupMenuItem<String>(
          value: c,
          child: Text(
            c,
            style: const TextStyle(
              fontFamily: 'Pretendard',
              fontSize: 14,
              fontWeight: FontWeight.w400,
              color: Color(0xFF303030),
            ),
          ),
        );
      }).toList(),
    );

    if (selected != null) {
      setState(() {
        filters = filters.copyWith(
          cuisine: selected == 'All' ? 'Cuisines' : selected,
        );
      });
      _runSearch();
    }
  }


  Future<void> _openPriceSheet() async {
    final selected = await showModalBottomSheet<PriceLevel>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
      ),
      builder: (_) => _PriceSheet(selected: filters.price),
    );

    if (selected != null) {
      setState(() => filters = filters.copyWith(price: selected));
      _runSearch();
    }
  }

  Future<void> _openSearchSheet() async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
      ),
      builder: (_) => _SearchSheet(
        initialAreaLabel: 'Seoul',
        popular: const ['Italian'],
        recentlyViewed: nearbyMock,
        onPickQuery: (query) {
          Navigator.pop(context);
          _runSearch(query: query);
        },
        onPickCurrentMapArea: () {
          Navigator.pop(context);
          _runSearch(useMapArea: true);
        },
      ),
    );
  }

  Future<void> _initLocation() async {
  final enabled = await Geolocator.isLocationServiceEnabled();
  if (!enabled) return;

  var perm = await Geolocator.checkPermission();
  if (perm == LocationPermission.denied) {
    perm = await Geolocator.requestPermission();
  }
  if (perm == LocationPermission.denied || perm == LocationPermission.deniedForever) return;

  final pos = await Geolocator.getCurrentPosition(
    desiredAccuracy: LocationAccuracy.high,
  );

  setState(() {
    _current = LatLng(pos.latitude, pos.longitude);
    _hasUserLocation = true;
  });

  // ✅ 지도 컨트롤러가 이미 준비돼 있으면 바로 내 위치로 한번 이동
  if (_controller != null) {
    _controller!.animateCamera(
      CameraUpdate.newLatLngZoom(_current, 14),
    );
  }
}

  void _resetFilters() {
    final now = DateTime.now();
    setState(() {
      filters = ExploreFilters(
        date: now.add(const Duration(days: 1)),
        time: const TimeOfDay(hour: 19, minute: 0),
        partySize: 2,
        price: PriceLevel.any,
        cuisine: 'Cuisines',
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,

      body: Stack(
        children: [
              /// ===== 지도 영역 =====
              Positioned.fill(
                child: GoogleMap(
                  initialCameraPosition: CameraPosition(
                    target: _current, // 아래 B에서 추가할 _current
                    zoom: 13,
                  ),
                  onMapCreated: (c) {
                    _controller = c;
                    // 위치 받아온 뒤 바로 내 위치로 한번 이동하고 싶으면:
                    if (_hasUserLocation) {
                      _controller?.animateCamera(
                        CameraUpdate.newLatLngZoom(_current, 14),
                      );
                    }
                  },
                  myLocationEnabled: true,          // ✅ 내 위치 점
                  myLocationButtonEnabled: false,   // ✅ 커스텀 버튼 쓸거라 false
                  zoomControlsEnabled: false,
                  mapToolbarEnabled: false,
                  markers: _markers,                // (선택) 마커 쓸 경우
                ),
              ),

          /// Search this area 버튼
          Positioned(
            top: 52,
            left: 100,
            right: 100,
              child: _PillButton(
                text: 'Search this area',
                onTap: () => _runSearch(useMapArea: true),
              ),
            ),

          /// 현재 위치 버튼(오른쪽 위)
          Positioned(
            top: 52,
            right: 16,
            child: GestureDetector(
              onTap: () async {
                  if (_controller == null) return;

                  if (!_hasUserLocation) {
                    await _initLocation();
                  }
                  if (!_hasUserLocation) return;

                  await _controller!.animateCamera(
                    CameraUpdate.newLatLngZoom(_current, 15),
                  );
                },
              child: Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(21),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x19000000),
                      blurRadius: 8,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
                child: const Icon(Icons.near_me, color: Color(0xFF383838)),
              ),
            ),
          ),

          /// ===== 하단 필터 바텀시트 UI 영역(1번 이미지 카드 느낌) =====
          /// ✅ 드래그 가능한 하단 패널
          Positioned.fill(
            child: DraggableScrollableSheet(
              initialChildSize: 0.38, // 처음 보이는 높이(화면 비율)
              minChildSize: 0.20,     // 최소로 내렸을 때
              maxChildSize: 0.92,     // 최대로 올렸을 때
              snap: true,             // ✅ 드래그 후 스냅(선택)
              snapSizes: const [0.20, 0.38, 0.92], // ✅ 원하는 구간으로 "딱" 붙게
              builder: (context, scrollCtrl) {
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                    boxShadow: [
                      BoxShadow(
                        color: Color(0x19000000),
                        blurRadius: 12,
                        offset: Offset(0, -2),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      // drag handle
                      Container(
                        width: 36,
                        height: 4,
                        decoration: BoxDecoration(
                          color: const Color(0xFFD1D1D6),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      const SizedBox(height: 12),

                      /// Search + Seoul
                      GestureDetector(
                        onTap: _openSearchSheet,
                        child: Container(
                          height: 48,
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          decoration: BoxDecoration(
                            border: Border.all(color: const Color(0xFFE5E5EA)),
                            borderRadius: BorderRadius.circular(24),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.search, color: Color(0xFF6E6E6E)),
                              const SizedBox(width: 8),
                              const Text(
                                'Search',
                                style: TextStyle(
                                  fontFamily: 'Pretendard',
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                  color: Color(0xFF6E6E6E),
                                ),
                              ),
                              const Spacer(),
                              const VerticalDivider(width: 20, thickness: 1, color: Color(0xFFE5E5EA)),
                              Text(
                                _locationLabel,
                                style: const TextStyle(
                                  fontFamily: 'Pretendard',
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                  color: Color(0xFF383838),
                                ),
                              ),
                              const SizedBox(width: 4),
                              const Icon(Icons.chevron_right, color: Color(0xFF6E6E6E)),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 12),

                      /// 필터 칩
                      SizedBox(
                        height: 40,
                        child: ListView(
                          scrollDirection: Axis.horizontal,
                          children: [
                            _FilterChipButton(
                              text: '${_dateLabel(filters.date)}  |  ${_timeLabel(filters.time)}  |  ${filters.partySize} guests',
                              onTap: _openDateTimeGuestSheet,
                            ),
                            const SizedBox(width: 12),
                            _FilterChipButton(
                              text: filters.price == PriceLevel.any ? '₩' : filters.price.label,
                              onTap: _openPriceSheet,
                            ),
                            const SizedBox(width: 12),
                            _FilterChipButton(
                              key: _cuisineChipKey,
                              text: filters.cuisine,
                              onTap: _openCuisineMenu,
                              trailing: Icons.expand_more,
                            ),
                          ],
                        ),
                      ),

                  const SizedBox(height: 16),

                  /// ✅ 결과 영역: DraggableScrollableSheet의 scrollCtrl에 연결
                  Expanded(
                    child: AnimatedBuilder(
                      animation: ExploreStore.instance,
                      builder: (context, _) {
                        final store = ExploreStore.instance;

                        if (store.isLoading) {
                          return ListView(
                            controller: scrollCtrl,
                            children: const [
                              SizedBox(height: 80),
                              Center(child: CircularProgressIndicator()),
                            ],
                          );
                        }

                        if (store.hasError) {
                          return ListView(
                            controller: scrollCtrl,
                            children: [
                              const SizedBox(height: 60),
                              const Center(
                                child: Text(
                                  "Couldn't load restaurants.\nPlease check your connection and try again.",
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontFamily: 'Pretendard',
                                    fontSize: 16,
                                    fontWeight: FontWeight.w500,
                                    color: Color(0xFF6E6E6E),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 18),
                              Center(
                                child: TextButton(
                                  onPressed: () => _runSearch(),
                                  child: const Text(
                                    'Retry',
                                    style: TextStyle(
                                      fontFamily: 'Pretendard',
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                      color: Color(0xFFD45425),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          );
                        }

                        final results = store.results;
                        if (results.isEmpty) {
                          return ListView(
                            controller: scrollCtrl,
                            children: [
                              const SizedBox(height: 60),
                              const Center(
                                child: Text(
                                  'No results found\nTry adjusting your search, filters, or zoom out.',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontFamily: 'Pretendard',
                                    fontSize: 16,
                                    fontWeight: FontWeight.w500,
                                    color: Color(0xFF6E6E6E),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 18),
                              Center(
                                child: TextButton(
                                  onPressed: () {
                                    _resetFilters();
                                    _runSearch();
                                  },
                                  child: const Text(
                                    'Reset',
                                    style: TextStyle(
                                      fontFamily: 'Pretendard',
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                      color: Color(0xFFD45425),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 120),
                            ],
                          );
                        }

                        return ListView.separated(
                          controller: scrollCtrl,
                          itemCount: results.length,
                          separatorBuilder: (_, __) =>
                              const Divider(height: 1, color: Color(0xFFE5E5E5)),
                          itemBuilder: (context, i) =>
                              _ExploreResultRow(restaurant: results[i]),
                        );
                      },
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    ],
   ),
   );
  }
}

/// ====== 공용 위젯들 ======

class _PillButton extends StatelessWidget {
  final String text;
  final VoidCallback onTap;

  const _PillButton({required this.text, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(24),
      elevation: 2,
      shadowColor: const Color(0x19000000),
      child: InkWell(
        borderRadius: BorderRadius.circular(24),
        onTap: onTap,
        child: Container(
          height: 48,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          alignment: Alignment.center,
          child: Text(
            text,
            style: const TextStyle(
              fontFamily: 'Pretendard',
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: Color(0xFF383838),
            ),
          ),
        ),
      ),
    );
  }
}

class _FilterChipButton extends StatelessWidget {
  final String text;
  final VoidCallback onTap;
  final IconData? trailing;

  const _FilterChipButton({
    super.key,
    required this.text,
    required this.onTap,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(24),
      child: Container(
        height: 40,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          border: Border.all(color: const Color(0xFFE5E5EA)),
          borderRadius: BorderRadius.circular(24),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              text,
              style: const TextStyle(
                fontFamily: 'Pretendard',
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: Color(0xFF303030),
              ),
            ),
            if (trailing != null) ...[
              const SizedBox(width: 4),
              Icon(trailing, size: 18, color: const Color(0xFF6E6E6E)),
            ],
          ],
        ),
      ),
    );
  }
}

/// ====== (2번 이미지) 날짜/시간/인원 바텀시트 ======
/// 실제 캘린더 위젯(table_calendar)로 교체 가능.
/// 지금은 DatePicker + TimePicker로 구현해둠 (가장 안전/간단)
class _DateTimeGuestSheet extends StatefulWidget {
  final ExploreFilters initial;

  const _DateTimeGuestSheet({required this.initial});

  @override
  State<_DateTimeGuestSheet> createState() => _DateTimeGuestSheetState();
}

class _DateTimeGuestSheetState extends State<_DateTimeGuestSheet> {
  late DateTime date;
  late TimeOfDay time;
  late int party;

  @override
  void initState() {
    super.initState();
    date = widget.initial.date;
    time = widget.initial.time;
    party = widget.initial.partySize;
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: date,
      firstDate: DateTime.now().subtract(const Duration(days: 0)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
          // DatePicker만 화이트 테마 적용
    builder: (context, child) {
      final base = Theme.of(context);

      return Theme(
        data: base.copyWith(
          // Dialog 배경
          dialogBackgroundColor: Colors.white,

          // (Material3) DatePicker 전용 테마
          datePickerTheme: const DatePickerThemeData(
            backgroundColor: Colors.white, // 전체 배경
            surfaceTintColor: Colors.transparent, // M3 틴트 제거(색 섞임 방지)
          ),

          // 버튼/선택색 등
          colorScheme: base.colorScheme.copyWith(
            surface: Colors.white,           // 달력 표면
            onSurface: Color(0xFF303030),    // 기본 글자색
            primary: Color(0xFFD45425),      // 선택/강조 색 (원하면 변경)
            onPrimary: Colors.white,         // 선택된 날짜 글자색
          ),
        ),
        child: child!,
      );
    },
    );
    if (picked != null) setState(() => date = picked);
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: time,
    );
    if (picked != null) setState(() => time = picked);
  }

  String _timeLabel(TimeOfDay t) {
    final hour = t.hourOfPeriod == 0 ? 12 : t.hourOfPeriod;
    final mm = t.minute.toString().padLeft(2, '0');
    final ap = t.period == DayPeriod.am ? 'AM' : 'PM';
    return '$hour:$mm $ap';
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).viewInsets.bottom;

    return Padding(
      padding: EdgeInsets.only(bottom: bottom),
      child: SafeArea(
        child: SizedBox(
          height: 618,
          child: Column(
            children: [
              const SizedBox(height: 12),
              // 상단 헤더 (Cancel / Search / Reset 느낌)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: const Text(
                        'Cancel',
                        style: TextStyle(
                          fontFamily: 'Pretendard',
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF6E6E6E),
                        ),
                      ),
                    ),
                    const Spacer(),
                    const Text(
                      'Search',
                      style: TextStyle(
                        fontFamily: 'Pretendard',
                        fontSize: 24,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF383838),
                      ),
                    ),
                    const Spacer(),
                    GestureDetector(
                      onTap: () {
                        setState(() {
                          final now = DateTime.now();
                          date = now.add(const Duration(days: 1));
                          time = const TimeOfDay(hour: 19, minute: 0);
                          party = 2;
                        });
                      },
                      child: const Text(
                        'Reset',
                        style: TextStyle(
                          fontFamily: 'Pretendard',
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF6E6E6E),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // Date
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: InkWell(
                  onTap: _pickDate,
                  borderRadius: BorderRadius.circular(16),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      border: Border.all(color: const Color(0xFFD9D9D9)),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      children: [
                        const Text(
                          'Date',
                          style: TextStyle(
                            fontFamily: 'Pretendard',
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF383838),
                          ),
                        ),
                        const Spacer(),
                        Text(
                          '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}',
                          style: const TextStyle(
                            fontFamily: 'Pretendard',
                            fontSize: 16,
                            color: Color(0xFF6E6E6E),
                          ),
                        ),
                        const SizedBox(width: 6),
                        const Icon(Icons.calendar_month, color: Color(0xFF6E6E6E)),
                      ],
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Time
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    const Text(
                      'Time',
                      style: TextStyle(
                        fontFamily: 'Pretendard',
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF383838),
                      ),
                    ),
                    const Spacer(),
                    InkWell(
                      onTap: _pickTime,
                      borderRadius: BorderRadius.circular(8),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: const Color(0xFFE5E5E5),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          _timeLabel(time),
                          style: const TextStyle(
                            fontFamily: 'Pretendard',
                            fontSize: 16,
                            color: Color(0xFF383838),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // Party Size
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    const Text(
                      'Party Size',
                      style: TextStyle(
                        fontFamily: 'Pretendard',
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF383838),
                      ),
                    ),
                    const Spacer(),
                    Container(
                      width: 140,
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                      decoration: BoxDecoration(
                        border: Border.all(color: const Color(0xFFE5E5E5)),
                        borderRadius: BorderRadius.circular(15),
                      ),
                      child: Row(
                        children: [
                          IconButton(
                            onPressed: party > 1 ? () => setState(() => party--) : null,
                            icon: const Icon(Icons.remove),
                          ),
                          Expanded(
                            child: Text(
                              '$party',
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                fontFamily: 'Pretendard',
                                fontSize: 16,
                                color: Color(0xFF383838),
                              ),
                            ),
                          ),
                          IconButton(
                            onPressed: () => setState(() => party++),
                            icon: const Icon(Icons.add),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const Spacer(),

              // Update 버튼
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: SizedBox(
                  width: double.infinity,
                  height: 44,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFD45425),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      elevation: 0,
                    ),
                    onPressed: () {
                      Navigator.pop(
                        context,
                        widget.initial.copyWith(
                          date: date,
                          time: time,
                          partySize: party,
                        ),
                      );
                    },
                    child: const Text(
                      'Update',
                      style: TextStyle(
                        fontFamily: 'Pretendard',
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
    );
  }
}

/// ====== Cuisine 선택 바텀시트 ======
class _CuisineSheet extends StatelessWidget {
  final List<String> items;
  final String selected;

  const _CuisineSheet({required this.items, required this.selected});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: items.map((c) {
          final isSelected = c == selected;
          return ListTile(
            title: Text(
              c,
              style: TextStyle(
                fontFamily: 'Pretendard',
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                color: const Color(0xFF383838),
              ),
            ),
            trailing: isSelected ? const Icon(Icons.check) : null,
            onTap: () => Navigator.pop(context, c),
          );
        }).toList(),
      ),
    );
  }
}

/// ====== Price 선택 바텀시트 (₩~₩₩₩₩) ======
class _PriceSheet extends StatelessWidget {
  final PriceLevel selected;

  const _PriceSheet({required this.selected});

  @override
  Widget build(BuildContext context) {
    final items = const [PriceLevel.any, PriceLevel.w1, PriceLevel.w2, PriceLevel.w3, PriceLevel.w4];

    return SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: items.map((p) {
          final isSelected = p == selected;
          final label = p == PriceLevel.any ? 'Any' : p.label;

          return ListTile(
            title: Text(
              label,
              style: TextStyle(
                fontFamily: 'Pretendard',
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                color: const Color(0xFF383838),
              ),
            ),
            trailing: isSelected ? const Icon(Icons.check) : null,
            onTap: () => Navigator.pop(context, p),
          );
        }).toList(),
      ),
    );
  }
}

/// ====== (3번 이미지) 검색 바텀시트: 드래그로 확장되는 리스트 ======
class _SearchSheet extends StatefulWidget {
  final String initialAreaLabel;
  final List<String> popular;
  final List<_RestaurantListItem> recentlyViewed;
  final ValueChanged<String> onPickQuery;
  final VoidCallback onPickCurrentMapArea;

  const _SearchSheet({
    required this.initialAreaLabel,
    required this.popular,
    required this.recentlyViewed,
    required this.onPickQuery,
    required this.onPickCurrentMapArea,
  });

  @override
  State<_SearchSheet> createState() => _SearchSheetState();
}

class _SearchSheetState extends State<_SearchSheet> {
  final TextEditingController ctrl = TextEditingController();

  @override
  void dispose() {
    ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).viewInsets.bottom;

    return Padding(
      padding: EdgeInsets.only(bottom: bottom),
      child: SafeArea(
        child: DraggableScrollableSheet(
          initialChildSize: 0.72,
          minChildSize: 0.50,
          maxChildSize: 0.95,
          expand: false,
          builder: (context, scrollCtrl) {
            return Column(
              children: [
                const SizedBox(height: 12),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    children: [
                      GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: const Text(
                          'Cancel',
                          style: TextStyle(
                            fontFamily: 'Pretendard',
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF6E6E6E),
                          ),
                        ),
                      ),
                      const Spacer(),
                      const Text(
                        'Search',
                        style: TextStyle(
                          fontFamily: 'Pretendard',
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF6E6E6E),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),

                Expanded(
                  child: ListView(
                    controller: scrollCtrl,
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Column(
                          children: [
                            // Find a business or cuisine
                            Container(
                              height: 40,
                              decoration: BoxDecoration(
                                border: Border.all(color: const Color(0xFFE5E5EA)),
                                borderRadius: BorderRadius.circular(24),
                              ),
                              child: TextField(
                                controller: ctrl,
                                textInputAction: TextInputAction.search,
                                onSubmitted: (v) {
                                  final q = v.trim();
                                  if (q.isNotEmpty) widget.onPickQuery(q);
                                },
                                decoration: const InputDecoration(
                                  border: InputBorder.none,
                                  prefixIcon: Icon(Icons.search, color: Color(0xFF6E6E6E)),
                                  hintText: 'Find a business or cuisine',
                                  hintStyle: TextStyle(
                                    fontFamily: 'Pretendard',
                                    fontSize: 16,
                                    fontWeight: FontWeight.w500,
                                    color: Color(0xFF6E6E6E),
                                  ),
                                  contentPadding: EdgeInsets.symmetric(vertical: 10),
                                ),
                              ),
                            ),
                            const SizedBox(height: 10),

                            // Current map area
                            InkWell(
                              onTap: widget.onPickCurrentMapArea,
                              borderRadius: BorderRadius.circular(24),
                              child: Container(
                                height: 40,
                                padding: const EdgeInsets.symmetric(horizontal: 12),
                                decoration: BoxDecoration(
                                  border: Border.all(color: const Color(0xFFE5E5EA)),
                                  borderRadius: BorderRadius.circular(24),
                                ),
                                child: Row(
                                  children: const [
                                    Icon(Icons.my_location, color: Color(0xFF6E6E6E)),
                                    SizedBox(width: 8),
                                    Text(
                                      'Current map area',
                                      style: TextStyle(
                                        fontFamily: 'Pretendard',
                                        fontSize: 16,
                                        fontWeight: FontWeight.w500,
                                        color: Color(0xFF6E6E6E),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 14),
                      Container(height: 8, color: const Color(0xFFF2F2F7)),
                      const SizedBox(height: 14),

                      // Popular searches
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Popular searches',
                              style: TextStyle(
                                fontFamily: 'Pretendard',
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                color: Color(0xFF6E6E6E),
                              ),
                            ),
                            const SizedBox(height: 12),
                            ...widget.popular.map((p) {
                              return InkWell(
                                onTap: () => widget.onPickQuery(p),
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(vertical: 8),
                                  child: Row(
                                    children: [
                                      const Icon(Icons.search, color: Color(0xFF6E6E6E)),
                                      const SizedBox(width: 8),
                                      Text(
                                        p,
                                        style: const TextStyle(
                                          fontFamily: 'Pretendard',
                                          fontSize: 18,
                                          fontWeight: FontWeight.w500,
                                          color: Color(0xFF383838),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            }),
                          ],
                        ),
                      ),

                      const SizedBox(height: 10),
                      const Divider(height: 1, color: Color(0xFFE5E5E5)),
                      const SizedBox(height: 14),

                      // Recently viewed
                      const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 20),
                        child: Text(
                          'Recently viewed',
                          style: TextStyle(
                            fontFamily: 'Pretendard',
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: Color(0xFF6E6E6E),
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),

                      ...widget.recentlyViewed.map((r) => _RestaurantRow(
                            item: r,
                            onTap: () => widget.onPickQuery(r.title),
                          )),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _RestaurantListItem {
  final String title;
  final String subtitle;
  final String? imageUrl;

  const _RestaurantListItem({
    required this.title,
    required this.subtitle,
    required this.imageUrl,
  });
}

/// Explore 결과 한 줄(백엔드 Restaurant 기반).
class _ExploreResultRow extends StatelessWidget {
  final Restaurant restaurant;

  const _ExploreResultRow({required this.restaurant});

  @override
  Widget build(BuildContext context) {
    final subtitleParts = <String>[
      if ((restaurant.rawCategory ?? '').isNotEmpty) restaurant.rawCategory!,
      if (restaurant.location.isNotEmpty) restaurant.location,
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 12),
      child: Row(
        children: [
          Container(
            width: 64,
            height: 64,
            clipBehavior: Clip.antiAlias,
            decoration: BoxDecoration(
              color: const Color(0xFFD5EAF7),
              borderRadius: BorderRadius.circular(12),
            ),
            child: restaurant.imagePath.isNotEmpty
                ? Image.network(
                    restaurant.imagePath,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => const Icon(
                      Icons.restaurant_rounded,
                      color: Colors.white,
                    ),
                  )
                : const Icon(Icons.restaurant_rounded, color: Colors.white),
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  restaurant.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontFamily: 'Pretendard',
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF383838),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  subtitleParts.join(' · '),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontFamily: 'Pretendard',
                    fontSize: 16,
                    fontWeight: FontWeight.w400,
                    color: Color(0xFF6E6E6E),
                  ),
                ),
              ],
            ),
          ),
          if (restaurant.rating > 0) ...[
            const Icon(Icons.star_rounded, size: 18, color: Color(0xFFD45425)),
            const SizedBox(width: 2),
            Text(
              restaurant.rating.toStringAsFixed(1),
              style: const TextStyle(
                fontFamily: 'Pretendard',
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Color(0xFF383838),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _RestaurantRow extends StatelessWidget {
  final _RestaurantListItem item;
  final VoidCallback onTap;

  const _RestaurantRow({required this.item, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                Container(
                  width: 88,
                  height: 88,
                  decoration: BoxDecoration(
                    color: const Color(0xFFD5EAF7),
                    borderRadius: BorderRadius.circular(12),
                    image: item.imageUrl == null
                        ? null
                        : DecorationImage(image: NetworkImage(item.imageUrl!), fit: BoxFit.cover),
                  ),
                ),
                const SizedBox(width: 15),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.title,
                        style: const TextStyle(
                          fontFamily: 'Pretendard',
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF383838),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        item.subtitle,
                        style: const TextStyle(
                          fontFamily: 'Pretendard',
                          fontSize: 16,
                          fontWeight: FontWeight.w400,
                          color: Color(0xFF6E6E6E),
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right, color: Color(0xFFB3B3B3)),
              ],
            ),
          ),
        ),
        const Divider(height: 1, color: Color(0xFFE5E5E5)),
      ],
    );
  }
}