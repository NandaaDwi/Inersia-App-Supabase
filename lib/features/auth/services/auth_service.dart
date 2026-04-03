import 'package:inersia_supabase/config/supabase_config.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AuthService {
  final client = supabaseConfig.client;

  Future<void> register({
    required String email,
    required String password,
    required String name,
    required String username,
  }) async {
    await client.auth.signUp(
      email: email,
      password: password,
      data: {'name': name, 'username': username},
      emailRedirectTo: 'io.supabase.flutter://login',
    );
  }

  Future<void> login(String email, String password) async {
    final response = await client.auth.signInWithPassword(
      email: email,
      password: password,
    );

    if (response.user != null) {
      final userData = await client
          .from('users')
          .select('status')
          .eq('id', response.user!.id)
          .single();

      if (userData['status'] == 'banned') {
        await logout();
        throw const AuthException('user_banned');
      }
    }
  }

  Future<void> logout() async {
    await client.auth.signOut();
  }

  Future<void> sendPasswordResetEmail(String email) async {
    await client.auth.resetPasswordForEmail(
      email,
      redirectTo: 'io.supabase.flutter://reset-password',
    );
  }

  Future<void> updateUserPassword(String newPassword) async {
    await client.auth.updateUser(UserAttributes(password: newPassword));
  }
}
