import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import '../services/admin_report_service.dart';
import '../providers/admin_report_provider.dart';

class ReportActionDialog {
  static void show(
    BuildContext context,
    WidgetRef ref,
    AdminReportItem item,
    ValueNotifier<bool> parentLoading,
  ) {
    final noteCtrl = TextEditingController();
    bool deleteContent = true;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setState) => AlertDialog(
          backgroundColor: const Color(0xFF111827),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: BorderSide(color: Colors.white.withOpacity(0.1)),
          ),
          title: const Text(
            'Konfirmasi Tindakan',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: noteCtrl,
                maxLines: 3,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: 'Tambahkan catatan admin...',
                  hintStyle: const TextStyle(color: Color(0xFF4B5563)),
                  filled: true,
                  fillColor: Colors.black.withOpacity(0.2),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              SwitchListTile(
                value: deleteContent,
                onChanged: (v) => setState(() => deleteContent = v),
                title: Text(
                  'Hapus ${item.targetType == 'article' ? 'Artikel' : 'Komentar'}',
                  style: const TextStyle(color: Colors.white, fontSize: 14),
                ),
                activeColor: const Color(0xFFDC2626),
                contentPadding: EdgeInsets.zero,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text(
                'Batal',
                style: TextStyle(color: Color(0xFF6B7280)),
              ),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFDC2626),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              onPressed: () async {
                Navigator.pop(ctx);
                parentLoading.value = true;
                final ok = await ref
                    .read(reportActionProvider.notifier)
                    .resolveReport(
                      reportId: item.id,
                      status: 'resolved',
                      adminNote: noteCtrl.text.isEmpty ? null : noteCtrl.text,
                      deleteTargetId: deleteContent ? item.targetId : null,
                      deleteTargetType: deleteContent ? item.targetType : null,
                    );
                parentLoading.value = false;

                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        ok ? 'Berhasil diproses' : 'Gagal memproses',
                      ),
                      backgroundColor: ok ? Colors.green : Colors.red,
                    ),
                  );
                }
              },
              child: const Text(
                'Konfirmasi',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
