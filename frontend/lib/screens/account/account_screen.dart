import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:yumbook_app/screens/account/my_profile_screen.dart';
import 'package:yumbook_app/state/user_profile_store.dart';
import 'package:yumbook_app/screens/account/saved_restaurants_screen.dart';
import 'package:yumbook_app/screens/account/transactions_screen.dart';
import 'package:yumbook_app/screens/food_records/food_record_list_screen.dart';
import 'package:yumbook_app/screens/payment/payment_register_screen.dart';
import 'package:yumbook_app/screens/account/notification_settings_screen.dart';
import 'package:yumbook_app/screens/auth/sign_in_welcome_screen.dart';

class AccountScreen extends StatelessWidget {
  const AccountScreen({super.key});

  static const Color _textDark = Color(0xFF383838);
  static const Color _textGray = Color(0xFF6E6E6E);
  static const Color _border = Color(0xFFE5E5E5);
  static const Color _bg = Colors.white;

  static const String _fontFamily = 'Pretendard';

  TextStyle _titleStyle() => const TextStyle(
        fontFamily: _fontFamily,
        color: _textDark,
        fontSize: 24,
        fontWeight: FontWeight.w600,
        height: 1.2,
      );

  TextStyle _logoutStyle() => const TextStyle(
        fontFamily: _fontFamily,
        color: _textDark,
        fontSize: 18,
        fontWeight: FontWeight.w600,
        height: 1.3,
        decoration: TextDecoration.underline,
      );

  TextStyle _versionStyle() => const TextStyle(
        fontFamily: _fontFamily,
        color: _textDark,
        fontSize: 18,
        fontWeight: FontWeight.w600,
        height: 1.3,
      );

  Future<void> _openUrl(BuildContext context, String url) async {
    final uri = Uri.parse(url);
    final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);

    if (!ok && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Unable to open the link.',
            style: TextStyle(fontFamily: _fontFamily),
          ),
        ),
      );
    }
  }

  Future<void> _sendHelpEmail(BuildContext context) async {
    final uri = Uri(
      scheme: 'mailto',
      path: 'yumbook.help@gmail.com',
      query: 'subject=Yumbook Help',
    );

    final ok = await launchUrl(uri);

    if (!ok && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Unable to open the email app.',
            style: TextStyle(fontFamily: _fontFamily),
          ),
        ),
      );
    }
  }

  Future<void> _showLogoutDialog(BuildContext context) async {
    await showDialog(
      context: context,
      barrierDismissible: true,
      barrierColor: Colors.black.withOpacity(0.35),
      builder: (dialogContext) {
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.symmetric(horizontal: 24),
          child: _LogoutDialog(
            onCancel: () {
              Navigator.of(dialogContext).pop();
            },
            onLogout: () {
              Navigator.of(dialogContext).pop();

              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text(
                    'Logged out',
                    style: TextStyle(fontFamily: _fontFamily),
                  ),
                ),
              );

              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(
                  builder: (_) => const SignInWelcomeScreen(),
                ),
                (route) => false,
              );
            },
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: UserProfileStore.instance,
      builder: (context, _) {
        final profile = UserProfileStore.instance.profile;

        return Scaffold(
          backgroundColor: _bg,
          body: SafeArea(
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 20, 16, 28),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Text(
                        'Account',
                        style: _titleStyle(),
                      ),
                    ),
                    const SizedBox(height: 20),

                    _ProfileHeaderTile(
                      name: profile.name,
                      subtitle: 'View profile',
                      imagePath: profile.profileImagePath,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const MyProfileScreen(),
                          ),
                        );
                      },
                    ),

                    const SizedBox(height: 4),
                    const Divider(color: _border, height: 1),

                    _AccountRow(
                      icon: Icons.star_border_rounded,
                      title: 'Saved Restaurants',
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const SavedRestaurantScreen(),
                          ),
                        );
                      },
                    ),
                    const Divider(color: _border, height: 1),

                    _AccountRow(
                      icon: Icons.menu_book_rounded,
                      title: 'My Records',
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const FoodRecordListScreen(
                              mine: true,
                              title: 'My Records',
                            ),
                          ),
                        );
                      },
                    ),
                    const Divider(color: _border, height: 1),

                    _AccountRow(
                      icon: Icons.receipt_long_outlined,
                      title: 'Transactions',
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const TransactionsScreen(),
                          ),
                        );
                      },
                    ),
                    const Divider(color: _border, height: 1),

                    const SizedBox(height: 16),
                    const _SectionTitle('Settings'),

                    _AccountRow(
                      icon: Icons.credit_card_outlined,
                      title: 'Payment methods',
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const PaymentRegisterScreen(),
                          ),
                        );
                      },
                    ),
                    const Divider(color: _border, height: 1),

                    _AccountRow(
                      icon: Icons.notifications_none_rounded,
                      title: 'Push notifications',
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) =>
                                const NotificationSettingsScreen(),
                          ),
                        );
                      },
                    ),
                    const Divider(color: _border, height: 1),

                    const SizedBox(height: 16),
                    const _SectionTitle('Support'),

                    _AccountRow(
                      title: 'Help',
                      onTap: () {
                        _sendHelpEmail(context);
                      },
                    ),
                    const Divider(color: _border, height: 1),

                    _AccountRow(
                      title: 'Give us feedback',
                      onTap: () {
                        _openUrl(
                          context,
                          'https://play.google.com/store/apps/details?id=com.yumbook.app',
                        );
                      },
                    ),
                    const Divider(color: _border, height: 1),

                    const SizedBox(height: 16),
                    const _SectionTitle('Legal'),

                    _AccountRow(
                      title: 'Terms',
                      onTap: () {
                        _openUrl(
                          context,
                          'https://www.yumbook.io/terms-conditions',
                        );
                      },
                    ),
                    const Divider(color: _border, height: 1),

                    _AccountRow(
                      title: 'Privacy',
                      onTap: () {
                        _openUrl(
                          context,
                          'https://www.yumbook.io/privacy-policy',
                        );
                      },
                    ),
                    const Divider(color: _border, height: 1),

                    const SizedBox(height: 20),

                    GestureDetector(
                      onTap: () {
                        _showLogoutDialog(context);
                      },
                      child: Text(
                        'Logout',
                        style: _logoutStyle(),
                      ),
                    ),

                    const SizedBox(height: 16),

                    Text(
                      'Version 1.0.0',
                      style: _versionStyle(),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _ProfileHeaderTile extends StatelessWidget {
  final String name;
  final String subtitle;
  final String? imagePath;
  final VoidCallback onTap;

  const _ProfileHeaderTile({
    required this.name,
    required this.subtitle,
    required this.imagePath,
    required this.onTap,
  });

  static const Color _textDark = Color(0xFF383838);
  static const Color _textGray = Color(0xFF6E6E6E);
  static const String _fontFamily = 'Pretendard';

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 14),
        child: Row(
          children: [
            Container(
              width: 58,
              height: 58,
              decoration: const BoxDecoration(
                color: Color(0xFFD5EAF7),
                shape: BoxShape.circle,
              ),
              clipBehavior: Clip.antiAlias,
              child: imagePath != null && imagePath!.isNotEmpty
                  ? Image.asset(
                      imagePath!,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => const Icon(
                        Icons.person,
                        size: 28,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(
                      Icons.person,
                      size: 28,
                      color: Colors.white,
                    ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Hi, $name',
                    style: const TextStyle(
                      fontFamily: _fontFamily,
                      color: _textDark,
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      height: 1.25,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontFamily: _fontFamily,
                      color: _textGray,
                      fontSize: 16,
                      fontWeight: FontWeight.w400,
                      height: 1.3,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.chevron_right_rounded,
              color: _textDark,
              size: 28,
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;
  const _SectionTitle(this.title);

  static const String _fontFamily = 'Pretendard';

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Text(
        title,
        style: const TextStyle(
          fontFamily: _fontFamily,
          color: Color(0xFF6E6E6E),
          fontSize: 14,
          fontWeight: FontWeight.w500,
          height: 1.3,
        ),
      ),
    );
  }
}

class _AccountRow extends StatelessWidget {
  final IconData? icon;
  final String title;
  final VoidCallback onTap;

  const _AccountRow({
    this.icon,
    required this.title,
    required this.onTap,
  });

  static const Color _textDark = Color(0xFF383838);
  static const String _fontFamily = 'Pretendard';

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 18),
        child: Row(
          children: [
            if (icon != null) ...[
              Icon(icon, size: 24, color: _textDark),
              const SizedBox(width: 14),
            ],
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  fontFamily: _fontFamily,
                  color: _textDark,
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  height: 1.25,
                ),
              ),
            ),
            const Icon(
              Icons.chevron_right_rounded,
              color: _textDark,
              size: 28,
            ),
          ],
        ),
      ),
    );
  }
}

