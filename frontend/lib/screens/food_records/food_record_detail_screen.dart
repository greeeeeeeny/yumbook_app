import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:yumbook_app/models/food_record.dart';
import 'package:yumbook_app/state/food_record_store.dart';

import 'create_food_record_screen.dart';

class FoodRecordDetailScreen extends StatefulWidget {
  final FoodRecord initialRecord;

  const FoodRecordDetailScreen({super.key, required this.initialRecord});

  @override
  State<FoodRecordDetailScreen> createState() => _FoodRecordDetailScreenState();
}

class _FoodRecordDetailScreenState extends State<FoodRecordDetailScreen> {
  static const Color _textDark = Color(0xFF303030);
  static const Color _textMuted = Color(0xFF7A7A7A);
  static const Color _border = Color(0xFFE5E5EA);
  static const Color _primary = Color(0xFFD45425);
  static const Color _danger = Color(0xFFD93025);

  late FoodRecord _record;
  bool _isDeleting = false;
  final PageController _pageController = PageController();
  int _currentPage = 0;

  @override
  void initState() {
    super.initState();
    _record = widget.initialRecord;
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  bool get _isOwner {
    final uid = Supabase.instance.client.auth.currentUser?.id;
    if (uid == null) return false;
    return _record.userId != null && _record.userId == uid;
  }

  Future<void> _openEdit() async {
    final updated = await Navigator.push<FoodRecord>(
      context,
      MaterialPageRoute(
        builder: (_) => CreateFoodRecordScreen(initialRecord: _record),
      ),
    );
    if (updated != null && mounted) {
      setState(() => _record = updated);
    }
  }

  Future<void> _confirmDelete() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        backgroundColor: Colors.white,
        title: const Text(
          'Delete record?',
          style: TextStyle(
            fontFamily: 'Pretendard',
            fontWeight: FontWeight.w600,
            color: _textDark,
          ),
        ),
        content: const Text(
          'This action cannot be undone.',
          style: TextStyle(
            fontFamily: 'Pretendard',
            color: _textMuted,
            fontSize: 14,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx, false),
            child: const Text(
              'Cancel',
              style: TextStyle(color: _textMuted, fontFamily: 'Pretendard'),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx, true),
            child: const Text(
              'Delete',
              style: TextStyle(color: _danger, fontFamily: 'Pretendard'),
            ),
          ),
        ],
      ),
    );

    if (ok != true) return;

    final id = _record.id;
    if (id == null) return;

    setState(() => _isDeleting = true);
    try {
      await FoodRecordStore.instance.deleteRecord(id);
      if (!mounted) return;
      Navigator.pop(context, true);
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to delete: $error')),
      );
    } finally {
      if (mounted) setState(() => _isDeleting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final titleParts = [
      if (_record.restaurantName.isNotEmpty) _record.restaurantName,
      if (_record.menuName.isNotEmpty) _record.menuName,
    ];
    final title = titleParts.isEmpty ? 'Record' : titleParts.join(' · ');

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: _textDark,
        title: const Text(
          'Record',
          style: TextStyle(
            color: _textDark,
            fontSize: 18,
            fontWeight: FontWeight.w600,
            fontFamily: 'Pretendard',
          ),
        ),
        actions: [
          if (_isOwner)
            PopupMenuButton<String>(
              icon: const Icon(Icons.more_horiz, color: _textDark),
              onSelected: (value) {
                if (value == 'edit') _openEdit();
                if (value == 'delete') _confirmDelete();
              },
              itemBuilder: (_) => const [
                PopupMenuItem(value: 'edit', child: Text('Edit')),
                PopupMenuItem(value: 'delete', child: Text('Delete')),
              ],
            ),
        ],
      ),
      body: Stack(
        children: [
          ListView(
            padding: const EdgeInsets.only(bottom: 32),
            children: [
              _ImageGallery(
                images: _record.images,
                controller: _pageController,
                onPageChanged: (i) => setState(() => _currentPage = i),
                currentPage: _currentPage,
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 18, 20, 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
                            title,
                            style: const TextStyle(
                              color: _textDark,
                              fontSize: 20,
                              fontWeight: FontWeight.w700,
                              fontFamily: 'Pretendard',
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        _RatingChip(rating: _record.rating),
                      ],
                    ),
                    if (_record.formattedVisitedAt.isNotEmpty) ...[
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          const Icon(
                            Icons.event,
                            size: 16,
                            color: _textMuted,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            _record.formattedVisitedAt,
                            style: const TextStyle(
                              color: _textMuted,
                              fontSize: 13,
                              fontFamily: 'Pretendard',
                            ),
                          ),
                          if (!_record.isPublic) ...[
                            const SizedBox(width: 8),
                            const _PrivateChip(),
                          ],
                        ],
                      ),
                    ] else if (!_record.isPublic) ...[
                      const SizedBox(height: 10),
                      const _PrivateChip(),
                    ],
                    if (_record.tags.isNotEmpty) ...[
                      const SizedBox(height: 14),
                      Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: _record.tags
                            .map((t) => _TagChip(text: t))
                            .toList(),
                      ),
                    ],
                  ],
                ),
              ),
              if (_record.review.isNotEmpty) ...[
                const Divider(
                  color: _border,
                  height: 1,
                  indent: 20,
                  endIndent: 20,
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                  child: Text(
                    _record.review,
                    style: const TextStyle(
                      color: _textDark,
                      fontSize: 15,
                      height: 1.5,
                      fontFamily: 'Pretendard',
                    ),
                  ),
                ),
              ],
            ],
          ),
          if (_isDeleting)
            Container(
              color: Colors.black26,
              alignment: Alignment.center,
              child: const CircularProgressIndicator(),
            ),
        ],
      ),
    );
  }
}

