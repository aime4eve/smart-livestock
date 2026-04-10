import 'package:smart_livestock_demo/features/fence/domain/fence_item.dart';

abstract class FenceRepository {
  List<FenceItem> loadAll();
}
