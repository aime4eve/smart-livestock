/// Web (and any platform without dart:io): connection-level failures of the
/// http package surface as http.ClientException, which the caller already
/// catches — there is no additional transport error type to classify here.
bool isOfflineTransportFailure(Object error) => false;
