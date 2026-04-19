import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:inersia_supabase/models/article_model.dart';

class EditorThumbPicker extends StatelessWidget {
  final ValueNotifier<File?> thumbnail;
  final ArticleModel? article;
  final VoidCallback onChanged;
  const EditorThumbPicker({
    required this.thumbnail,
    this.article,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: () async {
      final x = await ImagePicker().pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
      );
      if (x != null) {
        thumbnail.value = File(x.path);
        onChanged();
      }
    },
    child: Container(
      height: 200,
      width: double.infinity,
      decoration: BoxDecoration(
        color: const Color(0xFF161616),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF161616), width: 1.5),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(15),
        child: thumbnail.value != null
            ? Image.file(thumbnail.value!, fit: BoxFit.cover)
            : article?.thumbnail != null
            ? Image.network(
                article!.thumbnail!,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => _empty(),
              )
            : _empty(),
      ),
    ),
  );

  Widget _empty() => const Column(
    mainAxisAlignment: MainAxisAlignment.center,
    children: [
      Icon(
        Icons.add_photo_alternate_outlined,
        color: Color(0xFF374151),
        size: 40,
      ),
      SizedBox(height: 8),
      Text(
        'Pilih Thumbnail',
        style: TextStyle(color: Color(0xFF6B7280), fontSize: 13),
      ),
    ],
  );
}
