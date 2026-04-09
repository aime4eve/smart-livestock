import 'package:smart_livestock_demo/core/models/view_state.dart';

enum FenceType { rectangle, circle, polygon }

class FenceCreateViewData {
  const FenceCreateViewData({
    required this.viewState,
    required this.name,
    required this.fenceType,
    required this.enterAlert,
    required this.leaveAlert,
    this.areaHectares,
    this.saving = false,
    this.saved = false,
    this.message,
  });

  final ViewState viewState;
  final String name;
  final FenceType fenceType;
  final bool enterAlert;
  final bool leaveAlert;
  final double? areaHectares;
  final bool saving;
  final bool saved;
  final String? message;

  FenceCreateViewData copyWith({
    ViewState? viewState,
    String? name,
    FenceType? fenceType,
    bool? enterAlert,
    bool? leaveAlert,
    double? areaHectares,
    bool? saving,
    bool? saved,
    String? message,
  }) {
    return FenceCreateViewData(
      viewState: viewState ?? this.viewState,
      name: name ?? this.name,
      fenceType: fenceType ?? this.fenceType,
      enterAlert: enterAlert ?? this.enterAlert,
      leaveAlert: leaveAlert ?? this.leaveAlert,
      areaHectares: areaHectares ?? this.areaHectares,
      saving: saving ?? this.saving,
      saved: saved ?? this.saved,
      message: message ?? this.message,
    );
  }
}

abstract class FenceCreateRepository {
  FenceCreateViewData load({required ViewState viewState});
}
