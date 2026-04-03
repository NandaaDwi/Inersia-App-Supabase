import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import '../providers/admin_category_provider.dart';

class CategoryManagementScreen extends HookConsumerWidget {
  const CategoryManagementScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final categoriesAsync = ref.watch(categoriesProvider);
    final nameController = useTextEditingController();
    final editId = useState<String?>(null);

    void resetForm() {
      nameController.clear();
      editId.value = null;
      FocusScope.of(context).unfocus();
    }

    return Column(
      children: [
        // Modern Input Card
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 20),
          child: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFF161616),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.white.withOpacity(0.05)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: nameController,
                    style: const TextStyle(color: Colors.white, fontSize: 14),
                    decoration: InputDecoration(
                      hintText: editId.value == null
                          ? "Nama kategori baru..."
                          : "Ubah kategori...",
                      hintStyle: const TextStyle(color: Colors.white24),
                      filled: true,
                      fillColor: const Color(0xFF1E1E1E),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 15,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(15),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: () async {
                    if (nameController.text.isEmpty) return;
                    await ref
                        .read(categoryServiceProvider)
                        .upsertCategory(editId.value, nameController.text);
                    ref.invalidate(categoriesProvider);
                    resetForm();
                  },
                  child: Container(
                    height: 50,
                    width: 50,
                    decoration: BoxDecoration(
                      color: const Color(0xFF3F7AF6),
                      borderRadius: BorderRadius.circular(15),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF3F7AF6).withOpacity(0.3),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Icon(
                      editId.value == null
                          ? Icons.add_rounded
                          : Icons.check_rounded,
                      color: Colors.white,
                    ),
                  ),
                ),
                if (editId.value != null)
                  IconButton(
                    onPressed: resetForm,
                    icon: const Icon(
                      Icons.close_rounded,
                      color: Colors.redAccent,
                    ),
                  ),
              ],
            ),
          ),
        ),

        // Custom Search Bar
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: TextField(
            onChanged: (v) => ref.read(catSearchProvider.notifier).state = v,
            style: const TextStyle(color: Colors.white, fontSize: 13),
            decoration: InputDecoration(
              hintText: "Cari kategori...",
              hintStyle: const TextStyle(color: Colors.white38),
              prefixIcon: const Icon(
                Icons.search_rounded,
                size: 20,
                color: Colors.white38,
              ),
              filled: true,
              fillColor: Colors.transparent,
              contentPadding: EdgeInsets.zero,
              enabledBorder: UnderlineInputBorder(
                borderSide: BorderSide(color: Colors.white.withOpacity(0.05)),
              ),
              focusedBorder: const UnderlineInputBorder(
                borderSide: BorderSide(color: Color(0xFF3F7AF6)),
              ),
            ),
          ),
        ),

        const SizedBox(height: 16),

        Expanded(
          child: categoriesAsync.when(
            data: (list) => ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
              itemCount: list.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, i) {
                final item = list[i];
                return Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFF161616),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1E1E1E),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.folder_open_rounded,
                          color: Color(0xFF3F7AF6),
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              item.name,
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                              ),
                            ),
                            Text(
                              "${item.articleCount} Artikel",
                              style: const TextStyle(
                                color: Colors.white38,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(
                          Icons.edit_note_rounded,
                          color: Colors.white54,
                        ),
                        onPressed: () {
                          editId.value = item.id;
                          nameController.text = item.name;
                        },
                      ),
                      IconButton(
                        icon: const Icon(
                          Icons.delete_sweep_rounded,
                          color: Colors.redAccent,
                          size: 22,
                        ),
                        onPressed: () => _confirmDelete(context, () async {
                          await ref
                              .read(categoryServiceProvider)
                              .deleteCategory(item.id);
                          ref.invalidate(categoriesProvider);
                        }),
                      ),
                    ],
                  ),
                );
              },
            ),
            loading: () => const Center(
              child: CircularProgressIndicator(color: Color(0xFF3F7AF6)),
            ),
            error: (e, _) => Center(
              child: Text(
                "Error: $e",
                style: const TextStyle(color: Colors.white),
              ),
            ),
          ),
        ),
      ],
    );
  }

  void _confirmDelete(BuildContext context, VoidCallback onConfirm) {
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: '',
      transitionDuration: const Duration(milliseconds: 200),
      pageBuilder: (ctx, a1, a2) => Container(),
      transitionBuilder: (ctx, a1, a2, child) => Transform.scale(
        scale: a1.value,
        child: AlertDialog(
          backgroundColor: const Color(0xFF1A1A1A),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: const Text(
            "Hapus Kategori?",
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          content: const Text(
            "Menghapus ini mungkin mempengaruhi artikel terkait.",
            style: TextStyle(color: Colors.white60, fontSize: 14),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text(
                "Batal",
                style: TextStyle(color: Colors.white38),
              ),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.redAccent,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              onPressed: () {
                onConfirm();
                Navigator.pop(ctx);
              },
              child: const Text(
                "Hapus Sekarang",
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
