import 'dart:async';
import 'package:flutter/material.dart';
import 'package:hkt_livestock_agentic/core/api/api_client.dart';
import 'package:hkt_livestock_agentic/l10n/gen/app_localizations.dart';
import 'package:hkt_livestock_agentic/core/models/subscription_tier.dart';
import 'package:hkt_livestock_agentic/core/theme/app_colors.dart';

/// NIX-324 export-entitlement card (spec §5): 30-day GDPR window countdown
/// wired to the NIX-325 APIs via the JWT channel (login state, no API key).
/// Polls a pending job every 10s; stops on COMPLETED / FAILED / closed
/// window (spec v1.2 ruling #4).
class ExportEntitlementCard extends StatefulWidget {
  const ExportEntitlementCard({super.key, required this.exportWindow});

  final ExportWindow exportWindow;

  @override
  State<ExportEntitlementCard> createState() => _ExportEntitlementCardState();
}

class _ExportEntitlementCardState extends State<ExportEntitlementCard> {
  static const _pollInterval = Duration(seconds: 10);
  Timer? _timer;
  String? _jobStatus;
  int? _jobId;
  bool _busy = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _jobStatus = widget.exportWindow.latestJobStatus;
    _jobId = widget.exportWindow.latestJobId;
    _maybeResumePolling();
  }

  @override
  void didUpdateWidget(covariant ExportEntitlementCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.exportWindow.latestJobStatus != _jobStatus) {
      _jobStatus = widget.exportWindow.latestJobStatus;
      _maybeResumePolling();
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  bool get _isTerminal =>
      _jobStatus == 'COMPLETED' || _jobStatus == 'FAILED' || _jobStatus == 'EXPIRED_CLEANED';

  void _maybeResumePolling() {
    if (_jobStatus == 'PENDING') {
      _startPolling();
    } else {
      _timer?.cancel();
    }
  }

  void _startPolling() {
    _timer?.cancel();
    _timer = Timer.periodic(_pollInterval, (_) => _refreshJob());
  }

  Future<void> _requestExport() async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final farmId = ApiClient.instance.activeFarmId;
      if (farmId == null) {
        throw StateError('no active farm');
      }
      final data = await ApiClient.instance
          .post('/open/data-export/$farmId/request');
      if (!mounted) return;
      setState(() {
        _jobId = data['jobId'] is int ? data['jobId'] as int : null;
        _jobStatus = data['status'] as String? ?? 'PENDING';
      });
      _maybeResumePolling();
    } catch (e) {
      if (mounted) {
        setState(() => _error = '$e');
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _refreshJob() async {
    if (_jobId == null) return;
    try {
      final data =
          await ApiClient.instance.get('/open/data-export/jobs/$_jobId');
      if (!mounted) return;
      final status = data['status'] as String? ?? _jobStatus;
      setState(() => _jobStatus = status);
      if (status != 'PENDING') _timer?.cancel();
    } catch (_) {
      // Network hiccup: keep polling; terminal stop happens on success.
    }
  }

  Future<void> _download() async {
    if (_jobId == null) return;
    setState(() => _busy = true);
    try {
      await ApiClient.instance
          .downloadFile('/open/data-export/jobs/$_jobId/download');
    } catch (e) {
      if (mounted) setState(() => _error = '$e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final w = widget.exportWindow;
    final total = w.windowEndsAt.difference(w.terminatedAt).inDays;
    final progress = total <= 0 ? 0.0 : (w.daysLeft / total).clamp(0.0, 1.0);

    return Container(
      key: const Key('export-entitlement-card'),
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceAlt,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color(0xFF4A7F9D),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.download_outlined,
                  size: 16, color: Color(0xFF4A7F9D)),
              const SizedBox(width: 8),
              Text(
                l10n.subscriptionExportTitle,
                style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF4A7F9D)),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(l10n.subscriptionExportBody(w.daysLeft),
              style:
                  const TextStyle(fontSize: 12, height: 1.6)),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(3),
            child: SizedBox(
              height: 6,
              child: LinearProgressIndicator(
                value: progress,
                backgroundColor: const Color(0xFFE2EDF4),
                valueColor:
                    const AlwaysStoppedAnimation(Color(0xFF4A7F9D)),
              ),
            ),
          ),
          if (_error != null) ...[
            const SizedBox(height: 8),
            Text(_error!,
                style: const TextStyle(fontSize: 11, color: AppColors.danger)),
          ],
          const SizedBox(height: 12),
          _actionRow(l10n),
        ],
      ),
    );
  }

  Widget _actionRow(dynamic l10n) {
    switch (_jobStatus) {
      case 'PENDING':
        return Row(
          children: [
            const SizedBox(
                width: 14,
                height: 14,
                child: CircularProgressIndicator(strokeWidth: 2)),
            const SizedBox(width: 8),
            Text(l10n.subscriptionExportPending,
                style: const TextStyle(fontSize: 12)),
          ],
        );
      case 'COMPLETED':
        return TextButton.icon(
          key: const Key('export-download-btn'),
          onPressed: _busy ? null : _download,
          icon: const Icon(Icons.download, size: 14),
          label: Text(l10n.subscriptionExportDownload,
              style:
                  const TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
          style: TextButton.styleFrom(
            backgroundColor: const Color(0xFF4A7F9D),
            foregroundColor: AppColors.surfaceAlt,
          ),
        );
      case 'FAILED':
      case 'EXPIRED_CLEANED':
        return TextButton(
          onPressed: _busy ? null : _requestExport,
          child: Text(l10n.subscriptionExportRetry,
              style:
                  const TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
        );
      default:
        return TextButton(
          key: const Key('export-request-btn'),
          onPressed: _busy ? null : _requestExport,
          style: TextButton.styleFrom(
            backgroundColor: const Color(0xFF4A7F9D),
            foregroundColor: AppColors.surfaceAlt,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
          child: _busy
              ? const SizedBox(
                  width: 14,
                  height: 14,
                  child: CircularProgressIndicator(
                      strokeWidth: 2, color: AppColors.surfaceAlt))
              : Text(l10n.subscriptionExportRequest,
                  style: const TextStyle(
                      fontSize: 12, fontWeight: FontWeight.w700)),
        );
    }
  }
}
