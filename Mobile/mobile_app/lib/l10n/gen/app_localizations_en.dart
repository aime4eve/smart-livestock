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
}
