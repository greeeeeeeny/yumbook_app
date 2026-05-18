import 'package:flutter/material.dart';
import 'package:yumbook_app/models/restaurant.dart';
import 'package:yumbook_app/state/restaurant_store.dart';

/// 식당 검색 후 단일 선택. pop 으로 [Restaurant] 또는 null 반환.
class RestaurantPickerScreen extends StatefulWidget {
  const RestaurantPickerScreen({super.key});

  @override
  State<RestaurantPickerScreen> createState() => _RestaurantPickerScreenState();
}

class _RestaurantPickerScreenState extends State<RestaurantPickerScreen> {
  static const Color _textDark = Color(0xFF303030);
  static const Color _textMuted = Color(0xFF7A7A7A);
  static const Color _border = Color(0xFFE5E5EA);

  final TextEditingController _controller = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      RestaurantStore.instance.refresh();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _pick(Restaurant restaurant) {
    Navigator.pop(context, restaurant);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: _textDark,
        title: const Text(
          'Select restaurant',
          style: TextStyle(
            color: _textDark,
            fontSize: 18,
            fontWeight: FontWeight.w600,
            fontFamily: 'Pretendard',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, null),
            child: const Text(
              'Skip',
              style: TextStyle(
                color: _textMuted,
                fontFamily: 'Pretendard',
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
              child: TextField(
                controller: _controller,
                onChanged: RestaurantStore.instance.setQuery,
                style: const TextStyle(
                  fontFamily: 'Pretendard',
                  color: _textDark,
                  fontSize: 14,
                ),
                decoration: InputDecoration(
                  hintText: 'Search restaurants',
                  prefixIcon: const Icon(Icons.search),
                  isDense: true,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 12,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: _border),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: _textDark),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: _border),
                  ),
                ),
              ),
            ),
            Expanded(
              child: AnimatedBuilder(
                animation: RestaurantStore.instance,
                builder: (context, _) {
                  final store = RestaurantStore.instance;

                  if (store.isLoading && store.results.isEmpty) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (store.lastError != null && store.results.isEmpty) {
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Text(
                          'Failed to load: ${store.lastError}',
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: _textMuted),
                        ),
                      ),
                    );
                  }

                  if (store.results.isEmpty) {
                    return const Center(
                      child: Text(
                        'No restaurants match your search.',
                        style: TextStyle(color: _textMuted),
                      ),
                    );
                  }

                  return ListView.separated(
                    itemCount: store.results.length,
                    separatorBuilder: (_, __) =>
                        const Divider(height: 1, color: _border),
                    itemBuilder: (context, index) {
                      final r = store.results[index];
                      return ListTile(
                        title: Text(
                          r.name,
                          style: const TextStyle(
                            color: _textDark,
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            fontFamily: 'Pretendard',
                          ),
                        ),
                        subtitle: r.location.isEmpty
                            ? null
                            : Text(
                                r.location,
                                style: const TextStyle(
                                  color: _textMuted,
                                  fontSize: 13,
                                  fontFamily: 'Pretendard',
                                ),
                              ),
                        trailing: const Icon(
                          Icons.chevron_right_rounded,
                          color: _textMuted,
                        ),
                        onTap: () => _pick(r),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
