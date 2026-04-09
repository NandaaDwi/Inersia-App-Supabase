import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:inersia_supabase/features/admin/reports/providers/admin_report_provider.dart';
import 'package:inersia_supabase/features/admin/reports/services/admin_report_service.dart';

class AdminReportScreen extends ConsumerWidget {
  const AdminReportScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statusFilter = ref.watch(reportStatusFilterProvider);
    final typeFilter = ref.watch(reportTypeFilterProvider);
    final reportsAsync = ref.watch(reportsStreamProvider);

    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0F),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0A0A0F),
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
          'Laporan Pengguna',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w700,
            fontSize: 17,
          ),
        ),
      ),
      body: Column(
        children: [
          _FilterBar(
            statusFilter: statusFilter,
            typeFilter: typeFilter,
            onStatusChanged: (v) =>
                ref.read(reportStatusFilterProvider.notifier).state = v,
            onTypeChanged: (v) =>
                ref.read(reportTypeFilterProvider.notifier).state = v,
          ),
          Expanded(
            child: reportsAsync.when(
              data: (reports) => reports.isEmpty
                  ? const _EmptyView()
                  : RefreshIndicator(
                      color: const Color(0xFF3F7AF6),
                      backgroundColor: const Color(0xFF111827),
                      onRefresh: () async => ref.refresh(reportsStreamProvider),
                      child: ListView.separated(
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
                        itemCount: reports.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 10),
                        itemBuilder: (_, i) => _ReportCard(item: reports[i]),
                      ),
                    ),
              loading: () => const Center(
                child: CircularProgressIndicator(color: Color(0xFF3F7AF6)),
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
      ),
    );
  }
}

class _FilterBar extends StatelessWidget {
  final String? statusFilter;
  final String? typeFilter;
  final ValueChanged<String?> onStatusChanged;
  final ValueChanged<String?> onTypeChanged;

