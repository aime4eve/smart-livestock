// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get commonConfirm => 'Confirm';

  @override
  String get commonCancel => 'Cancel';

  @override
  String get commonSave => 'Save';

  @override
  String get commonDelete => 'Delete';

  @override
  String get commonEdit => 'Edit';

  @override
  String get commonBack => 'Back';

  @override
  String get commonLoading => 'Loading...';

  @override
  String get commonRetry => 'Retry';

  @override
  String get commonError => 'Error';

  @override
  String get commonSuccess => 'Success';

  @override
  String get commonSearch => 'Search';

  @override
  String get commonLogout => 'Log Out';

  @override
  String get commonSubmit => 'Submit';

  @override
  String get commonClose => 'Close';

  @override
  String get commonAll => 'All';

  @override
  String get commonNone => 'None';

  @override
  String get commonUnknown => 'Unknown';

  @override
  String get settingsLanguage => 'Language';

  @override
  String get settingsLanguageZh => '中文';

  @override
  String get settingsLanguageEn => 'English';

  @override
  String get settingsLanguageSystem => 'System';

  @override
  String get settingsTitle => 'Settings';

  @override
  String get errorAuthFailed => 'Authentication failed';

  @override
  String get errorServer => 'Server error';

  @override
  String get errorTenantDisabled => 'Tenant disabled';

  @override
  String get errorLoginFailed => 'Login failed';

  @override
  String get errorLoginCheckInput =>
      'Login failed, please check your phone and password';

  @override
  String get navLogin => 'Login';

  @override
  String get navRanch => 'Ranch';

  @override
  String get navTwin => 'Digital Twin';

  @override
  String get navAlerts => 'Alerts';

  @override
  String get navMine => 'Profile';

  @override
  String get navFence => 'Geofence';

  @override
  String get navAdmin => 'Admin';

  @override
  String get navOverview => 'Overview';

  @override
  String get navFarmManagement => 'Farms';

  @override
  String get navContractInfo => 'Contracts';

  @override
  String get navRevenue => 'Revenue';

  @override
  String get platformAdminTitle => 'Platform Admin';

  @override
  String get farmEmptyGuidance =>
      'No farm assigned yet. Please contact your administrator.';

  @override
  String get authAppTitle => 'Smart Livestock';

  @override
  String get authSubtitle => 'Intelligent Livestock Management';

  @override
  String get authPhoneLabel => 'Phone';

  @override
  String get authPhoneHint => 'Enter phone number';

  @override
  String get authPasswordLabel => 'Password';

  @override
  String get authPasswordHint => 'Enter password';

  @override
  String get authLoginButton => 'Log In';

  @override
  String authLoginFailed(String error) {
    return 'Login failed: $error';
  }

  @override
  String get deviceStatusOnline => 'Online';

  @override
  String get deviceStatusOffline => 'Offline';

  @override
  String get deviceStatusLowBattery => 'Low Battery';

  @override
  String get livestockHealthHealthy => 'Healthy';

  @override
  String get livestockHealthWatch => 'Watch';

  @override
  String get livestockHealthAbnormal => 'Abnormal';

  @override
  String get authLoginFormTitle => 'Account Login';

  @override
  String get authOnlineMode => 'Online Mode';

  @override
  String get authPhoneInvalid => 'Enter a valid 11-digit phone number';

  @override
  String get authLoginDescription =>
      'Sign in to manage your livestock, fences, and alerts.';

  @override
  String get deviceTypeGps => 'GPS Tracker';

  @override
  String get deviceTypeRumenCapsule => 'Rumen Capsule';

  @override
  String get deviceTypeAccelerometer => 'Accelerometer';

  @override
  String get subscriptionTierBasic => 'Basic';

  @override
  String get subscriptionTierStandard => 'Standard';

  @override
  String get subscriptionTierPremium => 'Premium';

  @override
  String get subscriptionTierEnterprise => 'Enterprise';

  @override
  String get commonLoadFailed => 'Loading Failed';

  @override
  String commonDeleteFailed(String error) => 'Delete failed: $error';

  @override
  String get commonConfirmDelete => 'Confirm Delete';

  @override
  String get commonConfirmLogout => 'Confirm Logout';

  @override
  String get commonConfirmLogoutMessage => 'Are you sure you want to log out?';

  @override
  String get ranchFenceList => 'Fence List';

  @override
  String get ranchNewFence => 'New Fence';

  @override
  String get ranchNoFence => 'No Fences';

  @override
  String get ranchCollapseFenceList => 'Collapse Fence List';

  @override
  String get ranchEditBoundary => 'Edit Boundary';

  @override
  String ranchFenceDeleted(String name) => 'Deleted "$name"';

  @override
  String ranchConfirmDeleteFence(String name) =>
      'Confirm delete "$name"? This cannot be undone.';

  @override
  String get ranchFenceActive => 'Active';

  @override
  String get ranchFenceInactive => 'Inactive';

  @override
  String ranchLivestockCountHead(String count) => '$count head';

  @override
  String get dashboardNoData => 'No Dashboard Data';

  @override
  String get dashboardTodayOverview => "Today's Ranch Overview";

  @override
  String get dashboardFarmOverview => 'Ranch Overview';

  @override
  String get dashboardNoFarm => 'No Ranch Yet';

  @override
  String get dashboardCreateFirstFarmDesc =>
      'Create your first ranch to start managing livestock';

  @override
  String get dashboardCreateFirstFarm => 'Create First Ranch';

  @override
  String get twinRealtimeOverview => 'Real-time Ranch Overview';

  @override
  String get twinHealthScenarios => 'Health Scenarios';

  @override
  String get twinPendingTasks => 'Pending Tasks';

  @override
  String get mineAccountNormal => 'Account Normal';

  @override
  String get mineAccountDisabled => 'Account Disabled';

  @override
  String mineProfileName(String name) => 'Name: $name';

  @override
  String mineProfilePhone(String phone) => 'Phone: $phone';

  @override
  String mineProfileRole(String role) => 'Role: $role';

  @override
  String get minePersonalDevices => 'Personal Devices & Tools';

  @override
  String get mineDeviceManagementDesc => 'View and manage bound IoT devices';

  @override
  String get mineOfflineMapDesc => 'Download and manage offline tile data';

  @override
  String get mineHelpSupportDesc =>
      'Device binding guide, help docs, and customer support';

  @override
  String get mineHelpSupportComingSoon => 'Help & Support page coming soon...';

  @override
  String get mineBusinessManagement => 'Business Management';

  @override
  String get mineSubscriptionManagementDesc =>
      'View and upgrade subscription plans';

  @override
  String get mineRevenueBoardDesc =>
      'View revenue sharing statements by period';

  @override
  String get mineSubscriptionServiceDesc =>
      'Manage subscription plans and business services';

  @override
  String get mineAdvancedManagement => 'Advanced Management';

  @override
  String get mineWorkerManagementDesc =>
      'View and remove ranchers in current ranch';

  @override
  String get mineApiAuthManagementDesc =>
      'Manage API Keys and third-party access authorization';

  @override
  String get mineDevicesTitle => 'Devices';

  @override
  String get mineOfflineMapTitle => 'Offline Map Management';

  @override
  String get mineHelpSupportTitle => 'Help & Support';

  @override
  String get mineSubscriptionTitle => 'Subscription Management';

  @override
  String get mineRevenueBoardTitle => 'Revenue Board';

  @override
  String get mineSubscriptionServiceTitle => 'Subscription Service Management';

  @override
  String get mineWorkerTitle => 'Worker Management';

  @override
  String get mineApiAuthTitle => 'API Authorization';

  @override
  String get commonLogoutButton => 'Exit';

  @override
  String get statsAnalysis => 'Statistics';

  @override
  String get statsTemperatureTrend => 'Temperature Trend (7d)';

  @override
  String get statsHealthRateTrend => 'Health Rate Trend (7d)';

  @override
  String get statsAlertTrend => 'Alert Trend (7d)';

  @override
  String get statsLivestock => 'Livestock';

  @override
  String get statsHealthRate => 'Health Rate';

  @override
  String get statsAlerts => 'Alerts';

  @override
  String get statsCritical => 'Critical';

  @override
  String get statsAvgTemp => 'Avg Temp';

  @override
  String get statsMotility => 'Motility';

  @override
  String get statsHealthDistribution => 'Health Distribution';

  @override
  String get fencePleaseSelectFarm => 'Please select a farm first';

  @override
  String get alertsNoAlerts => 'No Alerts';

  @override
  String get alertsNoAlertsDesc => 'No active P0 alerts.';

  @override
  String get alertsConfirm => 'Acknowledge';

  @override
  String get alertsHandle => 'Handle';

  @override
  String get alertsArchive => 'Archive';

  @override
  String get alertsBatchHandle => 'Batch Handle';

  @override
  String get alertsBatchDemo => 'Demo: Batch processing coming soon';

  @override
  String get livestockDetailTitle => 'Livestock Details';

  @override
  String get livestockBindDevices => 'Bound Devices';

  @override
  String get livestockHealthData => 'Health Data';

  @override
  String get livestockLocation => 'Location';

  @override
  String get livestockViewTrajectory => 'View Full Trajectory';

  @override
  String get feverWarningTitle => 'Fever Warning';

  @override
  String get feverNoData => 'No abnormal temperature data';

  @override
  String get digestiveTitle => 'Digestive Management';

  @override
  String get digestiveNoData => 'No abnormal digestive data';

  @override
  String digestiveItemSubtitle(String breed, String frequency, String dropPercent) =>
      '$breed  Motility $frequency/min  ↓$dropPercent%';

  @override
  String get estrusTitle => 'Estrus Detection';

  @override
  String get estrusNoData => 'No estrus data';

  @override
  String estrusItemSubtitle(String breed, String genderIcon, String stepInfo) =>
      '$breed $genderIcon $stepInfo';

  @override
  String get epidemicTitle => 'Epidemic Prevention';

  @override
  String get epidemicHerdHealth => 'Herd Health Metrics';

  @override
  String get epidemicContactTracing => 'Contact Tracing';

  @override
  String epidemicRiskLevel(String level) => 'Risk Level: $level';

  @override
  String get epidemicAvgTemperature => 'Avg Temperature';

  @override
  String get epidemicAbnormalRate => 'Abnormal Rate';

  @override
  String get epidemicAbnormalCount => 'Abnormal Count';

  @override
  String get feverDetailTitle => 'Temperature Details';

  @override
  String get feverDetailChartTitle => '72-Hour Temperature Trend';

  @override
  String get digestiveDetailTitle => 'Digestive Details';

  @override
  String get digestiveDetailChartTitle => '24-Hour Motility Trend';

  @override
  String get estrusDetailTitle => 'Estrus Details';

  @override
  String get estrusDetailChartTitle => '7-Day Score Trend';

  @override
  String get devicesManagement => 'Device Management';

  @override
  String get devicesAddDemo => 'Demo: Add new device coming soon';

  @override
  String get devicesNoDevices => 'No Devices';

  @override
  String devicesUnbindDemo(String name) => 'Demo: Unbind $name';

  @override
  String devicesViewLocationDemo(String name) => 'Demo: View $name location';

  @override
  String devicesInstallSuccess(String name) => 'Installation successful: $name';

  @override
  String devicesInstallFailed(String error) => 'Installation failed: $error';

  @override
  String devicesInstallTo(String name) => 'Install to — $name';

  @override
  String get devicesNoMatchingLivestock => 'No matching livestock';

  @override
  String get devicesOverview => 'Device Overview';

  @override
  String get devicesStatTotal => 'Total';

  @override
  String get devicesSearchHint => 'Search ear tag / breed';

  @override
  String get adminAnalytics => 'Analytics';

  @override
  String get adminAnalyticsDesc => 'API call statistics and trend analysis';

  @override
  String get adminFeatureGates => 'Feature Gates';

  @override
  String get adminFeatureGatesDesc => 'Manage tier quotas';

  @override
  String get adminAuditLog => 'Audit Log';

  @override
  String get adminAuditLogDesc => 'View system operation records';

  @override
  String get adminTileManagement => 'Tile Management';

  @override
  String get adminTileManagementDesc => 'Manage offline tile regions and tasks';

  @override
  String get adminTitle => 'Admin Console';

  @override
  String get adminSubtitle => 'Management Console — Business Data & Subscription Overview';

  @override
  String get fenceFormManualEntry => 'Manual Coordinate Entry';

  @override
  String get fenceFormApply => 'Apply';

  @override
  String get fenceFormVersionConflict => 'Version Conflict';

  @override
  String get fenceFormVersionConflictDesc =>
      'This fence has been modified elsewhere. Force overwrite?';

  @override
  String get fenceFormForceUpdate => 'Force Update';

  @override
  String fenceFormForceUpdateFailed(String error) => 'Force update failed: $error';

  @override
  String fenceFormSaveFailed(String error) => 'Save failed: $error';

  @override
  String get fenceFormRectangle => 'Rectangle';

  @override
  String get fenceFormCircle => 'Circle';

  @override
  String get fenceFormPolygon => 'Polygon';

  @override
  String get fenceFormReset => 'Reset';

  @override
  String get fenceFormManualInput => 'Manual Entry';

  @override
  String get fenceFormEnableAlarm => 'Enable Alarm';

  @override
  String get fenceFormEnableStatus => 'Enable Status';

  @override
  String get fenceFormSaveFence => 'Save Fence';

  @override String get b2bRevenueTitle => 'Revenue';
  @override String get b2bRevenueNoData => 'No revenue data available. Statements are generated on the 1st of each month.';
  @override String get b2bContractTitle => 'Contract Info';
  @override String get b2bContractTerms => 'Contract Terms';
  @override String get b2bContractServiceStatus => 'Subscription Service Status';
  @override String get b2bContractRenew => 'Contact to Renew';
  @override String get b2bDashboardTitle => 'Operations Overview';
  @override String get b2bDashboardMonthlyRevenue => 'Monthly Revenue';
  @override String get b2bDashboardPendingAlerts => 'Pending Alerts';
  @override String get b2bDashboardNoPendingAlerts => 'No pending alerts';
  @override String get b2bRevenueDetailConfirmOk => 'Revenue confirmed successfully';
  @override String get b2bRevenueDetailConfirmFailed => 'Confirmation failed, please retry';
  @override String get b2bRevenueDetailTitle => 'Revenue Details';
  @override String get b2bRevenueDetailDeviceFee => 'Device Fee Total';
  @override String get b2bRevenueDetailConfirmStatus => 'Confirmation Status';
  @override String get b2bRevenueDetailConfirmButton => 'Confirm Revenue';

  @override String get b2bFarmCreationEnterName => 'Enter ranch name';
  @override String get b2bFarmCreationSelectPoint => 'Select a point on the map or enter coordinates';
  @override String b2bFarmCreationSuccess(String name) => 'Ranch "$name" created successfully';
  @override String get b2bFarmCreationFailed => 'Creation failed, please retry';
  @override String get b2bFarmCreationTitle => 'New Ranch';
  @override String get b2bFarmCreationButton => 'Create Ranch';
  @override String get b2bFarmCreationNotSpecified => '— Not specified —';
  @override String get b2bFarmCreationUserLoadFailed => 'Failed to load user list';
  @override String get b2bFarmCreationSelectTile => 'Please select a tile region first';
  @override String get wizardExitConfirm => 'Ranch created. You will return to the main page. You can set up fences later.';
  @override String get wizardContinueSetup => 'Continue Setup';
  @override String get wizardNextStep => 'Next';
  @override String get wizardEnterRanch => 'Enter Ranch';
  @override String get wizardCreateFailedNoId => 'Failed to create ranch: no ranch ID returned';
  @override String get wizardCreateFailed => 'Failed to create ranch, please retry';
  @override String get wizardFenceMinVertices => 'Fence requires at least 3 vertices';
  @override String get wizardSetupLater => 'Set Up Later';

  @override String get subscriptionUpgradeTier => 'Upgrade Plan';
  @override String get subscriptionRenew => 'Renew';
  @override String get subscriptionConfirmCancel => 'Confirm Cancel';
  @override String get subscriptionCancelWarning => 'After cancellation, paid features will be unavailable at the end of the current period. Are you sure?';
  @override String get subscriptionKeepSubscription => 'Keep Subscription';
  @override String get subscriptionCancelled => 'Subscription Cancelled';
  @override String get subscriptionCurrentTier => 'Current Plan';
  @override String get subscriptionSelectTier => 'Select This Plan';
  @override String get subscriptionRenewNow => 'Renew Now';
  @override String subscriptionUpgradeTo(String tier) => 'Upgrade to $tier';
  @override String get subscriptionFeature => 'Feature';

  @override String get subscriptionStatusTrial => 'Trial';
  @override String get subscriptionStatusActive => 'Active';
  @override String get subscriptionStatusCancelled => 'Cancelled';
  @override String get subscriptionStatusExpired => 'Expired';

  @override String get adminSubscriptionsNoData => 'No subscription services';
  @override String get adminSubscriptionsRevoke => 'Revoke';
  @override String get adminSubscriptionsRenew => 'Renew';
  @override String get adminApiAuthCreateKey => 'Create Key';
  @override String get adminApiAuthNoKeys => 'No API Keys';
  @override String get adminApiAuthDescription => 'Manage API Key creation, activation, and revocation';
  @override String get adminApiAuthName => 'Name';
  @override String get adminApiAuthDescriptionOptional => 'Description (optional)';
  @override String get adminApiAuthScopes => 'Scopes:';
  @override String get adminApiAuthCreate => 'Create';
  @override String get adminApiAuthKeyCreated => 'Key Created';
  @override String get adminApiAuthKeyWarning => 'Save this key immediately. It will not be shown again once this dialog is closed.';
  @override String get adminApiAuthSaved => 'Saved';
  @override String get adminRevenueNoData => 'No revenue periods';
  @override String get adminContractActive => 'Active';
  @override String get adminContractDraft => 'Pending';
  @override String get adminContractTerminated => 'Terminated';
  @override String get adminContractTerminate => 'Terminate Contract';
  @override String get adminContractNoData => 'No contracts';

  @override String get adminSubscriptionsTierLabel => 'Plan';
  @override String get adminSubscriptionsQuotaLabel => 'Device Quota';

  @override String get adminApiAuthPrefixLabel => 'Prefix';
  @override String get fenceUnsavedTitle => 'Unsaved Changes';
  @override String get fenceUnsavedMessage => 'You have unsaved boundary changes. Please choose an option.';
  @override String get fenceUnsavedContinue => 'Continue Editing';
  @override String get fenceUnsavedDiscard => 'Discard Changes';
  @override String get fenceUnsavedSaveExit => 'Save and Exit';
  @override String get tenantAdjustLicenseTitle => 'Adjust License Quota';
  @override String tenantAdjustLicenseUsed(String used) => 'Currently used: $used';
  @override String get tenantAdjustLicenseNew => 'New License Quota';
  @override String get tenantAdjustLicenseConfirm => 'Confirm Adjustment';
  @override String get tenantDeleteTitle => 'Delete Tenant';
  @override String tenantDeleteMessage(String name) => 'About to delete tenant "$name". This action cannot be undone.';
  @override String get tenantDeleteReason => 'Deletion Reason';
  @override String get ranchHealthLatestAlerts => 'Latest Alerts';
  @override String ranchHealthAllRead(String count) => 'Mark All Read ($count)';
  @override String ranchHealthDismissed(String count) => 'Dismissed ($count)';
  @override String get ranchHealthIgnoreAlert => 'Ignore This Alert';
  @override String get ranchHealthFenceInfo => 'Fence Info';
  @override String get ranchHealthDetail => 'Health Details';
  @override String ranchHealthDetailLink(String type) => '$type Details';
  @override String get ranchLivestockDetailBtn => 'Details';
  @override String get ranchLivestockRelatedAlerts => 'Related Alerts';

  @override String get tenantLicenseInvalidInteger => 'Please enter a non-negative integer';
  @override String tenantLicenseBelowUsed(String used) => 'New quota cannot be less than currently used ($used)';
  @override String get tenantDeleteReasonRequired => 'Please enter a deletion reason';

  @override String get deviceInstallTo => 'Install to Livestock';
  @override String get deviceUnbind => 'Unbind';
  @override String get deviceViewLocation => 'View Location';
  @override String get offlineTileNoRegions => 'No offline maps available';
  @override String offlineTileRegionsAvailable(String count) => 'Available Regions ($count)';
  @override String get workerNewWorker => 'New Worker';
  @override String get workerName => 'Name';
  @override String get workerInitPassword => 'Initial Password';
  @override String get workerCreateSuccess => 'Worker created successfully';
  @override String workerCreateFailed(String error) => 'Creation failed: $error';
  @override String fenceConflictTitle(String name) => 'Fence Conflict: $name';
  @override String get fenceConflictDiscardMine => 'Discard My Changes';
  @override String get fenceConflictOverwrite => 'Overwrite Server Version';

  @override String fenceConflictServerVersion(String version) => 'Server Version (v$version)';
  @override String get fenceConflictLocalVersion => 'Your Changes (Offline Edit)';

  @override String get offlineTileTitle => 'Offline Map Management';

  @override String get workerAddWorker => 'Add Worker';
  @override String get workerNoFarm => 'No ranch to manage';
  @override String get workerNoFarmDesc => 'No ranch selected for current account.';
  @override String get workerNoWorkers => 'No Workers';
  @override String get workerNoWorkersDesc => 'Tap the add button to add a worker';
  @override String get workerLoadFailed => 'Failed to load workers';
  @override String get workerNameRequired => 'Name is required';
  @override String get workerPhoneRequired => 'Phone number is required';
  @override String get workerPasswordMinLength => 'Password must be at least 3 characters';

  @override String get auditLogTitle => 'Audit Log';
  @override String get auditLogOperationType => 'Operation Type';
  @override String get auditLogQuery => 'Query';
  @override String get auditLogNoData => 'No audit logs';
  @override String auditLogTotalCount(String count) => '$count total';
  @override String get tileAdminTitle => 'Tile Management';
  @override String get tileAdminNoRegions => 'No tile regions';
  @override String get tileAdminNoTasks => 'No tile tasks';
  @override String get tileAdminNoFarmTiles => 'No farm tiles assigned';
  @override String tileAdminStatusInfo(String status, String tiles, String size) => 'Status: $status | Tiles: $tiles | ${size}MB';
  @override String tileAdminRegionInfo(String region, String status) => 'Region: $region | Status: $status';
  @override String get featureGateTitle => 'Feature Gate Management';
  @override String get featureGateNoData => 'No feature gates for this tier';
  @override String get featureGateLimit => 'Limit';
  @override String get featureGateRetentionDays => 'Retention Days';
  @override String featureGateUpdated(String key) => '$key updated';
  @override String get analyticsTitle => 'Analytics';
  @override String get analyticsSelectRange => 'Select Range';
  @override String get checkoutTitle => 'Confirm Payment';
  @override String get checkoutLivestockCount => 'Enter livestock count';
  @override String get checkoutHeadUnit => 'head';
  @override String get planTitle => 'Select Plan';
  @override String get farmCreationLatLabel => 'Latitude (WGS-84)';
  @override String get farmCreationLatHint => 'Auto-filled after region selection';
  @override String get farmCreationLngLabel => 'Longitude (WGS-84)';
  @override String get farmCreationLngHint => 'Auto-filled after region selection';
  @override String get farmCreationNameLabel => 'Ranch Name *';
  @override String get farmCreationNameHint => 'Enter ranch name';
  @override String get farmCreationOwnerLabel => 'Owner';
  @override String get farmCreationOwnerHint => 'Select owner (optional)';
  @override String get farmCreationAreaLabel => 'Area (hectares)';
  @override String get farmCreationAreaHint => 'Optional';
  @override String get farmCreationTileLabel => 'Tile Region';
  @override String get farmCreationTileHint => 'Select offline tile region';
  @override String get alertSummaryTitle => 'Alert Summary';
  @override String alertSummaryCount(String count) => '$count total';
  @override String get commonNoData => 'No Data';

  @override String get tileAdminRegionsTab => 'Regions';
  @override String get tileAdminTasksTab => 'Tasks';
  @override String get tileAdminFarmTab => 'Farm Assignments';

  @override String get b2bFarmListTitle => 'Managed Farms';
  @override String get b2bFarmListOptional => 'Optional';
  @override String get b2bFarmEditName => 'Edit Farm Name';
  @override String get b2bFarmNotAssigned => 'Not Assigned';
  @override String b2bFarmCurrentOwner(String name) => 'Current Owner: $name';
  @override String get b2bFarmNewOwner => 'New Owner';
  @override String get b2bFarmConfirmChange => 'Confirm Change';
  @override String b2bFarmChangeSuccess(String farm, String owner) => '"$farm" owner changed to $owner';
  @override String b2bFarmRenameDemo(String name) => '"$name" rename feature coming soon';
  @override String get b2bFarmStatDevice => 'Devices';
  @override String get b2bFarmStatRanch => 'Ranches';
}
