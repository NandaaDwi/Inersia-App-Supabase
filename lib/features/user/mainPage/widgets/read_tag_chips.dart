import 'package:flutter/material.dart';
import 'package:inersia_supabase/models/tag_model.dart';

class ReadTagChips extends StatelessWidget {
  final List<TagModel> tags;
  const ReadTagChips({super.key, required this.tags});

  @override
  Widget build(BuildContext context) => Wrap(
    spacing: 8,
    runSpacing: 8,
    children: tags
        .map(
          (t) => Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
            decoration: BoxDecoration(
              color: const Color(0xFF161616),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFF1F2937)),
            ),
            child: Text(
              '#${t.name}',
              style: const TextStyle(color: Color(0xFF6B7280), fontSize: 13),
            ),
          ),
        )
        .toList(),
  );
}
