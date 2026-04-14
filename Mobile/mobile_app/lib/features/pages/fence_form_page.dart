import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:smart_livestock_demo/app/app_mode.dart';
import 'package:smart_livestock_demo/core/api/api_cache.dart';
import 'package:smart_livestock_demo/core/api/api_role.dart';
import 'package:smart_livestock_demo/core/data/demo_seed.dart';
import 'package:smart_livestock_demo/core/theme/app_colors.dart';
import 'package:smart_livestock_demo/core/theme/app_spacing.dart';
import 'package:smart_livestock_demo/features/fence/domain/fence_item.dart';
import 'package:smart_livestock_demo/features/fence/presentation/fence_controller.dart';

class FenceFormPage extends ConsumerStatefulWidget {
  const FenceFormPage({super.key, this.fenceId});

  final String? fenceId;

  @override
  ConsumerState<FenceFormPage> createState() => _FenceFormPageState();
}

class _FenceFormPageState extends ConsumerState<FenceFormPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  FenceType _type = FenceType.rectangle;
  bool _alarmEnabled = true;
  bool _active = true;
  bool _saving = false;
  bool _initialized = false;

  bool get _isEdit => widget.fenceId != null;

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  void _initForEdit() {
    if (_initialized || !_isEdit) return;
    _initialized = true;
    final fenceState = ref.read(fenceControllerProvider);
    FenceItem? fence;
    for (final f in fenceState.fences) {
      if (f.id == widget.fenceId) {
        fence = f;
        break;
      }
    }
    if (fence == null) return;
    _nameController.text = fence.name;
    _type = fence.type;
    _alarmEnabled = fence.alarmEnabled;
    _active = fence.active;
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);

    final appMode = ref.read(appModeProvider);
    final controller = ref.read(fenceControllerProvider.notifier);

    if (appMode.isLive) {
      final coords = _coordinatesForSave();
      final body = <String, dynamic>{
        'name': _nameController.text.trim(),
        'type': _type.name,
        'coordinates': coords,
        'alarmEnabled': _alarmEnabled,
      };
      if (_isEdit) {
        body['status'] = _active ? 'active' : 'inactive';
      }
      final ok = _isEdit
          ? await ApiCache.instance.updateFenceRemote(
              apiRoleFromEnvironment,
              widget.fenceId!,
              body,
            )
          : await ApiCache.instance.createFenceRemote(
              apiRoleFromEnvironment,
              body,
            );
      if (!ok) {
        if (mounted) {
          setState(() => _saving = false);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('保存失败，请稍后重试')),
          );
        }
        return;
      }
      await ApiCache.instance.refreshFencesAndMap(apiRoleFromEnvironment);
      controller.reloadFromRepository();
      if (mounted) {
        setState(() => _saving = false);
        context.pop();
      }
      return;
    }

    await Future.delayed(const Duration(milliseconds: 500));

    if (_isEdit) {
      final fenceState = ref.read(fenceControllerProvider);
      FenceItem? existing;
      for (final f in fenceState.fences) {
        if (f.id == widget.fenceId) {
          existing = f;
          break;
        }
      }
      if (existing != null) {
        controller.update(existing.copyWith(
          name: _nameController.text,
          type: _type,
          alarmEnabled: _alarmEnabled,
          active: _active,
        ));
      }
    } else {
      final id = 'fence_${DateTime.now().millisecondsSinceEpoch}';
      final fenceCount = ref.read(fenceControllerProvider).fences.length;
      controller.add(FenceItem(
        id: id,
        name: _nameController.text,
        type: _type,
        alarmEnabled: _alarmEnabled,
        active: _active,
        areaHectares: 1.0,
        livestockCount: 0,
        colorValue:
            FenceItem.defaultColors[fenceCount % FenceItem.defaultColors.length],
        points: FenceItem.defaultPointsForType(_type, DemoSeed.mapCenter),
      ));
    }

    if (mounted) {
      setState(() => _saving = false);
      context.pop();
    }
  }

  List<List<double>> _coordinatesForSave() {
    final fenceState = ref.read(fenceControllerProvider);
    if (_isEdit) {
      FenceItem? existing;
      for (final f in fenceState.fences) {
        if (f.id == widget.fenceId) {
          existing = f;
          break;
        }
      }
      if (existing != null) {
        final pts = existing.type == _type
            ? existing.points
            : FenceItem.defaultPointsForType(_type, DemoSeed.mapCenter);
        return pts.map((p) => [p.longitude, p.latitude]).toList();
      }
    }
    return FenceItem.defaultPointsForType(_type, DemoSeed.mapCenter)
        .map((p) => [p.longitude, p.latitude])
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    _initForEdit();
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEdit ? '编辑围栏' : '新建围栏'),
        leading: IconButton(
          key: const Key('fence-form-back'),
          onPressed: () => context.pop(),
          icon: const Icon(Icons.arrow_back),
        ),
      ),
      body: SingleChildScrollView(
        key: const Key('page-fence-form'),
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                key: const Key('fence-form-name'),
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: '围栏名称',
                  border: OutlineInputBorder(),
                ),
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? '请输入围栏名称' : null,
              ),
              const SizedBox(height: AppSpacing.lg),
              KeyedSubtree(
                key: const Key('fence-form-type'),
                child: DropdownButtonFormField<FenceType>(
                  key: ValueKey<FenceType>(_type),
                  initialValue: _type,
                  decoration: const InputDecoration(
                    labelText: '围栏类型',
                    border: OutlineInputBorder(),
                  ),
                  items: const [
                    DropdownMenuItem(
                      value: FenceType.rectangle,
                      child: Text('矩形'),
                    ),
                    DropdownMenuItem(
                      value: FenceType.circle,
                      child: Text('圆形'),
                    ),
                    DropdownMenuItem(
                      value: FenceType.polygon,
                      child: Text('多边形'),
                    ),
                  ],
                  onChanged: (v) {
                    if (v != null) setState(() => _type = v);
                  },
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              Text(
                '面积：1.0 公顷',
                key: const Key('fence-form-area'),
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(height: AppSpacing.lg),
              Container(
                key: const Key('fence-form-map-placeholder'),
                height: 180,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFE8F2E5), Color(0xFFF8F6F0)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(AppSpacing.lg),
                  border: Border.all(color: Theme.of(context).dividerColor),
                ),
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.draw_outlined,
                        size: 32,
                        color: AppColors.primary,
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      Text(
                        '地图选区（占位）',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              SwitchListTile(
                key: const Key('fence-form-alarm'),
                contentPadding: EdgeInsets.zero,
                title: const Text('启用告警'),
                value: _alarmEnabled,
                onChanged: (v) => setState(() => _alarmEnabled = v),
              ),
              SwitchListTile(
                key: const Key('fence-form-active'),
                contentPadding: EdgeInsets.zero,
                title: const Text('启用状态'),
                value: _active,
                onChanged: (v) => setState(() => _active = v),
              ),
              const SizedBox(height: AppSpacing.xl),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      key: const Key('fence-form-cancel'),
                      onPressed: () => context.pop(),
                      child: const Text('取消'),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: FilledButton(
                      key: const Key('fence-form-save'),
                      onPressed: _saving ? null : _save,
                      child: _saving
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child:
                                  CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Text('保存围栏'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
