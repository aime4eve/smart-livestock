// lib/core/models/user_role.dart

enum UserRole {
  owner,
  worker,
  platformAdmin,
  b2bAdmin,
  apiConsumer;

  static UserRole fromString(String value) {
    return switch (value.toUpperCase()) {
      'OWNER' => UserRole.owner,
      'WORKER' => UserRole.worker,
      'PLATFORM_ADMIN' => UserRole.platformAdmin,
      'B2B_ADMIN' => UserRole.b2bAdmin,
      'API_CONSUMER' => UserRole.apiConsumer,
      _ => UserRole.worker,
    };
  }

  String get wireName => switch (this) {
    UserRole.platformAdmin => 'platform_admin',
    UserRole.b2bAdmin => 'b2b_admin',
    UserRole.apiConsumer => 'api_consumer',
    _ => name,
  };

  bool get canAccessAdminTab => this == UserRole.owner;
  bool get isPlatformAdmin => this == UserRole.platformAdmin;
  bool get isB2bAdmin => this == UserRole.b2bAdmin;
  bool get isApiConsumer => this == UserRole.apiConsumer;
  bool get isOwner => this == UserRole.owner;
  bool get isWorker => this == UserRole.worker;

  Set<String> get visibleTabs => switch (this) {
    UserRole.owner => {'dashboard', 'map', 'alerts', 'fences', 'livestock', 'devices', 'stats', 'twin', 'subscription', 'mine', 'admin'},
    UserRole.worker => {'dashboard', 'map', 'alerts', 'fences', 'mine'},
    UserRole.platformAdmin => {'admin'},
    UserRole.b2bAdmin => {'b2b'},
    UserRole.apiConsumer => {},
  };
}
