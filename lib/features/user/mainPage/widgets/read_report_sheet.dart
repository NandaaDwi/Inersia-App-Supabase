import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:inersia_supabase/features/user/mainPage/providers/read_page_provider.dart';

void showReadReportSheet({
  required BuildContext context,
  required WidgetRef ref,
  required String targetId,
  required String targetType,
  required Map<String, dynamic> snapshot,
}) {
  showModalBottomSheet(
    context: context,
    backgroundColor: const Color(0xFF1F2937),
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    isScrollControlled: true,
    builder: (_) => _ReadReportSheet(
      targetType: targetType,
      onSubmit: (reason, desc) async {
        await ref
            .read(reportProvider.notifier)
            .submit(
              targetId: targetId,
              targetType: targetType,
              reasonCategory: reason,
              description: desc,
              contentSnapshot: snapshot,
            );
        if (context.mounted) {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Laporan berhasil dikirim.'),
              backgroundColor: Color(0xFF059669),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      },
    ),
  );
}

class _ReadReportSheet extends HookWidget {
  final String targetType;
  final Future<void> Function(String, String?) onSubmit;
  const _ReadReportSheet({required this.targetType, required this.onSubmit});

  static const _reasons = [
    ('spam', 'Spam / Iklan'),
    ('plagiat', 'Plagiat / Konten Curian'),
    ('tidak_pantas', 'Konten Tidak Pantas'),
    ('ujaran_kebencian', 'Ujaran Kebencian'),
    ('misinformasi', 'Informasi Menyesatkan'),
    ('lainnya', 'Lainnya'),
  ];

  @override
  Widget build(BuildContext context) {
    final selected = useState<String?>(null);
    final descCtrl = useTextEditingController();
    final isSubmitting = useState(false);

    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
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
          Text(
            'Laporkan ${targetType == 'article' ? 'Artikel' : 'Komentar'}',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 17,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Pilih alasan laporan kamu',
            style: TextStyle(color: Color(0xFF6B7280), fontSize: 13),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _reasons.map((r) {
              final isSel = selected.value == r.$1;
              return GestureDetector(
                onTap: () => selected.value = r.$1,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: isSel
                        ? const Color(0xFF1E3A5F)
                        : const Color(0xFF111827),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: isSel
                          ? const Color(0xFF2563EB)
                          : const Color(0xFF374151),
                    ),
                  ),
                  child: Text(
                    r.$2,
                    style: TextStyle(
                      color: isSel
                          ? const Color(0xFF60A5FA)
                          : const Color(0xFF9CA3AF),
                      fontSize: 13,
                      fontWeight: isSel ? FontWeight.w600 : FontWeight.normal,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: descCtrl,
            style: const TextStyle(color: Colors.white, fontSize: 14),
            maxLines: 3,
            decoration: InputDecoration(
              hintText: 'Deskripsi tambahan (opsional)...',
              hintStyle: const TextStyle(
                color: Color(0xFF4B5563),
                fontSize: 13,
              ),
              filled: true,
              fillColor: const Color(0xFF111827),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Color(0xFF374151)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Color(0xFF374151)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(
                  color: Color(0xFF2563EB),
                  width: 1.5,
                ),
              ),
              contentPadding: const EdgeInsets.all(14),
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: selected.value == null || isSubmitting.value
                  ? null
                  : () async {
                      isSubmitting.value = true;
                      try {
                        await onSubmit(
                          selected.value!,
                          descCtrl.text.trim().isEmpty
                              ? null
                              : descCtrl.text.trim(),
                        );
                      } finally {
                        isSubmitting.value = false;
                      }
                    },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFDC2626),
                foregroundColor: Colors.white,
                disabledBackgroundColor: const Color(0xFF374151),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 0,
              ),
              child: isSubmitting.value
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Text(
                      'Kirim Laporan',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}
