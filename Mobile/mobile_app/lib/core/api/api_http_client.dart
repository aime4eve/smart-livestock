import 'package:http/http.dart' as http;

class ApiHttpResponse {
  const ApiHttpResponse(this.statusCode, this.body, this.headers);

  final int statusCode;
  final String body;
  final Map<String, String> headers;
}

abstract class ApiHttpClient {
  Future<ApiHttpResponse> get(Uri uri, {Map<String, String>? headers});

  Future<ApiHttpResponse> post(
    Uri uri, {
    Map<String, String>? headers,
    Object? body,
  });
}

class DefaultApiHttpClient implements ApiHttpClient {
  const DefaultApiHttpClient();

  @override
  Future<ApiHttpResponse> get(Uri uri, {Map<String, String>? headers}) async {
    final response = await http
        .get(uri, headers: headers)
        .timeout(const Duration(seconds: 20));
    return ApiHttpResponse(
      response.statusCode,
      response.body,
      response.headers,
    );
  }

  @override
  Future<ApiHttpResponse> post(
    Uri uri, {
    Map<String, String>? headers,
    Object? body,
  }) async {
    final response = await http
        .post(uri, headers: headers, body: body)
        .timeout(const Duration(seconds: 20));
    return ApiHttpResponse(
      response.statusCode,
      response.body,
      response.headers,
    );
  }
}
