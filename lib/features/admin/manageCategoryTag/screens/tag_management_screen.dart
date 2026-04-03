import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:inersia_supabase/features/admin/manageCategoryTag/providers/admin_tag_provider.dart';

class TagManagementScreen extends HookConsumerWidget {
  const TagManagementScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tagsAsync = ref.watch(tagsProvider);
    final nameController = useTextEditingController();
    final editId = useState<String?>(null);

    void resetForm() {
      nameController.clear();
      editId.value = null;
      FocusScope.of(context).unfocus();
    }

    return Column(
      children: [
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
                          ? "Nama tag baru..."
                          : "Ubah tag...",
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
                        .read(tagServiceProvider)
                        .upsertTag(editId.value, nameController.text);
                    ref.invalidate(tagsProvider);
                    resetForm();
                  },
                  child: Container(
                    height: 50,
                    width: 50,
                    decoration: BoxDecoration(
                      color: const Color(0xFF3F7AF6),
                      borderRadius: BorderRadius.circular(15),
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

        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: TextField(
            onChanged: (v) => ref.read(tagSearchProvider.notifier).state = v,
            style: const TextStyle(color: Colors.white, fontSize: 13),
            decoration: InputDecoration(
              hintText: "Cari tag artikel...",
              hintStyle: const TextStyle(color: Colors.white38),
              prefixIcon: const Icon(
                Icons.search_rounded,
                size: 20,
                color: Colors.white38,
              ),
              filled: true,
              fillColor: Colors.transparent,
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
          child: tagsAsync.when(
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
                          Icons.local_offer_rounded,
                          color: Color(0xFF3F7AF6),
                          size: 18,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "#${item.name}",
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                                fontSize: 14,
                              ),
                            ),
                            Text(
                              "${item.articleCount} Digunakan",
                              style: const TextStyle(
                                color: Colors.white38,
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(
                          Icons.edit_rounded,
                          color: Colors.white30,
                          size: 20,
                        ),
                        onPressed: () {
                          editId.value = item.id;
                          nameController.text = item.name;
                        },
                      ),
                      IconButton(
                        icon: const Icon(
                          Icons.delete_rounded,
                          color: Colors.redAccent,
                          size: 20,
                        ),
                        onPressed: () => _confirmDelete(context, () async {
                          await ref.read(tagServiceProvider).deleteTag(item.id);
                          ref.invalidate(tagsProvider);
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
  }
}
