import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hkt_livestock_agentic/features/admin/telemetry_import/data/telemetry_import_api_repository.dart';
import 'package:hkt_livestock_agentic/features/admin/telemetry_import/domain/telemetry_import_models.dart';

final telemetryImportApiRepositoryProvider =
    Provider<TelemetryImportApiRepository>(
  (ref) => const TelemetryImportApiRepository(),
);

/// Wizard state of the telemetry import page (NIX-79).
@immutable
class TelemetryImportState {
  const TelemetryImportState({
    this.step = 0,
    this.busy = false,
    this.fileBytes,
    this.fileName,
    this.parseResult,
    this.importResult,
  });

  /// 0 upload, 1 parse preview, 2 import result.
  final int step;

  /// True while a parse/import request is in flight.
  final bool busy;
  final Uint8List? fileBytes;
  final String? fileName;
  final TelemetryParseResult? parseResult;
  final TelemetryImportResult? importResult;

  TelemetryImportState copyWith({
    int? step,
    bool? busy,
    Uint8List? fileBytes,
    String? fileName,
    TelemetryParseResult? parseResult,
    TelemetryImportResult? importResult,
  }) =>
      TelemetryImportState(
        step: step ?? this.step,
        busy: busy ?? this.busy,
        fileBytes: fileBytes ?? this.fileBytes,
        fileName: fileName ?? this.fileName,
        parseResult: parseResult ?? this.parseResult,
        importResult: importResult ?? this.importResult,
      );
}

/// State machine of the 3-step telemetry import flow:
/// upload -> parse preview -> import result.
class TelemetryImportController extends AsyncNotifier<TelemetryImportState> {
  @override
  TelemetryImportState build() => const TelemetryImportState();

  TelemetryImportState get _current =>
      state.value ?? const TelemetryImportState();

  /// Step 0: a file was picked (or replaced); any previous results are dropped.
  void selectFile(String fileName, Uint8List bytes) {
    state = AsyncData(
        TelemetryImportState(fileName: fileName, fileBytes: bytes));
  }

  /// Step 0 -> 1: parse-only preview. Rethrows on failure (page shows the
  /// error) and returns to step 0.
  Future<void> parse() async {
    final s = _current;
    final bytes = s.fileBytes;
    final name = s.fileName;
    if (bytes == null || name == null || s.busy) return;
    state = AsyncData(s.copyWith(step: 1, busy: true));
    try {
      final result = await ref
          .read(telemetryImportApiRepositoryProvider)
          .parse(bytes, name);
      state = AsyncData(_current.copyWith(busy: false, parseResult: result));
    } catch (_) {
      state = AsyncData(_current.copyWith(step: 0, busy: false));
      rethrow;
    }
  }

  /// Step 1 -> 2: persist the importable rows. Blocked when the device did
  /// not match. Rethrows on failure and returns to step 1.
  Future<void> importTelemetry() async {
    final s = _current;
    final bytes = s.fileBytes;
    final name = s.fileName;
    final parsed = s.parseResult;
    if (bytes == null || name == null || parsed == null || s.busy) return;
    if (!parsed.device.matched) return;
    state = AsyncData(s.copyWith(step: 2, busy: true));
    try {
      final result = await ref
          .read(telemetryImportApiRepositoryProvider)
          .importTelemetry(bytes, name);
      state = AsyncData(_current.copyWith(busy: false, importResult: result));
    } catch (_) {
      state = AsyncData(_current.copyWith(step: 1, busy: false));
      rethrow;
    }
  }

  /// Step 1 -> 0: keep the picked file so the user can re-parse directly.
  void backToUpload() {
    if (_current.busy) return;
    state = AsyncData(_current.copyWith(step: 0));
  }

  /// Full reset (result step "import another file" / "done").
  void reset() {
    state = const AsyncData(TelemetryImportState());
  }
}

final telemetryImportControllerProvider =
    AsyncNotifierProvider<TelemetryImportController, TelemetryImportState>(
  TelemetryImportController.new,
);
