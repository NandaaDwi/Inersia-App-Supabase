import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:inersia_supabase/features/admin/manageCategoryTag/providers/admin_category_provider.dart';
import 'package:inersia_supabase/features/admin/manageCategoryTag/providers/admin_tag_provider.dart';
import 'package:inersia_supabase/features/admin/manageCategoryTag/services/admin_category_service.dart';
import 'package:inersia_supabase/features/admin/manageCategoryTag/services/admin_tag_service.dart';
import 'package:inersia_supabase/models/category_model.dart';
import 'package:inersia_supabase/models/tag_model.dart';

ButtonStyle _outlineStyle() => OutlinedButton.styleFrom(
  foregroundColor: const Color(0xFF9CA3AF),
  side: const BorderSide(color: Color(0xFF1F2937)),
  padding: const EdgeInsets.symmetric(vertical: 14),
  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
);

ButtonStyle _primaryStyle() => ElevatedButton.styleFrom(
  backgroundColor: const Color(0xFF2563EB),
  foregroundColor: Colors.white,
  elevation: 0,
  padding: const EdgeInsets.symmetric(vertical: 14),
  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
);

ButtonStyle _dangerStyle() => ElevatedButton.styleFrom(
  backgroundColor: const Color(0xFFEF4444),
  foregroundColor: Colors.white,
  elevation: 0,
  padding: const EdgeInsets.symmetric(vertical: 12),
  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
);


class TaxonomyManagementScreen extends HookWidget {
  const TaxonomyManagementScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final selectedIndex = useState(0);
    const tabs = ['Kategori', 'Tag'];

    return Scaffold(
      backgroundColor: const Color(0xFF0D0D0D),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0D0D0D),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new,
            color: Colors.white,
            size: 18,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Kelola kategori & Tag',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w700,
            fontSize: 18,
          ),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(0.5),
          child: Container(height: 0.5, color: const Color(0xFF1F2937)),
        ),
      ),
      floatingActionButton: Consumer(
        builder: (ctx, ref, _) => FloatingActionButton.extended(
          onPressed: () => selectedIndex.value == 0
              ? _showCategorySheet(ctx, ref)
              : _showTagSheet(ctx, ref),
          backgroundColor: const Color(0xFF2563EB),
          foregroundColor: Colors.white,
          elevation: 4,
          icon: const Icon(Icons.add_rounded),
          label: Text(
            selectedIndex.value == 0 ? 'Tambah Kategori' : 'Tambah Tag',
            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
          ),
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: const Color(0xFF111827),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFF1F2937)),
              ),
              child: Row(
                children: List.generate(tabs.length, (i) {
                  final isSelected = selectedIndex.value == i;
                  return Expanded(
                    child: GestureDetector(
                      onTap: () => selectedIndex.value = i,
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: isSelected
                              ? const Color(0xFF2563EB)
                              : Color(0xFF111827),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          tabs[i],
                          style: TextStyle(
                            color: isSelected
                                ? Colors.white
                                : const Color(0xFF6B7280),
                            fontWeight: isSelected
                                ? FontWeight.w700
                                : FontWeight.normal,
                            fontSize: 14,
                            height: 1,
                          ),
                        ),
                      ),
                    ),
                  );
                }),
              ),
            ),
          ),
          Expanded(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              child: selectedIndex.value == 0
                  ? const _CategoryTab(key: ValueKey('cat'))
                  : const _TagTab(key: ValueKey('tag')),
            ),
          ),
        ],
      ),
    );
  }

  static void _showCategorySheet(
    BuildContext context,
    WidgetRef ref, {
    CategoryModel? item,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _CategoryFormSheet(
        item: item,
        onSave: (name) async {
          await AdminCategoryService().upsertCategory(item?.id, name);
          ref.invalidate(categoriesProvider);
        },
      ),
    );
  }

  static void _showTagSheet(
    BuildContext context,
    WidgetRef ref, {
    TagModel? item,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _TagFormSheet(
        item: item,
        onSave: (name) async {
          await AdminTagService().upsertTag(item?.id, name);
          ref.invalidate(tagsProvider);
        },
      ),
    );
  }
}


