import 'package:flutter/material.dart';
import 'package:yumbook_app/state/user_profile_store.dart';

class ProfileEditScreen extends StatefulWidget {
  const ProfileEditScreen({super.key});

  @override
  State<ProfileEditScreen> createState() => _ProfileEditScreenState();
}

class _ProfileEditScreenState extends State<ProfileEditScreen> {
  static const Color _textDark = Color(0xFF383838);
  static const Color _textGray = Color(0xFF9AA0A6);
  static const Color _border = Color(0xFFE5E5EA);
  static const Color _sectionBg = Color(0xFFF2F2F7);
  static const Color _orange = Color(0xFFD45425);

  late final TextEditingController _nameController;
  late final TextEditingController _dobController;
  late final TextEditingController _mobileController;
  late final TextEditingController _emailController;

  String? _selectedImagePath;
  bool _isSaving = false;

  final List<String> _avatarOptions = const [
    'assets/images/profile/avatar_1.png',
    'assets/images/profile/avatar_2.png',
    'assets/images/profile/avatar_3.png',
    'assets/images/profile/avatar_4.png',
  ];

  @override
  void initState() {
    super.initState();
    final profile = UserProfileStore.instance.profile;

    _nameController = TextEditingController(text: profile.name);
    _dobController = TextEditingController(text: profile.dateOfBirth);
    _mobileController = TextEditingController(text: profile.mobileNumber);
    _emailController = TextEditingController(text: profile.email);
    _selectedImagePath = profile.profileImagePath;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _dobController.dispose();
    _mobileController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _saveProfile() async {
    if (_isSaving) return;
    final store = UserProfileStore.instance;
    final current = store.profile;

    setState(() => _isSaving = true);
    try {
      await store.updateProfile(
        current.copyWith(
          name: _nameController.text.trim(),
          dateOfBirth: _dobController.text.trim(),
          mobileNumber: _mobileController.text.trim(),
          email: _emailController.text.trim(),
          profileImagePath: _selectedImagePath,
          clearProfileImage: _selectedImagePath == null,
        ),
      );
      if (!mounted) return;
      Navigator.pop(context);
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to save profile: $error')),
      );
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  void _showAvatarPicker() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Choose profile image',
                  style: TextStyle(
                    color: _textDark,
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    for (final path in _avatarOptions)
                      GestureDetector(
                        onTap: () {
                          setState(() {
                            _selectedImagePath = path;
                          });
                          Navigator.pop(context);
                        },
                        child: Container(
                          width: 72,
                          height: 72,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: _selectedImagePath == path
                                  ? _orange
                                  : _border,
                              width: 2,
                            ),
                          ),
                          clipBehavior: Clip.antiAlias,
                          child: Image.asset(
                            path,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => const ColoredBox(
                              color: Color(0xFFD5EAF7),
                              child: Icon(
                                Icons.person,
                                color: Colors.white,
                                size: 30,
                              ),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 16),
                TextButton(
                  onPressed: () {
                    setState(() {
                      _selectedImagePath = null;
                    });
                    Navigator.pop(context);
                  },
                  child: const Text(
                    'Remove current photo',
                    style: TextStyle(color: _textDark),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildTextField({
    required String label,
    required TextEditingController controller,
    String? hintText,
    TextInputType? keyboardType,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: _textDark,
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          keyboardType: keyboardType,
          decoration: InputDecoration(
            hintText: hintText,
            hintStyle: const TextStyle(color: _textGray),
            filled: true,
            fillColor: Colors.white,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 14,
              vertical: 14,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: _border),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: _orange),
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        surfaceTintColor: Colors.white,
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            color: _textDark,
            size: 22,
          ),
        ),
        centerTitle: true,
        title: const Text(
          'Edit Profile',
          style: TextStyle(
            color: _textDark,
            fontSize: 22,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 4),
                    Center(
                      child: Column(
                        children: [
                          GestureDetector(
                            onTap: _showAvatarPicker,
                            child: Container(
                              width: 120,
                              height: 120,
                              decoration: const BoxDecoration(
                                color: Color(0xFFD9D9D9),
                                shape: BoxShape.circle,
                              ),
                              clipBehavior: Clip.antiAlias,
                              child: _selectedImagePath != null &&
                                      _selectedImagePath!.isNotEmpty
                                  ? Image.asset(
                                      _selectedImagePath!,
                                      fit: BoxFit.cover,
                                      errorBuilder: (_, __, ___) =>
                                          const Icon(
                                        Icons.person,
                                        size: 52,
                                        color: Colors.white,
                                      ),
                                    )
                                  : const Icon(
                                      Icons.person,
                                      size: 52,
                                      color: Colors.white,
                                    ),
                            ),
                          ),
                          const SizedBox(height: 10),
                          TextButton(
                            onPressed: _showAvatarPicker,
                            child: const Text(
                              'Change profile photo',
                              style: TextStyle(
                                color: _orange,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 20),
                    Container(height: 12, color: _sectionBg),
                    const SizedBox(height: 20),

                    _buildTextField(
                      label: 'Name',
                      controller: _nameController,
                      hintText: 'Enter your name',
                    ),
                    const SizedBox(height: 16),

                    _buildTextField(
                      label: 'Date of Birth',
                      controller: _dobController,
                      hintText: 'e.g. Jan 1, 1991',
                    ),
                    const SizedBox(height: 16),

                    _buildTextField(
                      label: 'Mobile Number',
                      controller: _mobileController,
                      hintText: '010-1010-1010',
                      keyboardType: TextInputType.phone,
                    ),
                    const SizedBox(height: 16),

                    _buildTextField(
                      label: 'Email Address',
                      controller: _emailController,
                      hintText: 'test@mail.com',
                      keyboardType: TextInputType.emailAddress,
                    ),
                  ],
                ),
              ),
            ),

            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
              child: SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _isSaving ? null : _saveProfile,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _orange,
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: _orange.withValues(alpha: 0.4),
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: _isSaving
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor:
                                AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : const Text(
                          'Save',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}