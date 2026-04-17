import 'package:shared_preferences/shared_preferences.dart';

class LocalAuthService {
  static const String _registeredEmailKey = 'registered_email';
  static const String _registeredPasswordKey = 'registered_password';
  static const String _registeredUserNameKey = 'registered_user_name';
  static const String _lastSignedInEmailKey = 'last_signed_in_email';
  static const String _pendingSignUpEmailKey = 'pending_sign_up_email';

  static Future<void> savePendingSignUpEmail(String email) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_pendingSignUpEmailKey, email.trim());
  }

  static Future<String?> getPendingSignUpEmail() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_pendingSignUpEmailKey);
  }

  static Future<void> clearPendingSignUpEmail() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_pendingSignUpEmailKey);
  }

  static Future<void> registerUser({
    required String email,
    required String password,
    required String userName,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_registeredEmailKey, email.trim());
    await prefs.setString(_registeredPasswordKey, password);
    await prefs.setString(_registeredUserNameKey, userName.trim());
    await prefs.setString(_lastSignedInEmailKey, email.trim());
  }

  static Future<bool> signIn({
    required String email,
    required String password,
  }) async {
    final prefs = await SharedPreferences.getInstance();

    final savedEmail = prefs.getString(_registeredEmailKey);
    final savedPassword = prefs.getString(_registeredPasswordKey);

    final success =
        savedEmail == email.trim() && savedPassword == password.trim();

    if (success) {
      await prefs.setString(_lastSignedInEmailKey, email.trim());
    }

    return success;
  }

  static Future<String?> getRegisteredEmail() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_registeredEmailKey);
  }

  static Future<String?> getRegisteredUserName() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_registeredUserNameKey);
  }

  static Future<String?> getLastSignedInEmail() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_lastSignedInEmailKey);
  }

  static Future<bool> hasRegisteredUser() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.containsKey(_registeredEmailKey) &&
        prefs.containsKey(_registeredPasswordKey);
  }
}