import 'dart:io';

/// Native platforms (review 中1): the http package's IOClient surfaces
/// connection-level failures as SocketException (dart:io), not
/// http.ClientException — without this check an offline tap would fail
/// silently on mobile.
bool isOfflineTransportFailure(Object error) => error is SocketException;
