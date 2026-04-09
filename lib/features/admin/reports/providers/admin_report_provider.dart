import 'package:flutter_riverpod/legacy.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:inersia_supabase/config/supabase_config.dart';
import 'package:inersia_supabase/features/admin/reports/services/admin_report_service.dart';

final adminReportServiceProvider = Provider.autoDispose(
  (_) => AdminReportService(),
);

final reportStatusFilterProvider = StateProvider.autoDispose<String?>(
  (ref) => null,
);
final reportTypeFilterProvider = StateProvider.autoDispose<String?>(
  (ref) => null,
);

final reportsStreamProvider = StreamProvider.autoDispose<List<AdminReportItem>>(
  (ref) {
    final status = ref.watch(reportStatusFilterProvider);
    final type = ref.watch(reportTypeFilterProvider);

    return _buildReportStream(status: status, targetType: type);
  },
);

Stream<List<AdminReportItem>> _buildReportStream({
  String? status,
  String? targetType,
}) async* {
  final client = supabaseConfig.client;

  final rawStream = client
      .from('reports')
      .stream(primaryKey: ['id'])
      .order('created_at', ascending: false);

  await for (final rows in rawStream) {
    var filtered = rows.toList();

    if (status != null) {
      filtered = filtered.where((r) => r['status'] == status).toList();
    }
    if (targetType != null) {
      filtered = filtered.where((r) => r['target_type'] == targetType).toList();
    }

    if (filtered.isEmpty) {
      yield [];
      continue;
    }

    final reporterIds = filtered
        .map((r) => r['reporter_id'] as String)
        .toSet()
        .toList();
    final reporters = await client
        .from('users')
        .select('id,name')
        .inFilter('id', reporterIds);

    final reporterMap = {
      for (final u in reporters as List) u['id'] as String: u['name'] as String,
    };

    yield filtered.map((r) {
      final enriched = Map<String, dynamic>.from(r);
      enriched['reporter'] = {
        'name': reporterMap[r['reporter_id']] ?? 'Pengguna',
      };
      return AdminReportItem.fromJson(enriched);
    }).toList();
  }
}

class ReportActionNotifier extends StateNotifier<AsyncValue<void>> {
  final AdminReportService _service;

  ReportActionNotifier(this._service) : super(const AsyncValue.data(null));

  Future<bool> resolveReport({
    required String reportId,
    required String status,
    String? adminNote,
    String? deleteTargetId,
    String? deleteTargetType,
  }) async {
    state = const AsyncValue.loading();
    try {
      await _service.updateReportStatus(
        reportId: reportId,
        status: status,
        adminNote: adminNote,
      );

      if (deleteTargetId != null) {
        if (deleteTargetType == 'article') {
          await _service.deleteArticle(deleteTargetId);
        } else {
          await _service.deleteComment(deleteTargetId);
        }
      }

      state = const AsyncValue.data(null);
      return true;
    } catch (e, s) {
      state = AsyncValue.error(e, s);
      return false;
    }
  }
}

final reportActionProvider =
    StateNotifierProvider.autoDispose<ReportActionNotifier, AsyncValue<void>>(
      (ref) => ReportActionNotifier(ref.read(adminReportServiceProvider)),
    );
