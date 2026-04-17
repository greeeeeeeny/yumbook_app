import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class YumbookBottomNav extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;
  final bool isVisible;

  const YumbookBottomNav({
    super.key,
    required this.currentIndex,
    required this.onTap,
    required this.isVisible,
  });

  static const _selectedColor = Color(0xFFBF331B);
  static const _unselectedColor = Color(0xFF6E6E6E);

  @override
  Widget build(BuildContext context) {
    // ✅ SafeArea로 iPhone 홈 인디케이터 영역 대응
    return AnimatedSlide(
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOutCubic,
      offset: isVisible ? Offset.zero : const Offset(0, 1),
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 180),
        opacity: isVisible ? 1 : 0,
        child: SafeArea(
          top: false,
          child: Container(
            height: 70, // 유리님 피그마 값 유지 (요즘 기준도 적절)
            padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 10),
            decoration: const BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Color(0x19000000),
                  blurRadius: 8,
                  offset: Offset(0, -4),
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _NavItem(
                  label: 'Home',
                  iconAsset: 'assets/icons/nav/home.svg',
                  isSelected: currentIndex == 0,
                  selectedColor: _selectedColor,
                  unselectedColor: _unselectedColor,
                  onTap: () => onTap(0),
                ),
                _NavItem(
                  label: 'Explore',
                  iconAsset: 'assets/icons/nav/explore.svg',
                  isSelected: currentIndex == 1,
                  selectedColor: _selectedColor,
                  unselectedColor: _unselectedColor,
                  onTap: () => onTap(1),
                ),
                _NavItem(
                  label: 'Reserve',
                  iconAsset: 'assets/icons/nav/reserve.svg',
                  isSelected: currentIndex == 2,
                  selectedColor: _selectedColor,
                  unselectedColor: _unselectedColor,
                  onTap: () => onTap(2),
                ),
                _NavItem(
                  label: 'Account',
                  iconAsset: 'assets/icons/nav/account.svg',
                  isSelected: currentIndex == 3,
                  selectedColor: _selectedColor,
                  unselectedColor: _unselectedColor,
                  onTap: () => onTap(3),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final String label;
  final String iconAsset;
  final bool isSelected;
  final Color selectedColor;
  final Color unselectedColor;
  final VoidCallback onTap;

  const _NavItem({
    required this.label,
    required this.iconAsset,
    required this.isSelected,
    required this.selectedColor,
    required this.unselectedColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = isSelected ? selectedColor : unselectedColor;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: SizedBox(
        width: 72, // ✅ 아이콘/라벨 정렬 안정화 (피그마 느낌 유지)
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SvgPicture.asset(
              iconAsset,
              width: 24,
              height: 24,
              colorFilter: ColorFilter.mode(color, BlendMode.srcIn),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: color,
                fontSize: 12,
                fontWeight: FontWeight.w300,
                // Pretendard 쓰려면 pubspec 폰트 등록 필요 (아래 참고)
                fontFamily: 'Pretendard',
              ),
            ),
          ],
        ),
      ),
    );
  }
}