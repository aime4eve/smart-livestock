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
  String get deviceTypeEarTag => 'Ear Tag';

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
  String commonDeleteFailed(String error) {
    return 'Delete failed: $error';
  }

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
  String ranchFenceDeleted(String name) {
    return 'Deleted \"$name\"';
  }

  @override
  String ranchConfirmDeleteFence(String name) {
    return 'Confirm delete \"$name\"? This cannot be undone.';
  }

  @override
  String get ranchFenceActive => 'Active';

  @override
  String get ranchFenceInactive => 'Inactive';

  @override
  String ranchLivestockCountHead(String count) {
    return '$count head';
  }

  @override
  String get commonNotApplicable => 'N/A';

  @override
  String ranchPeekInFence(String percent) {
    return 'In Fence $percent%';
  }

  @override
  String ranchPeekHealth(String percent) {
    return 'Health $percent%';
  }

  @override
  String ranchPeekAlertCount(String count) {
    return '$count Alerts';
  }

  @override
  String get ranchSectionFenceAlerts => 'Fence Alerts';

  @override
  String get ranchSectionFenceNormal => 'Fence Normal';

  @override
  String get ranchSectionHealthAlerts => 'Health Alerts';

  @override
  String get ranchSectionLivestockHealthy => 'Livestock Healthy';

  @override
  String get ranchSectionFenceAlertDetail => 'Fence Alert Details';

  @override
  String get ranchSectionHealthAlertDetail => 'Health Alert Details';

  @override
  String get ranchCapabilityFenceNote =>
      'The system can detect fence breaches; positioning accuracy depends on GPS signal.';

  @override
  String get ranchCapabilityHealthNote =>
      'The system notifies you of health anomalies; onsite verification is required.';

  @override
  String get ranchAlertTypeFenceBreach => 'Breach';

  @override
  String get ranchAlertTypeFenceApproach => 'Approaching Fence';

  @override
  String get ranchAlertTypeZoneApproach => 'Approaching Zone';

  @override
  String get ranchAlertTypeFever => 'Fever';

  @override
  String get ranchAlertTypeDigestive => 'Digestive Issue';

  @override
  String get ranchAlertTypeEstrus => 'Estrus';

  @override
  String get ranchAlertTypeEpidemic => 'Epidemic';

  @override
  String get ranchAlertTypeShortApproach => 'Approach';

  @override
  String get ranchAlertTypeShortZone => 'Zone';

  @override
  String get ranchAlertTypeShortDigestive => 'Digestive';

  @override
  String get ranchAlertTypeEstrusHighScore => 'High Estrus Score';

  @override
  String get ranchAlertTypeEpidemicRisk => 'Epidemic Risk';

  @override
  String get ranchHealthStatusCritical => 'Critical';

  @override
  String get ranchHealthStatusWarning => 'Warning';

  @override
  String get ranchHealthStatusNormal => 'Normal';

  @override
  String get ranchAlertStatusActive => 'Active';

  @override
  String get ranchAlertStatusDismissed => 'Dismissed';

  @override
  String get ranchAlertStatusAutoResolved => 'Auto Resolved';

  @override
  String get ranchAlertStatusHandled => 'Handled';

  @override
  String get ranchAlertStatusArchived => 'Archived';

  @override
  String ranchTimeMinutesAgo(int minutes) {
    return '$minutes min ago';
  }

  @override
  String ranchTimeHoursAgo(int hours) {
    return '$hours hr ago';
  }

  @override
  String ranchTimeDaysAgo(int days) {
    return '$days d ago';
  }

  @override
  String get ranchTimeUnknown => 'Unknown';

  @override
  String get ranchFieldStatus => 'Status';

  @override
  String get ranchFieldPrimaryAlert => 'Primary Alert';

  @override
  String get ranchFieldLocation => 'Location';

  @override
  String get ranchFieldType => 'Type';

  @override
  String get ranchFieldDistanceToFence => 'Distance to Fence';

  @override
  String get ranchFieldDirection => 'Direction';

  @override
  String get ranchFieldOccurredTime => 'Occurred At';

  @override
  String get ranchFieldTime => 'Time';

  @override
  String get ranchFieldAbnormalType => 'Abnormal Type';

  @override
  String get ranchActionDismiss => 'Dismiss';

  @override
  String ranchFenceBreachCount(String count) {
    return 'Breach $count head';
  }

  @override
  String ranchFenceApproachCount(String count) {
    return 'Approach $count head';
  }

  @override
  String ranchAutoResolvedCount(String count) {
    return 'Auto Resolved ($count)';
  }

  @override
  String get dashboardNoData => 'No Dashboard Data';

  @override
  String get dashboardTodayOverview => 'Today\'s Ranch Overview';

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
  String mineProfileName(String name) {
    return 'Name: $name';
  }

  @override
  String mineProfilePhone(String phone) {
    return 'Phone: $phone';
  }

  @override
  String mineProfileRole(String role) {
    return 'Role: $role';
  }

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
  String digestiveItemSubtitle(
    String breed,
    String frequency,
    String dropPercent,
  ) {
    return '$breed  Motility $frequency/min  ↓$dropPercent%';
  }

  @override
  String get estrusTitle => 'Estrus Detection';

  @override
  String get estrusNoData => 'No estrus data';

  @override
  String estrusItemSubtitle(String breed, String genderIcon, String stepInfo) {
    return '$breed $genderIcon $stepInfo';
  }

  @override
  String get epidemicTitle => 'Epidemic Prevention';

  @override
  String get epidemicHerdHealth => 'Herd Health Metrics';

  @override
  String get epidemicContactTracing => 'Contact Tracing';

  @override
  String epidemicRiskLevel(String level) {
    return 'Risk Level: $level';
  }

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
  String get digestiveCurrentFreq => 'Current Freq';

  @override
  String get digestiveBaselineFreq => 'Baseline Freq';

  @override
  String get digestiveStatus => 'Status';

  @override
  String get digestiveFreqUnit => 'times/min';

  @override
  String get digestiveCapabilityNote =>
      'The system can notify you of digestive abnormalities; cause must be investigated offline.';

  @override
  String get estrusDetailTitle => 'Estrus Details';

  @override
  String get estrusDetailChartTitle => '7-Day Score Trend';

  @override
  String get devicesManagement => 'Device Management';

  @override
  String get deviceSearchHint => 'Search device code';

  @override
  String deviceSearchResult(Object total) {
    return '$total results found';
  }

  @override
  String get deviceShowAll => 'Show all';

  @override
  String devicePaginationInfo(
    Object currentPage,
    Object totalPages,
    Object total,
  ) {
    return 'Page $currentPage / $totalPages, $total items';
  }

  @override
  String get devicesAddDemo => 'Demo: Add new device coming soon';

  @override
  String get devicesNoDevices => 'No Devices';

  @override
  String devicesUnbindDemo(String name) {
    return 'Demo: Unbind $name';
  }

  @override
  String deviceUnbindConfirm(String name) {
    return 'Are you sure you want to unbind device $name? The device will no longer be associated with any livestock.';
  }

  @override
  String deviceUnbindSuccess(String name) {
    return 'Unbound successfully: $name';
  }

  @override
  String deviceUnbindFailed(String error) {
    return 'Unbind failed: $error';
  }

  @override
  String devicesViewLocationDemo(String name) {
    return 'Demo: View $name location';
  }

  @override
  String devicesInstallSuccess(String name) {
    return 'Installation successful: $name';
  }

  @override
  String devicesInstallFailed(String error) {
    return 'Installation failed: $error';
  }

  @override
  String devicesInstallTo(String name) {
    return 'Install to — $name';
  }

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
  String get adminSubtitle =>
      'Management Console — Business Data & Subscription Overview';

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
  String fenceFormForceUpdateFailed(String error) {
    return 'Force update failed: $error';
  }

  @override
  String fenceFormSaveFailed(String error) {
    return 'Save failed: $error';
  }

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

  @override
  String get b2bRevenueTitle => 'Revenue';

  @override
  String get b2bRevenueNoData =>
      'No revenue data available. Statements are generated on the 1st of each month.';

  @override
  String get b2bContractTitle => 'Contract Info';

  @override
  String get b2bContractTerms => 'Contract Terms';

  @override
  String get b2bContractServiceStatus => 'Subscription Service Status';

  @override
  String get b2bContractRenew => 'Contact to Renew';

  @override
  String get b2bDashboardTitle => 'Operations Overview';

  @override
  String get b2bDashboardMonthlyRevenue => 'Monthly Revenue';

  @override
  String get b2bDashboardPendingAlerts => 'Pending Alerts';

  @override
  String get b2bDashboardNoPendingAlerts => 'No pending alerts';

  @override
  String get b2bRevenueDetailConfirmOk => 'Revenue confirmed successfully';

  @override
  String get b2bRevenueDetailConfirmFailed =>
      'Confirmation failed, please retry';

  @override
  String get b2bRevenueDetailTitle => 'Revenue Details';

  @override
  String get b2bRevenueDetailDeviceFee => 'Device Fee Total';

  @override
  String get b2bRevenueDetailConfirmStatus => 'Confirmation Status';

  @override
  String get b2bRevenueDetailConfirmButton => 'Confirm Revenue';

  @override
  String get b2bFarmCreationEnterName => 'Enter ranch name';

  @override
  String get b2bFarmCreationSelectPoint =>
      'Select a point on the map or enter coordinates';

  @override
  String b2bFarmCreationSuccess(String name) {
    return 'Ranch \"$name\" created successfully';
  }

  @override
  String get b2bFarmCreationFailed => 'Creation failed, please retry';

  @override
  String get b2bFarmCreationTitle => 'New Ranch';

  @override
  String get b2bFarmCreationButton => 'Create Ranch';

  @override
  String get b2bFarmCreationNotSpecified => '— Not specified —';

  @override
  String get b2bFarmCreationUserLoadFailed => 'Failed to load user list';

  @override
  String get b2bFarmCreationSelectTile => 'Please select a tile region first';

  @override
  String get wizardExitConfirm =>
      'Ranch created. You will return to the main page. You can set up fences later.';

  @override
  String get wizardContinueSetup => 'Continue Setup';

  @override
  String get wizardNextStep => 'Next';

  @override
  String get wizardEnterRanch => 'Enter Ranch';

  @override
  String get wizardCreateFailedNoId =>
      'Failed to create ranch: no ranch ID returned';

  @override
  String get wizardCreateFailed => 'Failed to create ranch, please retry';

  @override
  String get wizardFenceMinVertices => 'Fence requires at least 3 vertices';

  @override
  String get wizardSetupLater => 'Set Up Later';

  @override
  String get subscriptionUpgradeTier => 'Upgrade Plan';

  @override
  String get subscriptionRenew => 'Renew';

  @override
  String get subscriptionConfirmCancel => 'Confirm Cancel';

  @override
  String get subscriptionCancelWarning =>
      'After cancellation, paid features will be unavailable at the end of the current period. Are you sure?';

  @override
  String get subscriptionKeepSubscription => 'Keep Subscription';

  @override
  String get subscriptionCancelled => 'Subscription Cancelled';

  @override
  String get subscriptionCurrentTier => 'Current Plan';

  @override
  String get subscriptionSelectTier => 'Select This Plan';

  @override
  String get subscriptionRenewNow => 'Renew Now';

  @override
  String subscriptionUpgradeTo(String tier) {
    return 'Upgrade to $tier';
  }

  @override
  String get subFeatureGpsLocation => 'GPS Tracking';

  @override
  String subFeatureFenceCount(String count) {
    return 'Geofence ($count)';
  }

  @override
  String get subFeatureFenceUnlimited => 'Geofence (Unlimited)';

  @override
  String subFeatureAlertHistoryDays(String count) {
    return 'Alert History ($count days)';
  }

  @override
  String get subFeatureAlertHistory1Year => 'Alert History (1 year)';

  @override
  String subFeatureDataRetentionDays(String count) {
    return 'Data Retention ($count days)';
  }

  @override
  String get subFeatureDataRetention365 => 'Data Retention (365 days)';

  @override
  String get subFeatureDataRetention3Year => 'Data Retention (3 years)';

  @override
  String get subFeatureDashboardBasic => 'Basic Dashboard';

  @override
  String get subFeatureDashboardAdvanced => 'Advanced Dashboard';

  @override
  String get subFeatureTrajectory => 'Historical Trajectory';

  @override
  String get subFeatureDeviceManagement => 'Device Management';

  @override
  String get subFeatureHealthScore => 'Health Score';

  @override
  String get subFeatureEstrusDetect => 'Estrus Detection';

  @override
  String get subFeatureEpidemicAlert => 'Epidemic Alert';

  @override
  String get subFeatureDedicatedSupport => 'Dedicated Support';

  @override
  String get subFeatureGaitAnalysis => 'Gait Analysis';

  @override
  String get subFeatureBehaviorStats => 'Behavior Statistics';

  @override
  String get subFeatureApiAccess => 'API Access';

  @override
  String get subCurrentTier => 'Current Plan';

  @override
  String get subCustomPricing => 'Custom Pricing';

  @override
  String subPerMonth(String price) {
    return '¥$price/mo';
  }

  @override
  String subLivestockLimit(String count) {
    return 'Up to $count head';
  }

  @override
  String get subLivestockUnlimited => 'Unlimited livestock';

  @override
  String subExcessFee(String price) {
    return 'Excess: ¥$price/head/mo';
  }

  @override
  String subFeatureCountSuffix(String count) {
    return '+$count more features';
  }

  @override
  String get subSelectedPlan => 'Selected Plan';

  @override
  String get subLivestockCountLabel => 'Livestock Count';

  @override
  String get subFeeBreakdown => 'Fee Breakdown';

  @override
  String subPlanFee(String tier) {
    return 'Plan Fee ($tier)';
  }

  @override
  String subTrialEndsAt(String date, Object days) {
    return 'Trial ends $date ($days days left)';
  }

  @override
  String subValidUntil(String date) {
    return 'Valid until $date';
  }

  @override
  String subExpiresOn(String date) {
    return 'Subscription expires on $date';
  }

  @override
  String get subSubscriptionCancelled => 'Subscription cancelled';

  @override
  String get subRenewalUrgent => 'Your subscription is expiring soon';

  @override
  String subTrialRenewHint(String days) {
    return 'Trial expires in $days days. Renew now to keep all data';
  }

  @override
  String subRenewHint(String days) {
    return 'Subscription expires in $days days';
  }

  @override
  String get subSelectPlanHint => 'Choose a plan that fits your ranch';

  @override
  String subExcessDeviceFee(String count, Object price) {
    return 'Excess device fee ($count head over x $price/head)';
  }

  @override
  String get subLockedNeedDevice =>
      'This feature requires the corresponding device';

  @override
  String subLockedUpgradeTier(String tier) {
    return 'This feature requires upgrading to $tier';
  }

  @override
  String get subServiceManagement => 'Subscription Service Management';

  @override
  String get subServiceManagementDesc =>
      'Manage subscription services for all tenants';

  @override
  String get subUnknownService => 'Unknown Service';

  @override
  String subServicePeriod(String start, String end) {
    return 'Period: $start ~ $end';
  }

  @override
  String get subTotal => 'Total';

  @override
  String subConfirmPay(String amount) {
    return 'Confirm Payment ¥$amount';
  }

  @override
  String subYuanSuffix(String amount) {
    return '¥$amount';
  }

  @override
  String subSubscribeSuccess(String tier) {
    return 'Successfully subscribed to $tier';
  }

  @override
  String subExcessDeviceFeeWithin(String quota) {
    return 'Excess device fee (within $quota)';
  }

  @override
  String get subCancelSubscription => 'Cancel Subscription';

  @override
  String get b2bContractNumber => 'Contract No.';

  @override
  String get b2bContractSigner => 'Signer';

  @override
  String get b2bContractBillingMode => 'Billing Mode';

  @override
  String get b2bContractTierLevel => 'Tier Level';

  @override
  String get b2bContractRevenueShare => 'Revenue Share';

  @override
  String get b2bContractEffectiveDate => 'Effective Date';

  @override
  String get b2bContractExpiryDate => 'Expiry Date';

  @override
  String get b2bContractDeployMode => 'Deployment';

  @override
  String get b2bContractDeviceQuota => 'Device Quota';

  @override
  String get b2bContractHeartbeat => 'Heartbeat';

  @override
  String get b2bContractExpiryTime => 'Expiry Time';

  @override
  String get b2bContractContactPlatform => 'Contact Platform';

  @override
  String get b2bContractContactPlatformDesc => 'Consult renewal or changes';

  @override
  String get b2bContractDownload => 'Download Contract';

  @override
  String get b2bContractDownloadDesc => 'Export PDF (placeholder)';

  @override
  String get b2bContractComingSoon => 'Coming Soon';

  @override
  String get b2bContractChatComingSoon => 'Live chat coming soon';

  @override
  String get b2bContractPdfComingSoon => 'Contract PDF download coming soon';

  @override
  String get b2bContractGotIt => 'Got it';

  @override
  String get b2bContractClose => 'Close';

  @override
  String get b2bContractStatusActive => 'Active';

  @override
  String get b2bContractStatusSuspended => 'Suspended';

  @override
  String get b2bContractStatusExpired => 'Expired';

  @override
  String get b2bContractModeRevenueShare => 'Revenue Share';

  @override
  String get b2bContractModeLicensed => 'Licensed';

  @override
  String get b2bContractDeployCloud => 'Cloud';

  @override
  String get b2bContractDeployOnPremise => 'On-Premise';

  @override
  String get b2bContractHealthRunning => 'Running';

  @override
  String get b2bContractHealthDegraded => 'Degraded';

  @override
  String get b2bContractHealthDown => 'Down';

  @override
  String get b2bContractUnknown => 'Unknown';

  @override
  String get b2bContractExpiryLabel => 'Contract Expiry';

  @override
  String b2bContractDaysLeft(String date, Object days) {
    return '$date  ·  $days days left';
  }

  @override
  String b2bContractExpiredOn(String date) {
    return '$date  ·  Expired';
  }

  @override
  String get subPlanFeeLabel => 'Plan Fee';

  @override
  String subDeviceFee(String count, Object price) {
    return 'Device Fee ($count head × ¥$price/head)';
  }

  @override
  String get subscriptionFeature => 'Feature';

  @override
  String get subscriptionStatusTrial => 'Trial';

  @override
  String get subscriptionStatusActive => 'Active';

  @override
  String get subscriptionStatusCancelled => 'Cancelled';

  @override
  String get subscriptionStatusExpired => 'Expired';

  @override
  String get adminSubscriptionsNoData => 'No subscription services';

  @override
  String get adminSubscriptionsRevoke => 'Revoke';

  @override
  String get adminSubscriptionsRenew => 'Renew';

  @override
  String get adminApiAuthCreateKey => 'Create Key';

  @override
  String get adminApiAuthNoKeys => 'No API Keys';

  @override
  String get adminApiAuthDescription =>
      'Manage API Key creation, activation, and revocation';

  @override
  String get adminApiAuthName => 'Name';

  @override
  String get adminApiAuthDescriptionOptional => 'Description (optional)';

  @override
  String get adminApiAuthScopes => 'Scopes:';

  @override
  String get adminApiAuthCreate => 'Create';

  @override
  String get adminApiAuthKeyCreated => 'Key Created';

  @override
  String get adminApiAuthKeyWarning =>
      'Save this key immediately. It will not be shown again once this dialog is closed.';

  @override
  String get adminApiAuthSaved => 'Saved';

  @override
  String get adminRevenueNoData => 'No revenue periods';

  @override
  String get adminContractActive => 'Active';

  @override
  String get adminContractDraft => 'Pending';

  @override
  String get adminContractTerminated => 'Terminated';

  @override
  String get adminContractTerminate => 'Terminate Contract';

  @override
  String get adminContractNoData => 'No contracts';

  @override
  String get adminSubscriptionsTierLabel => 'Plan';

  @override
  String get adminSubscriptionsQuotaLabel => 'Device Quota';

  @override
  String get adminApiAuthPrefixLabel => 'Prefix';

  @override
  String get fenceUnsavedTitle => 'Unsaved Changes';

  @override
  String get fenceUnsavedMessage =>
      'You have unsaved boundary changes. Please choose an option.';

  @override
  String get fenceUnsavedContinue => 'Continue Editing';

  @override
  String get fenceUnsavedDiscard => 'Discard Changes';

  @override
  String get fenceUnsavedSaveExit => 'Save and Exit';

  @override
  String get tenantAdjustLicenseTitle => 'Adjust License Quota';

  @override
  String tenantAdjustLicenseUsed(String used) {
    return 'Currently used: $used';
  }

  @override
  String get tenantAdjustLicenseNew => 'New License Quota';

  @override
  String get tenantAdjustLicenseConfirm => 'Confirm Adjustment';

  @override
  String get tenantDeleteTitle => 'Delete Tenant';

  @override
  String tenantDeleteMessage(String name) {
    return 'About to delete tenant \"$name\". This action cannot be undone.';
  }

  @override
  String get tenantDeleteReason => 'Deletion Reason';

  @override
  String get ranchHealthLatestAlerts => 'Latest Alerts';

  @override
  String ranchHealthAllRead(String count) {
    return 'Mark All Read ($count)';
  }

  @override
  String ranchHealthDismissed(String count) {
    return 'Dismissed ($count)';
  }

  @override
  String get ranchHealthIgnoreAlert => 'Ignore This Alert';

  @override
  String get ranchHealthFenceInfo => 'Fence Info';

  @override
  String get ranchHealthDetail => 'Health Details';

  @override
  String ranchHealthDetailLink(String type) {
    return '$type Details';
  }

  @override
  String get ranchLivestockDetailBtn => 'Details';

  @override
  String get ranchLivestockRelatedAlerts => 'Related Alerts';

  @override
  String get tenantLicenseInvalidInteger =>
      'Please enter a non-negative integer';

  @override
  String tenantLicenseBelowUsed(String used) {
    return 'New quota cannot be less than currently used ($used)';
  }

  @override
  String get tenantDeleteReasonRequired => 'Please enter a deletion reason';

  @override
  String get deviceInstallTo => 'Install to Livestock';

  @override
  String get deviceActivate => 'Activate';

  @override
  String deviceActivateSuccess(String name) {
    return 'Activated successfully: $name';
  }

  @override
  String deviceActivateFailed(String error) {
    return 'Activation failed: $error';
  }

  @override
  String get deviceUnbind => 'Unbind';

  @override
  String get deviceDeleteConfirmTitle => 'Delete Device';

  @override
  String get deviceDeleteConfirmContent =>
      'Delete this device? It will be removed from the list and its history is preserved. Re-adding a device with the same EUI will restore the original record.';

  @override
  String get deviceDeleteSuccess => 'Device deleted';

  @override
  String deviceDeleteFailed(String error) {
    return 'Failed to delete device: $error';
  }

  @override
  String get deviceViewLocation => 'View Location';

  @override
  String get offlineTileNoRegions => 'No offline maps available';

  @override
  String get offlineTileGenerate => 'Generate offline map';

  @override
  String get offlineTileGeneratingHint =>
      'Generation requested. It takes a few minutes; please re-enter this page later.';

  @override
  String get offlineTileRecheck => 'Re-check';

  @override
  String offlineTileRegionsAvailable(String count) {
    return 'Available Regions ($count)';
  }

  @override
  String get workerNewWorker => 'New Worker';

  @override
  String get workerName => 'Name';

  @override
  String get workerInitPassword => 'Initial Password';

  @override
  String get workerCreateSuccess => 'Worker created successfully';

  @override
  String workerCreateFailed(String error) {
    return 'Creation failed: $error';
  }

  @override
  String fenceConflictTitle(String name) {
    return 'Fence Conflict: $name';
  }

  @override
  String get fenceConflictDiscardMine => 'Discard My Changes';

  @override
  String get fenceConflictOverwrite => 'Overwrite Server Version';

  @override
  String fenceConflictServerVersion(String version) {
    return 'Server Version (v$version)';
  }

  @override
  String get fenceConflictLocalVersion => 'Your Changes (Offline Edit)';

  @override
  String get offlineTileTitle => 'Offline Map Management';

  @override
  String get offlineTileDownload => 'Download';

  @override
  String offlineTileDownloading(String region) {
    return 'Downloading $region...';
  }

  @override
  String offlineTileDownloadFailed(String error) {
    return 'Download failed: $error';
  }

  @override
  String get offlineTileDownloadSuccess => 'Download complete';

  @override
  String get offlineTileDelete => 'Delete';

  @override
  String get offlineTileDeleteConfirm =>
      'Delete this offline map? You will need to re-download it to use offline.';

  @override
  String offlineTileStorageUsed(String used) {
    return 'Storage: $used';
  }

  @override
  String offlineTileDownloadedRegions(String count) {
    return 'Downloaded ($count)';
  }

  @override
  String get offlineTileCancel => 'Cancel';

  @override
  String get offlineTileRedownload => 'Update';

  @override
  String get offlineTileNoDownloaded => 'No offline maps downloaded yet';

  @override
  String get workerAddWorker => 'Add Worker';

  @override
  String get workerNoFarm => 'No ranch to manage';

  @override
  String get workerNoFarmDesc => 'No ranch selected for current account.';

  @override
  String get workerNoWorkers => 'No Workers';

  @override
  String get workerNoWorkersDesc => 'Tap the add button to add a worker';

  @override
  String get workerLoadFailed => 'Failed to load workers';

  @override
  String get workerNameRequired => 'Name is required';

  @override
  String get workerPhoneRequired => 'Phone number is required';

  @override
  String get workerPasswordMinLength =>
      'Password must be at least 3 characters';

  @override
  String get auditLogTitle => 'Audit Log';

  @override
  String get auditLogOperationType => 'Operation Type';

  @override
  String get auditLogQuery => 'Query';

  @override
  String get auditLogNoData => 'No audit logs';

  @override
  String auditLogTotalCount(String count) {
    return '$count total';
  }

  @override
  String get tileAdminTitle => 'Tile Management';

  @override
  String get tileAdminNoRegions => 'No tile regions';

  @override
  String get tileAdminNoTasks => 'No tile tasks';

  @override
  String get tileAdminNoFarmTiles => 'No farm tiles assigned';

  @override
  String tileAdminStatusInfo(String status, String tiles, String size) {
    return 'Status: $status | Tiles: $tiles | ${size}MB';
  }

  @override
  String tileAdminRegionInfo(String region, String status) {
    return 'Region: $region | Status: $status';
  }

  @override
  String get featureGateTitle => 'Feature Gate Management';

  @override
  String get featureGateNoData => 'No feature gates for this tier';

  @override
  String get featureGateLimit => 'Limit';

  @override
  String get featureGateRetentionDays => 'Retention Days';

  @override
  String featureGateUpdated(String key) {
    return '$key updated';
  }

  @override
  String get analyticsTitle => 'Analytics';

  @override
  String get analyticsSelectRange => 'Select Range';

  @override
  String get checkoutTitle => 'Confirm Payment';

  @override
  String get checkoutLivestockCount => 'Enter livestock count';

  @override
  String get checkoutHeadUnit => 'head';

  @override
  String get planTitle => 'Select Plan';

  @override
  String get farmCreationLatLabel => 'Latitude (WGS-84)';

  @override
  String get farmCreationLatHint => 'Auto-filled after region selection';

  @override
  String get farmCreationLngLabel => 'Longitude (WGS-84)';

  @override
  String get farmCreationLngHint => 'Auto-filled after region selection';

  @override
  String get farmCreationNameLabel => 'Ranch Name *';

  @override
  String get farmCreationNameHint => 'Enter ranch name';

  @override
  String get farmCreationOwnerLabel => 'Owner';

  @override
  String get farmCreationOwnerHint => 'Select owner (optional)';

  @override
  String get farmCreationAreaLabel => 'Area (hectares)';

  @override
  String get farmCreationAreaHint => 'Optional';

  @override
  String get farmCreationTileLabel => 'Tile Region';

  @override
  String get farmCreationTileHint => 'Select offline tile region';

  @override
  String get alertSummaryTitle => 'Alert Summary';

  @override
  String alertSummaryCount(String count) {
    return '$count total';
  }

  @override
  String get commonNoData => 'No Data';

  @override
  String get tileAdminRegionsTab => 'Regions';

  @override
  String get tileAdminTasksTab => 'Tasks';

  @override
  String get tileAdminFarmTab => 'Farm Assignments';

  @override
  String get tileAdminCreateTask => 'New Tile Task';

  @override
  String get tileAdminReload => 'Reload';

  @override
  String get tileAdminRegionNameLabel => 'Region Name';

  @override
  String get tileAdminBoundsHint => 'Bounds: minLon, minLat, maxLon, maxLat';

  @override
  String get tileAdminMinZoomLabel => 'Min Zoom';

  @override
  String get tileAdminMaxZoomLabel => 'Max Zoom';

  @override
  String get tileAdminCreateSuccess =>
      'Task created. Background worker will generate tiles.';

  @override
  String get tileAdminCreateFailed => 'Failed to create task';

  @override
  String get tileAdminTaskPending => 'Queued for worker';

  @override
  String get tileAdminTilesUnit => 'tiles';

  @override
  String get tileAdminErrorPrefix => 'Error: ';

  @override
  String tileAdminRunningFor(String duration) {
    return 'Running $duration';
  }

  @override
  String tileAdminDuration(String duration) {
    return 'Duration $duration';
  }

  @override
  String get b2bFarmListTitle => 'Managed Farms';

  @override
  String get b2bFarmListOptional => 'Optional';

  @override
  String get b2bFarmEditName => 'Edit Farm Name';

  @override
  String get b2bFarmNotAssigned => 'Not Assigned';

  @override
  String b2bFarmCurrentOwner(String name) {
    return 'Current Owner: $name';
  }

  @override
  String get b2bFarmNewOwner => 'New Owner';

  @override
  String get b2bFarmConfirmChange => 'Confirm Change';

  @override
  String b2bFarmChangeSuccess(String farm, String owner) {
    return '\"$farm\" owner changed to $owner';
  }

  @override
  String b2bFarmRenameDemo(String name) {
    return '\"$name\" rename feature coming soon';
  }

  @override
  String get b2bFarmStatDevice => 'Devices';

  @override
  String get b2bFarmStatRanch => 'Ranches';

  @override
  String get b2bWorkerEditFarmInfo => 'Edit Farm Info';

  @override
  String get b2bWorkerFarmUpdated => 'Farm info updated';

  @override
  String get b2bWorkerAssign => 'Assign';

  @override
  String get b2bWorkerAssignTitle => 'Assign Workers';

  @override
  String get b2bWorkerAssignNone =>
      'No workers available. Create one with \"Add Worker\" first.';

  @override
  String b2bWorkerAssignConfirm(String count) {
    return 'Confirm Assign ($count)';
  }

  @override
  String get b2bWorkerRemoveTitle => 'Remove Worker';

  @override
  String b2bWorkerRemoveConfirm(String name, String farm) {
    return 'Remove \"$name\" from \"$farm\"?';
  }

  @override
  String get b2bWorkerConfirm => 'Confirm';

  @override
  String b2bWorkerCreated(String name) {
    return 'Worker \"$name\" created and assigned';
  }

  @override
  String get b2bWorkerUpdated => 'Worker info updated';

  @override
  String get b2bWorkerResetPwd => 'Reset Password';

  @override
  String b2bWorkerResetPwdTitle(String name) {
    return 'Reset \"$name\" Password';
  }

  @override
  String get b2bWorkerNewPassword => 'New Password';

  @override
  String get b2bWorkerConfirmReset => 'Confirm Reset';

  @override
  String get b2bWorkerPwdReset => 'Password Reset';

  @override
  String get subComparisonTitle => 'Feature Comparison';

  @override
  String get cmpFeatureFence => 'Geofence';

  @override
  String get cmpFeatureTempMonitor => 'Rumen Temperature Monitor';

  @override
  String get cmpFeaturePeristalticMonitor => 'Rumen Peristalsis Monitor';

  @override
  String get cmpFeatureStats => 'Statistics';

  @override
  String get cmpFeatureDashboard => 'Dashboard Overview';

  @override
  String get cmpFeatureDataRetention => 'Data Retention';

  @override
  String get cmpFeatureAlertHistory => 'Alert History';

  @override
  String get cmpFeatureLivestockDetail => 'Livestock Details';

  @override
  String get cmpFeatureProfile => 'Profile';

  @override
  String get cmpFeatureTenantAdmin => 'Tenant Management';

  @override
  String cmpCellYears(String count) {
    return '$count years';
  }

  @override
  String cmpCellDays(String count) {
    return '$count days';
  }

  @override
  String get cmpCellLifetime => 'Lifetime';

  @override
  String cmpCellItems(String count) {
    return '$count items';
  }

  @override
  String get fenceEditExit => 'Exit Edit';

  @override
  String get fenceEditToolMoveVertex => 'Drag Vertex';

  @override
  String get fenceEditToolInsertVertex => 'Insert Vertex';

  @override
  String get fenceEditToolDeleteVertex => 'Delete Vertex';

  @override
  String get fenceEditToolTranslate => 'Pan';

  @override
  String fenceEditTitle(String name) {
    return 'Edit Fence: $name';
  }

  @override
  String get fenceEditUndo => 'Undo';

  @override
  String get fenceEditRedo => 'Redo';

  @override
  String get fenceFormEditTitle => 'Edit Fence';

  @override
  String get fenceFormNewTitle => 'New Fence';

  @override
  String get fenceFormName => 'Fence Name';

  @override
  String get fenceFormNameRequired => 'Please enter a fence name';

  @override
  String get fenceFormType => 'Fence Type';

  @override
  String fenceFormArea(String area) {
    return 'Area: $area ha';
  }

  @override
  String fenceFormFinishDraw(String count) {
    return 'Finish Drawing ($count vertices)';
  }

  @override
  String get fenceFormDrawEnd => 'Finish';

  @override
  String get fenceFormDrawStart => 'Start Drawing';

  @override
  String get fenceFormBannerDragHint => 'Release to finish drawing';

  @override
  String get fenceFormBannerStartHint => 'Drag on the map to draw the area';

  @override
  String get fenceFormBannerPolyContinue =>
      'Tap to add more vertices, or use Finish Drawing below';

  @override
  String get fenceFormBannerPolyStart =>
      'Tap the map to add vertices (at least 3)';

  @override
  String get fenceFormFooterHint =>
      'Tap Start Drawing in the top-right to set the area, or use Manual Entry';

  @override
  String get fenceFormFooterDrag =>
      'Draw mode: map locked; drag to draw and release to finish';

  @override
  String get fenceFormFooterPoly =>
      'Draw mode: tap to add vertices; move cursor to preview lines';

  @override
  String get fenceFormManualRectHint => 'Enter 2 diagonal vertices (lat,lng)';

  @override
  String get fenceFormManualCircleHint =>
      'Enter center and boundary point (lat,lng), 2 lines';

  @override
  String get fenceFormManualPolyHint =>
      'Enter vertices (at least 3), one per line';

  @override
  String fenceFormManualMinPoints(String count) {
    return 'At least $count valid coordinate points required';
  }

  @override
  String get fenceSelectFence => 'Select Fence';

  @override
  String fenceHeadCount(String count) {
    return '$count heads';
  }

  @override
  String get fenceTemplateTitle => 'Fence Templates';

  @override
  String get fenceTemplateDesc =>
      'Quickly generate common fence shapes, then fine-tune manually';

  @override
  String get fenceTemplateRectangle => 'Rectangle Area';

  @override
  String get fenceTemplateCircle => 'Circle Area';

  @override
  String get fenceTemplateTrajectoryBuffer => 'Trajectory Buffer';

  @override
  String get fenceLoadFailed => 'Failed to load fences';

  @override
  String get fenceBoundaryMinPoints => 'Boundary requires at least 3 points';

  @override
  String get fenceBoundaryNoDuplicates =>
      'Boundary cannot have consecutive duplicate points';

  @override
  String get fenceBoundaryAreaPositive =>
      'Boundary area must be greater than 0';

  @override
  String get fenceBoundaryNoSelfIntersect => 'Boundary cannot self-intersect';

  @override
  String get fenceUnnamed => 'Unnamed';

  @override
  String get alertCenterTitle => 'Alert Center';

  @override
  String get alertCenterDesc =>
      'Focus on P0 alerts: fence breach, low battery, signal loss.';

  @override
  String get alertChipFenceBreach => 'Fence Breach';

  @override
  String get alertChipBatteryLow => 'Low Battery';

  @override
  String get alertChipSignalLost => 'Signal Lost';

  @override
  String get alertStageActive => 'Active';

  @override
  String get alertStageDismissed => 'Dismissed';

  @override
  String get alertStageAutoResolved => 'Auto Resolved';

  @override
  String get alertP0FenceBreachDetail =>
      'Tag-001 · North Zone · 24m from boundary';

  @override
  String get alertP0BatteryLowDetail =>
      'Device-045 · Battery 12% · Replace today';

  @override
  String get alertP0SignalLostDetail =>
      'Tag-023 · Offline 18 min · Last seen East Slope';

  @override
  String get b2bTabKpi => 'KPI Dashboard';

  @override
  String get b2bTabAlertActivity => 'Alert Activity';

  @override
  String get b2bStatSubFarms => 'Sub Farms';

  @override
  String get b2bStatLivestockTotal => 'Livestock Total';

  @override
  String get b2bStatWorkers => 'Workers';

  @override
  String get b2bStatDeviceOnlineRate => 'Device Online Rate';

  @override
  String get b2bStatDeviceTotal => 'Devices';

  @override
  String get b2bNavLinkDevices => 'Devices';

  @override
  String get b2bNavLinkContracts => 'Contracts';

  @override
  String get b2bNavLinkRevenue => 'Revenue';

  @override
  String get b2bContractActive => 'Contract Active';

  @override
  String get b2bContractPendingRenew => 'Contract Pending Renewal';

  @override
  String get b2bUnknownFarm => 'Unknown Farm';

  @override
  String get b2bAlertTypeDefault => 'Alert';

  @override
  String get b2bAlertTypeFenceBreach => 'Fence Breach';

  @override
  String get b2bAlertTypeHealth => 'Health Abnormal';

  @override
  String get b2bAlertTypeDeviceOffline => 'Device Offline';

  @override
  String b2bLivestockLabel(String id) {
    return 'Livestock #$id';
  }

  @override
  String get alertFilterPending => 'Pending';

  @override
  String get alertFilterHandled => 'Handled';

  @override
  String get feverCurrentTemp => 'Current Temp';

  @override
  String get feverBaselineTemp => 'Baseline Temp';

  @override
  String get feverStatus => 'Status';

  @override
  String get feverCapabilityNote =>
      'The system can notify you of temperature abnormalities; cause must be investigated offline.';

  @override
  String get feverDurationChartTitle => 'Fever Duration Analysis';

  @override
  String get feverDurationChartSubtitle =>
      'Daily hours above threshold (>39.5°C)';

  @override
  String get digestiveHeatmapTitle => '24h Motility Intensity Heatmap';

  @override
  String get digestiveHeatmapSubtitle =>
      'Darker = lower intensity (abnormal zones highlighted red)';

  @override
  String get estrusLockedTitle => 'Estrus Detection Detail';

  @override
  String get estrusCapabilityNote =>
      'The system can detect high-score estrus livestock; manual confirmation recommended.';

  @override
  String get metricScore => 'Score';

  @override
  String get metricStepIncrease => 'Step Increase';

  @override
  String get metricTempDelta => 'Temp Delta';

  @override
  String get epidemicContactTitle => 'Epidemic Contact Tracing';

  @override
  String get epidemicContactLockedMsg =>
      'Epidemic contact tracing requires Premium or above';

  @override
  String get epidemicContactUpgrade => 'Upgrade to Premium';

  @override
  String get epidemicNoContacts => 'No contact records';

  @override
  String get epidemicSourceInfected => 'Confirmed Infected';

  @override
  String get epidemicNotMarked => 'Not marked';

  @override
  String get epidemicMarkedAt => 'Marked at';

  @override
  String get epidemicUnknown => 'Unknown';

  @override
  String get epidemicRiskFormula =>
      'Risk Score = Time decay (40%) + Distance (35%) + Duration (25%). ≥70 High, 40-69 Medium, <40 Low.';

  @override
  String get epidemicNetworkGraph => 'Contact Network Graph';

  @override
  String get riskHigh => 'High';

  @override
  String get riskMedium => 'Medium';

  @override
  String get riskLow => 'Low';

  @override
  String get contactWindow24h => 'Within 24h';

  @override
  String get contactWindow48h => 'Within 48h';

  @override
  String get contactWindow72h => 'Within 72h';

  @override
  String get contactCountSuffix => 'head';

  @override
  String get contactScoreLabel => 'Score';

  @override
  String get contactDistance => 'Distance';

  @override
  String get contactDuration => 'Duration';

  @override
  String get contactFactorTime => 'Time';

  @override
  String get contactFactorDistance => 'Distance';

  @override
  String get contactFactorDuration => 'Duration';

  @override
  String get epidemicContactNote =>
      'Based on GPS trajectory spatiotemporal cross-analysis, automatically identifies livestock in close contact with the infected animal within 72h and assesses infection risk.';

  @override
  String get viewContactTracing => 'View Contact Tracing';

  @override
  String get livestockBreed => 'Breed';

  @override
  String get livestockAgeMonthsLabel => 'Age';

  @override
  String livestockAgeMonthsValue(int count) {
    return '$count months';
  }

  @override
  String get livestockWeight => 'Weight';

  @override
  String deviceBatteryValue(int percent) {
    return 'Battery $percent%';
  }

  @override
  String deviceSignalValue(String value) {
    return 'Signal $value';
  }

  @override
  String get livestockBodyTemp => 'Body Temp';

  @override
  String get livestockActivity => 'Activity';

  @override
  String get livestockRumination => 'Rumination';

  @override
  String livestockRuminationValue(String value) {
    return '$value times/min';
  }

  @override
  String get feverLoadFailed => 'Failed to load temperature data';

  @override
  String get feverNoRecords => 'No temperature records';

  @override
  String get feverLegendActual => 'Actual Temp';

  @override
  String get feverLegendBaseline => 'Baseline';

  @override
  String get estrusLoadFailed => 'Failed to load estrus data';

  @override
  String get estrusNoScores => 'No estrus scores';

  @override
  String get estrusLegendScore => 'Estrus Score';

  @override
  String get estrusLegendThreshold => 'Breeding Threshold';

  @override
  String livestockLastLocation(String location) {
    return 'Last location: $location';
  }

  @override
  String get aiAnomalyTitle => 'AI Anomaly Detection';

  @override
  String get aiAnomalyScoreLabel => 'Anomaly Score';

  @override
  String get aiAnomalyTypeNormal => 'Normal';

  @override
  String get aiAnomalyTypeCircadian => 'Circadian Disruption';

  @override
  String get aiAnomalyTypeAbrupt => 'Abrupt Change';

  @override
  String get aiAnomalyTypeMultivariate => 'Multivariate Anomaly';

  @override
  String get aiAnomalyNoData => 'No anomaly data yet';

  @override
  String get aiAnomalyEffSamples => 'Effective samples';

  @override
  String get aiAnomalyAssessedAt => 'Assessed';

  @override
  String get aiAnomalyViewHistory => 'Anomaly Score Trend';

  @override
  String get aiAnomalyAlertThreshold => 'Alert threshold';

  @override
  String get aiAnomalyRuleAlerts => 'Rule Alerts';

  @override
  String get aiAnomalyAiAlerts => 'AI Anomalies';

  @override
  String get aiAnomalyOverview => 'AI Anomaly Overview';

  @override
  String get aiAnomalyAvgScore => 'Average Score';

  @override
  String get aiAnomalyAnomalyCount => 'Anomaly Count';

  @override
  String get livestockListTitle => 'Livestock Management';

  @override
  String livestockSearchResult(Object total) {
    return '$total results found';
  }

  @override
  String get livestockShowAll => 'Show all';

  @override
  String get livestockSearchHint => 'Search by code or breed';

  @override
  String livestockPaginationInfo(
    Object currentPage,
    Object totalPages,
    Object total,
  ) {
    return 'Page $currentPage / $totalPages, $total items';
  }

  @override
  String get livestockAddNew => 'Add Livestock';

  @override
  String get livestockEdit => 'Edit Livestock';

  @override
  String get livestockFormFieldCode => 'Code';

  @override
  String get livestockFormFieldBreed => 'Breed';

  @override
  String get livestockFormFieldGender => 'Gender';

  @override
  String get livestockFormFieldBirthDate => 'Birth Date';

  @override
  String get livestockFormFieldWeight => 'Weight';

  @override
  String get livestockCreateSuccess => 'Livestock created successfully';

  @override
  String get livestockUpdateSuccess => 'Livestock updated successfully';

  @override
  String get livestockBreedAngus => 'Angus';

  @override
  String get livestockBreedWagyu => 'Wagyu';

  @override
  String get livestockBreedSimmental => 'Simmental';

  @override
  String get livestockBreedLimousin => 'Limousin';

  @override
  String get livestockBreedOther => 'Other';

  @override
  String get livestockGenderMale => 'Male';

  @override
  String get livestockGenderFemale => 'Female';

  @override
  String get deviceRegisterTitle => 'Register Device';

  @override
  String get deviceEditTitle => 'Edit Device';

  @override
  String get deviceFormFieldCode => 'Device Code';

  @override
  String get deviceFormFieldDevEui => 'LoRa EUI (optional)';

  @override
  String get deviceRegisterSuccess => 'Device registered successfully';

  @override
  String get deviceUpdateSuccess => 'Device updated successfully';

  @override
  String get installBindDevice => 'Bind Device';

  @override
  String get installSelectDevice => 'Select Device';

  @override
  String get installNoAvailableDevices => 'No available devices';

  @override
  String get installSuccess => 'Installed successfully';

  @override
  String get livestockNoDeviceBound => 'No device bound';

  @override
  String get livestockDeleteConfirmTitle => 'Confirm Delete?';

  @override
  String get livestockDeleteConfirmMsg => 'This action cannot be undone.';

  @override
  String livestockDeleteDeviceUnbind(String deviceName) {
    return 'Device $deviceName will be unbound';
  }

  @override
  String get livestockDeleteArchiveNote =>
      'Health history and trajectory data will be archived';

  @override
  String get livestockDeleted => 'Deleted, devices unbound';

  @override
  String get livestockTrajectoryTitle => 'Movement Trajectory';

  @override
  String get livestockTrajectoryPoints => 'Points';

  @override
  String get livestockTrajectoryDistance => 'Distance';

  @override
  String get livestockTrajectoryRange => 'Range';

  @override
  String get livestockTrajectoryEmpty => 'No trajectory data';

  @override
  String get livestockTrajectoryNoGps => 'Please bind a GPS device first';

  @override
  String get livestockTrajectoryCurrentTime => 'Current';

  @override
  String get livestockTrajectoryRange24h => 'Last 24h';

  @override
  String get livestockTrajectoryRange7d => 'Last 7d';

  @override
  String get livestockTrajectoryRange30d => 'Last 30d';

  @override
  String get livestockTrajectoryRangeCustom => 'Custom Date';

  @override
  String get livestockTrajectoryFollow => 'Follow';

  @override
  String get livestockTrajectoryFitAll => 'Fit All';

  @override
  String get livestockTrajectoryPointUnit => 'pts';

  @override
  String get livestockTrajectoryAccuracy => 'Accuracy';

  @override
  String get livestockTrajectoryLoading => 'Loading trajectory…';

  @override
  String get livestockTrajectoryPlay => 'Play';

  @override
  String get livestockTrajectoryPause => 'Pause';

  @override
  String get livestockFormFieldCodeRequired => 'Code is required';

  @override
  String get livestockEditSyncNote =>
      'After changing the code, it will be synced across alerts, trajectory, and health reports';

  @override
  String get livestockGenderValueMale => 'Male';

  @override
  String get livestockGenderValueFemale => 'Female';

  @override
  String get gpsQualityTitle => 'GPS Quality Check';

  @override
  String get gpsQualityTabRtkCalibration => 'RTK Calibration';

  @override
  String get gpsQualityTabQualityReport => 'Quality Report';

  @override
  String get gpsQualityRtkPointList => 'RTK Reference Points';

  @override
  String get gpsQualitySessionList => 'Sessions';

  @override
  String get gpsQualityAddRtkPoint => 'Add Point';

  @override
  String get gpsQualityAddSession => 'Create Session';

  @override
  String get gpsQualityLocationName => 'Location';

  @override
  String get gpsQualityPointLabel => 'Point Label';

  @override
  String get gpsQualityLatitude => 'Latitude';

  @override
  String get gpsQualityLongitude => 'Longitude';

  @override
  String get gpsQualityDevice => 'Device';

  @override
  String get gpsQualityStartTime => 'Start Time';

  @override
  String get gpsQualityEndTime => 'End Time';

  @override
  String get gpsQualityStartedAtFutureError =>
      'Start time cannot be in the future';

  @override
  String get gpsQualityEndedAtFutureError =>
      'End time cannot be in the future; leave it empty to create an in-progress live session';

  @override
  String get gpsQualityEndTimeHint =>
      'Leave empty = in-progress live test (click End later); fill a past time = backfill a historical session that produces a report on creation';

  @override
  String get gpsQualityBatchCreate => 'Batch Create Sessions';

  @override
  String get gpsQualityImportExcel => 'Import Excel';

  @override
  String get gpsQualityDownloadTemplate => 'Download Template';

  @override
  String get gpsQualityAddRow => 'Add Row';

  @override
  String get gpsQualityDeleteRow => 'Delete';

  @override
  String gpsQualityBatchCreateN(Object n) {
    return 'Batch Create ($n)';
  }

  @override
  String gpsQualityBatchResult(Object m, Object n) {
    return 'Success: $n / Failed: $m';
  }

  @override
  String gpsQualityDeviceNotFound(Object code) {
    return 'Device not found: $code';
  }

  @override
  String gpsQualityPointNotFound(Object label) {
    return 'Point not found: $label';
  }

  @override
  String gpsQualityImportRows(Object n) {
    return 'Imported $n rows';
  }

  @override
  String get gpsQualitySelectRtkPointShort => 'Point';

  @override
  String get gpsQualitySelectDeviceShort => 'Device';

  @override
  String gpsQualityBatchProgress(Object done, Object total) {
    return 'Creating $done/$total...';
  }

  @override
  String get gpsQualityTemplateColumns =>
      'Device Code,RTK Point Label,Start Time (optional),End Time (optional, empty=live test)';

  @override
  String get gpsQualityBatchEmpty => 'Please add at least one row';

  @override
  String get gpsQualityStatus => 'Status';

  @override
  String get gpsQualityStatusInProgress => 'In Progress';

  @override
  String get gpsQualityStatusCompleted => 'Completed';

  @override
  String get gpsQualityStatusCanceled => 'Canceled';

  @override
  String get gpsQualityEndSession => 'End';

  @override
  String get gpsQualityCancelSession => 'Cancel';

  @override
  String get gpsQualityEndSessionConfirm =>
      'Confirm end session? Statistics will be calculated automatically.';

  @override
  String get gpsQualitySelectRtkPoint => 'Select RTK Point';

  @override
  String get gpsQualitySelectDevice => 'Select Device';

  @override
  String get gpsQualityReportTitle => 'Quality Report';

  @override
  String get gpsQualityComparisonTitle => 'Device Comparison';

  @override
  String get gpsQualityExcludeSuspect => 'Exclude suspected motion';

  @override
  String get gpsQualityTotalPoints => 'Total Points';

  @override
  String get gpsQualityEffectivePoints => 'Effective Points';

  @override
  String get gpsQualitySuspectPoints => 'Suspected Motion';

  @override
  String get gpsQualityMeanError => 'Mean Error';

  @override
  String get gpsQualityP50 => 'P50 Median';

  @override
  String get gpsQualityP95 => 'P95 Jitter Radius';

  @override
  String get gpsQualityP99 => 'P99';

  @override
  String get gpsQualityMaxError => 'Max Error';

  @override
  String get gpsQualityJitterDiameter => 'Jitter Diameter';

  @override
  String get gpsQualityOutlierCount => 'Outliers';

  @override
  String get gpsQualityGradeExcellent => 'Excellent';

  @override
  String get gpsQualityGradeUsable => 'Usable';

  @override
  String get gpsQualityGradeMarginal => 'Marginal';

  @override
  String get gpsQualityGradeUnavailable => 'Unavailable';

  @override
  String get gpsQualityGradeStandard => 'Grade Standard';

  @override
  String get gpsQualityGradeExcellentDesc => 'P95 ≤ 15m and effective ≥ 20';

  @override
  String get gpsQualityGradeUsableDesc => 'P95 ≤ 25m and effective ≥ 20';

  @override
  String get gpsQualityGradeMarginalDesc =>
      '25m < P95 ≤ 40m and effective ≥ 10';

  @override
  String get gpsQualityGradeUnavailableDesc => 'P95 > 40m or effective < 10';

  @override
  String get gpsQualityNoData => 'No data';

  @override
  String get gpsQualityViewTrajectory => 'View trajectory';

  @override
  String get gpsQualityScatterChart => 'GPS Scatter Plot';

  @override
  String get gpsQualityErrorHistogram => 'Error Distribution';

  @override
  String get gpsQualityDistanceRange0to15 => '0-15m';

  @override
  String get gpsQualityDistanceRange15to25 => '15-25m';

  @override
  String get gpsQualityDistanceRange25to40 => '25-40m';

  @override
  String get gpsQualityDistanceRangeOver40 => '>40m';

  @override
  String get gpsQualityCumulativeWithin25m => '≤25m cumulative';

  @override
  String get gpsQualityCumulativeWithin40m => '≤40m cumulative';

  @override
  String get gpsQualityCalibrationLocations => 'Calibration Locations';

  @override
  String get gpsQualityRtkCoordinate => 'RTK Coordinates';

  @override
  String get gpsQualityTestTime => 'Test Time';

  @override
  String get gpsQualityActions => 'Actions';

  @override
  String get gpsQualityPointsUnit => 'points';

  @override
  String get gpsQualityCalibrated => 'Calibrated';

  @override
  String get gpsQualityPointUnitShort => 'pts';

  @override
  String get gpsQualitySessionUnitShort => 'sessions';

  @override
  String get gpsQualityUncalibratedPointsUnit => 'uncalibrated points';

  @override
  String get gpsQualityUncalibrated => 'Uncalibrated';

  @override
  String get gpsQualityCalibrate => 'Calibrate';

  @override
  String get gpsQualityNoSessionHint =>
      'No calibration sessions yet. Click \"+ Create Calibration Session\" to start.';

  @override
  String get gpsQualityDelete => 'Delete';

  @override
  String get gpsQualityTipP50 =>
      '50th percentile of errors\n= median, typical accuracy';

  @override
  String get gpsQualityTipP95 =>
      '95th percentile of errors\nFence STANDARD threshold basis';

  @override
  String get gpsQualityTipMeanError =>
      'Arithmetic mean of\npoint-to-truth distances';

  @override
  String get gpsQualityTipMaxError => 'Farthest point from RTK truth';

  @override
  String get gpsQualityTipJitterDiameter =>
      'Max pairwise haversine\ndistance between points';

  @override
  String get gpsQualityTipOutlier => 'Points exceeding max(P99, 3×P95, 30m)';

  @override
  String get gpsQualityTipTotalPoints =>
      'Total valid GPS points in session window';

  @override
  String get gpsQualityTipEffectivePoints =>
      'Points after excluding suspected motion';

  @override
  String get gpsQualityTipSuspectPoints => 'Points with step_number > 0';

  @override
  String get tenantListTitle => 'Tenant Management';

  @override
  String get tenantDetailTitle => 'Tenant Detail';

  @override
  String get gpsQualityTabDynamicReport => 'Dynamic Test';

  @override
  String get gpsQualityTestTypeStatic => 'Static';

  @override
  String get gpsQualityTestTypeDynamic => 'Dynamic';

  @override
  String get gpsQualityTestType => 'Test Type';

  @override
  String get gpsQualityRouteList => 'Test Routes';

  @override
  String get gpsQualityAddRoute => 'Add Route';

  @override
  String get gpsQualityRouteName => 'Route Name';

  @override
  String get gpsQualityRouteDescription => 'Description';

  @override
  String get gpsQualityRoutePoints => 'Route Points';

  @override
  String get gpsQualitySelectRoute => 'Select Route';

  @override
  String get gpsQualitySelectRouteShort => 'Route';

  @override
  String get gpsQualityCreateDynamicTest => 'Create Dynamic Test';

  @override
  String get gpsQualityAddRoutePoint => 'Add Point';

  @override
  String get gpsQualityDynamicCoverage => 'Coverage';

  @override
  String get gpsQualityDynamicMatched => 'Matched';

  @override
  String get gpsQualityDynamicMissed => 'Missed';

  @override
  String get gpsQualityDynamicAmbiguous => 'Ambiguous';

  @override
  String get gpsQualityDynamicInOrder => 'In Order';

  @override
  String get gpsQualityDynamicThreshold => 'Threshold (m)';

  @override
  String get gpsQualityDynamicSequenceNo => 'Seq';

  @override
  String get gpsQualityDynamicError => 'Error (m)';

  @override
  String get gpsQualityDynamicPassed => 'Passed';

  @override
  String get gpsQualityDynamicMissedPoint => 'Missed';

  @override
  String get gpsQualityDynamicNoRoute => 'Please create a test route first';

  @override
  String get gpsQualityDynamicNoTest => 'No dynamic test records';

  @override
  String get gpsQualityStaticComparison => 'Static Comparison';

  @override
  String get gpsQualityDynamicDeltaP95 => 'P95 Delta';

  @override
  String get gpsQualityRouteNoPoints =>
      'No points in this route. Please add RTK reference points.';

  @override
  String get gpsQualityDeleteRoute => 'Delete Route';

  @override
  String get gpsQualityTimeOverlapTitle => 'Time Conflict';

  @override
  String gpsQualityTimeOverlapMsg(
    Object device,
    Object existRange,
    Object sessionId,
  ) {
    return 'The selected time overlaps with session #$sessionId of device $device ($existRange). Please choose a non-overlapping time.';
  }

  @override
  String get gpsQualitySessionInProgress => 'In Progress';

  @override
  String get gpsQualityCreateSession => 'Create Session';

  @override
  String get gpsQualityTestList => 'Tests';

  @override
  String get gpsQualityCreateTest => 'Create Test';

  @override
  String get gpsQualityTabTruthRef => 'Reference';

  @override
  String get gpsQualityTabComparison => 'Comparison';

  @override
  String get gpsQualityDateFormatError =>
      'Invalid format, use yyyy-MM-dd HH:mm';

  @override
  String get gpsQualityRequiredField => 'This field is required';

  @override
  String get gpsQualityTabChecks => 'Quality Checks';

  @override
  String get gpsQualityCreateCheck => 'Create Check';

  @override
  String get gpsQualityBatchImport => 'Batch Import';

  @override
  String get gpsQualityDeviceEui => 'Device EUI';

  @override
  String get gpsQualityDeviceGroup => 'Device Group';

  @override
  String get gpsQualityTimeline => 'Timeline';

  @override
  String gpsQualityChecksCount(Object n) {
    return '$n checks';
  }

  @override
  String get gpsQualityDevicePending => 'Pending';

  @override
  String get gpsQualityImportFailed => 'Import Failed';

  @override
  String get gpsQualityUploadExcel => 'Upload Excel File';

  @override
  String get gpsQualityManualRegister => 'Manual Register';

  @override
  String get gpsQualityImportStepUpload => 'Upload';

  @override
  String get gpsQualityImportStepPreview => 'Preview';

  @override
  String get gpsQualityImportResult => 'Import Result';

  @override
  String get gpsQualityDeleteCheck => 'Delete Check';

  @override
  String get gpsQualityDeleteCheckConfirm =>
      'This will delete this quality check record. This action cannot be undone.';

  @override
  String get gpsQualityDeleteCheckSuccess => 'Check record deleted';

  @override
  String gpsQualityDeleteCheckTip(Object end, Object start, Object type) {
    return 'Delete $type, $start → $end';
  }

  @override
  String get gpsQualityBatchConfirmDelete => 'Confirm delete this batch?';

  @override
  String get gpsQualityRetrying => 'Retrying...';

  @override
  String get gpsQualityEditRetry => 'Edit & Retry';

  @override
  String get gpsQualityBatchRegister => 'Batch Register';

  @override
  String get gpsQualityEditAndRetry => 'Edit & Retry';

  @override
  String get gpsQualityCheckStatusReady => 'Ready';

  @override
  String get gpsQualityCheckStatusPending => 'Pending';

  @override
  String get gpsQualityCheckStatusFailed => 'Failed';

  @override
  String get gpsQualityDeviceDetail => 'Device Details';

  @override
  String get gpsQualityStaticChecks => 'Static checks';

  @override
  String get gpsQualityDynamicChecks => 'Dynamic checks';

  @override
  String get gpsQualityRegisterSuccess => 'Registration succeeded';

  @override
  String get gpsQualityNoChecks => 'No checks';

  @override
  String get commonOptional => 'Optional';

  @override
  String get commonMessage => 'Message';

  @override
  String get commonAction => 'Action';

  @override
  String get gpsQualityImportStepResult => 'Result';

  @override
  String get gpsQualityRowIndex => 'Row';

  @override
  String get gpsQualityRegisterAll => 'Register all';

  @override
  String get gpsQualitySearchDeviceHint => 'Search EUI or device code…';

  @override
  String get gpsQualityFilterAllStatus => 'All statuses';

  @override
  String get gpsQualityNoMatchDevice => 'No matching devices';

  @override
  String get gpsQualityDeleteDevice => 'Delete device';

  @override
  String gpsQualityDeleteDeviceConfirm(Object n) {
    return 'This will delete all $n quality check records under this device (the device itself is kept). This action cannot be undone.';
  }

  @override
  String gpsQualityDeleteDeviceSuccess(Object n) {
    return 'Deleted $n check records';
  }

  @override
  String get gpsQualityImportTotalRows => 'Total rows';

  @override
  String get gpsQualityImportOkRows => 'Report ready';

  @override
  String get gpsQualityDeleteRowsHint =>
      'You can delete rows before submitting';

  @override
  String get gpsQualityRowExcluded => 'Excluded';

  @override
  String get gpsQualityDeviceCode => 'Device code';

  @override
  String get gpsQualityTruthRef => 'Truth point/route';

  @override
  String get gpsQualityTimeRange => 'Time range';

  @override
  String get gpsQualityDynamicOrderOk => 'In order';

  @override
  String get gpsQualityRouteMatchChart => 'Route match chart';

  @override
  String get gpsQualitySelectRoutePrompt =>
      'Select a route to view the dynamic comparison';

  @override
  String gpsQualityDeviceCount(Object n) {
    return '$n devices';
  }

  @override
  String get commonNext => 'Next';

  @override
  String get commonDone => 'Done';

  @override
  String get gpsQualityTrajectoryImport => 'Import RTK Track Data';

  @override
  String get gpsQualityTrajectoryChecks => 'Track';

  @override
  String get gpsQualityTrajectoryReport => 'Trajectory Check Report';

  @override
  String get gpsQualityTrajectoryUploadTitle => 'Upload RTK track file';

  @override
  String get gpsQualityTrajectoryUploadHint => '.csv / .xlsx, up to 5000 rows';

  @override
  String get gpsQualityTrajectoryClockNote =>
      'Clock baseline: collection times must share the same baseline as device report timestamps (server ingestion time, UTC+8). Default pairing window ±60s, adjustable in the next step.';

  @override
  String get gpsQualityTrajectoryFormatTitle =>
      'File format (fixed column order, header optional)';

  @override
  String get gpsQualityTrajectoryRequired => 'Required';

  @override
  String get gpsQualityTrajectoryOptional => 'Optional';

  @override
  String get gpsQualityTrajectoryColEui => 'Device EUI';

  @override
  String get gpsQualityTrajectoryColTime => 'Collected At';

  @override
  String get gpsQualityTrajectoryColRtkLat => 'RTK Lat';

  @override
  String get gpsQualityTrajectoryColRtkLng => 'RTK Lng';

  @override
  String get gpsQualityTrajectoryColDevLat => 'Device Lat';

  @override
  String get gpsQualityTrajectoryColDevLng => 'Device Lng';

  @override
  String get gpsQualityTrajectoryColEuiNote =>
      'EUI of the tracker under test; must be registered';

  @override
  String get gpsQualityTrajectoryColTimeNote =>
      'Device report time, same clock baseline as report timestamps';

  @override
  String get gpsQualityTrajectoryColDevNote =>
      'Leave empty to pair from gps_logs by EUI + time';

  @override
  String get gpsQualityTrajectoryStatRows => 'Total rows';

  @override
  String get gpsQualityTrajectoryStatValid => 'Valid';

  @override
  String get gpsQualityTrajectoryStatInvalid => 'Invalid';

  @override
  String get gpsQualityTrajectoryStatDevices => 'Devices';

  @override
  String get gpsQualityTrajectoryAutoRegistered => 'Auto-registered';

  @override
  String get gpsQualityTrajectoryManualRegister => 'Manual register';

  @override
  String get gpsQualityFilePaired => 'From file';

  @override
  String get gpsQualityLogPaired => 'From gps_logs';

  @override
  String get gpsQualityUnpaired => 'Unpaired';

  @override
  String get gpsQualityPairTolerance => 'Pairing';

  @override
  String get gpsQualityPairToleranceSec => 's';

  @override
  String get gpsQualityPairToleranceNote =>
      'Takes the gps_logs report nearest to the collection time for the EUI; beyond the tolerance it counts as unpaired';

  @override
  String get gpsQualityTrajectoryMatchMode => 'Pairing';

  @override
  String get gpsQualityTrajectoryCheck => 'Check';

  @override
  String get gpsQualityTrajectoryMatchFile => 'File';

  @override
  String get gpsQualityTrajectoryMatchLog => 'DB';

  @override
  String get gpsQualityTrajectoryMatchUnpaired => 'Unpaired';

  @override
  String gpsQualityTrajectoryImportDone(int created, int skipped) {
    return 'Import finished: $created trajectory checks created, $skipped skipped (duplicates)';
  }

  @override
  String gpsQualityTrajectoryDevicePoints(int n) {
    return '$n pts';
  }

  @override
  String get gpsQualityTrajectoryCreated => 'Check created';

  @override
  String get gpsQualityTrajectorySkippedDuplicate => 'Exists, skipped';

  @override
  String get gpsQualityTrajectoryUnpairedNote =>
      'Unpaired samples (no gps_logs report within the window) stay in the check and are listed separately in the report; they do not join error statistics.';

  @override
  String get gpsQualityTrajectoryImportAction => 'Import';

  @override
  String get gpsQualityTrajectoryPoints => 'Track points';

  @override
  String get gpsQualityPairRate => 'Pair rate';

  @override
  String get gpsQualityTrajectoryMeanError => 'Mean error';

  @override
  String get gpsQualityTrajectoryMaxError => 'Max error';

  @override
  String get gpsQualityTrajectoryLegendRtk => 'RTK truth track';

  @override
  String get gpsQualityTrajectoryLegendDevice => 'Device track';

  @override
  String get gpsQualityTrajectoryLegendLink => 'Pair link (error)';

  @override
  String get gpsQualityTrajectoryLegendUnpaired => 'Unpaired point';

  @override
  String get gpsQualityTrajectoryErrorDist => 'Error distribution';

  @override
  String get gpsQualityTrajectoryError => 'Error';

  @override
  String get gpsQualityTrajectorySource => 'Source';

  @override
  String gpsQualityTrajectoryUnpairedDetail(int n, int tolerance) {
    return '$n unpaired samples: no gps_logs report for this device within ±${tolerance}s of the collection time (possible missing/delayed reports); excluded from error statistics.';
  }

  @override
  String get gpsQualityTrajectoryNoStatic =>
      'No static check data for this device; static-vs-dynamic comparison unavailable.';

  @override
  String gpsQualityTrajectoryStaticDelta(
    String staticP95,
    String dynamicP95,
    String delta,
    String direction,
  ) {
    return 'Static vs dynamic: static P95 = ${staticP95}m, this trajectory P95 = ${dynamicP95}m, dynamic error $direction by ${delta}m';
  }

  @override
  String get gpsQualityTrajectorySmaller => 'smaller';

  @override
  String get gpsQualityTrajectoryLarger => 'larger';

  @override
  String get gpsQualityTrajectoryComparison => 'Trajectory Comparison';

  @override
  String get gpsQualityTrajectoryEmpty =>
      'No trajectory checks yet — import an RTK track from the check list first';

  @override
  String get gpsQualityPaired => 'Paired';
}
