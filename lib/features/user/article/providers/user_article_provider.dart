import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:inersia_supabase/features/user/article/services/user_article_service.dart';

final userArticleServiceProvider = Provider((_) => UserArticleService());
