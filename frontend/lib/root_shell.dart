import 'package:flutter/material.dart';
import '../widgets/yumbook_bottom_nav.dart';

// ✅ screens 폴더 안에 있는 파일들
import 'home_screen.dart';
import 'explore_screen.dart';
import 'reserve_screen.dart';
import 'account/account_screen.dart';

final GlobalKey<_RootShellState> rootShellKey = GlobalKey<_RootShellState>();

class RootShell extends StatefulWidget {
  const RootShell({Key? key}) : super(key: key);

  @override
  State<RootShell> createState() => _RootShellState();
}

class _RootShellState extends State<RootShell> {
  int _index = 0;
  void goToTab(int index) {
  setState(() => _index = index);
}

  bool _navVisible = true;

  // 스크롤 방향 감지용
  double _lastScrollOffset = 0;

  void _onTap(int i) {
    setState(() => _index = i);
  }

  bool _handleScroll(ScrollNotification notification) {
    // ListView/SingleChildScrollView 등에서만 반응함
    if (notification.metrics.axis != Axis.vertical) return false;

    final current = notification.metrics.pixels;
    final diff = current - _lastScrollOffset;

    // 너무 민감하면 깜빡이니까 임계값
    const threshold = 6.0;

    if (diff > threshold && _navVisible) {
      // 아래로 스크롤 -> 숨김
      setState(() => _navVisible = false);
    } else if (diff < -threshold && !_navVisible) {
      // 위로 스크롤 -> 표시
      setState(() => _navVisible = true);
    }

    _lastScrollOffset = current;
    return false;
  }

  @override
  Widget build(BuildContext context) {
      final pages = <Widget>[
        const AHomeCategory(),
        const ExploreScreen(),
        const ReserveScreen(),
        const AccountScreen(),
      ];

      return Scaffold(
        backgroundColor: Colors.white,

        body: NotificationListener<ScrollNotification>(
          onNotification: _handleScroll,
          child: IndexedStack(
            index: _index,
            children: pages,
          ),
        ),

        bottomNavigationBar: YumbookBottomNav(
          currentIndex: _index,
          onTap: _onTap,
          isVisible: _navVisible,
        ),
      );
  }
}

