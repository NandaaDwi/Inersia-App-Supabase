import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:inersia_supabase/config/supabase_config.dart';
import 'package:inersia_supabase/features/admin/comments/screens/admin_comment_screen.dart';
import 'package:inersia_supabase/features/admin/reports/screens/admin_notiffication_screen.dart';
import 'package:inersia_supabase/features/admin/reports/screens/admin_report_screen.dart';
import 'package:inersia_supabase/features/auth/providers/auth_provider.dart';
import 'package:inersia_supabase/features/admin/dashboard/screens/admin_dashboard.dart';
import 'package:inersia_supabase/features/admin/manageArticle/screens/admin_article_management_screen.dart';
import 'package:inersia_supabase/features/admin/manageCategoryTag/screens/taxonomy_management_screen.dart';
import 'package:inersia_supabase/features/admin/manageUser/screens/user_management_screen.dart';
import 'package:inersia_supabase/features/auth/screens/forgot_password_screen.dart';
import 'package:inersia_supabase/features/auth/screens/login_screen.dart';
import 'package:inersia_supabase/features/auth/screens/register_screen.dart';
import 'package:inersia_supabase/features/auth/screens/reset_password_screen.dart';
import 'package:inersia_supabase/features/user/article/screens/user_article_editor_screen.dart';
import 'package:inersia_supabase/features/user/bookmark/screens/bookmark_screen.dart';
import 'package:inersia_supabase/features/user/mainPage/screens/article_read_screen.dart';
import 'package:inersia_supabase/features/user/mainPage/screens/main_page.dart';
import 'package:inersia_supabase/features/user/notification/screens/user_notification_screen.dart';
import 'package:inersia_supabase/features/user/profile/screens/draft_screen.dart';
import 'package:inersia_supabase/features/user/profile/screens/edit_profile_screen.dart';
import 'package:inersia_supabase/features/user/profile/screens/profile_screen.dart';
import 'package:inersia_supabase/features/user/search/screens/search_screen.dart';
import 'package:inersia_supabase/features/user/search/screens/search_user_profile_screen.dart';
import 'package:inersia_supabase/models/article_model.dart';

Page<void> _buildPage<T>({
  required GoRouterState state,
  required Widget child,
}) {
  return CustomTransitionPage<T>(
    key: state.pageKey,
    child: child,
    transitionsBuilder: (_, animation, __, child) =>
        FadeTransition(opacity: animation, child: child),
    transitionDuration: const Duration(milliseconds: 150),
  );
}

