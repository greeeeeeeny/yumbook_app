import 'package:flutter/foundation.dart';
import 'package:yumbook_app/models/user_profile.dart';

class UserProfileStore extends ChangeNotifier {
  UserProfileStore._();
  static final UserProfileStore instance = UserProfileStore._();

  UserProfile _profile = const UserProfile(
    name: 'Amy',
    dateOfBirth: 'Jan 1, 1991',
    mobileNumber: '010-1010-1010',
    email: 'test@mail.com',
    profileImagePath: null,
  );

  UserProfile get profile => _profile;

  void updateProfile(UserProfile profile) {
    _profile = profile;
    notifyListeners();
  }

  void updateName(String value) {
    _profile = _profile.copyWith(name: value);
    notifyListeners();
  }

  void updateDateOfBirth(String value) {
    _profile = _profile.copyWith(dateOfBirth: value);
    notifyListeners();
  }

  void updateMobileNumber(String value) {
    _profile = _profile.copyWith(mobileNumber: value);
    notifyListeners();
  }

  void updateEmail(String value) {
    _profile = _profile.copyWith(email: value);
    notifyListeners();
  }

  void updateProfileImagePath(String? value) {
    _profile = _profile.copyWith(
      profileImagePath: value,
      clearProfileImage: value == null,
    );
    notifyListeners();
  }
}