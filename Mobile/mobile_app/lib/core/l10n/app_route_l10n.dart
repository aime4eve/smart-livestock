import '../../app/app_route.dart';
import '../../l10n/gen/app_localizations.dart';

/// Localized display labels for [AppRoute] values.
///
/// Keeps `AppRoute.label` (Chinese) as a test/fallback string while
/// production UI reads the translated label via this extension.
extension AppRouteL10n on AppRoute {
  String localizedLabel(AppLocalizations l10n) {
    switch (this) {
      case AppRoute.login:
        return l10n.navLogin;
      case AppRoute.ranch:
        return l10n.navRanch;
      case AppRoute.twin:
      case AppRoute.twinFever:
      case AppRoute.twinDigestive:
      case AppRoute.twinEstrus:
      case AppRoute.twinEpidemic:
      case AppRoute.twinEpidemicContact:
      case AppRoute.twinFeverDetail:
      case AppRoute.twinDigestiveDetail:
      case AppRoute.twinEstrusDetail:
        return l10n.navTwin;
      case AppRoute.alerts:
        return l10n.navAlerts;
      case AppRoute.mine:
      case AppRoute.mineApiAuth:
      case AppRoute.workerManagement:
        return l10n.navMine;
      case AppRoute.fence:
      case AppRoute.fenceForm:
      case AppRoute.fenceConflict:
        return l10n.navFence;
      case AppRoute.b2bAdmin:
        return l10n.navOverview;
      case AppRoute.b2bAdminFarms:
      case AppRoute.b2bFarmCreation:
      case AppRoute.b2bWorkerDetail:
      case AppRoute.farmCreation:
        return l10n.navFarmManagement;
      case AppRoute.b2bAdminContract:
      case AppRoute.platformContracts:
        return l10n.navContractInfo;
      case AppRoute.b2bAdminRevenue:
      case AppRoute.b2bAdminRevenueDetail:
      case AppRoute.platformRevenue:
        return l10n.navRevenue;
      case AppRoute.devices:
     case AppRoute.livestockList:
     case AppRoute.livestockDetail:
      case AppRoute.stats:
      case AppRoute.subscription:
      case AppRoute.checkout:
      case AppRoute.subscriptionPlan:
      case AppRoute.admin:
      case AppRoute.platformAdmin:
      case AppRoute.platformSubscriptions:
      case AppRoute.platformApiAuth:
      case AppRoute.platformAuditLog:
      case AppRoute.platformFeatureGates:
      case AppRoute.platformAnalytics:
      case AppRoute.platformTileAdmin:
      case AppRoute.platformGpsQuality:
      case AppRoute.offlineTileManagement:
        return label;
    }
  }
}
