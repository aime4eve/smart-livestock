/// Platform gate for transport-level failure classification (review 中1):
/// the offline pre-flight in FenceFormPage._openTrackDraft must recognize
/// connection failures on every platform. Web compiles this facade without
/// dart:io — the io-specific check is swapped in only on native targets.
library;

export 'track_draft_offline_probe_stub.dart'
    if (dart.library.io) 'track_draft_offline_probe_io.dart';
