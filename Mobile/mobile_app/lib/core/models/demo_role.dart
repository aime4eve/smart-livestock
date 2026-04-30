enum DemoRole {
  owner,
  worker,
  platformAdmin,
  b2bAdmin,
  apiConsumer,
}

extension DemoRoleX on DemoRole {
  String get wireName {
    return switch (this) {
      DemoRole.platformAdmin => 'platform_admin',
      DemoRole.b2bAdmin => 'b2b_admin',
      DemoRole.apiConsumer => 'api_consumer',
      _ => name,
    };
  }

  String get mockToken => 'mock-token-${wireName.replaceAll('_', '-')}';
}

DemoRole demoRoleFromWireName(String value) {
  return DemoRole.values.firstWhere(
    (role) => role.name == value || role.wireName == value,
  );
}
