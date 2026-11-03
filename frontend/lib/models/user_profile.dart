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

  /// 빈 프로필(로그인 전/로드 전 초기 상태).
  static const empty = UserProfile(
    name: '',
    dateOfBirth: '',
    mobileNumber: '',
    email: '',
    profileImagePath: null,
  );

  /// 백엔드(`/api/account/profile/`) 응답을 모델로 변환.
  /// avatar_url ↔ profileImagePath 로 매핑한다.
  factory UserProfile.fromJson(Map<String, dynamic> json) {
    final avatar = json['avatar_url'] as String?;
    return UserProfile(
      name: json['name'] as String? ?? '',
      dateOfBirth: json['date_of_birth'] as String? ?? '',
      mobileNumber: json['mobile_number'] as String? ?? '',
      email: json['email'] as String? ?? '',
      profileImagePath: (avatar != null && avatar.isNotEmpty) ? avatar : null,
    );
  }

  /// PATCH 본문. profileImagePath → avatar_url.
  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'date_of_birth': dateOfBirth,
      'mobile_number': mobileNumber,
      'email': email,
      'avatar_url': profileImagePath ?? '',
    };
  }
}