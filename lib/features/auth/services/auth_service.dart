import 'package:inersia_supabase/config/supabase_config.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AuthService {
  final _client = supabaseConfig.client;

  Future<void> register({
    required String email,
    required String password,
    required String name,
    required String username,
  }) async {
    final existing = await _client
        .from('users')
        .select('id')
        .eq('username', username.trim().toLowerCase())
        .maybeSingle();

    if (existing != null) {
      throw const AuthException(
        'Username sudah digunakan. Pilih username lain.',
      );
    }

    await _client.auth.signUp(
      email: email,
      password: password,
      data: {'name': name.trim(), 'username': username.trim().toLowerCase()},
      emailRedirectTo: 'inersia-app://login',
    );
  }

  Future<void> login(String email, String password) async {
    final response = await _client.auth.signInWithPassword(
      email: email,
      password: password,
    );

    if (response.user != null) {
      try {
        final userData = await _client
            .from('users')
            .select('status')
            .eq('id', response.user!.id)
            .single();

        if (userData['status'] == 'banned') {
          await logout();
          throw const AuthException('user_banned');
        }
        if (userData['status'] == 'inactive') {
          await logout();
          throw const AuthException('inactive');
        }
      } catch (e) {
        if (e is AuthException) rethrow;
      }
    }
  }

  Future<void> logout() async {
    await _client.auth.signOut();
  }

  Future<void> sendPasswordResetEmail(String email) async {
    await _client.auth.resetPasswordForEmail(email);
  }

  Future<void> verifyResetOtp({
    required String email,
    required String token,
  }) async {
    await _client.auth.verifyOTP(
      email: email,
      token: token,
      type: OtpType.recovery,
    );
  }

  Future<void> updateUserPassword(String newPassword) async {
    await _client.auth.updateUser(UserAttributes(password: newPassword));
  }
}
