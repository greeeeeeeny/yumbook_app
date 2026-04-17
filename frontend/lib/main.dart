import 'dart:async';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:yumbook_frontend/screens/auth/splash_screen.dart';
import 'package:yumbook_frontend/screens/auth/update_password_screen.dart';
import 'package:yumbook_shared/themes/yum_colors.dart';
import 'core/supabase/supabase_client.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
StreamSubscription<AuthState>? _authSubscription;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await dotenv.load(fileName: 'assets/config/dotenv');
  await SupabaseClientManager.init();

  _authSubscription = SupabaseClientManager.client.auth.onAuthStateChange.listen(
    (data) {
      final event = data.event;

      if (event == AuthChangeEvent.passwordRecovery) {
        final currentContext = navigatorKey.currentContext;
        if (currentContext == null) return;

        navigatorKey.currentState?.push(
          MaterialPageRoute(
            builder: (_) => const UpdatePasswordScreen(),
          ),
        );
      }
    },
  );

  runApp(const YumbookApp());
}

class YumbookApp extends StatelessWidget {
  const YumbookApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: navigatorKey,
      title: 'Yumbook',
      debugShowCheckedModeBanner: false,
      scrollBehavior: const MaterialScrollBehavior().copyWith(
        dragDevices: {
          PointerDeviceKind.touch,
          PointerDeviceKind.mouse,
          PointerDeviceKind.trackpad,
          PointerDeviceKind.stylus,
        },
      ),
      home: const SplashScreen(),
      theme: ThemeData(
        fontFamily: 'Pretendard',
        colorScheme: ColorScheme.fromSeed(
          seedColor: YumColors.logoColor,
          primary: YumColors.logoColor,
        ),
        scaffoldBackgroundColor: Colors.white,
        useMaterial3: true,
      ),
    );
  }
}