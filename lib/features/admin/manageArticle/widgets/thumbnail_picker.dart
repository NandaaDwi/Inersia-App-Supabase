import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:inersia_supabase/models/article_model.dart';

class ThumbnailPicker extends StatelessWidget {
  final ValueNotifier<File?> thumbnail;
  final ArticleModel? article;

  const ThumbnailPicker({
    super.key,
    required this.thumbnail,
    this.article,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () async {
        final xfile = await ImagePicker().pickImage(
          source: ImageSource.gallery,
        );
        if (xfile != null) {
          thumbnail.value = File(xfile.path);
        }
      },
      child: Container(
        height: 200,
        width: double.infinity,
        decoration: BoxDecoration(
          color: const Color(0xFF111827),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: const Color(0xFF1F2937),
            width: 1.5,
          ),
        ),
        child: thumbnail.value != null
            ? ClipRRect(
                borderRadius: BorderRadius.circular(15),
                child: Image.file(thumbnail.value!, fit: BoxFit.cover),
              )
            : (article?.thumbnail != null
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(15),
                    child: Image.network(
                      article!.thumbnail!,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => _thumbnailEmpty(),
                    ),
                  )
                : _thumbnailEmpty()),
      ),
    );
  }

  Widget _thumbnailEmpty() {
    return const Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          Icons.add_photo_alternate_outlined,
          color: Color(0xFF374151),
          size: 40,
        ),
        SizedBox(height: 8),
        Text(
          "Pilih Thumbnail",
          style: TextStyle(color: Color(0xFF6B7280), fontSize: 13),
        ),
      ],
    );
  }
}