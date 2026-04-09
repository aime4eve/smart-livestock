class MockScenario {
  const MockScenario({
    required this.title,
    required this.subtitle,
  });

  final String title;
  final String subtitle;
}

class MockScenarios {
  const MockScenarios._();

  static const virtualFenceCanvas = MockScenario(
    title: '围栏绘制演示',
    subtitle: '支持绘制、编辑、删除与图层切换的高保真主场景',
  );

  static const offlineFence = MockScenario(
    title: '离线围栏缓存',
    subtitle: '当前为本地围栏缓存快照，恢复在线后自动同步',
  );
}
