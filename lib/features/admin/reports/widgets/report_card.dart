import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import '../services/admin_report_service.dart';
import '../providers/admin_report_provider.dart';
import 'report_action_dialog.dart';

class ReportCard extends HookConsumerWidget {
  final AdminReportItem item;
  const ReportCard({required this.item, super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isExpanded = useState(false);

    final statusColor = switch (item.status) {
      'pending' => const Color(0xFFF59E0B),
      'resolved' => const Color(0xFF10B981),
      _ => const Color(0xFF6B7280),
    };

    final reasonLabel = switch (item.reasonCategory) {
      'spam' => '🚫 Spam / Iklan',
      'plagiat' => '📋 Plagiat',
      'tidak_pantas' => '⚠️ Tidak Pantas',
      'ujaran_kebencian' => '🔥 Ujaran Kebencian',
      'misinformasi' => '❌ Misinformasi',
      _ => '📌 ${item.reasonCategory}',
    };

    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: const Color(0xFF111827),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: item.status == 'pending'
              ? statusColor.withOpacity(0.2)
              : Colors.white.withOpacity(0.05),
        ),
      ),
      child: Column(
        children: [
          InkWell(
            onTap: () => isExpanded.value = !isExpanded.value,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 8,
                              height: 8,
                              decoration: BoxDecoration(
                                color: statusColor,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              reasonLabel,
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${item.targetType == 'article' ? '📰 Artikel' : '💬 Komentar'} • Pelapor: ${item.reporterName}',
                          style: const TextStyle(
                            color: Color(0xFF6B7280),
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    isExpanded.value ? Icons.expand_less : Icons.expand_more,
                    color: const Color(0xFF4B5563),
                  ),
                ],
              ),
            ),
          ),
          if (isExpanded.value) _buildExpandedContent(context, ref),
        ],
      ),
    );
  }

  Widget _buildExpandedContent(BuildContext context, WidgetRef ref) {
    final isLoading = useState(false);

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Divider(color: Color(0xFF1F2937), height: 1),
          const SizedBox(height: 16),
          if (item.contentSnapshot != null) ...[
            _Label('KONTEN TERLAPOR'),
            const SizedBox(height: 8),
            _ReadableSnapshot(
              snapshot: item.contentSnapshot!,
              type: item.targetType,
            ),
            const SizedBox(height: 16),
          ],
          if (item.description != null && item.description!.isNotEmpty) ...[
            _Label('ALASAN PELAPOR'),
            const SizedBox(height: 4),
            Text(
              item.description!,
              style: const TextStyle(
                color: Color(0xFF9CA3AF),
                fontSize: 13,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 16),
          ],
          if (item.adminNote != null) ...[
            _Label('CATATAN ADMIN'),
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF064E3B).withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                item.adminNote!,
                style: const TextStyle(color: Color(0xFF34D399), fontSize: 13),
              ),
            ),
            const SizedBox(height: 16),
          ],
          if (item.status == 'pending')
            Row(
              children: [
                Expanded(
                  child: TextButton(
                    onPressed: isLoading.value
                        ? null
                        : () => _handleAction(ref, 'rejected', isLoading),
                    child: const Text(
                      'Tolak Laporan',
                      style: TextStyle(color: Color(0xFF6B7280)),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: isLoading.value
                        ? null
                        : () => ReportActionDialog.show(
                            context,
                            ref,
                            item,
                            isLoading,
                          ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFDC2626),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: isLoading.value
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Text(
                            'Tindak',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }

  Future<void> _handleAction(
    WidgetRef ref,
    String status,
    ValueNotifier<bool> loading,
  ) async {
    loading.value = true;
    await ref
        .read(reportActionProvider.notifier)
        .resolveReport(reportId: item.id, status: status);
    loading.value = false;
  }
}

class _Label extends StatelessWidget {
  final String text;
  const _Label(this.text);
  @override
  Widget build(BuildContext context) => Text(
    text,
    style: const TextStyle(
      color: Color(0xFF4B5563),
      fontSize: 10,
      fontWeight: FontWeight.w800,
      letterSpacing: 1,
    ),
  );
}

class _ReadableSnapshot extends StatelessWidget {
  final Map<String, dynamic> snapshot;
  final String type;
  const _ReadableSnapshot({required this.snapshot, required this.type});

  @override
  Widget build(BuildContext context) {
    String content = type == 'article'
        ? (snapshot['title'] ?? '')
        : (snapshot['comment_text'] ?? '');
    if (type == 'article') {
      final body = _parseQuill(snapshot['content'] ?? '');
      content = "$content\n\n$body";
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.3),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Text(
        content,
        style: const TextStyle(
          color: Color(0xFFD1D5DB),
          fontSize: 13,
          height: 1.5,
        ),
      ),
    );
  }

  String _parseQuill(String jsonStr) {
    try {
      final decoded = jsonDecode(jsonStr);
      if (decoded is List)
        return decoded
            .map((op) => op['insert']?.toString() ?? '')
            .join()
            .trim();
      return jsonStr;
    } catch (_) {
      return jsonStr;
    }
  }
}