class _CategoryTab extends ConsumerWidget {
  const _CategoryTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final categoriesAsync = ref.watch(categoriesProvider);
    return Column(
      children: [
        _SearchBar(
          hint: 'Cari kategori...',
          onChanged: (v) => ref.read(catSearchProvider.notifier).state = v,
        ),
        Expanded(
          child: categoriesAsync.when(
            data: (list) => list.isEmpty
                ? const _EmptyState(
                    label: 'Belum ada kategori',
                    icon: Icons.folder_open_rounded,
                  )
                : ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
                    itemCount: list.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (ctx, i) => _CategoryItem(
                      category: list[i],
                      onEdit: () => _showEdit(ctx, ref, list[i]),
                      onDelete: () =>
                          _confirmDelete(ctx, list[i].name, () async {
                            await AdminCategoryService().deleteCategory(
                              list[i].id,
                            );
                            ref.invalidate(categoriesProvider);
                          }),
                    ),
                  ),
            loading: () => const Center(
              child: CircularProgressIndicator(color: Color(0xFF2563EB)),
            ),
            error: (e, _) => Center(
              child: Text(
                'Error: $e',
                style: const TextStyle(color: Color(0xFF6B7280)),
              ),
            ),
          ),
        ),
      ],
    );
  }

  void _showEdit(BuildContext ctx, WidgetRef ref, CategoryModel item) {
    showModalBottomSheet(
      context: ctx,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _CategoryFormSheet(
        item: item,
        onSave: (name) async {
          await AdminCategoryService().upsertCategory(item.id, name);
          ref.invalidate(categoriesProvider);
        },
      ),
    );
  }

  void _confirmDelete(BuildContext ctx, String name, VoidCallback onConfirm) {
    showDialog(
      context: ctx,
      builder: (_) => _DeleteDialog(name: name, onConfirm: onConfirm),
    );
  }
}

class _CategoryItem extends StatelessWidget {
  final CategoryModel category;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  const _CategoryItem({
    required this.category,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 8, 14),
      decoration: BoxDecoration(
        color: const Color(0xFF111827),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFF1F2937), width: 0.5),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: const Color(0xFF1E3A5F),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.folder_rounded,
              color: Color(0xFF60A5FA),
              size: 20,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  category.name,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
                Text(
                  '${category.articleCount} artikel',
                  style: const TextStyle(
                    color: Color(0xFF6B7280),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(
              Icons.edit_rounded,
              color: Color(0xFF6B7280),
              size: 18,
            ),
            onPressed: onEdit,
          ),
          IconButton(
            icon: const Icon(
              Icons.delete_outline_rounded,
              color: Color(0xFFEF4444),
              size: 18,
            ),
            onPressed: onDelete,
          ),
        ],
      ),
    );
  }
}


class _TagTab extends ConsumerWidget {
  const _TagTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tagsAsync = ref.watch(tagsProvider);
    return Column(
      children: [
        _SearchBar(
          hint: 'Cari tag...',
          onChanged: (v) => ref.read(tagSearchProvider.notifier).state = v,
        ),
        Expanded(
          child: tagsAsync.when(
            data: (list) => list.isEmpty
                ? const _EmptyState(
                    label: 'Belum ada tag',
                    icon: Icons.local_offer_rounded,
                  )
                : ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
                    itemCount: list.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (ctx, i) => _TagItem(
                      tag: list[i],
                      onEdit: () => _showEdit(ctx, ref, list[i]),
                      onDelete: () =>
                          _confirmDelete(ctx, list[i].name, () async {
                            await AdminTagService().deleteTag(list[i].id);
                            ref.invalidate(tagsProvider);
                          }),
                    ),
                  ),
            loading: () => const Center(
              child: CircularProgressIndicator(color: Color(0xFF2563EB)),
            ),
            error: (e, _) => Center(
              child: Text(
                'Error: $e',
                style: const TextStyle(color: Color(0xFF6B7280)),
              ),
            ),
          ),
        ),
      ],
    );
  }

  void _showEdit(BuildContext ctx, WidgetRef ref, TagModel item) {
    showModalBottomSheet(
      context: ctx,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _TagFormSheet(
        item: item,
        onSave: (name) async {
          await AdminTagService().upsertTag(item.id, name);
          ref.invalidate(tagsProvider);
        },
      ),
    );
  }

  void _confirmDelete(BuildContext ctx, String name, VoidCallback onConfirm) {
    showDialog(
      context: ctx,
      builder: (_) => _DeleteDialog(name: name, onConfirm: onConfirm),
    );
  }
}

