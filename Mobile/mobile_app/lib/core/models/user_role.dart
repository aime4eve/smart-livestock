// lib/core/models/user_role.dart

import 'package:flutter/foundation.dart';

enum UserRole {
  owner,
  worker,
  platformAdmin,
  b2bAdmin,
  apiConsumer,
  superAdmin;

  static UserRole fromString(String value) {
    return switch (value.toUpperCase()) {
      'OWNER' => UserRole.owner,
      'WORKER' => UserRole.worker,
      'PLATFORM_ADMIN' => UserRole.platformAdmin,
      'B2B_ADMIN' => UserRole.b2bAdmin,
      'API_CONSUMER' => UserRole.apiConsumer,
      'SUPER_ADMIN' => UserRole.superAdmin,
      _ => _unknown(value),
    };
  }

  static UserRole _unknown(String value) {
    debugPrint('UserRole: unknown role "$value", falling back to worker');
    return UserRole.worker;
  }

  /// Wire-format name used in API calls and mock tokens.
  String get wireName => switch (this) {
        owner => 'owner',
        worker => 'worker',
        platformAdmin => 'platform_admin',
        b2bAdmin => 'b2b_admin',
        apiConsumer => 'api_consumer',
        superAdmin => 'super_admin',
      };

  bool get canAccessAdminTab => this == UserRole.owner;
  bool get isPlatformAdmin => this == UserRole.platformAdmin;
  bool get isB2bAdmin => this == UserRole.b2bAdmin;
  bool get isApiConsumer => this == UserRole.apiConsumer;
  bool get isOwner => this == UserRole.owner;
  bool get isWorker => this == UserRole.worker;

  /// Root super-admin identity: login-only, no business authority — the
  /// session enters the system via a switched context token instead
  /// (design 2026-10-19 §4.1).
  bool get isSuperAdmin => this == UserRole.superAdmin;
}