  const _FilterBar({
    required this.statusFilter,
    required this.typeFilter,
    required this.onStatusChanged,
    required this.onTypeChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      child: Column(
        children: [
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _FilterChip('Semua', null, statusFilter, onStatusChanged),
                const SizedBox(width: 8),
                _FilterChip(
                  'Menunggu',
                  'pending',
                  statusFilter,
                  onStatusChanged,
                  color: const Color(0xFFD97706),
                ),
                const SizedBox(width: 8),
                _FilterChip(
                  'Ditindak',
                  'resolved',
                  statusFilter,
                  onStatusChanged,
                  color: const Color(0xFF059669),
                ),
                const SizedBox(width: 8),
                _FilterChip(
                  'Ditolak',
                  'dismissed',
                  statusFilter,
                  onStatusChanged,
                  color: const Color(0xFF6B7280),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _FilterChip('📄 Semua', null, typeFilter, onTypeChanged),
                const SizedBox(width: 8),
                _FilterChip('📰 Artikel', 'article', typeFilter, onTypeChanged),
                const SizedBox(width: 8),
                _FilterChip(
                  '💬 Komentar',
                  'comment',
                  typeFilter,
                  onTypeChanged,
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final String? value;
  final String? current;
  final ValueChanged<String?> onChanged;
  final Color? color;

  const _FilterChip(
    this.label,
    this.value,
    this.current,
    this.onChanged, {
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final isSelected = current == value;
    final activeColor = color ?? const Color(0xFF3F7AF6);

    return GestureDetector(
      onTap: () => onChanged(value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected
              ? activeColor.withOpacity(0.15)
              : const Color(0xFF111827),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? activeColor : const Color(0xFF1F2937),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? activeColor : const Color(0xFF9CA3AF),
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
      ),
    );
  }
}

class _ReportCard extends HookConsumerWidget {
  final AdminReportItem item;
  const _ReportCard({required this.item});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isExpanded = useState(false);

    final statusColor = switch (item.status) {
      'pending' => const Color(0xFFD97706),
      'resolved' => const Color(0xFF059669),
      _ => const Color(0xFF6B7280),
    };
    final statusLabel = switch (item.status) {
      'pending' => 'Menunggu',
      'resolved' => 'Ditindak',
      _ => 'Ditolak',
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
      decoration: BoxDecoration(
        color: const Color(0xFF111827),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: item.status == 'pending'
              ? const Color(0xFFD97706).withOpacity(0.25)
              : const Color(0xFF1F2937),
          width: 0.5,
        ),
      ),
      child: Column(
        children: [
          // Header tap untuk expand
          InkWell(
            onTap: () => isExpanded.value = !isExpanded.value,
            borderRadius: BorderRadius.circular(14),
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      statusLabel,
                      style: TextStyle(
                        color: statusColor,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          reasonLabel,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                          ),
                        ),
                        Text(
                          '${item.targetType == 'article' ? '📰' : '💬'} • ${item.reporterName}',
                          style: const TextStyle(
                            color: Color(0xFF6B7280),
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    isExpanded.value
                        ? Icons.keyboard_arrow_up_rounded
                        : Icons.keyboard_arrow_down_rounded,
                    color: const Color(0xFF6B7280),
                    size: 20,
                  ),
                ],
              ),
            ),
          ),

          // Detail yang bisa di-expand
          if (isExpanded.value) ...[
            const Divider(
              height: 1,
              color: Color(0xFF1F2937),
              indent: 14,
              endIndent: 14,
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Konten yang dilaporkan — readable
                  if (item.contentSnapshot != null) ...[
                    const _DetailLabel('Konten yang Dilaporkan'),
                    const SizedBox(height: 8),
                    _ReadableContent(
                      snapshot: item.contentSnapshot!,
                      targetType: item.targetType,
                    ),
                    const SizedBox(height: 12),
                  ],

                  // Deskripsi pelapor
                  if (item.description != null &&
                      item.description!.isNotEmpty) ...[
                    const _DetailLabel('Keterangan Pelapor'),
                    const SizedBox(height: 6),
                    Text(
                      item.description!,
                      style: const TextStyle(
                        color: Color(0xFF9CA3AF),
                        fontSize: 13,
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],

                  // Catatan admin
                  if (item.adminNote != null && item.adminNote!.isNotEmpty) ...[
                    const _DetailLabel('Catatan Admin'),
                    const SizedBox(height: 6),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: const Color(0xFF059669).withOpacity(0.08),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: const Color(0xFF059669).withOpacity(0.2),
                        ),
                      ),
                      child: Text(
                        item.adminNote!,
                        style: const TextStyle(
                          color: Color(0xFF9CA3AF),
                          fontSize: 13,
                          height: 1.5,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],

                  // Action buttons — hanya jika pending
                  if (item.status == 'pending') _ActionButtons(item: item),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// Widget yang menampilkan konten laporan dengan cara yang mudah dibaca
class _ReadableContent extends StatelessWidget {
  final Map<String, dynamic> snapshot;
  final String targetType;

  const _ReadableContent({required this.snapshot, required this.targetType});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: const Color(0xFF0A0A0F),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFF1F2937)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (targetType == 'article') ...[
            _buildArticleContent(),
          ] else ...[
            _buildCommentContent(),
          ],
        ],
      ),
    );
  }

  Widget _buildArticleContent() {
    final title = snapshot['title'] as String? ?? '';
    final status = snapshot['status'] as String? ?? '';
    final content = snapshot['content'] as String? ?? '';

    // Parse konten Quill Delta JSON menjadi teks biasa
    final plainText = _parseQuillContent(content);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Judul artikel
        if (title.isNotEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 8),
            decoration: const BoxDecoration(
              border: Border(bottom: BorderSide(color: Color(0xFF1F2937))),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'JUDUL',
                  style: TextStyle(
                    color: Color(0xFF6B7280),
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),

        // Status
        if (status.isNotEmpty)
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
            child: Row(
              children: [
                const Text(
                  'Status: ',
                  style: TextStyle(color: Color(0xFF6B7280), fontSize: 12),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: status == 'published'
                        ? const Color(0xFF059669).withOpacity(0.15)
                        : const Color(0xFFD97706).withOpacity(0.15),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    status == 'published' ? 'Dipublikasi' : 'Draft',
                    style: TextStyle(
                      color: status == 'published'
                          ? const Color(0xFF34D399)
                          : const Color(0xFFFBBF24),
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),

        // Isi konten
        if (plainText.isNotEmpty)
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'ISI KONTEN',
                  style: TextStyle(
                    color: Color(0xFF6B7280),
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  plainText,
                  style: const TextStyle(
                    color: Color(0xFFD1D5DB),
                    fontSize: 13,
                    height: 1.6,
                  ),
                  // Tampilkan semua teks, tidak dibatasi maxLines
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildCommentContent() {
    final commentText = snapshot['comment_text'] as String? ?? '';
    final userId = snapshot['user_id'] as String? ?? '';

    return Padding(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'ISI KOMENTAR',
            style: TextStyle(
              color: Color(0xFF6B7280),
              fontSize: 10,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            commentText.isNotEmpty ? commentText : '(Komentar kosong)',
            style: const TextStyle(
              color: Color(0xFFD1D5DB),
              fontSize: 13,
              height: 1.6,
            ),
          ),
        ],
      ),
    );
  }

  String _parseQuillContent(String content) {
    if (content.isEmpty) return '';
    try {
      final decoded = jsonDecode(content);
      if (decoded is List) {
        final buffer = StringBuffer();
        for (final op in decoded) {
          if (op is Map && op['insert'] is String) {
            buffer.write(op['insert'] as String);
          }
        }
        return buffer.toString().trim();
      }
      return content;
    } catch (_) {
      return content;
    }
  }
}

class _DetailLabel extends StatelessWidget {
  final String text;
  const _DetailLabel(this.text);

  @override
  Widget build(BuildContext context) => Text(
    text,
    style: const TextStyle(
      color: Color(0xFF6B7280),
      fontSize: 10,
      fontWeight: FontWeight.w600,
      letterSpacing: 0.5,
    ),
  );
}

class _ActionButtons extends HookConsumerWidget {
  final AdminReportItem item;
  const _ActionButtons({required this.item});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isLoading = useState(false);
    final actionState = ref.watch(reportActionProvider);

    return Column(
      children: [
        const Divider(color: Color(0xFF1F2937), height: 16),
        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: isLoading.value
                    ? null
                    : () async {
                        isLoading.value = true;
                        await ref
                            .read(reportActionProvider.notifier)
                            .resolveReport(
                              reportId: item.id,
                              status: 'dismissed',
                            );
                        isLoading.value = false;
                      },
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFF9CA3AF),
                  side: const BorderSide(color: Color(0xFF374151)),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: const Text('Tolak'),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: ElevatedButton(
                onPressed: isLoading.value
                    ? null
                    : () => _showResolveDialog(context, ref, isLoading),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFDC2626),
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: isLoading.value
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Text('Tindak'),
              ),
            ),
          ],
        ),
      ],
    );
  }

  void _showResolveDialog(
    BuildContext context,
    WidgetRef ref,
    ValueNotifier<bool> loading,
  ) {
    final noteCtrl = TextEditingController();
    bool deleteContent = false;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setS) => AlertDialog(
          backgroundColor: const Color(0xFF1A1A2E),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Text(
            'Tindak Laporan',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Catatan admin (opsional)',
                  style: TextStyle(color: Color(0xFF9CA3AF), fontSize: 13),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: noteCtrl,
                  style: const TextStyle(color: Colors.white, fontSize: 14),
                  maxLines: 3,
                  decoration: InputDecoration(
                    hintText: 'Catatan keputusan...',
                    hintStyle: const TextStyle(
                      color: Color(0xFF4B5563),
                      fontSize: 13,
                    ),
                    filled: true,
                    fillColor: const Color(0xFF111827),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(color: Color(0xFF374151)),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(color: Color(0xFF374151)),
                    ),
                    contentPadding: const EdgeInsets.all(12),
                  ),
                ),
                const SizedBox(height: 10),
                CheckboxListTile(
                  value: deleteContent,
                  onChanged: (v) => setS(() => deleteContent = v ?? false),
                  title: Text(
                    'Hapus ${item.targetType == 'article' ? 'artikel' : 'komentar'} terkait',
                    style: const TextStyle(
                      color: Color(0xFFD1D5DB),
                      fontSize: 13,
                    ),
                  ),
                  controlAffinity: ListTileControlAffinity.leading,
                  contentPadding: EdgeInsets.zero,
                  activeColor: const Color(0xFFEF4444),
                  side: const BorderSide(color: Color(0xFF374151)),
                ),
              ],
            ),
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
              onPressed: () async {
                Navigator.pop(ctx);
                loading.value = true;
                final ok = await ref
                    .read(reportActionProvider.notifier)
                    .resolveReport(
                      reportId: item.id,
                      status: 'resolved',
                      adminNote: noteCtrl.text.trim().isEmpty
                          ? null
                          : noteCtrl.text.trim(),
                      deleteTargetId: deleteContent ? item.targetId : null,
                      deleteTargetType: deleteContent ? item.targetType : null,
                    );
                loading.value = false;

                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        ok
                            ? 'Laporan berhasil ditindak.'
                            : 'Gagal menindak laporan.',
                      ),
                      backgroundColor: ok
                          ? const Color(0xFF059669)
                          : const Color(0xFFDC2626),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFDC2626),
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text(
                'Konfirmasi',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyView extends StatelessWidget {
  const _EmptyView();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.report_off_outlined, color: Color(0xFF374151), size: 56),
          SizedBox(height: 12),
          Text('Tidak ada laporan', style: TextStyle(color: Color(0xFF6B7280))),
        ],
      ),
    );
  }
}
