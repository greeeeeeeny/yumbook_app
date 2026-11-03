import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:yumbook_app/models/food_record.dart';
import 'package:yumbook_app/models/region.dart';
import 'package:yumbook_app/models/restaurant.dart';
import 'package:yumbook_app/screens/food_records/food_record_detail_screen.dart';
import 'package:yumbook_app/screens/food_records/food_record_list_screen.dart';
import 'package:yumbook_app/services/django_restaurant_api.dart';
import 'package:yumbook_app/state/food_record_store.dart';
import 'detail_screen.dart';

class AHomeCategory extends StatefulWidget {
  const AHomeCategory({super.key});

  @override
  State<AHomeCategory> createState() => _AHomeCategoryState();
}

class _AHomeCategoryState extends State<AHomeCategory> {
  static const Color _textDark = Color(0xFF303030);
  static const Color _textMuted = Color(0xFF7A7A7A);
  static const Color _divider = Color(0xFFBDBDBD);

  /// 백엔드에서 받아온 활성 지역 목록(탭 소스). 모의 데이터는 없다.
  List<Region> _regions = const [];

  /// 지역 목록 로딩 상태(최초 로드 시 탭 영역 스피너 노출용).
  bool _isLoadingRegions = false;

  /// 지역 목록 로드 실패 여부(에러 상태 노출용). 성공 시 null.
  Object? _regionsError;

  /// 현재 선택된 지역 슬러그. 기본값은 첫 번째 지역의 슬러그.
  /// 지역 목록 로드 전에는 null.
  String? selectedRegion;

  /// 백엔드에서 받아온, 현재 지역에 해당하는 식당 목록.
  List<Restaurant> _visibleRestaurants = const [];

  /// 지역 데이터 로딩 상태(탭 전환/최초 로드 시 스피너 노출용).
  bool _isLoadingRestaurants = false;

  /// 마지막 로드 실패 여부(에러 상태 노출용). 성공 시 null.
  Object? _loadError;

  /// 빠른 탭 연타 시 늦게 끝난 이전 요청이 결과를 덮어쓰지 않도록 하는 토큰.
  int _filterToken = 0;

