import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hkt_livestock_agentic/core/utils/app_time.dart';
import 'package:hkt_livestock_agentic/l10n/gen/app_localizations.dart';

export 'package:hkt_livestock_agentic/core/utils/app_time.dart'
    show formatMdhm;

/// Wall-clock time of the last completed auto-refresh cycle, keyed by
/// livestock id. Auto-polling pages watch this so silent background
/// refreshes become visible instead of undetectable.
class DataRefreshedAtNotifier extends Notifier<DateTime?> {
  DataRefreshedAtNotifier(this.livestockId);
  final String livestockId;

  @override
  DateTime? build() => null;

  void mark() => state = DateTime.now();
}

final dataRefreshedAtProvider =
    NotifierProvider.family<DataRefreshedAtNotifier, DateTime?, String>(
  DataRefreshedAtNotifier.new,
);

/// Slim strip rendered as [AppBar.bottom] on auto-polling detail pages.
///
/// Silent refreshes never flash a loading state — without this strip the
/// user cannot tell that polling is running when values happen to be
/// unchanged. Hidden (empty spacer) until the first cycle completes.
class DataFreshnessIndicator extends StatelessWidget
    implements PreferredSizeWidget {
  const DataFreshnessIndicator({
    super.key,
    required this.refreshedAt,
    this.foregroundColor,
  });

  final DateTime? refreshedAt;

  /// Overrides the theme-derived tint — needed on pages whose AppBar sets an
  /// explicit dark background that the shared appBarTheme doesn't know about.
  final Color? foregroundColor;

  @override
  Size get preferredSize => const Size.fromHeight(22);

  @override
  Widget build(BuildContext context) {
    final fg = foregroundColor ??
        Theme.of(context).appBarTheme.foregroundColor ??
        Theme.of(context).colorScheme.onSurface;
    if (refreshedAt == null) {
      return SizedBox(height: preferredSize.height);
    }
    final t = refreshedAt!;
    final time = formatHms(t);
    final style = Theme.of(context).textTheme.labelSmall?.copyWith(
          color: fg.withValues(alpha: 0.7),
          fontSize: 10,
        );
    return Container(
      height: preferredSize.height,
      padding: const EdgeInsets.only(right: 16),
      alignment: Alignment.centerRight,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.sync, size: 11, color: fg.withValues(alpha: 0.7)),
          const SizedBox(width: 4),
          Text(AppLocalizations.of(context)!.dataUpdatedAt(time),
              style: style),
        ],
      ),
    );
  }
}
