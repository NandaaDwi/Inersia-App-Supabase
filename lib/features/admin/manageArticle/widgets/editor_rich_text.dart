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
          'KONTEN',
          style: TextStyle(
            color: Color(0xFF9CA3AF),
            fontSize: 11,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.0,
          ),
        ),
        const SizedBox(height: 8),

        // ─── Area Editor ─────────────────────────────────────
        // Tidak ada fixed height — mengikuti konten
        Container(
          constraints: const BoxConstraints(
            minHeight: 240,
            // Tidak ada maxHeight — tumbuh mengikuti konten
          ),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: const Color(0xFF161616),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFF1F2937)),
          ),
          child: quill.QuillEditor(
            controller: controller,
            scrollController: scrollController,
            focusNode: focusNode,
            config: quill.QuillEditorConfig(
              // scrollable: false → editor tidak scroll sendiri
              // parent SingleChildScrollView yang scroll
              scrollable: false,
              expands: false,
              autoFocus: false,
              placeholder: 'Mulai menulis konten artikel...',
              padding: EdgeInsets.zero,
              customStyles: quill.DefaultStyles(
                paragraph: quill.DefaultTextBlockStyle(
                  const TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    height: 1.7,
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
                    fontSize: 26,
                    fontWeight: FontWeight.w800,
                    height: 1.3,
                  ),
                  const quill.HorizontalSpacing(0, 0),
                  const quill.VerticalSpacing(8, 4),
                  const quill.VerticalSpacing(0, 0),
                  null,
                ),
                h2: quill.DefaultTextBlockStyle(
                  const TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    height: 1.3,
                  ),
                  const quill.HorizontalSpacing(0, 0),
                  const quill.VerticalSpacing(6, 4),
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
                  const quill.VerticalSpacing(4, 2),
                  const quill.VerticalSpacing(0, 0),
                  null,
                ),
                lists: quill.DefaultListBlockStyle(
                  // Ganti di bagian ini
                  const TextStyle(
                    color: Color(0xFFD1D5DB),
                    fontSize: 15,
                    height: 1.6,
                  ),
                  const quill.HorizontalSpacing(0, 0),
                  const quill.VerticalSpacing(0, 0),
                  const quill.VerticalSpacing(6, 0),
                  null,
                  null,
                ),
                quote: quill.DefaultTextBlockStyle(
                  const TextStyle(
                    color: Color(0xFF9CA3AF),
                    fontSize: 15,
                    height: 1.7,
                    fontStyle: FontStyle.italic,
                  ),
                  const quill.HorizontalSpacing(16, 0),
                  const quill.VerticalSpacing(6, 6),
                  const quill.VerticalSpacing(0, 0),
                  BoxDecoration(
                    border: Border(
                      left: BorderSide(
                        color: const Color(0xFF2563EB),
                        width: 3,
                      ),
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
                  const quill.HorizontalSpacing(12, 12),
                  const quill.VerticalSpacing(6, 6),
                  const quill.VerticalSpacing(0, 0),
                  BoxDecoration(
                    color: const Color(0xFF0D1F0F),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                      color: const Color(0xFF1F4730),
                      width: 0.5,
                    ),
                  ),
                ),
                placeHolder: quill.DefaultTextBlockStyle(
                  const TextStyle(
                    color: Color(0xFF4B5563),
                    fontSize: 15,
                    height: 1.7,
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

        const SizedBox(height: 8),

        // ─── Toolbar di bawah editor ─────────────────────────
        // Sticky di atas keyboard menggunakan AnimatedPadding
        // yang mengikuti viewInsets.bottom (tinggi keyboard)
        _StickyToolbar(controller: controller),

        const SizedBox(height: 8),
      ],
    );
  }
}

class _StickyToolbar extends StatelessWidget {
  final quill.QuillController controller;
  const _StickyToolbar({required this.controller});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF111827),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF1F2937)),
      ),
      child: _QuillToolbar(controller: controller),
    );
  }
}

