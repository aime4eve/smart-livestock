import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hkt_livestock_agentic/core/api/farm_scoped_controller.dart';
import 'package:hkt_livestock_agentic/features/physiology/data/physiology_api_repository.dart';
import 'package:hkt_livestock_agentic/features/physiology/domain/physiology_models.dart';
import 'package:hkt_livestock_agentic/features/physiology/domain/physiology_repository.dart';

final physiologyRepositoryProvider = Provider<PhysiologyRepository>((ref) {
  return const PhysiologyApiRepository();
});

/// Farm-scoped physiology event list for one livestock (NIX-256).
///
/// Farm-scoped API + family(livestockId), so it must extend
/// FarmScopedAsyncNotifier and watch the active farm (AGENTS §5).
class PhysiologyEventListController
    extends FarmScopedAsyncNotifier<PhysiologyEventListResponse> {
  PhysiologyEventListController(this.livestockId);

  final String livestockId;

  @override
  Future<PhysiologyEventListResponse> build() async {
    watchActiveFarmId();
    return ref.read(physiologyRepositoryProvider).listEvents(livestockId);
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => ref.read(physiologyRepositoryProvider).listEvents(livestockId),
    );
  }

  /// Creates a MANUAL event and invalidates the list so the card
  /// re-fetches. Throws (ConflictException/ValidationException with the
  /// server-side i18n message) so the sheet can show it in a SnackBar.
  Future<void> createEvent({
    required PhysiologyEventType eventType,
    required DateTime occurredAt,
    String? note,
  }) async {
    await ref.read(physiologyRepositoryProvider).createEvent(
          livestockId: livestockId,
          eventType: eventType,
          occurredAt: occurredAt,
          note: note,
        );
    ref.invalidateSelf();
  }

  /// Updates a MANUAL row (date / note only — the type chip is locked in
  /// the edit sheet; DISPOSITION / ALERT_CONFIRM rows get 409 from the
  /// backend) and invalidates the list. Throws (ConflictException /
  /// ValidationException with the server-side i18n message) so the sheet
  /// can show it in a SnackBar.
  Future<void> updateEvent({
    required int eventId,
    required DateTime occurredAt,
    String? note,
  }) async {
    await ref.read(physiologyRepositoryProvider).updateEvent(
          livestockId: livestockId,
          eventId: eventId,
          occurredAt: occurredAt,
          note: note,
        );
    ref.invalidateSelf();
  }

  /// Deletes a MANUAL row (same 409 semantics for non-MANUAL rows) and
  /// invalidates the list. Throws with the server-side i18n message so
  /// the caller can surface it in a SnackBar.
  Future<void> deleteEvent({required int eventId}) async {
    await ref.read(physiologyRepositoryProvider).deleteEvent(
          livestockId: livestockId,
          eventId: eventId,
        );
    ref.invalidateSelf();
  }
}

final physiologyEventsControllerProvider = AsyncNotifierProvider.family<
    PhysiologyEventListController, PhysiologyEventListResponse, String>(
  PhysiologyEventListController.new,
);
