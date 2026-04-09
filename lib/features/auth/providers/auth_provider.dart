import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:inersia_supabase/features/auth/services/auth_service.dart';
import 'package:inersia_supabase/config/supabase_config.dart';
import 'package:inersia_supabase/features/user/mainPage/providers/main_page_provider.dart';
import 'package:inersia_supabase/features/user/mainPage/providers/read_page_provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

final authServiceProvider = Provider((_) => AuthService());

final authStateProvider = StreamProvider<AuthState>((ref) {
  return supabaseConfig.client.auth.onAuthStateChange;
});

final currentUserIdProvider = Provider<String?>((ref) {
  final authState = ref.watch(authStateProvider).asData?.value;
  return authState?.session?.user.id ??
      supabaseConfig.client.auth.currentUser?.id;
});

final userRoleProvider = FutureProvider<String?>((ref) async {
  final userId = ref.watch(currentUserIdProvider);
  if (userId == null) return null;

  try {
    final data = await supabaseConfig.client
        .from('users')
        .select('role')
        .eq('id', userId)
        .single();
    return data['role'] as String?;
  } catch (_) {
    return 'user';
  }
});

class AuthNotifier extends Notifier<AsyncValue<void>> {
  @override
  AsyncValue<void> build() {
    return const AsyncData(null);
  }

  Future<void> login(String email, String password) async {
    state = const AsyncLoading();
    try {
      await ref.read(authServiceProvider).login(email, password);
      _invalidateUserProviders();
      state = const AsyncData(null);
    } catch (e, s) {
      state = AsyncError(e, s);
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
    } catch (e, s) {
      state = AsyncError(e, s);
    }
  }

  Future<void> logout() async {
    state = const AsyncLoading();
    try {
      await ref.read(authServiceProvider).logout();
      _invalidateUserProviders();
      state = const AsyncData(null);
    } catch (e, s) {
      state = AsyncError(e, s);
    }
  }

  Future<void> forgotPassword(String email) async {
    state = const AsyncLoading();
    try {
      await ref.read(authServiceProvider).sendPasswordResetEmail(email);
      state = const AsyncData(null);
    } catch (e, s) {
      state = AsyncError(e, s);
    }
  }

  Future<void> resetPassword(String newPassword) async {
    state = const AsyncLoading();
    try {
      await ref.read(authServiceProvider).updateUserPassword(newPassword);
      state = const AsyncData(null);
    } catch (e, s) {
      state = AsyncError(e, s);
    }
  }

  void _invalidateUserProviders() {
    ref.invalidate(userRoleProvider);
    ref.invalidate(articleListProvider);
    ref.invalidate(likeProvider);
    ref.invalidate(bookmarkProvider);
    ref.invalidate(followProvider);
    ref.invalidate(cardLikeStatusProvider);
    ref.invalidate(commentWriteProvider);
    ref.invalidate(categoriesProvider);
  }
}

final authProvider = NotifierProvider<AuthNotifier, AsyncValue<void>>(
  () => AuthNotifier(),
);
