class UserProfile {
  final String name;
  final String dateOfBirth;
  final String mobileNumber;
  final String email;
  final String? profileImagePath;

  const UserProfile({
    required this.name,
    required this.dateOfBirth,
    required this.mobileNumber,
    required this.email,
    this.profileImagePath,
  });

  UserProfile copyWith({
    String? name,
    String? dateOfBirth,
    String? mobileNumber,
    String? email,
    String? profileImagePath,
    bool clearProfileImage = false,
  }) {
    return UserProfile(
      name: name ?? this.name,
      dateOfBirth: dateOfBirth ?? this.dateOfBirth,
      mobileNumber: mobileNumber ?? this.mobileNumber,
      email: email ?? this.email,
      profileImagePath:
          clearProfileImage ? null : (profileImagePath ?? this.profileImagePath),
    );
  }
}