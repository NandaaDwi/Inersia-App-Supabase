import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:inersia_supabase/features/user/search/services/search_user_profile_service.dart';
import 'package:inersia_supabase/models/article_model.dart';
import 'package:inersia_supabase/models/user_model.dart';

final searchUserProfileServiceProvider = Provider(
  (ref) => SearchUserProfileService(),
);

final userProfilesProvider = FutureProvider.autoDispose
    .family<UserModel, String>((ref, userId) async {
      final service = ref.watch(searchUserProfileServiceProvider);
      return service.getUserProfile(userId);
    });

final userArticlesProvider = FutureProvider.autoDispose
    .family<List<ArticleModel>, String>((ref, userId) async {
      final service = ref.watch(searchUserProfileServiceProvider);
      return service.getUserArticles(userId);
    });
