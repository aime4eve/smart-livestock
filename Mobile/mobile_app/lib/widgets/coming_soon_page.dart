import 'package:flutter/material.dart';
import 'package:hkt_livestock_agentic/core/theme/app_colors.dart';
import 'package:hkt_livestock_agentic/core/theme/app_spacing.dart';

class ComingSoonPage extends StatelessWidget {
  const ComingSoonPage({super.key, required this.title});
  final String title;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.construction, size: 64, color: AppColors.info),
            const SizedBox(height: AppSpacing.lg),
            Text('功能开发中，敬请期待',
                style: Theme.of(context).textTheme.titleMedium),
          ],
        ),
      ),
    );
  }
}