class _QuillToolbar extends StatelessWidget {
  final quill.QuillController controller;
  const _QuillToolbar({required this.controller});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
      child: Row(
        children: [
          // ─── Heading ───────────────────────────────────────
          _ToolbarGroup(
            children: [
              _HeadingButton(controller: controller, level: 1, label: 'H1'),
              _HeadingButton(controller: controller, level: 2, label: 'H2'),
              _HeadingButton(controller: controller, level: 3, label: 'H3'),
            ],
          ),
          _Separator(),

          // ─── Format teks ───────────────────────────────────
          _ToolbarGroup(
            children: [
              _ToggleButton(
                controller: controller,
                attribute: quill.Attribute.bold,
                icon: Icons.format_bold,
                tooltip: 'Tebal',
              ),
              _ToggleButton(
                controller: controller,
                attribute: quill.Attribute.italic,
                icon: Icons.format_italic,
                tooltip: 'Miring',
              ),
              _ToggleButton(
                controller: controller,
                attribute: quill.Attribute.underline,
                icon: Icons.format_underline,
                tooltip: 'Garis bawah',
              ),
              _ToggleButton(
                controller: controller,
                attribute: quill.Attribute.strikeThrough,
                icon: Icons.format_strikethrough,
                tooltip: 'Coret',
              ),
            ],
          ),
          _Separator(),

          // ─── List ──────────────────────────────────────────
          _ToolbarGroup(
            children: [
              _ToggleButton(
                controller: controller,
                attribute: quill.Attribute.ul,
                icon: Icons.format_list_bulleted,
                tooltip: 'Bullet list',
              ),
              _ToggleButton(
                controller: controller,
                attribute: quill.Attribute.ol,
                icon: Icons.format_list_numbered,
                tooltip: 'Numbered list',
              ),
            ],
          ),
          _Separator(),

          // ─── Blockquote & Code ────────────────────────────
          _ToolbarGroup(
            children: [
              _ToggleButton(
                controller: controller,
                attribute: quill.Attribute.blockQuote,
                icon: Icons.format_quote,
                tooltip: 'Kutipan',
              ),
              _ToggleButton(
                controller: controller,
                attribute: quill.Attribute.codeBlock,
                icon: Icons.code,
                tooltip: 'Blok kode',
              ),
            ],
          ),
          _Separator(),

          // ─── Alignment ─────────────────────────────────────
          _ToolbarGroup(
            children: [
              _AlignButton(
                controller: controller,
                align: quill.Attribute.leftAlignment,
                icon: Icons.format_align_left,
                tooltip: 'Rata kiri',
              ),
              _AlignButton(
                controller: controller,
                align: quill.Attribute.centerAlignment,
                icon: Icons.format_align_center,
                tooltip: 'Rata tengah',
              ),
              _AlignButton(
                controller: controller,
                align: quill.Attribute.rightAlignment,
                icon: Icons.format_align_right,
                tooltip: 'Rata kanan',
              ),
            ],
          ),
          _Separator(),

          // ─── Indent ────────────────────────────────────────
          _ToolbarGroup(
            children: [
              _ActionButton(
                icon: Icons.format_indent_decrease,
                tooltip: 'Indent kurang',
                onPressed: () => controller.indentSelection(false),
              ),
              _ActionButton(
                icon: Icons.format_indent_increase,
                tooltip: 'Indent lebih',
                onPressed: () => controller.indentSelection(true),
              ),
            ],
          ),
          _Separator(),

          // ─── Undo / Redo ──────────────────────────────────
          _ToolbarGroup(
            children: [
              _ActionButton(
                icon: Icons.undo,
                tooltip: 'Undo',
                onPressed: () {
                  if (controller.hasUndo) controller.undo();
                },
              ),
              _ActionButton(
                icon: Icons.redo,
                tooltip: 'Redo',
                onPressed: () {
                  if (controller.hasRedo) controller.redo();
                },
              ),
            ],
          ),
          _Separator(),

          // ─── Clear format ─────────────────────────────────
          _ActionButton(
            icon: Icons.format_clear,
            tooltip: 'Hapus format',
            onPressed: () {
              controller.formatSelection(
                quill.Attribute.clone(quill.Attribute.bold, null),
              );
              controller.formatSelection(
                quill.Attribute.clone(quill.Attribute.italic, null),
              );
              controller.formatSelection(
                quill.Attribute.clone(quill.Attribute.underline, null),
              );
            },
          ),
        ],
      ),
    );
  }
}

// ─── Toolbar Widget Helpers ───────────────────────────────────

class _ToolbarGroup extends StatelessWidget {
  final List<Widget> children;
  const _ToolbarGroup({required this.children});

  @override
  Widget build(BuildContext context) {
    return Row(mainAxisSize: MainAxisSize.min, children: children);
  }
}

class _Separator extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Container(
    width: 1,
    height: 20,
    margin: const EdgeInsets.symmetric(horizontal: 4),
    color: const Color(0xFF1F2937),
  );
}

