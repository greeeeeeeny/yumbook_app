import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:yumbook_app/models/food_record.dart';
import 'package:yumbook_app/models/restaurant.dart';
import 'package:yumbook_app/screens/food_records/food_record_detail_screen.dart';
import 'package:yumbook_app/screens/food_records/food_record_list_screen.dart';
import 'package:yumbook_app/state/food_record_store.dart';
import 'detail_screen.dart';

class Category {
  final int id;
  final String label;
  const Category(this.id, this.label);
}

class AHomeCategory extends StatefulWidget {
  const AHomeCategory({super.key});

  @override
  State<AHomeCategory> createState() => _AHomeCategoryState();
}

class _AHomeCategoryState extends State<AHomeCategory> {
  static const Color _textDark = Color(0xFF303030);
  static const Color _textMuted = Color(0xFF7A7A7A);
  static const Color _divider = Color(0xFFBDBDBD);

  int activeCategory = 2;

  final ScrollController _tabScrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadPublicRecords();
    });
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

  final List<Category> categories = const [
    Category(1, "CURATOR PICK"),
    Category(2, "INSADONG"),
    Category(3, "HONGDAE"),
    Category(4, "ITAEWON"),
    Category(5, "SEONGSU"),
    Category(6, "GANGNAM"),
    Category(7, "REGIONAL EATS"),
    Category(8, "PLANT-BASED"),
    Category(9, "ASIAN EATS"),
    Category(10, "HIDDEN GEMS"),
  ];

  final List<Restaurant> restaurants = [
    Restaurant(
      id: 'intro',
      name: "The easiest way to\nbook Korean dining.",
      location: "Tell us where & when, we’ll secure the table for you.",
      description: "Intro card",
      imagePath: "https://images.unsplash.com/photo-1414235077428-338989a2e8c0",
      tags: const ["INTRO"],
    ),
    Restaurant(
      id: 'r001',
      name: "1993 Gogi",
      location: "Near Hoegi Station, Seoul",
      description:
          "1993 Gogi is a Korean barbecue restaurant popular for its juicy Samgyeopsal (pork belly), tender Moksal (pork neck), and chewy Jjonddeuksal (special pork cut).",
      imagePath: "https://images.unsplash.com/photo-1544025162-d76694265947",
      tags: const ["₩₩", "Korean food", "Hidden Gems"],
    ),
    Restaurant(
      id: 'r002',
      name: "Alpero",
      location: "Near Hoegi Station, Seoul",
      description: "A cozy Italian restaurant serving authentic pasta and wine.",
      imagePath: "https://images.unsplash.com/photo-1517248135467-4c7edcad34c4",
      tags: const ["₩₩₩", "Italian", "Date Night"],
    ),
  ];

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
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
                sliver: SliverList.separated(
                  itemCount: restaurants.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 28),
                  itemBuilder: (context, index) {
                    final restaurant = restaurants[index];
                    return _buildArticleCard(
                      context: context,
                      restaurant: restaurant,
                      isIntro: restaurant.id == 'intro',
                    );
                  },
                ),
              ),
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
        child: ListView.builder(
          controller: _tabScrollController,
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 24),
          itemCount: categories.length,
          itemBuilder: (context, index) {
            final cat = categories[index];
            final isActive = activeCategory == cat.id;

            return GestureDetector(
              onTap: () => setState(() => activeCategory = cat.id),
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
                  cat.label,
                  style: TextStyle(
                    color: isActive ? _textDark : _textMuted,
                    fontSize: 17,
                    fontWeight: FontWeight.w400,
                    fontFamily: 'Pretendard',
                    height: 1,
                  ),
                ),
              ),
            );
          },
        ),
      ),
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