import 'package:flutter/material.dart';
import 'package:inersia_supabase/models/article_model.dart';

class ReadAppBar extends StatelessWidget {
  final ArticleModel article;
  final VoidCallback onBack;
  final VoidCallback onReport;

  const ReadAppBar({
    super.key,
    required this.article,
    required this.onBack,
    required this.onReport,
  });

  @override
  Widget build(BuildContext context) {
    return SliverAppBar(
      expandedHeight: 280,
      pinned: true,
      backgroundColor: const Color(0xFF0D0D0D),
      automaticallyImplyLeading: false,
      leading: ReadCircleBtn(icon: Icons.arrow_back_ios_new, onTap: onBack),
      actions: [
        ReadCircleBtn(icon: Icons.flag_outlined, onTap: onReport),
        const SizedBox(width: 8),
      ],
      flexibleSpace: FlexibleSpaceBar(
        background: _ArticleThumbnailHero(article: article),
      ),
    );
  }
}

class _ArticleThumbnailHero extends StatelessWidget {
  final ArticleModel article;
  const _ArticleThumbnailHero({required this.article});

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        article.thumbnail != null
            ? Image.network(
                article.thumbnail!,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => _placeholder(),
              )
            : _placeholder(),
        DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.transparent,
                const Color(0xFF0D0D0D).withOpacity(0.85),
                const Color(0xFF0D0D0D),
              ],
              stops: const [0.3, 0.75, 1.0],
            ),
          ),
        ),
        Positioned(
          left: 20,
          right: 20,
          bottom: 16,
          child: Text(
            article.title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.w800,
              height: 1.25,
            ),
          ),
        ),
      ],
    );
  }

  Widget _placeholder() => Container(
    color: const Color(0xFF111827),
    child: const Center(
      child: Icon(Icons.image_outlined, color: Color(0xFF374151), size: 48),
    ),
  );
}

class ReadCircleBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const ReadCircleBtn({super.key, required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.all(8),
    decoration: BoxDecoration(
      color: Colors.black.withOpacity(0.5),
      shape: BoxShape.circle,
    ),
    child: IconButton(
      icon: Icon(icon, color: Colors.white, size: 18),
      onPressed: onTap,
    ),
  );
}

class ReadLoadingScaffold extends StatelessWidget {
  final ArticleModel article;
  const ReadLoadingScaffold({super.key, required this.article});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D0D0D),
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 280,
            pinned: true,
            backgroundColor: const Color(0xFF0D0D0D),
            automaticallyImplyLeading: false,
            leading: Container(
              margin: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.5),
                shape: BoxShape.circle,
              ),
              child: IconButton(
                icon: const Icon(
                  Icons.arrow_back_ios_new,
                  color: Colors.white,
                  size: 16,
                ),
                onPressed: () {},
              ),
            ),
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                fit: StackFit.expand,
                children: [
                  article.thumbnail != null
                      ? Image.network(article.thumbnail!, fit: BoxFit.cover)
                      : Container(color: const Color(0xFF111827)),
                  DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          const Color(0xFF0D0D0D).withOpacity(0.85),
                          const Color(0xFF0D0D0D),
                        ],
                        stops: const [0.3, 0.75, 1.0],
                      ),
                    ),
                  ),
                  Positioned(
                    left: 20,
                    right: 20,
                    bottom: 16,
                    child: Text(
                      article.title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.w800,
                        height: 1.25,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SliverFillRemaining(
            child: Center(
              child: CircularProgressIndicator(
                color: Color(0xFF2563EB),
                strokeWidth: 2,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class ReadErrorScaffold extends StatelessWidget {
  final ArticleModel article;
  final VoidCallback onRetry;
  const ReadErrorScaffold({
    super.key,
    required this.article,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D0D0D),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0D0D0D),
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new,
            color: Colors.white,
            size: 16,
          ),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, color: Color(0xFF6B7280), size: 48),
            const SizedBox(height: 12),
            const Text(
              'Gagal memuat artikel',
              style: TextStyle(color: Color(0xFF6B7280)),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: onRetry,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2563EB),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: const Text('Coba Lagi'),
            ),
          ],
        ),
      ),
    );
  }
}
