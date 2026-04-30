import 'package:smart_livestock_demo/app/app_mode.dart';
import 'package:smart_livestock_demo/core/api/api_cache.dart';
import 'package:smart_livestock_demo/core/models/view_state.dart';

class B2bFarmSummary {
  const B2bFarmSummary({
    required this.id,
    required this.name,
    required this.status,
    required this.ownerName,
    required this.livestockCount,
    required this.region,
    this.createdAt,
  });

  final String id;
  final String name;
  final String status;
  final String ownerName;
  final int livestockCount;
  final String region;
  final String? createdAt;
}

class B2bDashboardData {
  const B2bDashboardData({
    required this.viewState,
    this.totalFarms = 0,
    this.totalLivestock = 0,
    this.totalDevices = 0,
    this.pendingAlerts = 0,
    this.farms = const [],
    this.contractStatus,
    this.contractExpiresAt,
    this.message,
  });

  final ViewState viewState;
  final int totalFarms;
  final int totalLivestock;
  final int totalDevices;
  final int pendingAlerts;
  final List<B2bFarmSummary> farms;
  final String? contractStatus;
  final String? contractExpiresAt;
  final String? message;
}

class B2bContractData {
  const B2bContractData({
    required this.viewState,
    this.id,
    this.status,
    this.effectiveTier,
    this.revenueShareRatio,
    this.startedAt,
    this.expiresAt,
    this.signedBy,
    this.message,
  });

  final ViewState viewState;
  final String? id;
  final String? status;
  final String? effectiveTier;
  final double? revenueShareRatio;
  final String? startedAt;
  final String? expiresAt;
  final String? signedBy;
  final String? message;
}

class B2bRepository {
  const B2bRepository();

  B2bDashboardData loadDashboard(ViewState viewState, AppMode appMode) {
    if (viewState != ViewState.normal) {
      return B2bDashboardData(viewState: viewState);
    }

    if (appMode.isLive) {
      return _loadDashboardFromCache();
    }

    return const B2bDashboardData(
      viewState: ViewState.normal,
      totalFarms: 1,
      totalLivestock: 120,
      totalDevices: 95,
      pendingAlerts: 5,
      farms: [
        B2bFarmSummary(
          id: 'tenant_f_p001_001',
          name: '星辰合作牧场A',
          status: 'active',
          ownerName: '马七',
          livestockCount: 120,
          region: '华中',
        ),
      ],
      contractStatus: 'active',
      contractExpiresAt: '2027-01-01T00:00:00+08:00',
    );
  }

  B2bContractData loadContract(ViewState viewState, AppMode appMode) {
    if (viewState != ViewState.normal) {
      return B2bContractData(viewState: viewState);
    }

    if (appMode.isLive) {
      return _loadContractFromCache();
    }

    return const B2bContractData(
      viewState: ViewState.normal,
      id: 'contract_001',
      status: 'active',
      effectiveTier: 'standard',
      revenueShareRatio: 0.15,
      startedAt: '2026-01-01T00:00:00+08:00',
      expiresAt: '2027-01-01T00:00:00+08:00',
      signedBy: '王五',
    );
  }

  B2bDashboardData _loadDashboardFromCache() {
    try {
      final data = ApiCache.instance.b2bDashboard;
      if (data == null) {
        return const B2bDashboardData(viewState: ViewState.normal);
      }
      final farms = (data['farms'] as List?)
              ?.map((f) => B2bFarmSummary(
                    id: f['id'] as String,
                    name: f['name'] as String,
                    status: f['status'] as String,
                    ownerName: f['ownerName'] as String? ?? '',
                    livestockCount: f['livestockCount'] as int? ?? 0,
                    region: f['region'] as String? ?? '',
                  ))
              .toList() ??
          [];

      return B2bDashboardData(
        viewState: ViewState.normal,
        totalFarms: data['totalFarms'] as int? ?? 0,
        totalLivestock: data['totalLivestock'] as int? ?? 0,
        totalDevices: data['totalDevices'] as int? ?? 0,
        pendingAlerts: data['pendingAlerts'] as int? ?? 0,
        farms: farms,
        contractStatus: data['contractStatus'] as String?,
        contractExpiresAt: data['contractExpiresAt'] as String?,
      );
    } catch (_) {
      return const B2bDashboardData(viewState: ViewState.normal);
    }
  }

  B2bContractData _loadContractFromCache() {
    try {
      final data = ApiCache.instance.b2bContract;
      if (data == null) {
        return const B2bContractData(viewState: ViewState.normal);
      }
      return B2bContractData(
        viewState: ViewState.normal,
        id: data['id'] as String?,
        status: data['status'] as String?,
        effectiveTier: data['effectiveTier'] as String?,
        revenueShareRatio: (data['revenueShareRatio'] as num?)?.toDouble(),
        startedAt: data['startedAt'] as String?,
        expiresAt: data['expiresAt'] as String?,
        signedBy: data['signedBy'] as String?,
      );
    } catch (_) {
      return const B2bContractData(viewState: ViewState.normal);
    }
  }
}
