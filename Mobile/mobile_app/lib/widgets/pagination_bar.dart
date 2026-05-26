import 'package:flutter/material.dart';
import 'package:smart_livestock_demo/core/theme/app_spacing.dart';

class PaginationBar extends StatelessWidget {
  const PaginationBar({
    super.key,
    required this.page,
    required this.pageCount,
    required this.onPageChanged,
  });

  final int page;
  final int pageCount;
  final ValueChanged<int> onPageChanged;

  @override
  Widget build(BuildContext context) {
    final canPrev = page > 1;
    final canNext = page < pageCount;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          IconButton(
            key: const Key('pagination-prev'),
            icon: const Icon(Icons.chevron_left),
            onPressed: canPrev ? () => onPageChanged(page - 1) : null,
          ),
          const SizedBox(width: AppSpacing.sm),
          Text('$page / $pageCount'),
          const SizedBox(width: AppSpacing.sm),
          IconButton(
            key: const Key('pagination-next'),
            icon: const Icon(Icons.chevron_right),
            onPressed: canNext ? () => onPageChanged(page + 1) : null,
          ),
        ],
      ),
    );
  }
}
