// lib/features/user/mainPage/widgets/read_quill_content.dart
//
// Render konten artikel dengan flutter_quill dalam mode read-only.
// Semua formatting (justify, bold, heading, blockquote, dll) terjaga.
//
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_quill/flutter_quill.dart' as quill;

class ReadQuillContent extends HookWidget {
  final String content;

  const ReadQuillContent({super.key, required this.content});

  @override
  Widget build(BuildContext context) {
    // Controller dibuat sekali dan di-dispose otomatis via useEffect
    final controller = useMemoized(() => _buildController(content));
    useEffect(() => controller.dispose, const []);

    // FocusNode dummy — read-only tidak butuh focus aktif
    final focusNode = useMemoized(() => FocusNode());
    useEffect(() {
      // Pastikan tidak pernah dapat focus (baca saja)
      focusNode.canRequestFocus = false;
      return focusNode.dispose;
    }, const []);

    final scrollCtrl = useMemoized(() => ScrollController());
    useEffect(() => scrollCtrl.dispose, const []);

    return DefaultTextStyle(
      style: const TextStyle(color: Color(0xFFD1D5DB), fontSize: 15),
      child: quill.QuillEditor(
        controller: controller,
        scrollController: scrollCtrl,
        focusNode: focusNode,
        config: quill.QuillEditorConfig(
          scrollable: false, // Scroll dikontrol oleh CustomScrollView luar
          expands: false,
          autoFocus: false,
          enableInteractiveSelection: false, // Tidak bisa select/copy di read
          showCursor: false,
          padding: EdgeInsets.zero,
          customStyles: _buildReadStyles(),
        ),
      ),
    );
  }

  static quill.QuillController _buildController(String content) {
    if (content.isEmpty) return quill.QuillController.basic();
    try {
      final dynamic decoded = jsonDecode(content);
      final List ops = decoded is List
          ? decoded
          : (decoded is Map ? decoded['ops'] as List? ?? [] : []);
      return quill.QuillController(
        document: quill.Document.fromJson(ops),
        selection: const TextSelection.collapsed(offset: 0),
      );
    } catch (_) {
      // Fallback ke plain text jika content bukan JSON Quill
      return quill.QuillController(
        document: quill.Document()..insert(0, content),
        selection: const TextSelection.collapsed(offset: 0),
      );
    }
  }

  static quill.DefaultStyles _buildReadStyles() => quill.DefaultStyles(
    paragraph: quill.DefaultTextBlockStyle(
      const TextStyle(
        color: Color(0xFFD1D5DB),
        fontSize: 15,
        height: 1.75,
        letterSpacing: 0.1,
      ),
      const quill.HorizontalSpacing(0, 0),
      const quill.VerticalSpacing(0, 4),
      const quill.VerticalSpacing(0, 0),
      null,
    ),
    bold: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
    italic: const TextStyle(
      color: Color(0xFFD1D5DB),
      fontStyle: FontStyle.italic,
    ),
    underline: const TextStyle(
      color: Colors.white,
      decoration: TextDecoration.underline,
      decorationColor: Colors.white,
    ),
    strikeThrough: const TextStyle(
      color: Color(0xFF9CA3AF),
      decoration: TextDecoration.lineThrough,
      decorationColor: Color(0xFF9CA3AF),
    ),
    h1: quill.DefaultTextBlockStyle(
      const TextStyle(
        color: Colors.white,
        fontSize: 28,
        fontWeight: FontWeight.w800,
        height: 1.3,
      ),
      const quill.HorizontalSpacing(0, 0),
      const quill.VerticalSpacing(16, 8),
      const quill.VerticalSpacing(0, 0),
      null,
    ),
    h2: quill.DefaultTextBlockStyle(
      const TextStyle(
        color: Colors.white,
        fontSize: 23,
        fontWeight: FontWeight.w700,
        height: 1.3,
      ),
      const quill.HorizontalSpacing(0, 0),
      const quill.VerticalSpacing(12, 6),
      const quill.VerticalSpacing(0, 0),
      null,
    ),
    h3: quill.DefaultTextBlockStyle(
      const TextStyle(
        color: Colors.white,
        fontSize: 19,
        fontWeight: FontWeight.w600,
        height: 1.3,
      ),
      const quill.HorizontalSpacing(0, 0),
      const quill.VerticalSpacing(8, 4),
      const quill.VerticalSpacing(0, 0),
      null,
    ),
    lists: quill.DefaultListBlockStyle(
      const TextStyle(color: Color(0xFFD1D5DB), fontSize: 15, height: 1.6),
      const quill.HorizontalSpacing(0, 0),
      const quill.VerticalSpacing(0, 2),
      const quill.VerticalSpacing(0, 0),
      null,
      null,
    ),
    quote: quill.DefaultTextBlockStyle(
      const TextStyle(
        color: Color(0xFF9CA3AF),
        fontSize: 15,
        height: 1.75,
        fontStyle: FontStyle.italic,
      ),
      const quill.HorizontalSpacing(16, 0),
      const quill.VerticalSpacing(8, 8),
      const quill.VerticalSpacing(0, 0),
      BoxDecoration(
        border: const Border(
          left: BorderSide(color: Color(0xFF2563EB), width: 3),
        ),
        color: const Color(0xFF111827),
      ),
    ),
    code: quill.DefaultTextBlockStyle(
      const TextStyle(
        color: Color(0xFF34D399),
        fontSize: 13,
        fontFamily: 'monospace',
        height: 1.6,
      ),
      const quill.HorizontalSpacing(14, 14),
      const quill.VerticalSpacing(8, 8),
      const quill.VerticalSpacing(0, 0),
      BoxDecoration(
        color: const Color(0xFF0D1F0F),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFF1F4730), width: 0.5),
      ),
    ),
    placeHolder: quill.DefaultTextBlockStyle(
      const TextStyle(color: Color(0xFF4B5563), fontSize: 15, height: 1.75),
      const quill.HorizontalSpacing(0, 0),
      const quill.VerticalSpacing(0, 0),
      const quill.VerticalSpacing(0, 0),
      null,
    ),
  );
}
