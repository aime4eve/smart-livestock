import 'package:smart_livestock_demo/core/models/demo_role.dart';

class ApiAuthTokens {
  const ApiAuthTokens({
    this.accessToken,
    this.refreshToken,
    this.expiresAt,
  });

  final String? accessToken;
  final String? refreshToken;
  final DateTime? expiresAt;
}

Map<String, String> apiHeaders({
  required DemoRole role,
  ApiAuthTokens? tokens,
  bool allowMockTokenFallback = false,
}) {
  final accessToken = tokens?.accessToken;
  final authorizationValue =
      accessToken ?? (allowMockTokenFallback ? 'mock-token-${role.name}' : null);
  return {
    'Content-Type': 'application/json',
    if (authorizationValue != null)
      'Authorization': 'Bearer $authorizationValue',
  };
}
