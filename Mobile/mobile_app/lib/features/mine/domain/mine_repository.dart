abstract class MineRepository {
  Future<MineViewData> load();
}

class MineViewData {
  const MineViewData({
    required this.normalText,
  });

  final String normalText;
}
