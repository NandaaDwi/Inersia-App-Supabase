import 'package:inersia_supabase/config/supabase_config.dart';

enum SearchResultType { article, user, tag, category }

class ArticleResult {
  final String id;
  final String title;
  final String? thumbnail;
  final String authorName;
  final String? categoryName;
  final int likeCount;
  final int viewCount;
  final int estimatedReading;
  final DateTime createdAt;

  const ArticleResult({
    required this.id,
    required this.title,
    this.thumbnail,
    required this.authorName,
    this.categoryName,
    required this.likeCount,
    required this.viewCount,
    required this.estimatedReading,
    required this.createdAt,
  });

  factory ArticleResult.fromJson(Map<String, dynamic> j) {
    final author = j['users'] as Map<String, dynamic>?;
    final cat = j['categories'] as Map<String, dynamic>?;
    return ArticleResult(
      id: j['id'] as String,
      title: j['title'] as String? ?? '',
      thumbnail: j['thumbnail'] as String?,
      authorName: author?['name'] as String? ?? 'Anonim',
      categoryName: cat?['name'] as String?,
      likeCount: j['like_count'] as int? ?? 0,
      viewCount: j['view_count'] as int? ?? 0,
      estimatedReading: j['estimated_reading'] as int? ?? 0,
      createdAt: DateTime.parse(j['created_at'] as String),
    );
  }
}

class UserResult {
  final String id;
  final String name;
  final String username;
  final String? photoUrl;
  final String? bio;
  final int followersCount;

  const UserResult({
    required this.id,
    required this.name,
    required this.username,
    this.photoUrl,
    this.bio,
    required this.followersCount,
  });

  factory UserResult.fromJson(Map<String, dynamic> j) {
    return UserResult(
      id: j['id'] as String,
      name: j['name'] as String? ?? '',
      username: j['username'] as String? ?? '',
      photoUrl: j['photo_url'] as String?,
      bio: j['bio'] as String?,
      followersCount: j['followers_count'] as int? ?? 0,
    );
  }
}

class TagResult {
  final String id;
  final String name;
  final int articleCount;

  const TagResult({
    required this.id,
    required this.name,
    required this.articleCount,
  });

  factory TagResult.fromJson(Map<String, dynamic> j) {
    return TagResult(
      id: j['id'] as String,
      name: j['name'] as String? ?? '',
      articleCount: j['article_count'] as int? ?? 0,
    );
  }
}

class CategoryResult {
  final String id;
  final String name;
  final int articleCount;

  const CategoryResult({
    required this.id,
    required this.name,
    required this.articleCount,
  });

  factory CategoryResult.fromJson(Map<String, dynamic> j) {
    return CategoryResult(
      id: j['id'] as String,
      name: j['name'] as String? ?? '',
      articleCount: j['article_count'] as int? ?? 0,
    );
  }
}

class SuggestionItem {
  final String label;
  final SearchResultType type;
  final String? subtitle;

  const SuggestionItem({
    required this.label,
    required this.type,
    this.subtitle,
  });
}

class SearchResults {
  final List<ArticleResult> articles;
  final List<UserResult> users;
  final List<TagResult> tags;
  final List<CategoryResult> categories;
  final String query;

  const SearchResults({
    this.articles = const [],
    this.users = const [],
    this.tags = const [],
    this.categories = const [],
    required this.query,
  });

  bool get isEmpty =>
      articles.isEmpty && users.isEmpty && tags.isEmpty && categories.isEmpty;
}

class DiscoveryData {
  final List<ArticleResult> trending;
  final List<CategoryResult> categories;
  final List<TagResult> popularTags;

  const DiscoveryData({
    required this.trending,
    required this.categories,
    required this.popularTags,
  });
}


class SearchService {
  final _client = supabaseConfig.client;

  Future<List<SuggestionItem>> getSuggestions(String query) async {
    if (query.trim().isEmpty) return [];
    final q = query.trim();

    final results = await Future.wait([
      _client
          .from('articles')
          .select('title')
          .eq('status', 'published')
          .ilike('title', '%$q%')
          .limit(4),
      _client
          .from('users')
          .select('name, username')
          .ilike('name', '%$q%')
          .limit(3),
      _client
          .from('tags')
          .select('name, article_count')
          .ilike('name', '%$q%')
          .limit(3),
      _client.from('categories').select('name').ilike('name', '%$q%').limit(2),
    ]);

    final suggestions = <SuggestionItem>[];

    for (final row in results[0] as List) {
      suggestions.add(
        SuggestionItem(
          label: row['title'] as String,
          type: SearchResultType.article,
        ),
      );
    }
    for (final row in results[1] as List) {
      suggestions.add(
        SuggestionItem(
          label: row['name'] as String,
          type: SearchResultType.user,
          subtitle: '@${row['username']}',
        ),
      );
    }
    for (final row in results[2] as List) {
      suggestions.add(
        SuggestionItem(
          label: row['name'] as String,
          type: SearchResultType.tag,
          subtitle: '${row['article_count']} artikel',
        ),
      );
    }
    for (final row in results[3] as List) {
      suggestions.add(
        SuggestionItem(
          label: row['name'] as String,
          type: SearchResultType.category,
        ),
      );
    }

    return suggestions;
  }

