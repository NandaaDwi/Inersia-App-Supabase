import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:inersia_supabase/config/supabase_config.dart';
import 'package:inersia_supabase/features/auth/providers/auth_provider.dart';
import 'package:inersia_supabase/features/admin/dashboard/admin_dashboard.dart';
import 'package:inersia_supabase/features/admin/manageArticle/screens/admin_article_management_screen.dart';
import 'package:inersia_supabase/features/admin/manageCategoryTag/screens/taxonomy_management_screen.dart';
import 'package:inersia_supabase/features/admin/manageUser/screens/user_management_screen.dart';
import 'package:inersia_supabase/features/auth/screens/forgot_password_screen.dart';
import 'package:inersia_supabase/features/auth/screens/login_screen.dart';
import 'package:inersia_supabase/features/auth/screens/register_screen.dart';
import 'package:inersia_supabase/features/auth/screens/reset_password_screen.dart';
import 'package:inersia_supabase/features/user/article/screens/user_article_editor_screen.dart';
import 'package:inersia_supabase/features/user/mainPage/screens/article_read_screen.dart';
import 'package:inersia_supabase/features/user/mainPage/screens/main_page.dart';
import 'package:inersia_supabase/features/user/profile/screens/profile_screen.dart';
import 'package:inersia_supabase/models/article_model.dart';

Page<void> buildPageTransition<T>({
  required GoRouterState state,
  required Widget child,
}) {
  return CustomTransitionPage<T>(
    key: state.pageKey,
    child: child,
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      return FadeTransition(opacity: animation, child: child);
    },
    transitionDuration: const Duration(milliseconds: 150),
  );
}

final routerProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authStateProvider);
  final userRole = ref.watch(userRoleProvider);

  return GoRouter(
    initialLocation: '/',
    refreshListenable: RouterNotifier(ref),
    redirect: (context, state) {
      final session = supabaseConfig.client.auth.currentSession;
      final isLoggingIn =
          state.matchedLocation == '/login' ||
          state.matchedLocation == '/register' ||
          state.matchedLocation == '/forgot-password';

      if (session == null) return isLoggingIn ? null : '/login';
      if (isLoggingIn) return '/';

      final adminRoutes = [
        '/manageUser',
        '/manageCategoryTag',
        '/manageArticles',
      ];
      final isAdminRoute = adminRoutes.contains(state.matchedLocation);

      if (isAdminRoute && userRole.value != 'admin') return '/';

      return null;
    },
    routes: [
      GoRoute(
        path: '/login',
        pageBuilder: (context, state) =>
            buildPageTransition(state: state, child: const LoginScreen()),
      ),
      GoRoute(
        path: '/register',
        pageBuilder: (context, state) =>
            buildPageTransition(state: state, child: const RegisterScreen()),
      ),
      GoRoute(
        path: '/forgot-password',
        pageBuilder: (context, state) => buildPageTransition(
          state: state,
          child: const ForgotPasswordScreen(),
        ),
      ),
      GoRoute(
        path: '/reset-password',
        pageBuilder: (context, state) => buildPageTransition(
          state: state,
          child: const ResetPasswordScreen(),
        ),
      ),
      GoRoute(
        path: '/',
        pageBuilder: (context, state) => buildPageTransition(
          state: state,
          child: userRole.when(
            data: (role) =>
                role == 'admin' ? const AdminDashboard() : const MainPage(),
            loading: () => const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            ),
            error: (_, __) => const MainPage(),
          ),
        ),
      ),
      GoRoute(
        path: '/home',
        pageBuilder: (context, state) =>
            buildPageTransition(state: state, child: const MainPage()),
      ),
      GoRoute(
        path: '/article/:id',
        pageBuilder: (context, state) {
          final article = state.extra as ArticleModel?;
          return buildPageTransition(
            state: state,
            child: article != null
                ? ArticleReadScreen(article: article)
                : const SizedBox(),
          );
        },
      ),
      GoRoute(
        path: '/profile',
        pageBuilder: (context, state) =>
            buildPageTransition(state: state, child: const ProfilePage()),
      ),
      GoRoute(
        path: '/create-article',
        pageBuilder: (context, state) =>
            buildPageTransition(state: state, child: const UserArticleEditorScreen()),
      ),
      GoRoute(
        path: '/manageUser',
        pageBuilder: (context, state) => buildPageTransition(
          state: state,
          child: const UserManagementScreen(),
        ),
      ),
      GoRoute(
        path: '/manageCategoryTag',
        pageBuilder: (context, state) => buildPageTransition(
          state: state,
          child: const TaxonomyManagementScreen(),
        ),
      ),
      GoRoute(
        path: '/manageArticles',
        pageBuilder: (context, state) => buildPageTransition(
          state: state,
          child: const AdminArticleManagementScreen(),
        ),
      ),
    ],
  );
});

class RouterNotifier extends ChangeNotifier {
  RouterNotifier(Ref ref) {
    ref.listen(authStateProvider, (_, __) => notifyListeners());
    ref.listen(userRoleProvider, (_, __) => notifyListeners());
  }
}
