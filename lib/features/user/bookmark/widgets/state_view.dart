import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class LoadingViewWidget extends StatelessWidget {
  const LoadingViewWidget();

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      itemCount: 4,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (_, __) => const SkeletonCardWidget(),
    );
  }
}

class SkeletonCardWidget extends StatelessWidget {
  const SkeletonCardWidget();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 120,
      decoration: BoxDecoration(
        color: const Color(0xFF161616),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF1F2937), width: 0.5),
      ),
      child: Row(
        children: [
          Container(
            width: 100,
            decoration: const BoxDecoration(
              color: Color(0xFF1F2937),
              borderRadius: BorderRadius.horizontal(left: Radius.circular(16)),
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  SkeletonLineWidget(width: 0.4),
                  SkeletonLineWidget(width: 1.0),
                  SkeletonLineWidget(width: 0.75),
                  SkeletonLineWidget(width: 0.5),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class SkeletonLineWidget extends StatelessWidget {
  final double width;
  const SkeletonLineWidget({required this.width});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (_, constraints) => Container(
        width: constraints.maxWidth * width,
        height: 12,
        decoration: BoxDecoration(
          color: const Color(0xFF1F2937),
          borderRadius: BorderRadius.circular(4),
        ),
      ),
    );
  }
}

class ErrorViewWidget extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  const ErrorViewWidget({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, color: Color(0xFF374151), size: 48),
            const SizedBox(height: 12),
            Text(
              message,
              style: const TextStyle(color: Color(0xFF6B7280), fontSize: 14),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded, size: 18),
              label: const Text('Coba Lagi'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2563EB),
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class EmptyViewWidget extends StatelessWidget {
  const EmptyViewWidget();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: const Color(0xFF161616),
                shape: BoxShape.circle,
                border: Border.all(color: const Color(0xFF1F2937)),
              ),
              child: const Icon(
                Icons.bookmark_border_rounded,
                color: Color(0xFF374151),
                size: 36,
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Belum ada artikel tersimpan',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Tekan ikon bookmark saat membaca artikel\nuntuk menyimpannya di sini.',
              style: TextStyle(
                color: Color(0xFF6B7280),
                fontSize: 13,
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 28),
            ElevatedButton.icon(
              onPressed: () => context.go('/home'),
              icon: const Icon(Icons.explore_outlined, size: 18),
              label: const Text('Jelajahi Artikel'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2563EB),
                foregroundColor: Colors.white,
                elevation: 0,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class NoResultsViewWidget extends StatelessWidget {
  final String query;
  const NoResultsViewWidget({required this.query});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.search_off_rounded,
              color: Color(0xFF374151),
              size: 48,
            ),
            const SizedBox(height: 16),
            const Text(
              'Tidak ada hasil',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Tidak ada artikel tersimpan yang cocok\ndengan "$query"',
              style: const TextStyle(
                color: Color(0xFF6B7280),
                fontSize: 13,
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