  Future<SearchResults> search(String query) async {
    if (query.trim().isEmpty) {
      return const SearchResults(query: '');
    }
    final q = query.trim();

    final results = await Future.wait([
      _searchArticles(q),
      _searchUsers(q),
      _searchTags(q),
      _searchCategories(q),
    ]);

    return SearchResults(
      articles: results[0] as List<ArticleResult>,
      users: results[1] as List<UserResult>,
      tags: results[2] as List<TagResult>,
      categories: results[3] as List<CategoryResult>,
      query: q,
    );
  }

  Future<List<ArticleResult>> _searchArticles(String q) async {
    final byTitle = await _client
        .from('articles')
        .select(
          'id,title,thumbnail,like_count,view_count,estimated_reading,created_at,'
          'users:author_id(name),'
          'categories:category_id(name)',
        )
        .eq('status', 'published')
        .ilike('title', '%$q%')
        .order('view_count', ascending: false)
        .limit(10);

    return (byTitle as List).map((e) => ArticleResult.fromJson(e)).toList();
  }

  Future<List<ArticleResult>> searchByTag(String tagId) async {
    final pivotRes = await _client
        .from('article_tags')
        .select('article_id')
        .eq('tag_id', tagId)
        .limit(20);

    final articleIds = (pivotRes as List)
        .map((e) => e['article_id'] as String)
        .toList();

    if (articleIds.isEmpty) return [];

    final res = await _client
        .from('articles')
        .select(
          'id,title,thumbnail,like_count,view_count,estimated_reading,created_at,'
          'users:author_id(name),'
          'categories:category_id(name)',
        )
        .eq('status', 'published')
        .inFilter('id', articleIds)
        .order('view_count', ascending: false);

    return (res as List).map((e) => ArticleResult.fromJson(e)).toList();
  }

  Future<List<ArticleResult>> searchByCategory(String categoryId) async {
    final res = await _client
        .from('articles')
        .select(
          'id,title,thumbnail,like_count,view_count,estimated_reading,created_at,'
          'users:author_id(name),'
          'categories:category_id(name)',
        )
        .eq('status', 'published')
        .eq('category_id', categoryId)
        .order('view_count', ascending: false)
        .limit(20);

    return (res as List).map((e) => ArticleResult.fromJson(e)).toList();
  }

  Future<List<UserResult>> _searchUsers(String q) async {
    final res = await _client
        .from('users')
        .select('id,name,username,photo_url,bio,followers_count')
        .or('name.ilike.%$q%,username.ilike.%$q%')
        .eq('status', 'active')
        .order('followers_count', ascending: false)
        .limit(8);

    return (res as List).map((e) => UserResult.fromJson(e)).toList();
  }

  Future<List<TagResult>> _searchTags(String q) async {
    final res = await _client
        .from('tags')
        .select('id,name,article_count')
        .ilike('name', '%$q%')
        .order('article_count', ascending: false)
        .limit(10);

    return (res as List).map((e) => TagResult.fromJson(e)).toList();
  }

  Future<List<CategoryResult>> _searchCategories(String q) async {
    final res = await _client
        .from('categories')
        .select('id,name,article_count')
        .ilike('name', '%$q%')
        .order('article_count', ascending: false)
        .limit(6);

    return (res as List).map((e) => CategoryResult.fromJson(e)).toList();
  }

  Future<DiscoveryData> getDiscovery() async {
    final results = await Future.wait([
      _client
          .from('articles')
          .select(
            'id,title,thumbnail,like_count,view_count,estimated_reading,created_at,'
            'users:author_id(name),'
            'categories:category_id(name)',
          )
          .eq('status', 'published')
          .order('view_count', ascending: false)
          .limit(6),
      _client
          .from('categories')
          .select('id,name,article_count')
          .order('article_count', ascending: false)
          .limit(8),
      _client
          .from('tags')
          .select('id,name,article_count')
          .order('article_count', ascending: false)
          .limit(12),
    ]);

    return DiscoveryData(
      trending: (results[0] as List)
          .map((e) => ArticleResult.fromJson(e))
          .toList(),
      categories: (results[1] as List)
          .map((e) => CategoryResult.fromJson(e))
          .toList(),
      popularTags: (results[2] as List)
          .map((e) => TagResult.fromJson(e))
          .toList(),
    );
  }
}
