abstract class AdminRepository {
  Future<AdminViewData> load();
}

class AdminViewData {
  const AdminViewData({
    required this.tenantTitle,
    required this.tenantSubtitle,
    required this.licenseAdjusted,
  });

  final String tenantTitle;
  final String tenantSubtitle;
  final bool licenseAdjusted;
}