class _ImageGallery extends StatelessWidget {
  final List<FoodRecordImage> images;
  final PageController controller;
  final ValueChanged<int> onPageChanged;
  final int currentPage;

  const _ImageGallery({
    required this.images,
    required this.controller,
    required this.onPageChanged,
    required this.currentPage,
  });

  @override
  Widget build(BuildContext context) {
    if (images.isEmpty) {
      return AspectRatio(
        aspectRatio: 16 / 10,
        child: Container(
          color: const Color(0xFFEAEAEA),
          alignment: Alignment.center,
          child: const Icon(
            Icons.restaurant,
            color: Color(0xFF9AA0A6),
            size: 40,
          ),
        ),
      );
    }

    return Stack(
      children: [
        AspectRatio(
          aspectRatio: 4 / 3,
          child: PageView.builder(
            controller: controller,
            itemCount: images.length,
            onPageChanged: onPageChanged,
            itemBuilder: (context, index) {
              final url = images[index].imageUrl;
              return Image.network(
                url,
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) => Container(
                  color: const Color(0xFFEAEAEA),
                  alignment: Alignment.center,
                  child: const Icon(
                    Icons.broken_image_outlined,
                    color: Color(0xFF9AA0A6),
                  ),
                ),
              );
            },
          ),
        ),
        if (images.length > 1)
          Positioned(
            left: 0,
            right: 0,
            bottom: 10,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(images.length, (i) {
                final active = i == currentPage;
                return Container(
                  width: active ? 18 : 6,
                  height: 6,
                  margin: const EdgeInsets.symmetric(horizontal: 2),
                  decoration: BoxDecoration(
                    color: active ? Colors.white : Colors.white54,
                    borderRadius: BorderRadius.circular(3),
                  ),
                );
              }),
            ),
          ),
      ],
    );
  }
}

class _RatingChip extends StatelessWidget {
  final double rating;
  const _RatingChip({required this.rating});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF1EC),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.star,
            color: _FoodRecordDetailScreenState._primary,
            size: 16,
          ),
          const SizedBox(width: 4),
          Text(
            rating.toStringAsFixed(1),
            style: const TextStyle(
              color: _FoodRecordDetailScreenState._primary,
              fontSize: 14,
              fontWeight: FontWeight.w700,
              fontFamily: 'Pretendard',
            ),
          ),
        ],
      ),
    );
  }
}

class _PrivateChip extends StatelessWidget {
  const _PrivateChip();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: const Color(0xFFEFEFEF),
        borderRadius: BorderRadius.circular(4),
      ),
      child: const Text(
        'Private',
        style: TextStyle(
          color: Color(0xFF6E6E6E),
          fontSize: 11,
          fontWeight: FontWeight.w500,
          fontFamily: 'Pretendard',
        ),
      ),
    );
  }
}

class _TagChip extends StatelessWidget {
  final String text;
  const _TagChip({required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFFF4F4F6),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        text,
        style: const TextStyle(
          color: Color(0xFF383838),
          fontSize: 12,
          fontWeight: FontWeight.w500,
          fontFamily: 'Pretendard',
        ),
      ),
    );
  }
}
