import 'package:flutter/material.dart';

class BottomSheetDescription extends StatelessWidget {
  const BottomSheetDescription({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 40), // 좌, 상, 우, 하 패딩
      child: Column(
        mainAxisSize: MainAxisSize.min, // 중요: 내용만큼만 높이 차지
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'About 1993 Gogi',
                style: TextStyle(
                  color: Color(0xFF383838),
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
              GestureDetector(
                onTap: () => Navigator.pop(context), // Done 클릭 시 닫기
                child: const Text(
                  'Done',
                  style: TextStyle(
                    color: Color(0xFF6E6E6E),
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          const Text(
            '1993 Gogi is a Korean barbecue restaurant popular for its juicy Samgyeopsal (pork belly), tender Moksal (pork neck), and chewy Jjonddeuksal (special pork cut).\n\nSpecial side dishes include Bibim Noodles made with a house special sauce and Kimchi Fried Rice topped with plenty of cheese, both considered must-tries.\n\nThe interior is clean and modern, and staff grill the meat at the table, making for a convenient and enjoyable dining experience.',
            style: TextStyle(
              color: Color(0xFF303030),
              fontSize: 15,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}