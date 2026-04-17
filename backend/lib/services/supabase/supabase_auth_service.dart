import 'package:supabase/supabase.dart';
import 'package:yumbook_backend/core/supabase/supabase_client.dart';

class SupabaseAuthService {
  static final SupabaseClient _client = SupabaseClientManager.client;

  static User? get currentUser => _client.auth.currentUser;
  static Session? get currentSession => _client.auth.currentSession;

  static Future<void> sendSignUpOtp({
    required String email,
  }) async {
    await _client.auth.signInWithOtp(
      email: email,
      shouldCreateUser: true,
    );
  }

  static Future<AuthResponse> verifyEmailOtp({
    required String email,
    required String token,
  }) async {
    return await _client.auth.verifyOTP(
      email: email,
      token: token,
      type: OtpType.email,
    );
  }

  static Future<void> completeSignUp({
    required String email,
    required String password,
    required String userName,
  }) async {
    final user = _client.auth.currentUser;

    if (user == null) {
      throw const AuthException(
        'No verified session found. Please verify your email first.',
      );
    }

    if ((user.email ?? '').toLowerCase() != email.toLowerCase()) {
      throw const AuthException(
        'Verified email does not match the requested email.',
      );
    }

    await _client.auth.updateUser(
      UserAttributes(
        password: password,
        data: {
          'username': userName,
          'full_name': userName,
        },
      ),
    );

    await _client.from('profiles').upsert(
      {
        'id': user.id,
        'email': email,
        'username': userName,
        'full_name': userName,
        'updated_at': DateTime.now().toIso8601String(),
      },
      onConflict: 'id',
    );
  }

  static Future<AuthResponse> signIn({
    required String email,
    required String password,
  }) async {
    return await _client.auth.signInWithPassword(
      email: email,
      password: password,
    );
  }

  static Future<void> sendPasswordReset({
    required String email,
  }) async {
      await Supabase.instance.client.auth.resetPasswordForEmail(
        email,
        redirectTo: 'yumbook://reset-password',
      );
  }

  static Future<void> signOut() async {
    await _client.auth.signOut();
  }
}