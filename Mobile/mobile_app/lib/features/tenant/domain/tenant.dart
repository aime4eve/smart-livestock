enum TenantStatus {
  active('active'),
  disabled('disabled');

  const TenantStatus(this.wireValue);
  final String wireValue;

  static TenantStatus? tryParse(String? value) {
    for (final s in TenantStatus.values) {
      if (s.wireValue == value) return s;
    }
    return null;
  }
}

class Tenant {
  const Tenant({
    required this.id,
    required this.name,
    required this.status,
    required this.licenseUsed,
    required this.licenseTotal,
  });

  final String id;
  final String name;
  final TenantStatus status;
  final int licenseUsed;
  final int licenseTotal;

  double get licenseUsage =>
      licenseTotal == 0 ? 0 : licenseUsed / licenseTotal;

  Tenant copyWith({
    String? name,
    TenantStatus? status,
    int? licenseUsed,
    int? licenseTotal,
  }) {
    return Tenant(
      id: id,
      name: name ?? this.name,
      status: status ?? this.status,
      licenseUsed: licenseUsed ?? this.licenseUsed,
      licenseTotal: licenseTotal ?? this.licenseTotal,
    );
  }
}
