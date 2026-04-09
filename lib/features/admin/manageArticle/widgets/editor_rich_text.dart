import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart' as quill;

class EditorRichText extends StatelessWidget {
  final quill.QuillController controller;
  final ScrollController scrollController;
  final FocusNode focusNode;

  const EditorRichText({
    super.key,
    required this.controller,
    required this.scrollController,
    required this.focusNode,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Konten",
          style: TextStyle(
            color: Color(0xFF9CA3AF),
            fontSize: 12,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.8,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: const Color(0xFF111827),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
            border: Border.all(color: const Color(0xFF1F2937)),
          ),
          child: quill.QuillSimpleToolbar(
            controller: controller,
            config: const quill.QuillSimpleToolbarConfig(
              showFontFamily: false,
              showFontSize: false,
              multiRowsDisplay: false,
              toolbarIconAlignment: WrapAlignment.start,
            ),
          ),
        ),
        Container(
          height: 400,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: const Color(0xFF161616),
            borderRadius: BorderRadius.circular(
              12,
            ).copyWith(topLeft: Radius.zero, topRight: Radius.zero),
            border: Border.all(color: const Color(0xFF1F2937)),
          ),
          child: quill.QuillEditor(
            controller: controller,
            scrollController: scrollController,
            focusNode: focusNode,
            config: quill.QuillEditorConfig(
              placeholder: 'Mulai menulis konten artikel...',
              padding: EdgeInsets.zero,
              autoFocus: false,
              customStyles: quill.DefaultStyles(
                paragraph: quill.DefaultTextBlockStyle(
                  const TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    height: 1.6,
                  ),
                  const quill.HorizontalSpacing(0, 0),
                  const quill.VerticalSpacing(0, 0),
                  const quill.VerticalSpacing(0, 0),
                  null,
                ),
                bold: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
                italic: const TextStyle(
                  color: Color(0xFFD1D5DB),
                  fontStyle: FontStyle.italic,
                ),
                placeHolder: quill.DefaultTextBlockStyle(
                  const TextStyle(
                    color: Color(0xFF4B5563),
                    fontSize: 15,
                    height: 1.6,
                  ),
                  const quill.HorizontalSpacing(0, 0),
                  const quill.VerticalSpacing(0, 0),
                  const quill.VerticalSpacing(0, 0),
                  null,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
