import 'package:flutter_riverpod/legacy.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:inersia_supabase/features/auth/services/auth_service.dart';
import 'package:inersia_supabase/config/supabase_config.dart';

final authServiceProvider = Provider((ref) => AuthService());

final authStateProvider = StreamProvider((ref) {
  return supabaseConfig.client.auth.onAuthStateChange;
});

final userRoleProvider = FutureProvider<String?>((ref) async {
  final authState = ref.watch(authStateProvider).value;
  final session =
      authState?.session ?? supabaseConfig.client.auth.currentSession;

  if (session == null) return null;

  try {
    final data = await supabaseConfig.client
        .from('users')
        .select('role')
        .eq('id', session.user.id)
        .single();
    return data['role'] as String?;
  } catch (_) {
    return 'user';
  }
});

final authProvider = StateNotifierProvider<AuthNotifier, AsyncValue<void>>(
  (ref) => AuthNotifier(ref),
);

class AuthNotifier extends StateNotifier<AsyncValue<void>> {
  final Ref ref;

  AuthNotifier(this.ref) : super(const AsyncData(null));

  Future<void> login(String email, String password) async {
    state = const AsyncLoading();
    try {
      await ref.read(authServiceProvider).login(email, password);
      ref.invalidate(userRoleProvider);
      state = const AsyncData(null);
    } catch (e, stack) {
      state = AsyncError(e, stack);
    }
  }

  Future<void> register(
    String email,
    String password,
    String name,
    String username,
  ) async {
    state = const AsyncLoading();
    try {
      await ref
          .read(authServiceProvider)
          .register(
            email: email,
            password: password,
            name: name,
            username: username,
          );
      state = const AsyncData(null);
    } catch (e, stack) {
      state = AsyncError(e, stack);
    }
  }

  Future<void> logout() async {
    state = const AsyncLoading();
    try {
      await ref.read(authServiceProvider).logout();
      ref.invalidate(userRoleProvider);
      state = const AsyncData(null);
    } catch (e, stack) {
      state = AsyncError(e, stack);
    }
  }

  Future<void> forgotPassword(String email) async {
    state = const AsyncLoading();
    try {
      await ref.read(authServiceProvider).sendPasswordResetEmail(email);
      state = const AsyncData(null);
    } catch (e, stack) {
      state = AsyncError(e, stack);
    }
  }

  Future<void> resetPassword(String newPassword) async {
    state = const AsyncLoading();
    try {
      await ref.read(authServiceProvider).updateUserPassword(newPassword);
      state = const AsyncData(null);
    } catch (e, stack) {
      state = AsyncError(e, stack);
    }
  }
}
