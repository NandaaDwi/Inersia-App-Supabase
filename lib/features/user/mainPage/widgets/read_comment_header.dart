import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:inersia_supabase/models/comment_model.dart';

class ReadCommentsHeader extends StatelessWidget {
  final AsyncValue<List<CommentModel>> commentsAsync;
  const ReadCommentsHeader({super.key, required this.commentsAsync});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Text(
          'Komentar',
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(width: 8),
        commentsAsync.when(
          data: (c) => Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: const Color(0xFF1E3A5F),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              '${c.length}',
              style: const TextStyle(
                color: Color(0xFF60A5FA),
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          loading: () => const SizedBox.shrink(),
          error: (_, __) => const SizedBox.shrink(),
        ),
        const Spacer(),
        const Text(
          'Terbaru di atas',
          style: TextStyle(color: Color(0xFF4B5563), fontSize: 11),
        ),
      ],
    );
  }
}
