import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart' as quill;

/// Widget editor artikel — dipakai di admin DAN user editor.
/// Toolbar di bawah editor (bukan di atas), auto-sticky di atas keyboard
/// via bottomSheet di parent Scaffold.
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
          'KONTEN',
          style: TextStyle(
            color: Color(0xFF9CA3AF),
            fontSize: 11,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.0,
          ),
        ),
        const SizedBox(height: 8),

        // ── Area tulis ──────────────────────────────────────
        Container(
          // Minimum 360px — nyaman untuk menulis artikel
          constraints: const BoxConstraints(minHeight: 360),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFF161616),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFF1F2937)),
          ),
          child: quill.QuillEditor(
            controller: controller,
            scrollController: scrollController,
            focusNode: focusNode,
            config: quill.QuillEditorConfig(
              scrollable: false,
              expands: false,
              autoFocus: false,
              placeholder: 'Mulai menulis konten artikel...',
              padding: EdgeInsets.zero,
              customStyles: _buildStyles(),
            ),
          ),
        ),
      ],
    );
  }

  quill.DefaultStyles _buildStyles() => quill.DefaultStyles(
    paragraph: quill.DefaultTextBlockStyle(
      const TextStyle(color: Colors.white, fontSize: 15, height: 1.75),
      const quill.HorizontalSpacing(0, 0),
      const quill.VerticalSpacing(0, 0),
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
      const quill.VerticalSpacing(10, 6),
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
      const quill.VerticalSpacing(8, 4),
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
      const quill.VerticalSpacing(6, 2),
      const quill.VerticalSpacing(0, 0),
      null,
    ),
    lists: quill.DefaultListBlockStyle(
      const TextStyle(color: Color(0xFFD1D5DB), fontSize: 15, height: 1.65),
      const quill.HorizontalSpacing(0, 0),
      const quill.VerticalSpacing(0, 0),
      const quill.VerticalSpacing(4, 0),
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
      const quill.VerticalSpacing(6, 6),
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
      const quill.VerticalSpacing(6, 6),
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

/// Toolbar yang sticky di atas keyboard.
/// Pasang ini sebagai `bottomSheet` di Scaffold:
///
/// ```dart
/// bottomSheet: QuillKeyboardToolbar(controller: quillCtrl),
/// ```
class QuillKeyboardToolbar extends StatelessWidget {
  final quill.QuillController controller;
  const QuillKeyboardToolbar({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xFF0F1923),
      child: SafeArea(
        top: false,
        child: Container(
          decoration: const BoxDecoration(
            border: Border(
              top: BorderSide(color: Color(0xFF1F2937), width: 0.5),
            ),
          ),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            child: Row(
              children: [
                // ── Heading ─────────────────────────────────
                _H(c: controller, level: 1, label: 'H1'),
                _H(c: controller, level: 2, label: 'H2'),
                _H(c: controller, level: 3, label: 'H3'),
                _Div(),

                // ── Format teks ─────────────────────────────
                _T(
                  c: controller,
                  attr: quill.Attribute.bold,
                  icon: Icons.format_bold_rounded,
                ),
                _T(
                  c: controller,
                  attr: quill.Attribute.italic,
                  icon: Icons.format_italic_rounded,
                ),
                _T(
                  c: controller,
                  attr: quill.Attribute.underline,
                  icon: Icons.format_underlined_rounded,
                ),
                _T(
                  c: controller,
                  attr: quill.Attribute.strikeThrough,
                  icon: Icons.strikethrough_s_rounded,
                ),
                _Div(),

                // ── List ─────────────────────────────────────
                _T(
                  c: controller,
                  attr: quill.Attribute.ul,
                  icon: Icons.format_list_bulleted_rounded,
                ),
                _T(
                  c: controller,
                  attr: quill.Attribute.ol,
                  icon: Icons.format_list_numbered_rounded,
                ),
                _Div(),

                // ── Blockquote & Code ────────────────────────
                _T(
                  c: controller,
                  attr: quill.Attribute.blockQuote,
                  icon: Icons.format_quote_rounded,
                ),
                _T(
                  c: controller,
                  attr: quill.Attribute.codeBlock,
                  icon: Icons.code_rounded,
                ),
                _Div(),

                // ── Alignment — termasuk justify ─────────────
                _A(
                  c: controller,
                  align: quill.Attribute.leftAlignment,
                  icon: Icons.format_align_left_rounded,
                ),
                _A(
                  c: controller,
                  align: quill.Attribute.centerAlignment,
                  icon: Icons.format_align_center_rounded,
                ),
                _A(
                  c: controller,
                  align: quill.Attribute.rightAlignment,
                  icon: Icons.format_align_right_rounded,
                ),
                _A(
                  c: controller,
                  align: quill.Attribute.justifyAlignment,
                  icon: Icons.format_align_justify_rounded,
                ),
                _Div(),

                // ── Indent ───────────────────────────────────
                _I(
                  icon: Icons.format_indent_decrease_rounded,
                  onTap: () => controller.indentSelection(false),
                ),
                _I(
                  icon: Icons.format_indent_increase_rounded,
                  onTap: () => controller.indentSelection(true),
                ),
                _Div(),

                // ── Undo / Redo ──────────────────────────────
                _I(
                  icon: Icons.undo_rounded,
                  onTap: () {
                    if (controller.hasUndo) controller.undo();
                  },
                ),
                _I(
                  icon: Icons.redo_rounded,
                  onTap: () {
                    if (controller.hasRedo) controller.redo();
                  },
                ),
                _Div(),

                // ── Clear format ─────────────────────────────
                _I(
                  icon: Icons.format_clear_rounded,
                  onTap: () {
                    for (final a in [
                      quill.Attribute.bold,
                      quill.Attribute.italic,
                      quill.Attribute.underline,
                      quill.Attribute.strikeThrough,
                    ]) {
                      controller.formatSelection(
                        quill.Attribute.clone(a, null),
                      );
                    }
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ── Toolbar widget helpers ────────────────────────────────────

class _Div extends StatelessWidget {
  @override
  Widget build(_) => Container(
    width: 1,
    height: 20,
    margin: const EdgeInsets.symmetric(horizontal: 3),
    color: const Color(0xFF1F2937),
  );
}

class _H extends StatelessWidget {
  final quill.QuillController c;
  final int level;
  final String label;
  const _H({required this.c, required this.level, required this.label});

  @override
  Widget build(_) {
    bool active = false;
    try {
      active = c.getSelectionStyle().attributes['header']?.value == level;
    } catch (_) {}
    return _Btn(
      active: active,
      onTap: () {
        if (active) {
          c.formatSelection(quill.Attribute.header);
        } else {
          c.formatSelection(quill.Attribute.fromKeyValue('header', level));
        }
      },
      child: Text(
        label,
        style: TextStyle(
          color: active ? const Color(0xFF2563EB) : const Color(0xFF9CA3AF),
          fontSize: 11,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _T extends StatelessWidget {
  final quill.QuillController c;
  final quill.Attribute attr;
  final IconData icon;
  const _T({required this.c, required this.attr, required this.icon});

  @override
  Widget build(_) {
    bool active = false;
    try {
      final attrs = c.getSelectionStyle().attributes;
      final val = attrs[attr.key];
      active = attr.key == 'list'
          ? val?.value == attr.value
          : val?.value == true;
    } catch (_) {}
    return _Btn(
      active: active,
      onTap: () =>
          c.formatSelection(active ? quill.Attribute.clone(attr, null) : attr),
      child: Icon(
        icon,
        size: 18,
        color: active ? const Color(0xFF2563EB) : const Color(0xFF9CA3AF),
      ),
    );
  }
}

class _A extends StatelessWidget {
  final quill.QuillController c;
  final quill.Attribute align;
  final IconData icon;
  const _A({required this.c, required this.align, required this.icon});

  @override
  Widget build(_) {
    bool active = false;
    try {
      active = c.getSelectionStyle().attributes['align']?.value == align.value;
    } catch (_) {}
    return _Btn(
      active: active,
      onTap: () => c.formatSelection(
        active
            ? quill.Attribute.clone(
                quill.Attribute.fromKeyValue('align', 'center')!,
                null,
              )
            : align,
      ),
      child: Icon(
        icon,
        size: 18,
        color: active ? const Color(0xFF2563EB) : const Color(0xFF9CA3AF),
      ),
    );
  }
}

class _I extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _I({required this.icon, required this.onTap});

  @override
  Widget build(_) => _Btn(
    onTap: onTap,
    child: Icon(icon, size: 18, color: const Color(0xFF9CA3AF)),
  );
}

class _Btn extends StatelessWidget {
  final bool active;
  final VoidCallback onTap;
  final Widget child;
  const _Btn({this.active = false, required this.onTap, required this.child});

  @override
  Widget build(_) => GestureDetector(
    onTap: onTap,
    child: Container(
      width: 34,
      height: 34,
      margin: const EdgeInsets.symmetric(horizontal: 1),
      alignment: Alignment.center,
      decoration: active
          ? BoxDecoration(
              color: const Color(0xFF1E3A5F),
              borderRadius: BorderRadius.circular(7),
            )
          : null,
      child: child,
    ),
  );
}