class _TagItem extends StatelessWidget {
  final TagModel tag;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  const _TagItem({
    required this.tag,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 8, 14),
      decoration: BoxDecoration(
        color: const Color(0xFF111827),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFF1F2937), width: 0.5),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: const Color(0xFF1E3A5F).withOpacity(0.5),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.local_offer_rounded,
              color: Color(0xFF93C5FD),
              size: 18,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                RichText(
                  text: TextSpan(
                    children: [
                      const TextSpan(
                        text: '#',
                        style: TextStyle(
                          color: Color(0xFF60A5FA),
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                        ),
                      ),
                      TextSpan(
                        text: tag.name,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
                Text(
                  '${tag.articleCount} artikel',
                  style: const TextStyle(
                    color: Color(0xFF6B7280),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(
              Icons.edit_rounded,
              color: Color(0xFF6B7280),
              size: 18,
            ),
            onPressed: onEdit,
          ),
          IconButton(
            icon: const Icon(
              Icons.delete_outline_rounded,
              color: Color(0xFFEF4444),
              size: 18,
            ),
            onPressed: onDelete,
          ),
        ],
      ),
    );
  }
}


class _CategoryFormSheet extends HookWidget {
  final CategoryModel? item;
  final Future<void> Function(String) onSave;
  const _CategoryFormSheet({this.item, required this.onSave});

  @override
  Widget build(BuildContext context) {
    final ctrl = useTextEditingController(text: item?.name ?? '');
    final isSaving = useState(false);

    return _FormSheetWrapper(
      icon: Icons.folder_rounded,
      iconBg: const Color(0xFF1E3A5F),
      iconColor: const Color(0xFF60A5FA),
      title: item == null ? 'Tambah Kategori' : 'Edit Kategori',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Nama Kategori',
            style: TextStyle(
              color: Color(0xFF9CA3AF),
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          _ThemedTextField(controller: ctrl, hint: 'Masukkan nama kategori...'),
          const SizedBox(height: 20),
          _FormButtons(
            isSaving: isSaving.value,
            confirmLabel: item == null ? 'Tambah' : 'Simpan',
            onCancel: () => Navigator.pop(context),
            onConfirm: () async {
              final name = ctrl.text.trim();
              if (name.isEmpty) return;
              isSaving.value = true;
              try {
                await onSave(name);
                if (context.mounted) Navigator.pop(context);
              } finally {
                isSaving.value = false;
              }
            },
          ),
        ],
      ),
    );
  }
}

class _TagFormSheet extends HookWidget {
  final TagModel? item;
  final Future<void> Function(String) onSave;
  const _TagFormSheet({this.item, required this.onSave});

  @override
  Widget build(BuildContext context) {
    final ctrl = useTextEditingController(text: item?.name ?? '');
    final isSaving = useState(false);

    return _FormSheetWrapper(
      icon: Icons.local_offer_rounded,
      iconBg: const Color(0xFF1E3A5F),
      iconColor: const Color(0xFF93C5FD),
      title: item == null ? 'Tambah Tag' : 'Edit Tag',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Nama Tag',
            style: TextStyle(
              color: Color(0xFF9CA3AF),
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          _ThemedTextField(
            controller: ctrl,
            hint: 'Masukkan nama tag...',
            prefix: '# ',
          ),
          const SizedBox(height: 20),
          _FormButtons(
            isSaving: isSaving.value,
            confirmLabel: item == null ? 'Tambah' : 'Simpan',
            onCancel: () => Navigator.pop(context),
            onConfirm: () async {
              final name = ctrl.text.trim();
              if (name.isEmpty) return;
              isSaving.value = true;
              try {
                await onSave(name);
                if (context.mounted) Navigator.pop(context);
              } finally {
                isSaving.value = false;
              }
            },
          ),
        ],
      ),
    );
  }
}


