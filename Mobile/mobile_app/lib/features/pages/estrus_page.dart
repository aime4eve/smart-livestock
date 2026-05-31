import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:smart_livestock_demo/core/theme/app_colors.dart';
import 'package:smart_livestock_demo/features/estrus/presentation/estrus_controller.dart';
import 'package:smart_livestock_demo/core/models/health_models.dart';

class EstrusPage extends ConsumerWidget {
  const EstrusPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncList = ref.watch(estrusListControllerProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('💕 发情识别'), backgroundColor: AppColors.primary, foregroundColor: Colors.white),
      body: asyncList.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('加载失败: $e')),
        data: (items) {
          if (items.isEmpty) {
            return const Center(child: Text('暂无发情数据', style: TextStyle(fontSize: 16)));
          }
          return RefreshIndicator(
            onRefresh: () => ref.read(estrusListControllerProvider.notifier).refresh(),
            child: ListView.builder(
              itemCount: items.length,
              padding: const EdgeInsets.all(12),
              itemBuilder: (context, index) => _EstrusCard(item: items[index]),
            ),
          );
        },
      ),
    );
  }
}

class _EstrusCard extends StatelessWidget {
  const _EstrusCard({required this.item});
  final EstrusListItem item;

  Color _scoreColor() {
    if (item.score >= 70) return AppColors.success;
    if (item.score >= 50) return AppColors.warning;
    return AppColors.textSecondary;
  }

  @override
  Widget build(BuildContext context) {
    final color = _scoreColor();
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10), side: BorderSide(color: color.withOpacity(0.3))),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: color.withOpacity(0.15),
          child: Text('${item.score}', style: TextStyle(fontWeight: FontWeight.bold, color: color)),
        ),
        title: Text(item.livestockCode, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text('${item.breed ?? ""} ${item.gender == "FEMALE" ? "♀" : ""} ${item.stepIncreasePercent != null ? "步数+${item.stepIncreasePercent}%" : ""}'),
        trailing: item.advice != null && item.score >= 50
            ? Icon(Icons.lightbulb, color: AppColors.warning, size: 20)
            : null,
        onTap: () => context.push('/twin/estrus/${item.livestockId}'),
      ),
    );
  }
}
