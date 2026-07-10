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
    this.contactName,
    this.contactPhone,
    this.contactEmail,
    this.region,
    this.remarks,
    this.createdAt,
    this.updatedAt,
    this.lastUpdatedBy,
  });

  final String id;
  final String name;
  final TenantStatus status;
  final int licenseUsed;
  final int licenseTotal;
  final String? contactName;
  final String? contactPhone;
  final String? contactEmail;
  final String? region;
  final String? remarks;
  final String? createdAt;
  final String? updatedAt;
  final String? lastUpdatedBy;

  double get licenseUsage =>
      licenseTotal == 0 ? 0 : licenseUsed / licenseTotal;

  Tenant copyWith({
    String? name,
    TenantStatus? status,
    int? licenseUsed,
    int? licenseTotal,
    String? contactName,
    String? contactPhone,
    String? contactEmail,
    String? region,
    String? remarks,
    bool clearContactName = false,
    bool clearContactPhone = false,
    bool clearContactEmail = false,
    bool clearRegion = false,
    bool clearRemarks = false,
  }) {
    return Tenant(
      id: id,
      name: name ?? this.name,
      status: status ?? this.status,
      licenseUsed: licenseUsed ?? this.licenseUsed,
      licenseTotal: licenseTotal ?? this.licenseTotal,
      contactName: clearContactName ? null : (contactName ?? this.contactName),
      contactPhone: clearContactPhone ? null : (contactPhone ?? this.contactPhone),
      contactEmail: clearContactEmail ? null : (contactEmail ?? this.contactEmail),
      region: clearRegion ? null : (region ?? this.region),
      remarks: clearRemarks ? null : (remarks ?? this.remarks),
      createdAt: createdAt,
      updatedAt: updatedAt,
      lastUpdatedBy: lastUpdatedBy,
    );
  }
}
