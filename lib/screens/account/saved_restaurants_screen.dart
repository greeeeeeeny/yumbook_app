import 'package:flutter/material.dart';
import 'package:yumbook_app/models/restaurant.dart';
import 'package:yumbook_app/state/saved_restaurants_store.dart';
import 'package:yumbook_app/state/user_session_store.dart';

class SavedRestaurantScreen extends StatelessWidget {
  const SavedRestaurantScreen({super.key});

  static const Color _bg = Colors.white;
  static const Color _textDark = Color(0xFF383838);
  static const Color _textGray = Color(0xFF6E6E6E);
  static const Color _border = Color(0xFFE5E5EA);
  static const Color _imageBg = Color(0xFFD5EAF7);

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: SavedRestaurantsStore.instance,
      builder: (context, _) {
        final currentUser = UserSessionStore.instance.currentUser;

        if (currentUser == null) {
          return const Scaffold(
            body: Center(
              child: Text('Please log in.'),
            ),
          );
        }

        final userId = currentUser.id;
        final savedRestaurants =
            SavedRestaurantsStore.instance.getSavedRestaurants(userId);

        return Scaffold(
          backgroundColor: _bg,
          body: SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(15, 10, 15, 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 6),

                  // 상단 제목 영역
                  Stack(
                    alignment: Alignment.center,
                    children: [
                      Align(
                        alignment: Alignment.centerLeft,
                        child: InkWell(
                          borderRadius: BorderRadius.circular(20),
                          onTap: () => Navigator.pop(context),
                          child: const Padding(
                            padding: EdgeInsets.all(4),
                            child: Icon(
                              Icons.chevron_left_rounded,
                              size: 30,
                              color: _textDark,
                            ),
                          ),
                        ),
                      ),
                      const Center(
                        child: Text(
                          'Saved Restaurants',
                          style: TextStyle(
                            color: Colors.black,
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 20),

                  Expanded(
                    child: savedRestaurants.isEmpty
                        ? const _EmptySavedRestaurants()
                        : ListView.separated(
                            itemCount: savedRestaurants.length,
                            separatorBuilder: (_, __) =>
                                const SizedBox(height: 15),
                            itemBuilder: (context, index) {
                              final restaurant = savedRestaurants[index];
                              return _SavedRestaurantCard(
                                restaurant: restaurant,
                                userId: userId,
                              );
                            },
                          ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _EmptySavedRestaurants extends StatelessWidget {
  const _EmptySavedRestaurants();

  static const Color _textDark = Color(0xFF383838);
  static const Color _textGray = Color(0xFF6E6E6E);

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: const [
          Icon(
            Icons.bookmark_border_rounded,
            size: 42,
            color: _textGray,
          ),
          SizedBox(height: 12),
          Text(
            'No saved restaurants yet',
            style: TextStyle(
              color: _textDark,
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: 6),
          Text(
            'Restaurants you save will appear here.',
            style: TextStyle(
              color: _textGray,
              fontSize: 14,
              fontWeight: FontWeight.w400,
            ),
          ),
        ],
      ),
    );
  }
}

class _SavedRestaurantCard extends StatelessWidget {
  final Restaurant restaurant;
  final String userId;

  const _SavedRestaurantCard({
    required this.restaurant,
    required this.userId,
  });

  static const Color _textDark = Color(0xFF383838);
  static const Color _textGray = Color(0xFF1E1E1E);
  static const Color _border = Color(0xFFE5E5EA);
  static const Color _imageBg = Color(0xFFD5EAF7);

  @override
  Widget build(BuildContext context) {

    return Container(
      height: 107,
      padding: const EdgeInsets.all(16),
      decoration: ShapeDecoration(
        shape: RoundedRectangleBorder(
          side: const BorderSide(
            width: 1,
            color: _border,
          ),
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: SizedBox(
              height: 88,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    restaurant.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: _textDark,
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(
                        Icons.location_on_outlined,
                        size: 18,
                        color: _textGray,
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          _buildLocationText(restaurant),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: _textGray,
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const Spacer(),
                  Row(
                    children: [
                      InkWell(
                        onTap: () {
                          SavedRestaurantsStore.instance.removeSaved(
                            userId: userId,
                            restaurantId: restaurant.id,
                          );
                        },
                        borderRadius: BorderRadius.circular(20),
                        child: const Padding(
                          padding: EdgeInsets.symmetric(
                            horizontal: 2,
                            vertical: 2,
                          ),
                          child: Icon(
                            Icons.bookmark,
                            size: 22,
                            color: _textDark,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 12),
          _RestaurantThumbnail(restaurant: restaurant),
        ],
      ),
    );
  }

  String _buildLocationText(Restaurant restaurant) {
    // restaurant 모델에 맞게 우선순위 대응
    final district = _readString(restaurant, 'district');
    final city = _readString(restaurant, 'city');
    final location = _readString(restaurant, 'location');
    final address = _readString(restaurant, 'address');

    if (location.isNotEmpty) return location;
    if (district.isNotEmpty && city.isNotEmpty) return '$district, $city';
    if (district.isNotEmpty) return district;
    if (city.isNotEmpty) return city;
    if (address.isNotEmpty) return address;

    return 'Seoul';
  }

  String _readString(Restaurant restaurant, String fieldName) {
    try {
      final value = (restaurant as dynamic)
          .toJson?[fieldName]; // 혹시 toJson 스타일이면 대응
      if (value is String && value.trim().isNotEmpty) {
        return value.trim();
      }
    } catch (_) {}

    try {
      final value = (restaurant as dynamic).__noSuchMethod__;
      if (value == null) {}
    } catch (_) {}

    try {
      final dynamicRestaurant = restaurant as dynamic;
      final value = dynamicRestaurant
          .toString(); // 단순 fallback, 직접 field 접근 전용 아님
      if (value.isNotEmpty) {}
    } catch (_) {}

    try {
      final dynamic r = restaurant;
      final value = switch (fieldName) {
        'district' => r.district,
        'city' => r.city,
        'location' => r.location,
        'address' => r.address,
        _ => null,
      };
      if (value is String && value.trim().isNotEmpty) {
        return value.trim();
      }
    } catch (_) {}

    return '';
  }
}

class _RestaurantThumbnail extends StatelessWidget {
  final Restaurant restaurant;

  const _RestaurantThumbnail({
    required this.restaurant,
  });

  static const Color _imageBg = Color(0xFFD5EAF7);

  @override
  Widget build(BuildContext context) {
    final imagePath = _readImagePath(restaurant);

    return Container(
      width: 88,
      height: 88,
      clipBehavior: Clip.antiAlias,
      decoration: ShapeDecoration(
        color: _imageBg,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      child: imagePath != null && imagePath.isNotEmpty
          ? Image.asset(
              imagePath,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => const Icon(
                Icons.restaurant_rounded,
                size: 30,
                color: Colors.white,
              ),
            )
          : const Icon(
              Icons.restaurant_rounded,
              size: 30,
              color: Colors.white,
            ),
    );
  }

  String? _readImagePath(Restaurant restaurant) {
    try {
      final dynamic r = restaurant;
      final value = r.imagePath;
      if (value is String && value.trim().isNotEmpty) {
        return value.trim();
      }
    } catch (_) {}

    try {
      final dynamic r = restaurant;
      final value = r.thumbnailImagePath;
      if (value is String && value.trim().isNotEmpty) {
        return value.trim();
      }
    } catch (_) {}

    try {
      final dynamic r = restaurant;
      final value = r.mainImagePath;
      if (value is String && value.trim().isNotEmpty) {
        return value.trim();
      }
    } catch (_) {}

    return null;
  }
}