  final DjangoRestaurantApi _restaurantApi = DjangoRestaurantApi();
  final ScrollController _tabScrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadPublicRecords();
      // 지역 탭을 백엔드에서 로드한 뒤, 첫 지역의 식당을 로드한다.
      _loadRegions();
    });
  }

  /// 활성 지역 목록(`/api/regions/`)을 로드해 탭 소스를 구성한다.
  /// 성공 시 첫 번째 지역을 기본 선택으로 두고 해당 식당을 로드한다.
  /// 모의 데이터 폴백은 없다.
  Future<void> _loadRegions() async {
    setState(() {
      _isLoadingRegions = true;
      _regionsError = null;
    });

    try {
      final accessToken =
          Supabase.instance.client.auth.currentSession?.accessToken;
      final regions = await _restaurantApi.fetchRegions(
        accessToken: accessToken,
      );
      if (!mounted) return;

      final firstSlug = regions.isNotEmpty ? regions.first.slug : null;
      setState(() {
        _regions = regions;
        selectedRegion = firstSlug;
        _isLoadingRegions = false;
      });

      // 지역이 하나라도 있으면 첫 지역 식당을 로드한다.
      if (firstSlug != null) {
        _loadRegion(firstSlug);
      } else {
        // 지역이 없으면 빈 식당 목록 상태로 둔다.
        setState(() {
          _visibleRestaurants = const [];
          _isLoadingRestaurants = false;
          _loadError = null;
        });
      }
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _regionsError = error;
        _regions = const [];
        _isLoadingRegions = false;
      });
    }
  }

  /// 선택된 지역으로 백엔드(`/api/restaurants/?region=...`)에서 식당을 로드한다.
  /// 로딩 → 성공/빈 결과 → 에러 상태를 모두 처리한다. 모의 데이터 폴백은 없다.
  Future<void> _loadRegion(String? region) async {
    final token = ++_filterToken;
    setState(() {
      _isLoadingRestaurants = true;
      _loadError = null;
    });

    try {
      final accessToken =
          Supabase.instance.client.auth.currentSession?.accessToken;
      final results = await _restaurantApi.searchRestaurants(
        region: region,
        accessToken: accessToken,
      );
      // 위젯이 사라졌거나 더 최신 요청이 시작됐다면 이 결과는 버린다.
      if (!mounted || token != _filterToken) return;
      setState(() {
        _visibleRestaurants = results;
        _isLoadingRestaurants = false;
      });
    } catch (error) {
      if (!mounted || token != _filterToken) return;
      setState(() {
        _loadError = error;
        _visibleRestaurants = const [];
        _isLoadingRestaurants = false;
      });
    }
  }

  Future<void> _loadPublicRecords() async {
    try {
      await FoodRecordStore.instance.loadPublicFeed();
    } catch (_) {
      // 홈에서는 실패해도 조용히 숨김 — 카드들로 본 흐름은 유지
    }
  }

  void _openAllPublicRecords() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const FoodRecordListScreen(
          mine: false,
          title: 'Recent Records',
        ),
      ),
    );
  }

  Future<void> _openRecordDetail(FoodRecord record) async {
    final deleted = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => FoodRecordDetailScreen(initialRecord: record),
      ),
    );
    if (deleted == true) {
      _loadPublicRecords();
    }
  }

  /// 지역과 무관하게 항상 상단에 고정되는 인트로(히어로) 카드.
  static const Restaurant _introCard = Restaurant(
    id: 'intro',
    name: "The easiest way to\nbook Korean dining.",
    location: "Tell us where & when, we’ll secure the table for you.",
    description: "Intro card",
    imagePath: "https://images.unsplash.com/photo-1414235077428-338989a2e8c0",
    tags: ["INTRO"],
  );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F7F7),
      body: SafeArea(
        bottom: false,
        child: ScrollConfiguration(
          behavior: const MaterialScrollBehavior().copyWith(
            dragDevices: {
              PointerDeviceKind.touch,
              PointerDeviceKind.mouse,
              PointerDeviceKind.trackpad,
              PointerDeviceKind.stylus,
            },
          ),
          child: CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: Container(
                  color: const Color(0xFFF7F7F7),
                  padding: const EdgeInsets.only(top: 8),
                  child: Column(
                    children: [
                      _buildTopHeader(),
                      _buildCategoryTabs(),
                    ],
                  ),
                ),
              ),
              // 지역과 무관한 인트로 히어로 카드는 항상 상단에 고정.
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
                sliver: SliverToBoxAdapter(
                  child: _buildArticleCard(
                    context: context,
                    restaurant: _introCard,
                    isIntro: true,
                  ),
                ),
              ),
              // 선택된 지역으로 필터된 식당 목록 / 로딩 / 빈 상태.
              _buildRegionListSliver(),
              SliverToBoxAdapter(child: _buildRecentRecordsSection()),
              const SliverToBoxAdapter(child: SizedBox(height: 24)),
            ],
          ),
        ),
      ),
    );
  }

    Widget _buildTopHeader() {
      return Padding(
        padding: const EdgeInsets.fromLTRB(24, 10, 24, 18),
        child: Center(
          child: SizedBox(
            height: 44,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Image.asset(
                  'assets/icons/yumbook_logo_mark.png',
                  width: 33,
                  height: 19,
                  fit: BoxFit.contain,
                ),
                const SizedBox(width: 8),
                const Text(
                  'Yumbook',
                  style: TextStyle(
                    color: Colors.black,
                    fontSize: 24,
                    fontWeight: FontWeight.w600,
                    fontFamily: 'Pretendard',
                    height: 1.0,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

  Widget _buildCategoryTabs() {
    return Container(
      decoration: const BoxDecoration(
        border: Border(
          bottom: BorderSide(color: _divider, width: 1),
        ),
      ),
      child: SizedBox(
        height: 54,
        child: _buildCategoryTabsContent(),
      ),
    );
  }

  /// 지역 탭 영역의 본문. 로딩 / 에러 / 정상(탭 목록) 상태를 그린다.
  Widget _buildCategoryTabsContent() {
    if (_isLoadingRegions) {
      return const Center(
        child: SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(strokeWidth: 2.2),
        ),
      );
    }

    if (_regionsError != null) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Row(
          children: [
            const Icon(Icons.cloud_off_outlined, size: 18, color: _textMuted),
            const SizedBox(width: 8),
            const Text(
              "Couldn't load regions.",
              style: TextStyle(
                color: _textMuted,
                fontSize: 14,
                fontWeight: FontWeight.w500,
                fontFamily: 'Pretendard',
              ),
            ),
            const SizedBox(width: 8),
            GestureDetector(
              onTap: _loadRegions,
              child: const Text(
                'Retry',
                style: TextStyle(
                  color: _textDark,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  fontFamily: 'Pretendard',
                ),
              ),
            ),
          ],
        ),
      );
    }

    if (_regions.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(horizontal: 24),
        child: Align(
          alignment: Alignment.centerLeft,
          child: Text(
            'No regions available.',
            style: TextStyle(
              color: _textMuted,
              fontSize: 14,
              fontWeight: FontWeight.w500,
              fontFamily: 'Pretendard',
            ),
          ),
        ),
      );
    }

    return ListView.builder(
      controller: _tabScrollController,
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      itemCount: _regions.length,
      itemBuilder: (context, index) {
        final region = _regions[index];
        final isActive = selectedRegion == region.slug;

        return GestureDetector(
          onTap: () {
            if (selectedRegion == region.slug) return;
            setState(() {
              selectedRegion = region.slug;
            });
            // 즉시 로딩 표시 후 백엔드에서 해당 지역 식당을 다시 로드한다.
            _loadRegion(region.slug);
          },
          child: Container(
            margin: const EdgeInsets.only(right: 22),
            padding: const EdgeInsets.only(top: 6, bottom: 10),
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(
                  color: isActive ? _textDark : Colors.transparent,
                  width: 2,
                ),
              ),
            ),
            alignment: Alignment.center,
            child: Text(
              region.name,
              style: TextStyle(
                color: isActive ? _textDark : _textMuted,
                fontSize: 17,
                fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
                fontFamily: 'Pretendard',
                height: 1,
              ),
            ),
          ),
        );
      },
    );
  }

  /// 로딩 / 에러 / 빈 상태 / 식당 목록을 상황에 맞게 그리는 sliver.
  Widget _buildRegionListSliver() {
    // 지역 목록 자체를 아직 못 받았거나(로딩/에러) 비어 있으면, 식당 목록 영역은
    // 비워 둔다. 탭 영역에서 이미 상태를 표시하므로 중복 노출을 피한다.
    if (_isLoadingRegions || _regionsError != null || _regions.isEmpty) {
      return const SliverToBoxAdapter(child: SizedBox.shrink());
    }

    if (_isLoadingRestaurants) {
      return const SliverPadding(
        padding: EdgeInsets.fromLTRB(24, 48, 24, 48),
        sliver: SliverToBoxAdapter(
          child: Center(
            child: CircularProgressIndicator(strokeWidth: 2.4),
          ),
        ),
      );
    }

    if (_loadError != null) {
      return SliverPadding(
        padding: const EdgeInsets.fromLTRB(24, 48, 24, 48),
        sliver: SliverToBoxAdapter(child: _buildErrorState()),
      );
    }

    if (_visibleRestaurants.isEmpty) {
      return SliverPadding(
        padding: const EdgeInsets.fromLTRB(24, 48, 24, 48),
        sliver: SliverToBoxAdapter(child: _buildEmptyState()),
      );
    }

    return SliverPadding(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
      sliver: SliverList.separated(
        itemCount: _visibleRestaurants.length,
        separatorBuilder: (_, __) => const SizedBox(height: 28),
        itemBuilder: (context, index) {
          return _buildArticleCard(
            context: context,
            restaurant: _visibleRestaurants[index],
            isIntro: false,
          );
        },
      ),
    );
  }

  Widget _buildEmptyState() {
    return Column(
      children: const [
        Icon(Icons.storefront_outlined, size: 48, color: _textMuted),
        SizedBox(height: 12),
        Text(
          'No restaurants found in this area.',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: _textMuted,
            fontSize: 16,
            fontWeight: FontWeight.w500,
            fontFamily: 'Pretendard',
          ),
        ),
      ],
    );
  }

  Widget _buildErrorState() {
    return Column(
      children: [
        const Icon(Icons.cloud_off_outlined, size: 48, color: _textMuted),
        const SizedBox(height: 12),
        const Text(
          "Couldn't load restaurants.",
          textAlign: TextAlign.center,
          style: TextStyle(
            color: _textDark,
            fontSize: 16,
            fontWeight: FontWeight.w600,
            fontFamily: 'Pretendard',
          ),
        ),
        const SizedBox(height: 6),
        const Text(
          'Please check your connection and try again.',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: _textMuted,
            fontSize: 14,
            fontFamily: 'Pretendard',
          ),
        ),
        const SizedBox(height: 16),
        OutlinedButton(
          onPressed: () => _loadRegion(selectedRegion),
          child: const Text('Retry'),
        ),
      ],
    );
  }

  Widget _buildRecentRecordsSection() {
    return AnimatedBuilder(
      animation: FoodRecordStore.instance,
      builder: (context, _) {
        final store = FoodRecordStore.instance;
        final records = store.publicRecords;
        final isLoading = store.isLoadingPublic;

        if (records.isEmpty && !isLoading) {
          // 아직 데이터 없으면 섹션 자체를 숨김
          return const SizedBox.shrink();
        }

        return Padding(
          padding: const EdgeInsets.fromLTRB(0, 12, 0, 4),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 0, 24, 12),
                child: Row(
                  children: [
                    const Expanded(
                      child: Text(
                        'Recent Records',
                        style: TextStyle(
                          color: _textDark,
                          fontSize: 20,
                          fontWeight: FontWeight.w600,
                          fontFamily: 'Pretendard',
                        ),
                      ),
                    ),
                    GestureDetector(
                      onTap: _openAllPublicRecords,
                      child: const Text(
                        'See all',
                        style: TextStyle(
                          color: _textMuted,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          fontFamily: 'Pretendard',
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(
                height: 220,
                child: isLoading && records.isEmpty
                    ? const Center(child: CircularProgressIndicator())
                    : ListView.separated(
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        itemCount: records.length,
                        separatorBuilder: (_, __) => const SizedBox(width: 12),
                        itemBuilder: (context, index) {
                          final record = records[index];
                          return _RecentRecordTile(
                            record: record,
                            onTap: () => _openRecordDetail(record),
                          );
                        },
                      ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildArticleCard({
    required BuildContext context,
    required Restaurant restaurant,
    bool isIntro = false,
  }) {
    return GestureDetector(
      onTap: isIntro
          ? null
          : () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => AHome11CardDetail(restaurant: restaurant),
                ),
              );
            },
      child: Container(
        width: double.infinity,
        height: isIntro ? 340 : 540,
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(22),
          color: const Color(0xFFE5E5E5),
        ),
        child: Stack(
          fit: StackFit.expand,
          children: [
            Image.network(
              restaurant.imagePath,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Container(
                color: const Color(0xFFEAEAEA),
              ),
            ),
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withOpacity(0.02),
                    Colors.black.withOpacity(0.12),
                    Colors.black.withOpacity(0.42),
                  ],
                ),
              ),
            ),
            Positioned(
              left: 28,
              right: 28,
              bottom: 28,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    restaurant.name,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: isIntro ? 34 : 28,
                      fontWeight: FontWeight.w700,
                      fontFamily: 'Pretendard',
                      height: 1.08,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    restaurant.location,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w400,
                      fontFamily: 'Pretendard',
                      height: 1.3,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RecentRecordTile extends StatelessWidget {
  final FoodRecord record;
  final VoidCallback onTap;

  const _RecentRecordTile({required this.record, required this.onTap});

  static const Color _textDark = Color(0xFF303030);
  static const Color _textMuted = Color(0xFF7A7A7A);
  static const Color _border = Color(0xFFE5E5EA);
  static const Color _primary = Color(0xFFD45425);

  @override
  Widget build(BuildContext context) {
    final imageUrl =
        record.images.isNotEmpty ? record.images.first.imageUrl : null;
    final titleParts = [
      if (record.restaurantName.isNotEmpty) record.restaurantName,
      if (record.menuName.isNotEmpty) record.menuName,
    ];
    final title = titleParts.isEmpty ? 'Untitled' : titleParts.join(' · ');

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 200,
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: _border),
          borderRadius: BorderRadius.circular(14),
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AspectRatio(
              aspectRatio: 16 / 10,
              child: imageUrl != null && imageUrl.isNotEmpty
                  ? Image.network(
                      imageUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (_, _, _) => Container(
                        color: const Color(0xFFEAEAEA),
                        alignment: Alignment.center,
                        child: const Icon(
                          Icons.broken_image_outlined,
                          color: _textMuted,
                        ),
                      ),
                    )
                  : Container(
                      color: const Color(0xFFEAEAEA),
                      alignment: Alignment.center,
                      child: const Icon(
                        Icons.restaurant,
                        color: _textMuted,
                      ),
                    ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 10, 10, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: _textDark,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      fontFamily: 'Pretendard',
                    ),
                  ),
                  if (record.review.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      record.review,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: _textMuted,
                        fontSize: 12,
                        fontFamily: 'Pretendard',
                        height: 1.3,
                      ),
                    ),
                  ],
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      const Icon(Icons.star, color: _primary, size: 13),
                      const SizedBox(width: 3),
                      Text(
                        record.rating.toStringAsFixed(1),
                        style: const TextStyle(
                          color: _primary,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          fontFamily: 'Pretendard',
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}