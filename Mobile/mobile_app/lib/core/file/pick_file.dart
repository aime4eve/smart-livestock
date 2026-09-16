export 'pick_file_stub.dart'
    if (dart.library.html) 'pick_file_web.dart'
    if (dart.library.io) 'pick_file_io.dart';

/// Picked file with its original name (used for format detection server-side).
typedef PickedFile = ({String name, List<int> bytes});