class _LogoutDialog extends StatelessWidget {
  final VoidCallback onCancel;
  final VoidCallback onLogout;

  const _LogoutDialog({
    required this.onCancel,
    required this.onLogout,
  });

  static const Color _titleDark = Color(0xFF303030);
  static const Color _textGray = Color(0xFF6E6E6E);
  static const Color _border = Color(0xFFE5E5EA);
  static const Color _cancelButton = Color(0xFFB4B4B4);
  static const Color _logoutButton = Color(0xFFD45425);
  static const String _fontFamily = 'Pretendard';

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        width: 363,
        padding: const EdgeInsets.all(16),
        decoration: ShapeDecoration(
          color: Colors.white,
          shape: RoundedRectangleBorder(
            side: const BorderSide(
              width: 1,
              color: _border,
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          shadows: const [
            BoxShadow(
              color: Color(0x3F000000),
              blurRadius: 4,
              offset: Offset(0, 4),
              spreadRadius: 0,
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Log Out',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: _fontFamily,
                color: _titleDark,
                fontSize: 18,
                fontWeight: FontWeight.w600,
                height: 1.2,
              ),
            ),
            const SizedBox(height: 18),
            const Text(
              'Are you sure you want to log out?',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: _fontFamily,
                color: _textGray,
                fontSize: 13,
                fontWeight: FontWeight.w400,
                height: 1.35,
              ),
            ),
            const SizedBox(height: 18),
            Row(
              children: [
                Expanded(
                  child: SizedBox(
                    height: 36,
                    child: ElevatedButton(
                      onPressed: onCancel,
                      style: ElevatedButton.styleFrom(
                        elevation: 0,
                        backgroundColor: _cancelButton,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(25),
                        ),
                      ),
                      child: const Text(
                        'Cancel',
                        style: TextStyle(
                          fontFamily: _fontFamily,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          height: 1.2,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: SizedBox(
                    height: 36,
                    child: ElevatedButton(
                      onPressed: onLogout,
                      style: ElevatedButton.styleFrom(
                        elevation: 0,
                        backgroundColor: _logoutButton,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(25),
                        ),
                      ),
                      child: const Text(
                        'Log Out',
                        style: TextStyle(
                          fontFamily: _fontFamily,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          height: 1.2,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}