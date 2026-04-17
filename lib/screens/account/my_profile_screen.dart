import 'package:flutter/material.dart';
import 'package:yumbook_app/models/dining_preferences.dart';
import 'package:yumbook_app/screens/account/dining_preferences_flow_screen.dart';
import 'package:yumbook_app/state/user_profile_store.dart';
import 'package:yumbook_app/screens/account/profile_edit_screen.dart';

class MyProfileScreen extends StatefulWidget {
  const MyProfileScreen({super.key});

  @override
  State<MyProfileScreen> createState() => _MyProfileScreenState();
}

class _MyProfileScreenState extends State<MyProfileScreen> {
  static const Color _textDark = Color(0xFF383838);
  static const Color _textGray = Color(0xFF9AA0A6);
  static const Color _sectionBg = Color(0xFFF2F2F7);

  DiningPreferences _preferences = const DiningPreferences(
    favoriteCuisines: ['Vegetarian / Vegan'],
    diningStyles: ['Casual dining'],
    dietaryRestrictions: ['Gluten-free'],
    additionalNotes: 'No spicy food',
  );

  void _goToProfileEdit() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const ProfileEditScreen(),
      ),
    );
  }

  void _showDietaryInfo(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        contentPadding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
        content: const Text(
          'Please note:\n'
          'Dietary preferences are shared for reference only.\n'
          'We recommend confirming details directly with the restaurant.',
          style: TextStyle(
            color: _textDark,
            fontSize: 14,
            height: 1.45,
          ),
        ),
      ),
    );
  }

  Future<void> _openDiningPreferences(int initialStep) async {
    final result = await Navigator.push<DiningPreferences>(
      context,
      MaterialPageRoute(
        builder: (_) => DiningPreferencesFlowScreen(
          initialStep: initialStep,
          initialData: _preferences,
        ),
      ),
    );

    if (result != null) {
      setState(() {
        _preferences = result;
      });
    }
  }

  String _joinOrFallback(List<String> items) {
    if (items.isEmpty) return 'Not set';
    return items.join(', ');
  }

  String _notesOrFallback(String value) {
    if (value.trim().isEmpty) return 'Not set';
    return value.trim();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: UserProfileStore.instance,
      builder: (context, _) {
        final profile = UserProfileStore.instance.profile;

        return Scaffold(
          backgroundColor: Colors.white,
          body: SafeArea(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 20, 16, 20),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            IconButton(
                              onPressed: () => Navigator.pop(context),
                              icon: const Icon(
                                Icons.arrow_back_ios_new_rounded,
                                color: _textDark,
                                size: 22,
                              ),
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                            ),
                            const Expanded(
                              child: Center(
                                child: Text(
                                  'My Profile',
                                  style: TextStyle(
                                    color: _textDark,
                                    fontSize: 24,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 22),
                          ],
                        ),
                        const SizedBox(height: 18),

                        GestureDetector(
                          onTap: _goToProfileEdit,
                          child: Container(
                            width: 132,
                            height: 132,
                            decoration: const BoxDecoration(
                              color: Color(0xFFD9D9D9),
                              shape: BoxShape.circle,
                            ),
                            clipBehavior: Clip.antiAlias,
                            child: profile.profileImagePath != null &&
                                    profile.profileImagePath!.isNotEmpty
                                ? Image.asset(
                                    profile.profileImagePath!,
                                    fit: BoxFit.cover,
                                    errorBuilder: (_, __, ___) => const Icon(
                                      Icons.person,
                                      size: 56,
                                      color: Colors.white,
                                    ),
                                  )
                                : const Icon(
                                    Icons.person,
                                    size: 56,
                                    color: Colors.white,
                                  ),
                          ),
                        ),

                        const SizedBox(height: 18),

                        Text(
                          profile.name,
                          style: const TextStyle(
                            color: _textDark,
                            fontSize: 24,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),

                  Container(height: 12, color: _sectionBg),

                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        InkWell(
                          onTap: _goToProfileEdit,
                          borderRadius: BorderRadius.circular(12),
                          child: const Padding(
                            padding: EdgeInsets.symmetric(vertical: 4),
                            child: Text(
                              'Basic Info',
                              style: TextStyle(
                                color: _textDark,
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 18),

                        _InfoRow(
                          label: 'Name',
                          value: profile.name,
                          onTap: _goToProfileEdit,
                        ),
                        const SizedBox(height: 12),

                        _InfoRow(
                          label: 'Date of Birth',
                          value: profile.dateOfBirth,
                          onTap: _goToProfileEdit,
                        ),
                        const SizedBox(height: 12),

                        _InfoRow(
                          label: 'Mobile Number',
                          value: profile.mobileNumber,
                          trailingText: 'Edit',
                          onTap: _goToProfileEdit,
                        ),
                        const SizedBox(height: 12),

                        _InfoRow(
                          label: 'Email Address',
                          value: profile.email,
                          trailingText: 'Edit',
                          onTap: _goToProfileEdit,
                        ),
                      ],
                    ),
                  ),

                  Container(height: 12, color: _sectionBg),

                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Expanded(
                              child: Text(
                                'Set up your dining preferences',
                                style: TextStyle(
                                  color: _textDark,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            InkWell(
                              onTap: () => _showDietaryInfo(context),
                              borderRadius: BorderRadius.circular(20),
                              child: const Padding(
                                padding: EdgeInsets.all(2),
                                child: Icon(
                                  Icons.info_outline,
                                  size: 24,
                                  color: _textDark,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),

                        _PreferenceCard(
                          label: 'Your favorite cuisines',
                          value: _joinOrFallback(_preferences.favoriteCuisines),
                          showArrow: true,
                          onTap: () => _openDiningPreferences(0),
                        ),
                        const SizedBox(height: 12),

                        _PreferenceCard(
                          label: 'Your hospitality preferences',
                          value: _joinOrFallback(_preferences.diningStyles),
                          showArrow: true,
                          onTap: () => _openDiningPreferences(1),
                        ),
                        const SizedBox(height: 12),

                        _PreferenceCard(
                          label: 'Your dietary restrictions',
                          value:
                              _joinOrFallback(_preferences.dietaryRestrictions),
                          showArrow: true,
                          onTap: () => _openDiningPreferences(2),
                        ),
                        const SizedBox(height: 12),

                        _PreferenceCard(
                          label: 'Additional dietary notes',
                          value: _notesOrFallback(_preferences.additionalNotes),
                          showArrow: true,
                          onTap: () => _openDiningPreferences(3),
                        ),
                      ],
                    ),
                  ),

                  Container(height: 12, color: _sectionBg),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  final String? trailingText;
  final VoidCallback? onTap;

  const _InfoRow({
    required this.label,
    required this.value,
    this.trailingText,
    this.onTap,
  });

  static const Color _textDark = Color(0xFF383838);
  static const Color _textGray = Color(0xFF9AA0A6);

  @override
  Widget build(BuildContext context) {
    final row = Row(
      children: [
        SizedBox(
          width: 120,
          child: Text(
            label,
            style: const TextStyle(
              color: _textGray,
              fontSize: 14,
              fontWeight: FontWeight.w400,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              color: _textDark,
              fontSize: 14,
              fontWeight: FontWeight.w400,
            ),
          ),
        ),
        if (trailingText != null)
          Text(
            trailingText!,
            style: const TextStyle(
              color: _textDark,
              fontSize: 14,
              fontWeight: FontWeight.w400,
            ),
          ),
      ],
    );

    if (onTap == null) return row;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: row,
      ),
    );
  }
}

class _PreferenceCard extends StatelessWidget {
  final String label;
  final String value;
  final bool showArrow;
  final VoidCallback? onTap;

  const _PreferenceCard({
    required this.label,
    required this.value,
    this.showArrow = false,
    this.onTap,
  });

  static const Color _textDark = Color(0xFF303030);
  static const Color _border = Color(0xFFE5E5EA);

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border.all(color: _border),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: const TextStyle(
                      color: _textDark,
                      fontSize: 14,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    value,
                    style: const TextStyle(
                      color: _textDark,
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            if (showArrow)
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