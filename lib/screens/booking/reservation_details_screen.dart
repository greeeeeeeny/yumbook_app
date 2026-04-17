import 'package:flutter/material.dart';
import 'package:yumbook_app/models/reservation_data.dart';
import 'package:flutter_svg/flutter_svg.dart';

class ReservationDetailsScreen extends StatelessWidget {
  final ReservationData data;

  const ReservationDetailsScreen({
    super.key,
    required this.data,
  });


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leadingWidth: 90,
        leading: TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text(
            'Done',
            style: TextStyle(
              color: Color(0xFF383838),
              fontSize: 16,
              fontFamily: 'Pretendard',
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        centerTitle: true,
        title: const Text(
          'Confirm',
          style: TextStyle(
            color: Color(0xFF383838),
            fontSize: 24,
            fontFamily: 'Pretendard',
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: ListView(
        children: [
          _divider(),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Reservation details',
                  style: TextStyle(
                    color: Color(0xFF383838),
                    fontSize: 24,
                    fontFamily: 'Pretendard',
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Confirmation: ${data.confirmationCode}',
                  style: const TextStyle(
                    color: Color(0xFF6E6E6E),
                    fontSize: 16,
                    fontFamily: 'Pretendard',
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ],
            ),
          ),
          _divider(),

          // Restaurant + image row
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        data.restaurantName,
                        style: const TextStyle(
                          color: Color(0xFF383838),
                          fontSize: 18,
                          fontFamily: 'Pretendard',
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Reservation',
                        style: TextStyle(
                          color: Color(0xFF6E6E6E),
                          fontSize: 16,
                          fontFamily: 'Pretendard',
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  width: 88,
                  height: 88,
                  clipBehavior: Clip.antiAlias,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    color: const Color(0xFFD5EAF7),
                    image: const DecorationImage(
                      image: NetworkImage("https://placehold.co/104x139"),
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Details texts
            // Details (SVG rows)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _svgRow(
                    'assets/icons/party.svg',
                    '${data.partySize} guests for ${data.guestName}',
                  ),
                  const SizedBox(height: 12),

                  // ✅ seatType optional: 값 있을 때만 보이기
                  if (data.seatType != null && data.seatType!.trim().isNotEmpty) ...[
                    _svgRow('assets/icons/table.svg', data.seatType!.trim()),
                    const SizedBox(height: 12),
                  ],

                  _svgRow(
                    'assets/icons/time.svg',
                    '${data.formattedDate} at ${data.formattedTime}',
                  ),
                ],
              ),
            ),

          const SizedBox(height: 16),

          // Cancellation policy card
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFF8F8F8),
                border: Border.all(color: const Color(0xFFE5E5EA)),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Cancellation policy',
                    style: TextStyle(
                      color: Color(0xFF383838),
                      fontSize: 18,
                      fontFamily: 'Pretendard',
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Your reservation can be canceled at any time before the scheduled reservation time should your plans change.\n'
                    'However, we kindly ask that you cancel at least 24 hours in advance so the restaurant can plan accordingly.',
                    style: TextStyle(
                      color: Color(0xFF6E6E6E),
                      fontSize: 16,
                      fontFamily: 'Pretendard',
                      fontWeight: FontWeight.w400,
                      height: 1.35,
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 24),
          _divider(),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  static Widget _divider() => Container(
        height: 1,
        color: const Color(0xFFE5E5E5),
      );
Widget _svgRow(String assetPath, String text) {
  return Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      SvgPicture.asset(
        assetPath,
        width: 18,
        height: 18,
      ),
      const SizedBox(width: 10),
      Expanded(
        child: Text(
          text,
          style: const TextStyle(
            color: Color(0xFF303030),
            fontSize: 16,
            fontFamily: 'Pretendard',
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    ],
  );
}
}