class _ToggleButton extends StatelessWidget {
  final quill.QuillController controller;
  final quill.Attribute attribute;
  final IconData icon;
  final String tooltip;

  const _ToggleButton({
    required this.controller,
    required this.attribute,
    required this.icon,
    required this.tooltip,
  });

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<quill.QuillController>(
      valueListenable: ValueNotifier(controller),
      builder: (_, __, ___) {
        // Cek apakah atribut aktif pada selection saat ini
        final isActive = _isActive();
        return _ToolbarBtn(
          icon: icon,
          tooltip: tooltip,
          isActive: isActive,
          onPressed: () => controller.formatSelection(
            isActive
                ? quill.Attribute.clone(attribute, null) // toggle off
                : attribute, // toggle on
          ),
        );
      },
    );
  }

  bool _isActive() {
    try {
      final attrs = controller.getSelectionStyle().attributes;
      final val = attrs[attribute.key];
      if (val == null) return false;
      // Untuk bullet/numbered list, cek nilai
      if (attribute.key == 'list') {
        return val.value == attribute.value;
      }
      // Untuk blockquote, codeBlock
      if (attribute.key == 'blockquote' || attribute.key == 'code-block') {
        return val.value == true;
      }
      // Untuk bold, italic, underline, strikethrough
      return val.value == true;
    } catch (_) {
      return false;
    }
  }
}

class _HeadingButton extends StatelessWidget {
  final quill.QuillController controller;
  final int level;
  final String label;

  const _HeadingButton({
    required this.controller,
    required this.level,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    final attribute = quill.Attribute.h1.key == 'header'
        ? quill.Attribute.fromKeyValue('header', level)
        : quill.Attribute.h1;

    return ValueListenableBuilder<quill.QuillController>(
      valueListenable: ValueNotifier(controller),
      builder: (_, __, ___) {
        bool isActive = false;
        try {
          final attrs = controller.getSelectionStyle().attributes;
          isActive = attrs['header']?.value == level;
        } catch (_) {}

        return _ToolbarBtn(
          tooltip: 'Heading $level',
          isActive: isActive,
          onPressed: () {
            if (isActive) {
              controller.formatSelection(
                quill.Attribute.clone(quill.Attribute.header, null),
              );
            } else {
              controller.formatSelection(
                quill.Attribute.fromKeyValue('header', level),
              );
            }
          },
          child: Text(
            label,
            style: TextStyle(
              color: isActive
                  ? const Color(0xFF2563EB)
                  : const Color(0xFF9CA3AF),
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        );
      },
    );
  }
}

class _AlignButton extends StatelessWidget {
  final quill.QuillController controller;
  final quill.Attribute align;
  final IconData icon;
  final String tooltip;

  const _AlignButton({
    required this.controller,
    required this.align,
    required this.icon,
    required this.tooltip,
  });

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<quill.QuillController>(
      valueListenable: ValueNotifier(controller),
      builder: (_, __, ___) {
        bool isActive = false;
        try {
          final attrs = controller.getSelectionStyle().attributes;
          isActive = attrs['align']?.value == align.value;
        } catch (_) {}

        return _ToolbarBtn(
          icon: icon,
          tooltip: tooltip,
          isActive: isActive,
          onPressed: () => controller.formatSelection(
            isActive
                ? quill.Attribute.clone(quill.Attribute.align, null)
                : align,
          ),
        );
      },
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback onPressed;

  const _ActionButton({
    required this.icon,
    required this.tooltip,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) =>
      _ToolbarBtn(icon: icon, tooltip: tooltip, onPressed: onPressed);
}

class _ToolbarBtn extends StatelessWidget {
  final IconData? icon;
  final String tooltip;
  final bool isActive;
  final VoidCallback onPressed;
  final Widget? child;

  const _ToolbarBtn({
    this.icon,
    required this.tooltip,
    this.isActive = false,
    required this.onPressed,
    this.child,
  });

  @override
  Widget build(BuildContext context) {
    final color = isActive ? const Color(0xFF2563EB) : const Color(0xFF9CA3AF);

    return Tooltip(
      message: tooltip,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(6),
          onTap: onPressed,
          child: Container(
            width: 32,
            height: 32,
            alignment: Alignment.center,
            decoration: isActive
                ? BoxDecoration(
                    color: const Color(0xFF1E3A5F),
                    borderRadius: BorderRadius.circular(6),
                  )
                : null,
            child: child ?? Icon(icon, size: 18, color: color),
          ),
        ),
      ),
    );
  }
}
