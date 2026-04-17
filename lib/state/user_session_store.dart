import 'package:flutter/foundation.dart';

class AppUser {
  final String id;
  final String name;
  final String email;
  final String? profileImageUrl;

  const AppUser({
    required this.id,
    required this.name,
    required this.email,
    this.profileImageUrl,
  });

  AppUser copyWith({
    String? id,
    String? name,
    String? email,
    String? profileImageUrl,
  }) {
    return AppUser(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      profileImageUrl: profileImageUrl ?? this.profileImageUrl,
    );
  }
}

class UserSessionStore extends ChangeNotifier {
  UserSessionStore._();
  static final UserSessionStore instance = UserSessionStore._();

  AppUser? _currentUser = const AppUser(
    id: 'user_001',
    name: 'Amy',
    email: 'amy@yumbook.com',
    profileImageUrl: null,
  );

  AppUser? get currentUser => _currentUser;
  bool get isLoggedIn => _currentUser != null;
  String? get userId => _currentUser?.id;

  void login(AppUser user) {
    _currentUser = user;
    notifyListeners();
  }

  void logout() {
    _currentUser = null;
    notifyListeners();
  }

  void updateProfile({
    String? name,
    String? email,
    String? profileImageUrl,
  }) {
    if (_currentUser == null) return;

    _currentUser = _currentUser!.copyWith(
      name: name,
      email: email,
      profileImageUrl: profileImageUrl,
    );
    notifyListeners();
  }
}