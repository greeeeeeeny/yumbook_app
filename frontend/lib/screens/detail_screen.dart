import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:share_plus/share_plus.dart';

// models
import 'package:yumbook_app/models/reservation_data.dart';
import 'package:yumbook_app/models/restaurant.dart';

// screens
import 'package:yumbook_app/screens/profile_update_screen.dart';
import 'package:yumbook_app/screens/payment/payment_register_screen.dart';

// widgets
import 'package:yumbook_app/widgets/bottom_sheet_description.dart';
import 'package:yumbook_app/widgets/booking_details_sheet.dart';

import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:yumbook_app/state/saved_restaurants_store.dart';

class AHome11CardDetail extends StatelessWidget {
  final Restaurant restaurant;

  const AHome11CardDetail({super.key, required this.restaurant});

  static const Color _textDark = Color(0xFF303030);
  static const Color _titleDark = Color(0xFF383838);
  static const Color _sectionBg = Color(0xFFF2F2F7);
  static const Color _primary = Color(0xFFD45425);
  static const Color _border = Color(0xFFE5E5EA);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(child: _buildHeaderImage(context)),

          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 20),
              child: _buildTopInfo(context),
            ),
          ),

          const SliverToBoxAdapter(
            child: SizedBox(
              height: 12,
              child: ColoredBox(color: _sectionBg),
            ),
          ),

          SliverToBoxAdapter(child: _buildMenuSection()),

          const SliverToBoxAdapter(
            child: SizedBox(
              height: 12,
              child: ColoredBox(color: _sectionBg),
            ),
          ),

          SliverToBoxAdapter(child: _buildReservationSection(context)),

          const SliverToBoxAdapter(
            child: SizedBox(
              height: 12,
              child: ColoredBox(color: _sectionBg),
            ),
          ),

          SliverToBoxAdapter(child: _buildInfoSection()),

          const SliverToBoxAdapter(child: SizedBox(height: 32)),
        ],
      ),
    );
  }

  Widget _buildHeaderImage(BuildContext context) {
  final topInset = MediaQuery.of(context).padding.top;

  return ClipRRect(
    borderRadius: const BorderRadius.only(
      bottomLeft: Radius.circular(22),
      bottomRight: Radius.circular(22),
    ),
    child: SizedBox(
      height: 430,
      width: double.infinity,
      child: Stack(
        fit: StackFit.expand,
        children: [
          _buildRestaurantImage(restaurant.imagePath),
          Positioned(
            top: topInset + 10,
            left: 20,
            child: _circleAssetButton(
              assetPath: 'assets/icons/ic_detail_back.png',
              fallbackIcon: Icons.arrow_back_ios_new_rounded,
              onTap: () => Navigator.pop(context),
            ),
          ),
          Positioned(
            top: topInset + 10,
            right: 20,
            child: _circleAssetButton(
              assetPath: 'assets/icons/ic_detail_calendar.png',
              fallbackIcon: Icons.calendar_today_outlined,
              onTap: () {
                showModalBottomSheet(
                  context: context,
                  isScrollControlled: true,
                  backgroundColor: Colors.transparent,
                  barrierColor: Colors.black54,
                  builder: (context) {
                    return BottomSheetPopupReservationCalender(
                      restaurant: restaurant,
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

Widget _circleAssetButton({
  required String assetPath,
  required IconData fallbackIcon,
  required VoidCallback onTap,
}) {
  return GestureDetector(
    onTap: onTap,
    child: Container(
      width: 54,
      height: 54,
      decoration: const BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
      ),
      alignment: Alignment.center,
      child: Image.asset(
        assetPath,
        width: 24,
        height: 24,
        errorBuilder: (_, __, ___) {
          return Icon(fallbackIcon, color: Colors.black, size: 22);
        },
      ),
    ),
  );
}

  Widget _buildTopInfo(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Text(
                restaurant.name,
                style: const TextStyle(
                  color: _titleDark,
                  fontSize: 24,
                  fontWeight: FontWeight.w600,
                  height: 1.2,
                ),
              ),
            ),
            const SizedBox(width: 12),
            AnimatedBuilder(
              animation: SavedRestaurantsStore.instance,
              builder: (context, _) {
                SavedRestaurantsStore.instance.ensureLoaded();
                final user = Supabase.instance.client.auth.currentUser;

                final isSaved = user != null &&
                    SavedRestaurantsStore.instance.isSaved(
                      userId: user.id,
                      restaurantId: restaurant.id,
                    );

                return Row(
                  children: [
                    IconButton(
                      onPressed: () {
                        final currentUser =
                            Supabase.instance.client.auth.currentUser;

                        if (currentUser == null) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Please log in to save restaurants.'),
                            ),
                          );
                          return;
                        }

                        SavedRestaurantsStore.instance.toggleSaved(
                          userId: currentUser.id,
                          restaurantId: restaurant.id,
                        );

                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              isSaved
                                  ? 'Removed from saved restaurants.'
                                  : 'Saved to your restaurants.',
                            ),
                            duration: const Duration(seconds: 1),
                          ),
                        );
                      },
                      icon: Icon(
                        isSaved ? Icons.star : Icons.star_border_rounded,
                        color: isSaved ? _primary : _titleDark,
                        size: 26,
                      ),
                    ),
                    IconButton(
                      onPressed: () {
                        Share.share(
                          '${restaurant.name}\n${restaurant.location}\nCheck this place on Yumbook!',
                        );
                      },
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(
                        minWidth: 40,
                        minHeight: 40,
                      ),
                      icon: const Icon(
                        Icons.ios_share_outlined,
                        color: _titleDark,
                        size: 24,
                      ),
                    ),
                  ],
                );
              },
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          '${restaurant.location}\n${restaurant.tags.join(' · ')}',
          style: const TextStyle(
            color: _textDark,
            fontSize: 15,
            fontWeight: FontWeight.w500,
            height: 1.45,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          restaurant.description,
          style: const TextStyle(
            color: _textDark,
            fontSize: 14,
            fontWeight: FontWeight.w400,
            height: 1.45,
          ),
        ),
        const SizedBox(height: 8),
        TextButton(
          onPressed: () {
            showModalBottomSheet(
              context: context,
              isScrollControlled: true,
              backgroundColor: Colors.transparent,
              builder: (BuildContext context) {
                return BottomSheetDescription();
              },
            );
          },
          style: TextButton.styleFrom(
            padding: EdgeInsets.zero,
            minimumSize: Size.zero,
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
          child: const Text(
            'Learn more',
            style: TextStyle(
              decoration: TextDecoration.underline,
              color: _textDark,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMenuSection() {
  return Padding(
    padding: const EdgeInsets.symmetric(vertical: 20),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            'Popular Menus',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Color(0xFF383838),
            ),
          ),
        ),
        const SizedBox(height: 16),
          ScrollConfiguration(
          behavior: const MaterialScrollBehavior().copyWith(
            dragDevices: {
              PointerDeviceKind.touch,
              PointerDeviceKind.mouse,
              PointerDeviceKind.trackpad,
              PointerDeviceKind.stylus,
            },
          ),
          child: SizedBox(
          height: 360,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: 3,
            separatorBuilder: (_, __) => const SizedBox(width: 16),
            itemBuilder: (context, index) {
              return _buildMenuCard(
                index == 0 ? "Kimchi Fried Rice" : "Korean BBQ",
                index == 0
                    ? "A spicy Korean dish of rice stir-fried with kimchi."
                    : "A popular Korean BBQ dish of grilled pork belly.",
                index == 0
                    ? "https://images.unsplash.com/photo-1603133872878-684f208fb84b"
                    : "https://images.unsplash.com/photo-1544025162-d76694265947",
              );
            },
          ),
         ),
       ),
      ],
    ),
  );
}

Widget _buildMenuCard(String title, String desc, String imageUrl) {
  return Container(
    width: 280,
    clipBehavior: Clip.antiAlias,
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(20),
      boxShadow: const [
        BoxShadow(
          color: Color(0x16000000),
          blurRadius: 16,
          offset: Offset(0, 6),
        ),
      ],
    ),
    child: Stack(
      fit: StackFit.expand,
      children: [
        Image.network(imageUrl, fit: BoxFit.cover),
        Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.transparent,
                Colors.black.withOpacity(0.35),
              ],
            ),
          ),
        ),
        Positioned(
          left: 16,
          right: 16,
          bottom: 16,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                desc,
                style: TextStyle(
                  color: Colors.white.withOpacity(0.92),
                  fontSize: 13,
                  height: 1.3,
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

  Widget _buildReservationSection(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Reservations',
            style: TextStyle(
              color: _titleDark,
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 16),
          _reservationCard(
            context,
            "Chef Counter Seats",
            "Secure your table in advance and enjoy a smooth dining experience. Choose your party size and seating preference before you visit.",
            "1–4 guests",
            "Bar, Counter",
            "\$155 / person",
          ),
          const SizedBox(height: 12),
          _reservationCard(
            context,
            "Dining Room Seats",
            "Secure your table in advance and enjoy a smooth dining experience. Choose your party size and seating preference before you visit.",
            "1–4 guests",
            "Hall, Counter",
            "\$155 / person",
          ),
          const SizedBox(height: 12),
          _reservationCard(
            context,
            "The Library Room",
            "Secure your table in advance and enjoy a smooth dining experience. Choose your party size and seating preference before you visit.",
            "2–6 guests",
            "Private Room",
            "\$155 / person",
          ),
        ],
      ),
    );
  }

  Widget _reservationCard(
    BuildContext context,
    String title,
    String desc,
    String guests,
    String seatType,
    String price,
  ) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border.all(color: _border),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: _textDark,
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            desc,
            style: const TextStyle(
              color: _textDark,
              fontSize: 14,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: Text(
                  guests,
                  style: const TextStyle(
                    color: _textDark,
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              Expanded(
                child: Text(
                  seatType,
                  style: const TextStyle(
                    color: _textDark,
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            price,
            style: const TextStyle(
              color: _textDark,
              fontSize: 15,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 36,
            child: ElevatedButton(
              onPressed: () {
                final data = ReservationData(
                  restaurantName: restaurant.name,
                  restaurantId: restaurant.id,
                  date: DateTime.now(),
                  time: DateTime.now(),
                  partySize: 2,
                  guestName: 'Kim',
                  seatType: seatType,
                  confirmationCode: 'Yumbook-B-TEST',
                );

                final hasSavedCard = false;

                if (!hasSavedCard) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ProfileUpdateScreen(data: data),
                    ),
                  );
                } 
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: _primary,
                foregroundColor: Colors.white,
                elevation: 0,
                padding: const EdgeInsets.symmetric(horizontal: 20),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: const Text(
                'BOOK',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoSection() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'More information',
            style: TextStyle(
              color: _titleDark,
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 16),

          Container(
            width: double.infinity,
            clipBehavior: Clip.antiAlias,
            decoration: BoxDecoration(
              border: Border.all(color: _border),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                SizedBox(
                  height: 196,
                  width: double.infinity,
                  child: Container(
                    color: const Color(0xFFF5F5F5),
                    alignment: Alignment.center,
                    child: const Text(
                      'Google Map goes here',
                      style: TextStyle(color: Colors.grey),
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          const Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.location_on_outlined, size: 20, color: Colors.grey),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  '1F, 18 Hoegi-ro 19-gil, Dongdaemun-gu, Seoul, South Korea',
                  style: TextStyle(
                    color: _textDark,
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                    height: 1.4,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          const Row(
            children: [
              Icon(Icons.camera_alt_outlined, size: 20, color: Colors.grey),
              SizedBox(width: 8),
              Text(
                'Visit Instagram',
                style: TextStyle(
                  color: _textDark,
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _circleActionButton({
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 42,
        height: 42,
        decoration: const BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: Colors.black, size: 20),
      ),
    );
  }

  Widget _buildRestaurantImage(String path) {
    final bool isNetwork =
        path.startsWith('http://') || path.startsWith('https://');

    final ImageProvider provider =
        isNetwork ? NetworkImage(path) : AssetImage(path) as ImageProvider;

    return Image(
      image: provider,
      fit: BoxFit.cover,
      errorBuilder: (_, __, ___) {
        return Container(
          color: const Color(0xFFEAEAEA),
          alignment: Alignment.center,
          child: const Icon(Icons.image_not_supported_outlined, color: Colors.grey),
        );
      },
    );
  }
}