final routerProvider = Provider<GoRouter>((ref) {
  final notifier = RouterNotifier(ref);

  return GoRouter(
    initialLocation: '/',
    refreshListenable: notifier,
    redirect: (context, state) {
      final location = state.matchedLocation;
      final session = supabaseConfig.client.auth.currentSession;
      final isAuthenticated = session != null;

      final isAuthRoute =
          location == '/login' ||
          location == '/register' ||
          location == '/forgot-password' ||
          location == '/reset-password';

      if (!isAuthenticated) {
        return isAuthRoute ? null : '/login';
      }

      if (isAuthenticated && isAuthRoute) {
        return '/';
      }

      final roleAsync = ref.read(userRoleProvider);
      final userRole = roleAsync.asData?.value;
      const adminRoutes = [
        '/manageUser',
        '/manageCategoryTag',
        '/manageArticles',
        '/reports',
        '/manageComments',
        '/admin-notiffications',
      ];

      if (adminRoutes.contains(location) &&
          userRole != null &&
          userRole != 'admin') {
        return '/';
      }

      return null;
    },
    routes: [
      GoRoute(
        path: '/login',
        pageBuilder: (context, state) =>
            _buildPage(state: state, child: const LoginScreen()),
      ),
      GoRoute(
        path: '/register',
        pageBuilder: (context, state) =>
            _buildPage(state: state, child: const RegisterScreen()),
      ),
      GoRoute(
        path: '/forgot-password',
        pageBuilder: (context, state) =>
            _buildPage(state: state, child: const ForgotPasswordScreen()),
      ),
      GoRoute(
        path: '/reset-password',
        pageBuilder: (context, state) =>
            _buildPage(state: state, child: const ResetPasswordScreen()),
      ),
      GoRoute(
        path: '/',
        pageBuilder: (context, state) {
          return _buildPage(
            state: state,
            child: Consumer(
              builder: (context, ref, _) {
                final roleAsync = ref.watch(userRoleProvider);
                return roleAsync.when(
                  data: (role) => role == 'admin'
                      ? const AdminDashboard()
                      : const MainPage(),
                  loading: () => const Scaffold(
                    backgroundColor: Color(0xFF0D0D0D),
                    body: Center(
                      child: CircularProgressIndicator(
                        color: Color(0xFF2563EB),
                      ),
                    ),
                  ),
                  error: (_, __) => const MainPage(),
                );
              },
            ),
          );
        },
      ),
      GoRoute(
        path: '/home',
        pageBuilder: (context, state) =>
            _buildPage(state: state, child: const MainPage()),
      ),
      GoRoute(
        path: '/search',
        pageBuilder: (context, state) =>
            _buildPage(state: state, child: const SearchScreen()),
      ),
      GoRoute(
        path: '/bookmark',
        pageBuilder: (context, state) =>
            _buildPage(state: state, child: const BookmarkScreen()),
      ),
      GoRoute(
        path: '/profile/drafts',
        pageBuilder: (context, state) =>
            _buildPage(state: state, child: const DraftScreen()),
      ),
      GoRoute(
        path: '/profile/edit',
        pageBuilder: (context, state) =>
            _buildPage(state: state, child: const EditProfileScreen()),
      ),
      GoRoute(
        path: '/user/:id',
        pageBuilder: (context, state) {
          final userId = state.pathParameters['id']!;
          return _buildPage(
            state: state,
            child: SearchUserProfileScreen(userId: userId),
          );
        },
      ),
      GoRoute(
        path: '/article/:id',
        redirect: (context, state) {
          final article = state.extra;
          if (article == null || article is! ArticleModel) {
            return '/';
          }
          return null;
        },
        pageBuilder: (context, state) {
          final article = state.extra as ArticleModel;
          return _buildPage(
            state: state,
            child: ArticleReadScreen(article: article),
          );
        },
      ),
      GoRoute(
        path: '/notifications',
        pageBuilder: (context, state) =>
            _buildPage(state: state, child: const UserNotificationScreen()),
      ),
      GoRoute(
        path: '/profile',
        pageBuilder: (context, state) =>
            _buildPage(state: state, child: const ProfilePage()),
      ),
      GoRoute(
        path: '/create-article',
        pageBuilder: (context, state) =>
            _buildPage(state: state, child: const UserArticleEditorScreen()),
      ),
      GoRoute(
        path: '/manageUser',
        pageBuilder: (context, state) =>
            _buildPage(state: state, child: const UserManagementScreen()),
      ),
      GoRoute(
        path: '/manageCategoryTag',
        pageBuilder: (context, state) =>
            _buildPage(state: state, child: const TaxonomyManagementScreen()),
      ),
      GoRoute(
        path: '/manageArticles',
        pageBuilder: (context, state) => _buildPage(
          state: state,
          child: const AdminArticleManagementScreen(),
        ),
      ),
      GoRoute(
        path: '/manageComments',
        pageBuilder: (context, state) =>
            _buildPage(state: state, child: const AdminCommentScreen()),
      ),
      GoRoute(
        path: '/reports',
        pageBuilder: (context, state) =>
            _buildPage(state: state, child: const AdminReportScreen()),
      ),
      GoRoute(
        path: '/admin-notiffications',
        pageBuilder: (context, state) =>
            _buildPage(state: state, child: const AdminNotificationScreen()),
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