class _FormSheetWrapper extends StatelessWidget {
  final IconData icon;
  final Color iconBg;
  final Color iconColor;
  final String title;
  final Widget child;
  const _FormSheetWrapper({
    required this.icon,
    required this.iconBg,
    required this.iconColor,
    required this.title,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFF161616),
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 24,
        bottom: MediaQuery.of(context).viewInsets.bottom + 32,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: const Color(0xFF374151),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: iconBg,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: iconColor, size: 20),
              ),
              const SizedBox(width: 12),
              Text(
                title,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          child,
        ],
      ),
    );
  }
}

class _ThemedTextField extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final String? prefix;
  const _ThemedTextField({
    required this.controller,
    required this.hint,
    this.prefix,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      autofocus: true,
      style: const TextStyle(color: Colors.white, fontSize: 15),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: Color(0xFF4B5563)),
        prefixText: prefix,
        prefixStyle: const TextStyle(
          color: Color(0xFF60A5FA),
          fontWeight: FontWeight.w700,
        ),
        filled: true,
        fillColor: const Color(0xFF111827),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF1F2937)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF1F2937)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF2563EB), width: 1.5),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
      ),
    );
  }
}

class _FormButtons extends StatelessWidget {
  final bool isSaving;
  final String confirmLabel;
  final VoidCallback onCancel;
  final VoidCallback onConfirm;
  const _FormButtons({
    required this.isSaving,
    required this.confirmLabel,
    required this.onCancel,
    required this.onConfirm,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton(
            onPressed: onCancel,
            style: _outlineStyle(),
            child: const Text(
              'Batal',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: ElevatedButton(
            onPressed: isSaving ? null : onConfirm,
            style: _primaryStyle(),
            child: isSaving
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : Text(
                    confirmLabel,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
          ),
        ),
      ],
    );
  }
}

class _DeleteDialog extends StatelessWidget {
  final String name;
  final VoidCallback onConfirm;
  const _DeleteDialog({required this.name, required this.onConfirm});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: const Color(0xFF161616),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: const Color(0xFFEF4444).withOpacity(0.12),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.delete_forever_rounded,
                color: Color(0xFFEF4444),
                size: 26,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Hapus?',
              style: TextStyle(
                color: Colors.white,
                fontSize: 17,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '"$name" akan dihapus permanen.',
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Color(0xFF9CA3AF),
                fontSize: 13,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    style: _outlineStyle(),
                    child: const Text(
                      'Batal',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      onConfirm();
                      Navigator.pop(context);
                    },
                    style: _dangerStyle(),
                    child: const Text(
                      'Hapus',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _SearchBar extends StatelessWidget {
  final String hint;
  final ValueChanged<String> onChanged;
  const _SearchBar({required this.hint, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      child: TextField(
        onChanged: onChanged,
        style: const TextStyle(color: Colors.white, fontSize: 14),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: const TextStyle(color: Color(0xFF4B5563)),
          prefixIcon: const Icon(
            Icons.search_rounded,
            color: Color(0xFF4B5563),
            size: 20,
          ),
          filled: true,
          fillColor: const Color(0xFF111827),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFF1F2937)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFF1F2937)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFF2563EB), width: 1.5),
          ),
          contentPadding: const EdgeInsets.symmetric(vertical: 13),
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final String label;
  final IconData icon;
  const _EmptyState({required this.label, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: const Color(0xFF374151), size: 52),
          const SizedBox(height: 12),
          Text(label, style: const TextStyle(color: Color(0xFF6B7280))),
        ],
      ),
    );
  }
}
