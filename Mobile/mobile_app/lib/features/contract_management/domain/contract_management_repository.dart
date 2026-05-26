class ContractSummary {
  const ContractSummary({
    required this.id,
    this.tenantId,
    this.contractNumber,
    this.billingModel,
    this.effectiveTier,
    this.revenueShareRatio,
    this.status = '',
    this.signedAt,
    this.startedAt,
    this.expiresAt,
  });

  final String id;
  final int? tenantId;
  final String? contractNumber;
  final String? billingModel;
  final String? effectiveTier;
  final double? revenueShareRatio;
  final String status;
  final String? signedAt;
  final String? startedAt;
  final String? expiresAt;

  factory ContractSummary.fromJson(Map<String, dynamic> json) {
    final rawId = json['id'];
    return ContractSummary(
      id: rawId is int ? rawId.toString() : (rawId as String? ?? ''),
      tenantId: json['tenantId'] as int?,
      contractNumber: json['contractNumber'] as String?,
      billingModel: json['billingModel'] as String?,
      effectiveTier: json['effectiveTier'] as String?,
      revenueShareRatio: (json['revenueShareRatio'] as num?)?.toDouble(),
      status: (json['status'] as String? ?? '').toLowerCase(),
      signedAt: json['signedAt'] as String?,
      startedAt: json['startedAt'] as String?,
      expiresAt: json['expiresAt'] as String?,
    );
  }

  bool get isDraft => status == 'draft';
  bool get isActive => status == 'active';
  bool get isSuspended => status == 'suspended';
  bool get isTerminated => status == 'terminated';

  String get statusLabel => switch (status) {
        'draft' => '待签署',
        'active' => '生效中',
        'suspended' => '已暂停',
        'terminated' => '已终止',
        _ => status,
      };
}

class ContractListViewData {
  const ContractListViewData({
    this.contracts = const [],
    this.total = 0,
  });

  final List<ContractSummary> contracts;
  final int total;

  bool get isEmpty => contracts.isEmpty;
}

abstract class ContractManagementRepository {
  Future<ContractListViewData> getContracts();
  Future<ContractSummary> getContractDetail(String id);
  Future<ContractSummary> createContract(Map<String, dynamic> data);
  Future<ContractSummary> updateDraft(String id, Map<String, dynamic> data);
  Future<ContractSummary> signContract(String id);
  Future<bool> updateContractStatus(String id, String targetStatus);
}
