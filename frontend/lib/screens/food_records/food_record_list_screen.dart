import 'package:flutter/material.dart';
import 'package:yumbook_app/models/food_record.dart';
import 'package:yumbook_app/state/food_record_store.dart';
import 'package:yumbook_app/widgets/food_record_card.dart';

import 'create_food_record_screen.dart';
import 'food_record_detail_screen.dart';

/// FoodRecord 리스트 화면.
/// [mine] = true 면 내 기록만, false 면 전체 공개 피드.
class FoodRecordListScreen extends StatefulWidget {
  final bool mine;
  final String title;

  const FoodRecordListScreen({
    super.key,
    this.mine = false,
    this.title = 'Food Records',
  });

  @override
  State<FoodRecordListScreen> createState() => _FoodRecordListScreenState();
}

class _FoodRecordListScreenState extends State<FoodRecordListScreen> {
  static const Color _textDark = Color(0xFF303030);
  static const Color _textMuted = Color(0xFF7A7A7A);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _refresh();
    });
  }

  Future<void> _refresh() async {
    try {
      if (widget.mine) {
        await FoodRecordStore.instance.loadMyFeed();
      } else {
        await FoodRecordStore.instance.loadPublicFeed();
      }
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load records: $error')),
      );
    }
  }

  Future<void> _openCreate() async {
    final created = await Navigator.push<FoodRecord>(
      context,
      MaterialPageRoute(builder: (_) => const CreateFoodRecordScreen()),
    );
    if (created != null) {
      _refresh();
    }
  }

  Future<void> _openDetail(FoodRecord record) async {
    final deleted = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => FoodRecordDetailScreen(initialRecord: record),
      ),
    );
    if (deleted == true) {
      _refresh();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: _textDark,
        title: Text(
          widget.title,
          style: const TextStyle(
            color: _textDark,
            fontSize: 18,
            fontWeight: FontWeight.w600,
            fontFamily: 'Pretendard',
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: const Color(0xFFD45425),
        foregroundColor: Colors.white,
        onPressed: _openCreate,
        icon: const Icon(Icons.add),
        label: const Text(
          'Add record',
          style: TextStyle(fontFamily: 'Pretendard', fontWeight: FontWeight.w600),
        ),
      ),
      body: AnimatedBuilder(
        animation: FoodRecordStore.instance,
        builder: (context, _) {
          final store = FoodRecordStore.instance;
          final records = widget.mine ? store.myRecords : store.publicRecords;
          final isLoading =
              widget.mine ? store.isLoadingMine : store.isLoadingPublic;

          if (isLoading && records.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }

          if (records.isEmpty) {
            return RefreshIndicator(
              onRefresh: _refresh,
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                children: [
                  const SizedBox(height: 120),
                  Center(
                    child: Column(
                      children: [
                        const Icon(
                          Icons.restaurant_menu,
                          color: _textMuted,
                          size: 48,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          widget.mine
                              ? 'No records yet.\nTap "Add record" to share your first meal.'
                              : 'No public records yet.',
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: _textMuted,
                            fontSize: 14,
                            fontFamily: 'Pretendard',
                            height: 1.4,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: _refresh,
            child: ListView.builder(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
              itemCount: records.length,
              itemBuilder: (context, index) {
                final record = records[index];
                return FoodRecordCard(
                  record: record,
                  onTap: () => _openDetail(record),
                );
              },
            ),
          );
        },
      ),
    );
  }
}
