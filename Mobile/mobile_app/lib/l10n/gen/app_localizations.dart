import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_zh.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'gen/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('zh'),
  ];

  /// No description provided for @commonConfirm.
  ///
  /// In zh, this message translates to:
  /// **'确认'**
  String get commonConfirm;

  /// No description provided for @commonCancel.
  ///
  /// In zh, this message translates to:
  /// **'取消'**
  String get commonCancel;

  /// No description provided for @commonSave.
  ///
  /// In zh, this message translates to:
  /// **'保存'**
  String get commonSave;

  /// No description provided for @commonDelete.
  ///
  /// In zh, this message translates to:
  /// **'删除'**
  String get commonDelete;

  /// No description provided for @commonEdit.
  ///
  /// In zh, this message translates to:
  /// **'编辑'**
  String get commonEdit;

  /// No description provided for @commonBack.
  ///
  /// In zh, this message translates to:
  /// **'返回'**
  String get commonBack;

  /// No description provided for @commonLoading.
  ///
  /// In zh, this message translates to:
  /// **'加载中...'**
  String get commonLoading;

  /// No description provided for @commonRetry.
  ///
  /// In zh, this message translates to:
  /// **'重试'**
  String get commonRetry;

  /// No description provided for @commonError.
  ///
  /// In zh, this message translates to:
  /// **'出错了'**
  String get commonError;

  /// No description provided for @commonSuccess.
  ///
  /// In zh, this message translates to:
  /// **'成功'**
  String get commonSuccess;

  /// No description provided for @commonSearch.
  ///
  /// In zh, this message translates to:
  /// **'搜索'**
  String get commonSearch;

  /// No description provided for @commonLogout.
  ///
  /// In zh, this message translates to:
  /// **'退出登录'**
  String get commonLogout;

  /// No description provided for @commonSubmit.
  ///
  /// In zh, this message translates to:
  /// **'提交'**
  String get commonSubmit;

  /// No description provided for @commonClose.
  ///
  /// In zh, this message translates to:
  /// **'关闭'**
  String get commonClose;

  /// No description provided for @commonAll.
  ///
  /// In zh, this message translates to:
  /// **'全部'**
  String get commonAll;

  /// No description provided for @commonNone.
  ///
  /// In zh, this message translates to:
  /// **'无'**
  String get commonNone;

  /// No description provided for @commonUnknown.
  ///
  /// In zh, this message translates to:
  /// **'未知'**
  String get commonUnknown;

  /// No description provided for @settingsLanguage.
  ///
  /// In zh, this message translates to:
  /// **'语言'**
  String get settingsLanguage;

  /// No description provided for @settingsLanguageZh.
  ///
  /// In zh, this message translates to:
  /// **'中文'**
  String get settingsLanguageZh;

  /// No description provided for @settingsLanguageEn.
  ///
  /// In zh, this message translates to:
  /// **'English'**
  String get settingsLanguageEn;

  /// No description provided for @settingsLanguageSystem.
  ///
  /// In zh, this message translates to:
  /// **'跟随系统'**
  String get settingsLanguageSystem;

  /// No description provided for @settingsTitle.
  ///
  /// In zh, this message translates to:
  /// **'设置'**
  String get settingsTitle;

  /// No description provided for @errorAuthFailed.
  ///
  /// In zh, this message translates to:
  /// **'认证失败'**
  String get errorAuthFailed;

  /// No description provided for @errorServer.
  ///
  /// In zh, this message translates to:
  /// **'服务器异常'**
  String get errorServer;

  /// No description provided for @errorTenantDisabled.
  ///
  /// In zh, this message translates to:
  /// **'租户已禁用'**
  String get errorTenantDisabled;

  /// No description provided for @errorLoginFailed.
  ///
  /// In zh, this message translates to:
  /// **'登录失败'**
  String get errorLoginFailed;

  /// No description provided for @errorLoginCheckInput.
  ///
  /// In zh, this message translates to:
  /// **'登录失败，请检查手机号和密码'**
  String get errorLoginCheckInput;

  /// No description provided for @navLogin.
  ///
  /// In zh, this message translates to:
  /// **'登录'**
  String get navLogin;

  /// No description provided for @navRanch.
  ///
  /// In zh, this message translates to:
  /// **'牧场'**
  String get navRanch;

  /// No description provided for @navTwin.
  ///
  /// In zh, this message translates to:
  /// **'数智孪生'**
  String get navTwin;

  /// No description provided for @navAlerts.
  ///
  /// In zh, this message translates to:
  /// **'告警'**
  String get navAlerts;

  /// No description provided for @navMine.
  ///
  /// In zh, this message translates to:
  /// **'我的'**
  String get navMine;

  /// No description provided for @navFence.
  ///
  /// In zh, this message translates to:
  /// **'围栏'**
  String get navFence;

  /// No description provided for @navAdmin.
  ///
  /// In zh, this message translates to:
  /// **'后台'**
  String get navAdmin;

  /// No description provided for @navOverview.
  ///
  /// In zh, this message translates to:
  /// **'概览'**
  String get navOverview;

  /// No description provided for @navFarmManagement.
  ///
  /// In zh, this message translates to:
  /// **'牧场管理'**
  String get navFarmManagement;

  /// No description provided for @navContractInfo.
  ///
  /// In zh, this message translates to:
  /// **'合同信息'**
  String get navContractInfo;

  /// No description provided for @navRevenue.
  ///
  /// In zh, this message translates to:
  /// **'对账'**
  String get navRevenue;

  /// No description provided for @platformAdminTitle.
  ///
  /// In zh, this message translates to:
  /// **'平台管理'**
  String get platformAdminTitle;

  /// No description provided for @farmEmptyGuidance.
  ///
  /// In zh, this message translates to:
  /// **'暂无关联牧场，请联系管理员为您分配牧场。'**
  String get farmEmptyGuidance;

  /// No description provided for @authAppTitle.
  ///
  /// In zh, this message translates to:
  /// **'智慧畜牧'**
  String get authAppTitle;

  /// No description provided for @authSubtitle.
  ///
  /// In zh, this message translates to:
  /// **'智能畜牧管理平台'**
  String get authSubtitle;

  /// No description provided for @authPhoneLabel.
  ///
  /// In zh, this message translates to:
  /// **'手机号'**
  String get authPhoneLabel;

  /// No description provided for @authPhoneHint.
  ///
  /// In zh, this message translates to:
  /// **'请输入手机号'**
  String get authPhoneHint;

  /// No description provided for @authPasswordLabel.
  ///
  /// In zh, this message translates to:
  /// **'密码'**
  String get authPasswordLabel;

  /// No description provided for @authPasswordHint.
  ///
  /// In zh, this message translates to:
  /// **'请输入密码'**
  String get authPasswordHint;

  /// No description provided for @authLoginButton.
  ///
  /// In zh, this message translates to:
  /// **'登录'**
  String get authLoginButton;

  /// No description provided for @authLoginFailed.
  ///
  /// In zh, this message translates to:
  /// **'登录失败: {error}'**
  String authLoginFailed(String error);

  /// No description provided for @deviceStatusOnline.
  ///
  /// In zh, this message translates to:
  /// **'在线'**
  String get deviceStatusOnline;

  /// No description provided for @deviceStatusOffline.
  ///
  /// In zh, this message translates to:
  /// **'离线'**
  String get deviceStatusOffline;

  /// No description provided for @deviceStatusLowBattery.
  ///
  /// In zh, this message translates to:
  /// **'低电'**
  String get deviceStatusLowBattery;

  /// No description provided for @livestockHealthHealthy.
  ///
  /// In zh, this message translates to:
  /// **'健康'**
  String get livestockHealthHealthy;

  /// No description provided for @livestockHealthWatch.
  ///
  /// In zh, this message translates to:
  /// **'关注'**
  String get livestockHealthWatch;

  /// No description provided for @livestockHealthAbnormal.
  ///
  /// In zh, this message translates to:
  /// **'异常'**
  String get livestockHealthAbnormal;

  /// No description provided for @authLoginFormTitle.
  ///
  /// In zh, this message translates to:
  /// **'账号登录'**
  String get authLoginFormTitle;

  /// No description provided for @authOnlineMode.
  ///
  /// In zh, this message translates to:
  /// **'在线模式'**
  String get authOnlineMode;

  /// No description provided for @authPhoneInvalid.
  ///
  /// In zh, this message translates to:
  /// **'请输入正确的11位手机号'**
  String get authPhoneInvalid;

  /// No description provided for @authLoginDescription.
  ///
  /// In zh, this message translates to:
  /// **'登录您的牧场账户，管理牲畜、围栏与告警。'**
  String get authLoginDescription;

  /// No description provided for @deviceTypeGps.
  ///
  /// In zh, this message translates to:
  /// **'GPS定位器'**
  String get deviceTypeGps;

  /// No description provided for @deviceTypeRumenCapsule.
  ///
  /// In zh, this message translates to:
  /// **'瘤胃胶囊'**
  String get deviceTypeRumenCapsule;

  /// No description provided for @deviceTypeEarTag.
  ///
  /// In zh, this message translates to:
  /// **'耳标'**
  String get deviceTypeEarTag;

  /// No description provided for @subscriptionTierBasic.
  ///
  /// In zh, this message translates to:
  /// **'基础版'**
  String get subscriptionTierBasic;

  /// No description provided for @subscriptionTierStandard.
  ///
  /// In zh, this message translates to:
  /// **'标准版'**
  String get subscriptionTierStandard;

  /// No description provided for @subscriptionTierPremium.
  ///
  /// In zh, this message translates to:
  /// **'高级版'**
  String get subscriptionTierPremium;

  /// No description provided for @subscriptionTierEnterprise.
  ///
  /// In zh, this message translates to:
  /// **'企业版'**
  String get subscriptionTierEnterprise;

  /// No description provided for @commonLoadFailed.
  ///
  /// In zh, this message translates to:
  /// **'加载失败'**
  String get commonLoadFailed;

  /// No description provided for @commonDeleteFailed.
  ///
  /// In zh, this message translates to:
  /// **'删除失败: {error}'**
  String commonDeleteFailed(String error);

  /// No description provided for @commonConfirmDelete.
  ///
  /// In zh, this message translates to:
  /// **'确认删除'**
  String get commonConfirmDelete;

  /// No description provided for @commonConfirmLogout.
  ///
  /// In zh, this message translates to:
  /// **'确认退出'**
  String get commonConfirmLogout;

  /// No description provided for @commonConfirmLogoutMessage.
  ///
  /// In zh, this message translates to:
  /// **'确定要退出登录吗？'**
  String get commonConfirmLogoutMessage;

  /// No description provided for @ranchFenceList.
  ///
  /// In zh, this message translates to:
  /// **'围栏列表'**
  String get ranchFenceList;

  /// No description provided for @ranchNewFence.
  ///
  /// In zh, this message translates to:
  /// **'新建围栏'**
  String get ranchNewFence;

  /// No description provided for @ranchNoFence.
  ///
  /// In zh, this message translates to:
  /// **'暂无围栏'**
  String get ranchNoFence;

  /// No description provided for @ranchCollapseFenceList.
  ///
  /// In zh, this message translates to:
  /// **'收起围栏列表'**
  String get ranchCollapseFenceList;

  /// No description provided for @ranchEditBoundary.
  ///
  /// In zh, this message translates to:
  /// **'编辑边界'**
  String get ranchEditBoundary;

  /// No description provided for @ranchFenceDeleted.
  ///
  /// In zh, this message translates to:
  /// **'已删除「{name}」'**
  String ranchFenceDeleted(String name);

  /// No description provided for @ranchConfirmDeleteFence.
  ///
  /// In zh, this message translates to:
  /// **'确认删除「{name}」？删除后无法恢复。'**
  String ranchConfirmDeleteFence(String name);

  /// No description provided for @ranchFenceActive.
  ///
  /// In zh, this message translates to:
  /// **'启用'**
  String get ranchFenceActive;

  /// No description provided for @ranchFenceInactive.
  ///
  /// In zh, this message translates to:
  /// **'停用'**
  String get ranchFenceInactive;

  /// No description provided for @ranchLivestockCountHead.
  ///
  /// In zh, this message translates to:
  /// **'{count}头'**
  String ranchLivestockCountHead(String count);

  /// No description provided for @commonNotApplicable.
  ///
  /// In zh, this message translates to:
  /// **'暂无'**
  String get commonNotApplicable;

  /// No description provided for @ranchPeekInFence.
  ///
  /// In zh, this message translates to:
  /// **'归栏 {percent}%'**
  String ranchPeekInFence(String percent);

  /// No description provided for @ranchPeekHealth.
  ///
  /// In zh, this message translates to:
  /// **'健康 {percent}%'**
  String ranchPeekHealth(String percent);

  /// No description provided for @ranchPeekAlertCount.
  ///
  /// In zh, this message translates to:
  /// **'{count}条告警'**
  String ranchPeekAlertCount(String count);

  /// No description provided for @ranchSectionFenceAlerts.
  ///
  /// In zh, this message translates to:
  /// **'围栏告警'**
  String get ranchSectionFenceAlerts;

  /// No description provided for @ranchSectionFenceNormal.
  ///
  /// In zh, this message translates to:
  /// **'围栏正常'**
  String get ranchSectionFenceNormal;

  /// No description provided for @ranchSectionHealthAlerts.
  ///
  /// In zh, this message translates to:
  /// **'健康告警'**
  String get ranchSectionHealthAlerts;

  /// No description provided for @ranchSectionLivestockHealthy.
  ///
  /// In zh, this message translates to:
  /// **'牲畜健康'**
  String get ranchSectionLivestockHealthy;

  /// No description provided for @ranchSectionFenceAlertDetail.
  ///
  /// In zh, this message translates to:
  /// **'围栏告警详情'**
  String get ranchSectionFenceAlertDetail;

  /// No description provided for @ranchSectionHealthAlertDetail.
  ///
  /// In zh, this message translates to:
  /// **'健康告警详情'**
  String get ranchSectionHealthAlertDetail;

  /// No description provided for @ranchCapabilityFenceNote.
  ///
  /// In zh, this message translates to:
  /// **'系统能检测围栏越界，定位精度取决于GPS信号'**
  String get ranchCapabilityFenceNote;

  /// No description provided for @ranchCapabilityHealthNote.
  ///
  /// In zh, this message translates to:
  /// **'系统能通知你健康异常，需线下排查确认'**
  String get ranchCapabilityHealthNote;

  /// No description provided for @ranchAlertTypeFenceBreach.
  ///
  /// In zh, this message translates to:
  /// **'越界'**
  String get ranchAlertTypeFenceBreach;

  /// No description provided for @ranchAlertTypeFenceApproach.
  ///
  /// In zh, this message translates to:
  /// **'接近围栏'**
  String get ranchAlertTypeFenceApproach;

  /// No description provided for @ranchAlertTypeZoneApproach.
  ///
  /// In zh, this message translates to:
  /// **'接近区域'**
  String get ranchAlertTypeZoneApproach;

  /// No description provided for @ranchAlertTypeFever.
  ///
  /// In zh, this message translates to:
  /// **'发热'**
  String get ranchAlertTypeFever;

  /// No description provided for @ranchAlertTypeDigestive.
  ///
  /// In zh, this message translates to:
  /// **'消化异常'**
  String get ranchAlertTypeDigestive;

  /// No description provided for @ranchAlertTypeEstrus.
  ///
  /// In zh, this message translates to:
  /// **'发情'**
  String get ranchAlertTypeEstrus;

  /// No description provided for @ranchAlertTypeEpidemic.
  ///
  /// In zh, this message translates to:
  /// **'疫病'**
  String get ranchAlertTypeEpidemic;

  /// No description provided for @ranchAlertTypeShortApproach.
  ///
  /// In zh, this message translates to:
  /// **'接近'**
  String get ranchAlertTypeShortApproach;

  /// No description provided for @ranchAlertTypeShortZone.
  ///
  /// In zh, this message translates to:
  /// **'区域'**
  String get ranchAlertTypeShortZone;

  /// No description provided for @ranchAlertTypeShortDigestive.
  ///
  /// In zh, this message translates to:
  /// **'消化'**
  String get ranchAlertTypeShortDigestive;

  /// No description provided for @ranchAlertTypeEstrusHighScore.
  ///
  /// In zh, this message translates to:
  /// **'发情高分'**
  String get ranchAlertTypeEstrusHighScore;

  /// No description provided for @ranchAlertTypeEpidemicRisk.
  ///
  /// In zh, this message translates to:
  /// **'疫病风险'**
  String get ranchAlertTypeEpidemicRisk;

  /// No description provided for @ranchHealthStatusCritical.
  ///
  /// In zh, this message translates to:
  /// **'严重'**
  String get ranchHealthStatusCritical;

  /// No description provided for @ranchHealthStatusWarning.
  ///
  /// In zh, this message translates to:
  /// **'预警'**
  String get ranchHealthStatusWarning;

  /// No description provided for @ranchHealthStatusNormal.
  ///
  /// In zh, this message translates to:
  /// **'正常'**
  String get ranchHealthStatusNormal;

  /// No description provided for @ranchAlertStatusActive.
  ///
  /// In zh, this message translates to:
  /// **'活跃'**
  String get ranchAlertStatusActive;

  /// No description provided for @ranchAlertStatusDismissed.
  ///
  /// In zh, this message translates to:
  /// **'已忽略'**
  String get ranchAlertStatusDismissed;

  /// No description provided for @ranchAlertStatusAutoResolved.
  ///
  /// In zh, this message translates to:
  /// **'已自动解除'**
  String get ranchAlertStatusAutoResolved;

  /// No description provided for @ranchAlertStatusHandled.
  ///
  /// In zh, this message translates to:
  /// **'已处理'**
  String get ranchAlertStatusHandled;

  /// No description provided for @ranchAlertStatusArchived.
  ///
  /// In zh, this message translates to:
  /// **'已归档'**
  String get ranchAlertStatusArchived;

  /// No description provided for @ranchTimeMinutesAgo.
  ///
  /// In zh, this message translates to:
  /// **'{minutes}分钟前'**
  String ranchTimeMinutesAgo(int minutes);

  /// No description provided for @ranchTimeHoursAgo.
  ///
  /// In zh, this message translates to:
  /// **'{hours}小时前'**
  String ranchTimeHoursAgo(int hours);

  /// No description provided for @ranchTimeDaysAgo.
  ///
  /// In zh, this message translates to:
  /// **'{days}天前'**
  String ranchTimeDaysAgo(int days);

  /// No description provided for @ranchTimeUnknown.
  ///
  /// In zh, this message translates to:
  /// **'未知'**
  String get ranchTimeUnknown;

  /// No description provided for @ranchFieldStatus.
  ///
  /// In zh, this message translates to:
  /// **'状态'**
  String get ranchFieldStatus;

  /// No description provided for @ranchFieldPrimaryAlert.
  ///
  /// In zh, this message translates to:
  /// **'主要异常'**
  String get ranchFieldPrimaryAlert;

  /// No description provided for @ranchFieldLocation.
  ///
  /// In zh, this message translates to:
  /// **'位置'**
  String get ranchFieldLocation;

  /// No description provided for @ranchFieldType.
  ///
  /// In zh, this message translates to:
  /// **'类型'**
  String get ranchFieldType;

  /// No description provided for @ranchFieldDistanceToFence.
  ///
  /// In zh, this message translates to:
  /// **'距围栏'**
  String get ranchFieldDistanceToFence;

  /// No description provided for @ranchFieldDirection.
  ///
  /// In zh, this message translates to:
  /// **'方向'**
  String get ranchFieldDirection;

  /// No description provided for @ranchFieldOccurredTime.
  ///
  /// In zh, this message translates to:
  /// **'发生时间'**
  String get ranchFieldOccurredTime;

  /// No description provided for @ranchFieldTime.
  ///
  /// In zh, this message translates to:
  /// **'时间'**
  String get ranchFieldTime;

  /// No description provided for @ranchFieldAbnormalType.
  ///
  /// In zh, this message translates to:
  /// **'异常类型'**
  String get ranchFieldAbnormalType;

  /// No description provided for @ranchActionDismiss.
  ///
  /// In zh, this message translates to:
  /// **'忽略'**
  String get ranchActionDismiss;

  /// No description provided for @ranchFenceBreachCount.
  ///
  /// In zh, this message translates to:
  /// **'越界 {count} 头'**
  String ranchFenceBreachCount(String count);

  /// No description provided for @ranchFenceApproachCount.
  ///
  /// In zh, this message translates to:
  /// **'接近 {count} 头'**
  String ranchFenceApproachCount(String count);

  /// No description provided for @ranchAutoResolvedCount.
  ///
  /// In zh, this message translates to:
  /// **'已自动解除 ({count})'**
  String ranchAutoResolvedCount(String count);

  /// No description provided for @dashboardNoData.
  ///
  /// In zh, this message translates to:
  /// **'暂无看板数据'**
  String get dashboardNoData;

  /// No description provided for @dashboardTodayOverview.
  ///
  /// In zh, this message translates to:
  /// **'今日牧场概览'**
  String get dashboardTodayOverview;

  /// No description provided for @dashboardFarmOverview.
  ///
  /// In zh, this message translates to:
  /// **'牧场概览'**
  String get dashboardFarmOverview;

  /// No description provided for @dashboardNoFarm.
  ///
  /// In zh, this message translates to:
  /// **'您还没有牧场'**
  String get dashboardNoFarm;

  /// No description provided for @dashboardCreateFirstFarmDesc.
  ///
  /// In zh, this message translates to:
  /// **'创建您的第一个牧场，开始管理牲畜'**
  String get dashboardCreateFirstFarmDesc;

  /// No description provided for @dashboardCreateFirstFarm.
  ///
  /// In zh, this message translates to:
  /// **'创建第一个牧场'**
  String get dashboardCreateFirstFarm;

  /// No description provided for @twinRealtimeOverview.
  ///
  /// In zh, this message translates to:
  /// **'牧场实时概览'**
  String get twinRealtimeOverview;

  /// No description provided for @twinHealthScenarios.
  ///
  /// In zh, this message translates to:
  /// **'健康场景'**
  String get twinHealthScenarios;

  /// No description provided for @twinPendingTasks.
  ///
  /// In zh, this message translates to:
  /// **'待处理任务'**
  String get twinPendingTasks;

  /// No description provided for @mineAccountNormal.
  ///
  /// In zh, this message translates to:
  /// **'账户正常'**
  String get mineAccountNormal;

  /// No description provided for @mineAccountDisabled.
  ///
  /// In zh, this message translates to:
  /// **'账户已停用'**
  String get mineAccountDisabled;

  /// No description provided for @mineProfileName.
  ///
  /// In zh, this message translates to:
  /// **'姓名：{name}'**
  String mineProfileName(String name);

  /// No description provided for @mineProfilePhone.
  ///
  /// In zh, this message translates to:
  /// **'手机号：{phone}'**
  String mineProfilePhone(String phone);

  /// No description provided for @mineProfileRole.
  ///
  /// In zh, this message translates to:
  /// **'角色：{role}'**
  String mineProfileRole(String role);

  /// No description provided for @minePersonalDevices.
  ///
  /// In zh, this message translates to:
  /// **'个人设备与工具'**
  String get minePersonalDevices;

  /// No description provided for @mineDeviceManagementDesc.
  ///
  /// In zh, this message translates to:
  /// **'查看和管理绑定的 IoT 设备'**
  String get mineDeviceManagementDesc;

  /// No description provided for @mineOfflineMapDesc.
  ///
  /// In zh, this message translates to:
  /// **'下载和管理离线瓦片数据'**
  String get mineOfflineMapDesc;

  /// No description provided for @mineHelpSupportDesc.
  ///
  /// In zh, this message translates to:
  /// **'查看设备绑定、帮助文档与联系客服入口'**
  String get mineHelpSupportDesc;

  /// No description provided for @mineHelpSupportComingSoon.
  ///
  /// In zh, this message translates to:
  /// **'帮助与支持页面开发中...'**
  String get mineHelpSupportComingSoon;

  /// No description provided for @mineBusinessManagement.
  ///
  /// In zh, this message translates to:
  /// **'业务管理'**
  String get mineBusinessManagement;

  /// No description provided for @mineSubscriptionManagementDesc.
  ///
  /// In zh, this message translates to:
  /// **'查看和升级订阅套餐'**
  String get mineSubscriptionManagementDesc;

  /// No description provided for @mineRevenueBoardDesc.
  ///
  /// In zh, this message translates to:
  /// **'查看各周期分润对账数据'**
  String get mineRevenueBoardDesc;

  /// No description provided for @mineSubscriptionServiceDesc.
  ///
  /// In zh, this message translates to:
  /// **'管理订阅套餐和业务服务'**
  String get mineSubscriptionServiceDesc;

  /// No description provided for @mineAdvancedManagement.
  ///
  /// In zh, this message translates to:
  /// **'高级管理'**
  String get mineAdvancedManagement;

  /// No description provided for @mineWorkerManagementDesc.
  ///
  /// In zh, this message translates to:
  /// **'查看和移除当前牧场牧工'**
  String get mineWorkerManagementDesc;

  /// No description provided for @mineApiAuthManagementDesc.
  ///
  /// In zh, this message translates to:
  /// **'管理 API Key 和第三方访问授权'**
  String get mineApiAuthManagementDesc;

  /// No description provided for @mineDevicesTitle.
  ///
  /// In zh, this message translates to:
  /// **'设备管理'**
  String get mineDevicesTitle;

  /// No description provided for @mineOfflineMapTitle.
  ///
  /// In zh, this message translates to:
  /// **'离线地图管理'**
  String get mineOfflineMapTitle;

  /// No description provided for @mineHelpSupportTitle.
  ///
  /// In zh, this message translates to:
  /// **'帮助与支持'**
  String get mineHelpSupportTitle;

  /// No description provided for @mineSubscriptionTitle.
  ///
  /// In zh, this message translates to:
  /// **'订阅管理'**
  String get mineSubscriptionTitle;

  /// No description provided for @mineRevenueBoardTitle.
  ///
  /// In zh, this message translates to:
  /// **'对账看板'**
  String get mineRevenueBoardTitle;

  /// No description provided for @mineSubscriptionServiceTitle.
  ///
  /// In zh, this message translates to:
  /// **'订阅服务管理'**
  String get mineSubscriptionServiceTitle;

  /// No description provided for @mineWorkerTitle.
  ///
  /// In zh, this message translates to:
  /// **'牧工管理'**
  String get mineWorkerTitle;

  /// No description provided for @mineApiAuthTitle.
  ///
  /// In zh, this message translates to:
  /// **'API授权管理'**
  String get mineApiAuthTitle;

  /// No description provided for @commonLogoutButton.
  ///
  /// In zh, this message translates to:
  /// **'退出'**
  String get commonLogoutButton;

  /// No description provided for @statsAnalysis.
  ///
  /// In zh, this message translates to:
  /// **'统计分析'**
  String get statsAnalysis;

  /// No description provided for @statsTemperatureTrend.
  ///
  /// In zh, this message translates to:
  /// **'体温趋势 (7日)'**
  String get statsTemperatureTrend;

  /// No description provided for @statsHealthRateTrend.
  ///
  /// In zh, this message translates to:
  /// **'健康率趋势 (7日)'**
  String get statsHealthRateTrend;

  /// No description provided for @statsAlertTrend.
  ///
  /// In zh, this message translates to:
  /// **'告警趋势 (7日)'**
  String get statsAlertTrend;

  /// No description provided for @statsLivestock.
  ///
  /// In zh, this message translates to:
  /// **'牲畜'**
  String get statsLivestock;

  /// No description provided for @statsHealthRate.
  ///
  /// In zh, this message translates to:
  /// **'健康率'**
  String get statsHealthRate;

  /// No description provided for @statsAlerts.
  ///
  /// In zh, this message translates to:
  /// **'告警'**
  String get statsAlerts;

  /// No description provided for @statsCritical.
  ///
  /// In zh, this message translates to:
  /// **'严重'**
  String get statsCritical;

  /// No description provided for @statsAvgTemp.
  ///
  /// In zh, this message translates to:
  /// **'均温'**
  String get statsAvgTemp;

  /// No description provided for @statsMotility.
  ///
  /// In zh, this message translates to:
  /// **'蠕动'**
  String get statsMotility;

  /// No description provided for @statsHealthDistribution.
  ///
  /// In zh, this message translates to:
  /// **'健康分布'**
  String get statsHealthDistribution;

  /// No description provided for @fencePleaseSelectFarm.
  ///
  /// In zh, this message translates to:
  /// **'请先选择一个牧场'**
  String get fencePleaseSelectFarm;

  /// No description provided for @alertsNoAlerts.
  ///
  /// In zh, this message translates to:
  /// **'暂无告警'**
  String get alertsNoAlerts;

  /// No description provided for @alertsNoAlertsDesc.
  ///
  /// In zh, this message translates to:
  /// **'当前没有触发中的 P0 告警。'**
  String get alertsNoAlertsDesc;

  /// No description provided for @alertsConfirm.
  ///
  /// In zh, this message translates to:
  /// **'确认'**
  String get alertsConfirm;

  /// No description provided for @alertsHandle.
  ///
  /// In zh, this message translates to:
  /// **'处理'**
  String get alertsHandle;

  /// No description provided for @alertsArchive.
  ///
  /// In zh, this message translates to:
  /// **'归档'**
  String get alertsArchive;

  /// No description provided for @alertsBatchHandle.
  ///
  /// In zh, this message translates to:
  /// **'批量处理'**
  String get alertsBatchHandle;

  /// No description provided for @alertsBatchDemo.
  ///
  /// In zh, this message translates to:
  /// **'演示：批量处理待接入'**
  String get alertsBatchDemo;

  /// No description provided for @livestockDetailTitle.
  ///
  /// In zh, this message translates to:
  /// **'牲畜详情'**
  String get livestockDetailTitle;

  /// No description provided for @livestockBindDevices.
  ///
  /// In zh, this message translates to:
  /// **'绑定设备'**
  String get livestockBindDevices;

  /// No description provided for @livestockHealthData.
  ///
  /// In zh, this message translates to:
  /// **'健康数据'**
  String get livestockHealthData;

  /// No description provided for @livestockLocation.
  ///
  /// In zh, this message translates to:
  /// **'位置信息'**
  String get livestockLocation;

  /// No description provided for @livestockViewTrajectory.
  ///
  /// In zh, this message translates to:
  /// **'查看完整轨迹'**
  String get livestockViewTrajectory;

  /// No description provided for @feverWarningTitle.
  ///
  /// In zh, this message translates to:
  /// **'发热预警'**
  String get feverWarningTitle;

  /// No description provided for @feverNoData.
  ///
  /// In zh, this message translates to:
  /// **'暂无体温异常数据'**
  String get feverNoData;

  /// No description provided for @digestiveTitle.
  ///
  /// In zh, this message translates to:
  /// **'消化管理'**
  String get digestiveTitle;

  /// No description provided for @digestiveNoData.
  ///
  /// In zh, this message translates to:
  /// **'暂无消化异常数据'**
  String get digestiveNoData;

  /// No description provided for @digestiveItemSubtitle.
  ///
  /// In zh, this message translates to:
  /// **'{breed}  蠕动 {frequency}次/分  ↓{dropPercent}%'**
  String digestiveItemSubtitle(
    String breed,
    String frequency,
    String dropPercent,
  );

  /// No description provided for @estrusTitle.
  ///
  /// In zh, this message translates to:
  /// **'发情识别'**
  String get estrusTitle;

  /// No description provided for @estrusNoData.
  ///
  /// In zh, this message translates to:
  /// **'暂无发情数据'**
  String get estrusNoData;

  /// No description provided for @estrusItemSubtitle.
  ///
  /// In zh, this message translates to:
  /// **'{breed} {genderIcon} {stepInfo}'**
  String estrusItemSubtitle(String breed, String genderIcon, String stepInfo);

  /// No description provided for @epidemicTitle.
  ///
  /// In zh, this message translates to:
  /// **'疫病防控'**
  String get epidemicTitle;

  /// No description provided for @epidemicHerdHealth.
  ///
  /// In zh, this message translates to:
  /// **'群体健康指标'**
  String get epidemicHerdHealth;

  /// No description provided for @epidemicContactTracing.
  ///
  /// In zh, this message translates to:
  /// **'接触追踪'**
  String get epidemicContactTracing;

  /// No description provided for @epidemicRiskLevel.
  ///
  /// In zh, this message translates to:
  /// **'风险等级: {level}'**
  String epidemicRiskLevel(String level);

  /// No description provided for @epidemicAvgTemperature.
  ///
  /// In zh, this message translates to:
  /// **'平均体温'**
  String get epidemicAvgTemperature;

  /// No description provided for @epidemicAbnormalRate.
  ///
  /// In zh, this message translates to:
  /// **'异常率'**
  String get epidemicAbnormalRate;

  /// No description provided for @epidemicAbnormalCount.
  ///
  /// In zh, this message translates to:
  /// **'异常数'**
  String get epidemicAbnormalCount;

  /// No description provided for @feverDetailTitle.
  ///
  /// In zh, this message translates to:
  /// **'体温详情'**
  String get feverDetailTitle;

  /// No description provided for @feverDetailChartTitle.
  ///
  /// In zh, this message translates to:
  /// **'72小时温度曲线'**
  String get feverDetailChartTitle;

  /// No description provided for @digestiveDetailTitle.
  ///
  /// In zh, this message translates to:
  /// **'消化详情'**
  String get digestiveDetailTitle;

  /// No description provided for @digestiveDetailChartTitle.
  ///
  /// In zh, this message translates to:
  /// **'24小时蠕动曲线'**
  String get digestiveDetailChartTitle;

  /// No description provided for @digestiveCurrentFreq.
  ///
  /// In zh, this message translates to:
  /// **'当前频率'**
  String get digestiveCurrentFreq;

  /// No description provided for @digestiveBaselineFreq.
  ///
  /// In zh, this message translates to:
  /// **'基线频率'**
  String get digestiveBaselineFreq;

  /// No description provided for @digestiveStatus.
  ///
  /// In zh, this message translates to:
  /// **'状态'**
  String get digestiveStatus;

  /// No description provided for @digestiveFreqUnit.
  ///
  /// In zh, this message translates to:
  /// **'次/分'**
  String get digestiveFreqUnit;

  /// No description provided for @digestiveCapabilityNote.
  ///
  /// In zh, this message translates to:
  /// **'系统能通知你消化异常，需线下排查确认原因'**
  String get digestiveCapabilityNote;

  /// No description provided for @estrusDetailTitle.
  ///
  /// In zh, this message translates to:
  /// **'发情详情'**
  String get estrusDetailTitle;

  /// No description provided for @estrusDetailChartTitle.
  ///
  /// In zh, this message translates to:
  /// **'7天评分趋势'**
  String get estrusDetailChartTitle;

  /// No description provided for @devicesManagement.
  ///
  /// In zh, this message translates to:
  /// **'设备管理'**
  String get devicesManagement;

  /// No description provided for @deviceSearchHint.
  ///
  /// In zh, this message translates to:
  /// **'搜索设备编号'**
  String get deviceSearchHint;

  /// No description provided for @deviceSearchResult.
  ///
  /// In zh, this message translates to:
  /// **'搜索结果：{total} 条'**
  String deviceSearchResult(Object total);

  /// No description provided for @deviceShowAll.
  ///
  /// In zh, this message translates to:
  /// **'查看全部'**
  String get deviceShowAll;

  /// No description provided for @devicePaginationInfo.
  ///
  /// In zh, this message translates to:
  /// **'第 {currentPage} / {totalPages} 页，共 {total} 条'**
  String devicePaginationInfo(
    Object currentPage,
    Object totalPages,
    Object total,
  );

  /// No description provided for @devicesAddDemo.
  ///
  /// In zh, this message translates to:
  /// **'演示：添加新设备待接入'**
  String get devicesAddDemo;

  /// No description provided for @devicesNoDevices.
  ///
  /// In zh, this message translates to:
  /// **'暂无设备'**
  String get devicesNoDevices;

  /// No description provided for @devicesUnbindDemo.
  ///
  /// In zh, this message translates to:
  /// **'演示：解绑 {name}'**
  String devicesUnbindDemo(String name);

  /// No description provided for @deviceUnbindConfirm.
  ///
  /// In zh, this message translates to:
  /// **'确定要解绑设备 {name} 吗？解绑后该设备将不再关联牲畜。'**
  String deviceUnbindConfirm(String name);

  /// No description provided for @deviceUnbindSuccess.
  ///
  /// In zh, this message translates to:
  /// **'解绑成功：{name}'**
  String deviceUnbindSuccess(String name);

  /// No description provided for @deviceUnbindFailed.
  ///
  /// In zh, this message translates to:
  /// **'解绑失败: {error}'**
  String deviceUnbindFailed(String error);

  /// No description provided for @devicesViewLocationDemo.
  ///
  /// In zh, this message translates to:
  /// **'演示：查看 {name} 位置'**
  String devicesViewLocationDemo(String name);

  /// No description provided for @devicesInstallSuccess.
  ///
  /// In zh, this message translates to:
  /// **'安装成功：{name}'**
  String devicesInstallSuccess(String name);

  /// No description provided for @devicesInstallFailed.
  ///
  /// In zh, this message translates to:
  /// **'安装失败: {error}'**
  String devicesInstallFailed(String error);

  /// No description provided for @devicesInstallTo.
  ///
  /// In zh, this message translates to:
  /// **'安装到牲畜 — {name}'**
  String devicesInstallTo(String name);

  /// No description provided for @devicesNoMatchingLivestock.
  ///
  /// In zh, this message translates to:
  /// **'无匹配牲畜'**
  String get devicesNoMatchingLivestock;

  /// No description provided for @devicesOverview.
  ///
  /// In zh, this message translates to:
  /// **'设备概览'**
  String get devicesOverview;

  /// No description provided for @devicesStatTotal.
  ///
  /// In zh, this message translates to:
  /// **'总数'**
  String get devicesStatTotal;

  /// No description provided for @devicesSearchHint.
  ///
  /// In zh, this message translates to:
  /// **'搜索耳标/品种'**
  String get devicesSearchHint;

  /// No description provided for @adminAnalytics.
  ///
  /// In zh, this message translates to:
  /// **'用量分析'**
  String get adminAnalytics;

  /// No description provided for @adminAnalyticsDesc.
  ///
  /// In zh, this message translates to:
  /// **'API 调用量统计与趋势分析'**
  String get adminAnalyticsDesc;

  /// No description provided for @adminFeatureGates.
  ///
  /// In zh, this message translates to:
  /// **'功能门控'**
  String get adminFeatureGates;

  /// No description provided for @adminFeatureGatesDesc.
  ///
  /// In zh, this message translates to:
  /// **'管理各等级功能配额'**
  String get adminFeatureGatesDesc;

  /// No description provided for @adminAuditLog.
  ///
  /// In zh, this message translates to:
  /// **'审计日志'**
  String get adminAuditLog;

  /// No description provided for @adminAuditLogDesc.
  ///
  /// In zh, this message translates to:
  /// **'查看系统操作记录'**
  String get adminAuditLogDesc;

  /// No description provided for @adminTileManagement.
  ///
  /// In zh, this message translates to:
  /// **'瓦片管理'**
  String get adminTileManagement;

  /// No description provided for @adminTileManagementDesc.
  ///
  /// In zh, this message translates to:
  /// **'管理离线瓦片区域和任务'**
  String get adminTileManagementDesc;

  /// No description provided for @adminTitle.
  ///
  /// In zh, this message translates to:
  /// **'后台管理'**
  String get adminTitle;

  /// No description provided for @adminSubtitle.
  ///
  /// In zh, this message translates to:
  /// **'管理控制台 - 业务数据与订阅概览'**
  String get adminSubtitle;

  /// No description provided for @fenceFormManualEntry.
  ///
  /// In zh, this message translates to:
  /// **'手动录入坐标'**
  String get fenceFormManualEntry;

  /// No description provided for @fenceFormApply.
  ///
  /// In zh, this message translates to:
  /// **'应用'**
  String get fenceFormApply;

  /// No description provided for @fenceFormVersionConflict.
  ///
  /// In zh, this message translates to:
  /// **'版本冲突'**
  String get fenceFormVersionConflict;

  /// No description provided for @fenceFormVersionConflictDesc.
  ///
  /// In zh, this message translates to:
  /// **'该围栏已被其他操作修改，是否强制覆盖？'**
  String get fenceFormVersionConflictDesc;

  /// No description provided for @fenceFormForceUpdate.
  ///
  /// In zh, this message translates to:
  /// **'强制更新'**
  String get fenceFormForceUpdate;

  /// No description provided for @fenceFormForceUpdateFailed.
  ///
  /// In zh, this message translates to:
  /// **'强制更新失败: {error}'**
  String fenceFormForceUpdateFailed(String error);

  /// No description provided for @fenceFormSaveFailed.
  ///
  /// In zh, this message translates to:
  /// **'保存失败: {error}'**
  String fenceFormSaveFailed(String error);

  /// No description provided for @fenceFormRectangle.
  ///
  /// In zh, this message translates to:
  /// **'矩形'**
  String get fenceFormRectangle;

  /// No description provided for @fenceFormCircle.
  ///
  /// In zh, this message translates to:
  /// **'圆形'**
  String get fenceFormCircle;

  /// No description provided for @fenceFormPolygon.
  ///
  /// In zh, this message translates to:
  /// **'多边形'**
  String get fenceFormPolygon;

  /// No description provided for @fenceFormReset.
  ///
  /// In zh, this message translates to:
  /// **'重置'**
  String get fenceFormReset;

  /// No description provided for @fenceFormManualInput.
  ///
  /// In zh, this message translates to:
  /// **'手动录入'**
  String get fenceFormManualInput;

  /// No description provided for @fenceFormEnableAlarm.
  ///
  /// In zh, this message translates to:
  /// **'启用告警'**
  String get fenceFormEnableAlarm;

  /// No description provided for @fenceFormEnableStatus.
  ///
  /// In zh, this message translates to:
  /// **'启用状态'**
  String get fenceFormEnableStatus;

  /// No description provided for @fenceFormSaveFence.
  ///
  /// In zh, this message translates to:
  /// **'保存围栏'**
  String get fenceFormSaveFence;

  /// No description provided for @b2bRevenueTitle.
  ///
  /// In zh, this message translates to:
  /// **'对账'**
  String get b2bRevenueTitle;

  /// No description provided for @b2bRevenueNoData.
  ///
  /// In zh, this message translates to:
  /// **'暂无对账数据，系统将在每月1日自动生成结算周期'**
  String get b2bRevenueNoData;

  /// No description provided for @b2bContractTitle.
  ///
  /// In zh, this message translates to:
  /// **'合同信息'**
  String get b2bContractTitle;

  /// No description provided for @b2bContractTerms.
  ///
  /// In zh, this message translates to:
  /// **'合同条款'**
  String get b2bContractTerms;

  /// No description provided for @b2bContractServiceStatus.
  ///
  /// In zh, this message translates to:
  /// **'订阅服务状态'**
  String get b2bContractServiceStatus;

  /// No description provided for @b2bContractRenew.
  ///
  /// In zh, this message translates to:
  /// **'联系续签'**
  String get b2bContractRenew;

  /// No description provided for @b2bDashboardTitle.
  ///
  /// In zh, this message translates to:
  /// **'运营概览'**
  String get b2bDashboardTitle;

  /// No description provided for @b2bDashboardMonthlyRevenue.
  ///
  /// In zh, this message translates to:
  /// **'本月营收'**
  String get b2bDashboardMonthlyRevenue;

  /// No description provided for @b2bDashboardPendingAlerts.
  ///
  /// In zh, this message translates to:
  /// **'待处理告警'**
  String get b2bDashboardPendingAlerts;

  /// No description provided for @b2bDashboardNoPendingAlerts.
  ///
  /// In zh, this message translates to:
  /// **'暂无待处理告警'**
  String get b2bDashboardNoPendingAlerts;

  /// No description provided for @b2bRevenueDetailConfirmOk.
  ///
  /// In zh, this message translates to:
  /// **'对账确认成功'**
  String get b2bRevenueDetailConfirmOk;

  /// No description provided for @b2bRevenueDetailConfirmFailed.
  ///
  /// In zh, this message translates to:
  /// **'确认失败，请重试'**
  String get b2bRevenueDetailConfirmFailed;

  /// No description provided for @b2bRevenueDetailTitle.
  ///
  /// In zh, this message translates to:
  /// **'对账明细'**
  String get b2bRevenueDetailTitle;

  /// No description provided for @b2bRevenueDetailDeviceFee.
  ///
  /// In zh, this message translates to:
  /// **'设备费用合计'**
  String get b2bRevenueDetailDeviceFee;

  /// No description provided for @b2bRevenueDetailConfirmStatus.
  ///
  /// In zh, this message translates to:
  /// **'确认状态'**
  String get b2bRevenueDetailConfirmStatus;

  /// No description provided for @b2bRevenueDetailConfirmButton.
  ///
  /// In zh, this message translates to:
  /// **'确认对账'**
  String get b2bRevenueDetailConfirmButton;

  /// No description provided for @b2bFarmCreationEnterName.
  ///
  /// In zh, this message translates to:
  /// **'请输入牧场名称'**
  String get b2bFarmCreationEnterName;

  /// No description provided for @b2bFarmCreationSelectPoint.
  ///
  /// In zh, this message translates to:
  /// **'请在地图上选点或输入经纬度'**
  String get b2bFarmCreationSelectPoint;

  /// No description provided for @b2bFarmCreationSuccess.
  ///
  /// In zh, this message translates to:
  /// **'牧场「{name}」创建成功'**
  String b2bFarmCreationSuccess(String name);

  /// No description provided for @b2bFarmCreationFailed.
  ///
  /// In zh, this message translates to:
  /// **'创建失败，请重试'**
  String get b2bFarmCreationFailed;

  /// No description provided for @b2bFarmCreationTitle.
  ///
  /// In zh, this message translates to:
  /// **'新建牧场'**
  String get b2bFarmCreationTitle;

  /// No description provided for @b2bFarmCreationButton.
  ///
  /// In zh, this message translates to:
  /// **'创建牧场'**
  String get b2bFarmCreationButton;

  /// No description provided for @b2bFarmCreationNotSpecified.
  ///
  /// In zh, this message translates to:
  /// **'— 暂不指定 —'**
  String get b2bFarmCreationNotSpecified;

  /// No description provided for @b2bFarmCreationUserLoadFailed.
  ///
  /// In zh, this message translates to:
  /// **'加载用户列表失败'**
  String get b2bFarmCreationUserLoadFailed;

  /// No description provided for @b2bFarmCreationSelectTile.
  ///
  /// In zh, this message translates to:
  /// **'请先选择瓦片区域'**
  String get b2bFarmCreationSelectTile;

  /// No description provided for @wizardExitConfirm.
  ///
  /// In zh, this message translates to:
  /// **'牧场已创建。退出后将进入主页面，您可以稍后设置围栏。'**
  String get wizardExitConfirm;

  /// No description provided for @wizardContinueSetup.
  ///
  /// In zh, this message translates to:
  /// **'继续设置'**
  String get wizardContinueSetup;

  /// No description provided for @wizardNextStep.
  ///
  /// In zh, this message translates to:
  /// **'下一步'**
  String get wizardNextStep;

  /// No description provided for @wizardEnterRanch.
  ///
  /// In zh, this message translates to:
  /// **'进入牧场'**
  String get wizardEnterRanch;

  /// No description provided for @wizardCreateFailedNoId.
  ///
  /// In zh, this message translates to:
  /// **'创建牧场失败：未获取到牧场ID'**
  String get wizardCreateFailedNoId;

  /// No description provided for @wizardCreateFailed.
  ///
  /// In zh, this message translates to:
  /// **'创建牧场失败，请重试'**
  String get wizardCreateFailed;

  /// No description provided for @wizardFenceMinVertices.
  ///
  /// In zh, this message translates to:
  /// **'围栏至少需要 3 个顶点'**
  String get wizardFenceMinVertices;

  /// No description provided for @wizardSetupLater.
  ///
  /// In zh, this message translates to:
  /// **'稍后设置'**
  String get wizardSetupLater;

  /// No description provided for @subscriptionUpgradeTier.
  ///
  /// In zh, this message translates to:
  /// **'升级套餐'**
  String get subscriptionUpgradeTier;

  /// No description provided for @subscriptionRenew.
  ///
  /// In zh, this message translates to:
  /// **'续费'**
  String get subscriptionRenew;

  /// No description provided for @subscriptionConfirmCancel.
  ///
  /// In zh, this message translates to:
  /// **'确认取消'**
  String get subscriptionConfirmCancel;

  /// No description provided for @subscriptionCancelWarning.
  ///
  /// In zh, this message translates to:
  /// **'取消订阅后，当前周期结束后将无法使用付费功能。确定要取消吗？'**
  String get subscriptionCancelWarning;

  /// No description provided for @subscriptionKeepSubscription.
  ///
  /// In zh, this message translates to:
  /// **'暂不取消'**
  String get subscriptionKeepSubscription;

  /// No description provided for @subscriptionCancelled.
  ///
  /// In zh, this message translates to:
  /// **'订阅已取消'**
  String get subscriptionCancelled;

  /// No description provided for @subscriptionCurrentTier.
  ///
  /// In zh, this message translates to:
  /// **'当前套餐'**
  String get subscriptionCurrentTier;

  /// No description provided for @subscriptionSelectTier.
  ///
  /// In zh, this message translates to:
  /// **'选择此套餐'**
  String get subscriptionSelectTier;

  /// No description provided for @subscriptionRenewNow.
  ///
  /// In zh, this message translates to:
  /// **'立即续费'**
  String get subscriptionRenewNow;

  /// No description provided for @subscriptionUpgradeTo.
  ///
  /// In zh, this message translates to:
  /// **'升级到{tier}'**
  String subscriptionUpgradeTo(String tier);

  /// No description provided for @subFeatureGpsLocation.
  ///
  /// In zh, this message translates to:
  /// **'GPS定位'**
  String get subFeatureGpsLocation;

  /// No description provided for @subFeatureFenceCount.
  ///
  /// In zh, this message translates to:
  /// **'电子围栏({count}个)'**
  String subFeatureFenceCount(String count);

  /// No description provided for @subFeatureFenceUnlimited.
  ///
  /// In zh, this message translates to:
  /// **'电子围栏(不限)'**
  String get subFeatureFenceUnlimited;

  /// No description provided for @subFeatureAlertHistoryDays.
  ///
  /// In zh, this message translates to:
  /// **'告警历史({count}天)'**
  String subFeatureAlertHistoryDays(String count);

  /// No description provided for @subFeatureAlertHistory1Year.
  ///
  /// In zh, this message translates to:
  /// **'告警历史(1年)'**
  String get subFeatureAlertHistory1Year;

  /// No description provided for @subFeatureDataRetentionDays.
  ///
  /// In zh, this message translates to:
  /// **'数据保留({count}天)'**
  String subFeatureDataRetentionDays(String count);

  /// No description provided for @subFeatureDataRetention365.
  ///
  /// In zh, this message translates to:
  /// **'数据保留(365天)'**
  String get subFeatureDataRetention365;

  /// No description provided for @subFeatureDataRetention3Year.
  ///
  /// In zh, this message translates to:
  /// **'数据保留(3年)'**
  String get subFeatureDataRetention3Year;

  /// No description provided for @subFeatureDashboardBasic.
  ///
  /// In zh, this message translates to:
  /// **'基础看板'**
  String get subFeatureDashboardBasic;

  /// No description provided for @subFeatureDashboardAdvanced.
  ///
  /// In zh, this message translates to:
  /// **'高级看板'**
  String get subFeatureDashboardAdvanced;

  /// No description provided for @subFeatureTrajectory.
  ///
  /// In zh, this message translates to:
  /// **'历史轨迹'**
  String get subFeatureTrajectory;

  /// No description provided for @subFeatureDeviceManagement.
  ///
  /// In zh, this message translates to:
  /// **'设备管理'**
  String get subFeatureDeviceManagement;

  /// No description provided for @subFeatureHealthScore.
  ///
  /// In zh, this message translates to:
  /// **'健康评分'**
  String get subFeatureHealthScore;

  /// No description provided for @subFeatureEstrusDetect.
  ///
  /// In zh, this message translates to:
  /// **'发情检测'**
  String get subFeatureEstrusDetect;

  /// No description provided for @subFeatureEpidemicAlert.
  ///
  /// In zh, this message translates to:
  /// **'疫病预警'**
  String get subFeatureEpidemicAlert;

  /// No description provided for @subFeatureDedicatedSupport.
  ///
  /// In zh, this message translates to:
  /// **'专属客服'**
  String get subFeatureDedicatedSupport;

  /// No description provided for @subFeatureGaitAnalysis.
  ///
  /// In zh, this message translates to:
  /// **'步态分析'**
  String get subFeatureGaitAnalysis;

  /// No description provided for @subFeatureBehaviorStats.
  ///
  /// In zh, this message translates to:
  /// **'行为统计'**
  String get subFeatureBehaviorStats;

  /// No description provided for @subFeatureApiAccess.
  ///
  /// In zh, this message translates to:
  /// **'API访问'**
  String get subFeatureApiAccess;

  /// No description provided for @subCurrentTier.
  ///
  /// In zh, this message translates to:
  /// **'当前套餐'**
  String get subCurrentTier;

  /// No description provided for @subCustomPricing.
  ///
  /// In zh, this message translates to:
  /// **'按需定价'**
  String get subCustomPricing;

  /// No description provided for @subPerMonth.
  ///
  /// In zh, this message translates to:
  /// **'¥{price}/月'**
  String subPerMonth(String price);

  /// No description provided for @subLivestockLimit.
  ///
  /// In zh, this message translates to:
  /// **'最多{count}头牲畜'**
  String subLivestockLimit(String count);

  /// No description provided for @subLivestockUnlimited.
  ///
  /// In zh, this message translates to:
  /// **'不限牲畜数量'**
  String get subLivestockUnlimited;

  /// No description provided for @subExcessFee.
  ///
  /// In zh, this message translates to:
  /// **'超出部分 ¥{price}/头/月'**
  String subExcessFee(String price);

  /// No description provided for @subFeatureCountSuffix.
  ///
  /// In zh, this message translates to:
  /// **'等{count}项功能'**
  String subFeatureCountSuffix(String count);

  /// No description provided for @subSelectedPlan.
  ///
  /// In zh, this message translates to:
  /// **'已选择套餐'**
  String get subSelectedPlan;

  /// No description provided for @subLivestockCountLabel.
  ///
  /// In zh, this message translates to:
  /// **'牲畜数量'**
  String get subLivestockCountLabel;

  /// No description provided for @subFeeBreakdown.
  ///
  /// In zh, this message translates to:
  /// **'费用明细'**
  String get subFeeBreakdown;

  /// No description provided for @subPlanFee.
  ///
  /// In zh, this message translates to:
  /// **'套餐费（{tier}）'**
  String subPlanFee(String tier);

  /// No description provided for @subTrialEndsAt.
  ///
  /// In zh, this message translates to:
  /// **'试用期至 {date}（剩余{days}天）'**
  String subTrialEndsAt(String date, Object days);

  /// No description provided for @subValidUntil.
  ///
  /// In zh, this message translates to:
  /// **'有效期至 {date}'**
  String subValidUntil(String date);

  /// No description provided for @subExpiresOn.
  ///
  /// In zh, this message translates to:
  /// **'订阅将于 {date} 到期'**
  String subExpiresOn(String date);

  /// No description provided for @subSubscriptionCancelled.
  ///
  /// In zh, this message translates to:
  /// **'订阅已取消'**
  String get subSubscriptionCancelled;

  /// No description provided for @subRenewalUrgent.
  ///
  /// In zh, this message translates to:
  /// **'您的订阅即将到期'**
  String get subRenewalUrgent;

  /// No description provided for @subTrialRenewHint.
  ///
  /// In zh, this message translates to:
  /// **'试用期还有{days}天到期，立即续费保留所有数据'**
  String subTrialRenewHint(String days);

  /// No description provided for @subRenewHint.
  ///
  /// In zh, this message translates to:
  /// **'订阅还有{days}天到期'**
  String subRenewHint(String days);

  /// No description provided for @subSelectPlanHint.
  ///
  /// In zh, this message translates to:
  /// **'选择适合您牧场的套餐方案'**
  String get subSelectPlanHint;

  /// No description provided for @subExcessDeviceFee.
  ///
  /// In zh, this message translates to:
  /// **'超出设备费（超出{count}头 × ¥{price}/头）'**
  String subExcessDeviceFee(String count, Object price);

  /// No description provided for @subLockedNeedDevice.
  ///
  /// In zh, this message translates to:
  /// **'该功能需要安装相应设备'**
  String get subLockedNeedDevice;

  /// No description provided for @subLockedUpgradeTier.
  ///
  /// In zh, this message translates to:
  /// **'该功能需要升级到{tier}'**
  String subLockedUpgradeTier(String tier);

  /// No description provided for @subServiceManagement.
  ///
  /// In zh, this message translates to:
  /// **'订阅服务管理'**
  String get subServiceManagement;

  /// No description provided for @subServiceManagementDesc.
  ///
  /// In zh, this message translates to:
  /// **'管理所有租户的订阅服务'**
  String get subServiceManagementDesc;

  /// No description provided for @subUnknownService.
  ///
  /// In zh, this message translates to:
  /// **'未知服务'**
  String get subUnknownService;

  /// No description provided for @subServicePeriod.
  ///
  /// In zh, this message translates to:
  /// **'期限: {start} ~ {end}'**
  String subServicePeriod(String start, String end);

  /// No description provided for @subTotal.
  ///
  /// In zh, this message translates to:
  /// **'合计'**
  String get subTotal;

  /// No description provided for @subConfirmPay.
  ///
  /// In zh, this message translates to:
  /// **'确认支付 ¥{amount}'**
  String subConfirmPay(String amount);

  /// No description provided for @subYuanSuffix.
  ///
  /// In zh, this message translates to:
  /// **'¥{amount} 元'**
  String subYuanSuffix(String amount);

  /// No description provided for @subSubscribeSuccess.
  ///
  /// In zh, this message translates to:
  /// **'已成功订阅{tier}'**
  String subSubscribeSuccess(String tier);

  /// No description provided for @subExcessDeviceFeeWithin.
  ///
  /// In zh, this message translates to:
  /// **'超出设备费（在{quota}额度内）'**
  String subExcessDeviceFeeWithin(String quota);

  /// No description provided for @subCancelSubscription.
  ///
  /// In zh, this message translates to:
  /// **'取消订阅'**
  String get subCancelSubscription;

  /// No description provided for @b2bContractNumber.
  ///
  /// In zh, this message translates to:
  /// **'编号'**
  String get b2bContractNumber;

  /// No description provided for @b2bContractSigner.
  ///
  /// In zh, this message translates to:
  /// **'签约人'**
  String get b2bContractSigner;

  /// No description provided for @b2bContractBillingMode.
  ///
  /// In zh, this message translates to:
  /// **'计费模式'**
  String get b2bContractBillingMode;

  /// No description provided for @b2bContractTierLevel.
  ///
  /// In zh, this message translates to:
  /// **'套餐等级'**
  String get b2bContractTierLevel;

  /// No description provided for @b2bContractRevenueShare.
  ///
  /// In zh, this message translates to:
  /// **'分润比例'**
  String get b2bContractRevenueShare;

  /// No description provided for @b2bContractEffectiveDate.
  ///
  /// In zh, this message translates to:
  /// **'生效日期'**
  String get b2bContractEffectiveDate;

  /// No description provided for @b2bContractExpiryDate.
  ///
  /// In zh, this message translates to:
  /// **'到期日期'**
  String get b2bContractExpiryDate;

  /// No description provided for @b2bContractDeployMode.
  ///
  /// In zh, this message translates to:
  /// **'部署方式'**
  String get b2bContractDeployMode;

  /// No description provided for @b2bContractDeviceQuota.
  ///
  /// In zh, this message translates to:
  /// **'设备配额'**
  String get b2bContractDeviceQuota;

  /// No description provided for @b2bContractHeartbeat.
  ///
  /// In zh, this message translates to:
  /// **'心跳'**
  String get b2bContractHeartbeat;

  /// No description provided for @b2bContractExpiryTime.
  ///
  /// In zh, this message translates to:
  /// **'到期时间'**
  String get b2bContractExpiryTime;

  /// No description provided for @b2bContractContactPlatform.
  ///
  /// In zh, this message translates to:
  /// **'联系平台'**
  String get b2bContractContactPlatform;

  /// No description provided for @b2bContractContactPlatformDesc.
  ///
  /// In zh, this message translates to:
  /// **'咨询续签或变更'**
  String get b2bContractContactPlatformDesc;

  /// No description provided for @b2bContractDownload.
  ///
  /// In zh, this message translates to:
  /// **'下载合同'**
  String get b2bContractDownload;

  /// No description provided for @b2bContractDownloadDesc.
  ///
  /// In zh, this message translates to:
  /// **'导出 PDF（占位）'**
  String get b2bContractDownloadDesc;

  /// No description provided for @b2bContractComingSoon.
  ///
  /// In zh, this message translates to:
  /// **'功能开发中'**
  String get b2bContractComingSoon;

  /// No description provided for @b2bContractChatComingSoon.
  ///
  /// In zh, this message translates to:
  /// **'在线客服功能即将上线'**
  String get b2bContractChatComingSoon;

  /// No description provided for @b2bContractPdfComingSoon.
  ///
  /// In zh, this message translates to:
  /// **'合同 PDF 下载功能即将上线'**
  String get b2bContractPdfComingSoon;

  /// No description provided for @b2bContractGotIt.
  ///
  /// In zh, this message translates to:
  /// **'知道了'**
  String get b2bContractGotIt;

  /// No description provided for @b2bContractClose.
  ///
  /// In zh, this message translates to:
  /// **'关闭'**
  String get b2bContractClose;

  /// No description provided for @b2bContractStatusActive.
  ///
  /// In zh, this message translates to:
  /// **'生效中'**
  String get b2bContractStatusActive;

  /// No description provided for @b2bContractStatusSuspended.
  ///
  /// In zh, this message translates to:
  /// **'已暂停'**
  String get b2bContractStatusSuspended;

  /// No description provided for @b2bContractStatusExpired.
  ///
  /// In zh, this message translates to:
  /// **'已过期'**
  String get b2bContractStatusExpired;

  /// No description provided for @b2bContractModeRevenueShare.
  ///
  /// In zh, this message translates to:
  /// **'分润模式'**
  String get b2bContractModeRevenueShare;

  /// No description provided for @b2bContractModeLicensed.
  ///
  /// In zh, this message translates to:
  /// **'授权模式'**
  String get b2bContractModeLicensed;

  /// No description provided for @b2bContractDeployCloud.
  ///
  /// In zh, this message translates to:
  /// **'云端'**
  String get b2bContractDeployCloud;

  /// No description provided for @b2bContractDeployOnPremise.
  ///
  /// In zh, this message translates to:
  /// **'本地部署'**
  String get b2bContractDeployOnPremise;

  /// No description provided for @b2bContractHealthRunning.
  ///
  /// In zh, this message translates to:
  /// **'正常运行'**
  String get b2bContractHealthRunning;

  /// No description provided for @b2bContractHealthDegraded.
  ///
  /// In zh, this message translates to:
  /// **'性能降级'**
  String get b2bContractHealthDegraded;

  /// No description provided for @b2bContractHealthDown.
  ///
  /// In zh, this message translates to:
  /// **'服务中断'**
  String get b2bContractHealthDown;

  /// No description provided for @b2bContractUnknown.
  ///
  /// In zh, this message translates to:
  /// **'未知'**
  String get b2bContractUnknown;

  /// No description provided for @b2bContractExpiryLabel.
  ///
  /// In zh, this message translates to:
  /// **'合同到期日'**
  String get b2bContractExpiryLabel;

  /// No description provided for @b2bContractDaysLeft.
  ///
  /// In zh, this message translates to:
  /// **'{date}  ·  剩余 {days} 天'**
  String b2bContractDaysLeft(String date, Object days);

  /// No description provided for @b2bContractExpiredOn.
  ///
  /// In zh, this message translates to:
  /// **'{date}  ·  已过期'**
  String b2bContractExpiredOn(String date);

  /// No description provided for @subPlanFeeLabel.
  ///
  /// In zh, this message translates to:
  /// **'套餐费'**
  String get subPlanFeeLabel;

  /// No description provided for @subDeviceFee.
  ///
  /// In zh, this message translates to:
  /// **'设备费（{count}头 × ¥{price}/头）'**
  String subDeviceFee(String count, Object price);

  /// No description provided for @subscriptionFeature.
  ///
  /// In zh, this message translates to:
  /// **'功能'**
  String get subscriptionFeature;

  /// No description provided for @subscriptionStatusTrial.
  ///
  /// In zh, this message translates to:
  /// **'试用中'**
  String get subscriptionStatusTrial;

  /// No description provided for @subscriptionStatusActive.
  ///
  /// In zh, this message translates to:
  /// **'已订阅'**
  String get subscriptionStatusActive;

  /// No description provided for @subscriptionStatusCancelled.
  ///
  /// In zh, this message translates to:
  /// **'已取消'**
  String get subscriptionStatusCancelled;

  /// No description provided for @subscriptionStatusExpired.
  ///
  /// In zh, this message translates to:
  /// **'已过期'**
  String get subscriptionStatusExpired;

  /// No description provided for @adminSubscriptionsNoData.
  ///
  /// In zh, this message translates to:
  /// **'暂无订阅服务'**
  String get adminSubscriptionsNoData;

  /// No description provided for @adminSubscriptionsRevoke.
  ///
  /// In zh, this message translates to:
  /// **'撤销'**
  String get adminSubscriptionsRevoke;

  /// No description provided for @adminSubscriptionsRenew.
  ///
  /// In zh, this message translates to:
  /// **'续期'**
  String get adminSubscriptionsRenew;

  /// No description provided for @adminApiAuthCreateKey.
  ///
  /// In zh, this message translates to:
  /// **'创建 Key'**
  String get adminApiAuthCreateKey;

  /// No description provided for @adminApiAuthNoKeys.
  ///
  /// In zh, this message translates to:
  /// **'暂无 API Key'**
  String get adminApiAuthNoKeys;

  /// No description provided for @adminApiAuthDescription.
  ///
  /// In zh, this message translates to:
  /// **'管理 API Key 的创建、启用和撤销'**
  String get adminApiAuthDescription;

  /// No description provided for @adminApiAuthName.
  ///
  /// In zh, this message translates to:
  /// **'名称'**
  String get adminApiAuthName;

  /// No description provided for @adminApiAuthDescriptionOptional.
  ///
  /// In zh, this message translates to:
  /// **'描述（可选）'**
  String get adminApiAuthDescriptionOptional;

  /// No description provided for @adminApiAuthScopes.
  ///
  /// In zh, this message translates to:
  /// **'权限范围:'**
  String get adminApiAuthScopes;

  /// No description provided for @adminApiAuthCreate.
  ///
  /// In zh, this message translates to:
  /// **'创建'**
  String get adminApiAuthCreate;

  /// No description provided for @adminApiAuthKeyCreated.
  ///
  /// In zh, this message translates to:
  /// **'Key 已创建'**
  String get adminApiAuthKeyCreated;

  /// No description provided for @adminApiAuthKeyWarning.
  ///
  /// In zh, this message translates to:
  /// **'请立即保存此 Key，关闭后将无法再次查看。'**
  String get adminApiAuthKeyWarning;

  /// No description provided for @adminApiAuthSaved.
  ///
  /// In zh, this message translates to:
  /// **'已保存'**
  String get adminApiAuthSaved;

  /// No description provided for @adminRevenueNoData.
  ///
  /// In zh, this message translates to:
  /// **'暂无对账周期'**
  String get adminRevenueNoData;

  /// No description provided for @adminContractActive.
  ///
  /// In zh, this message translates to:
  /// **'生效中'**
  String get adminContractActive;

  /// No description provided for @adminContractDraft.
  ///
  /// In zh, this message translates to:
  /// **'待签署'**
  String get adminContractDraft;

  /// No description provided for @adminContractTerminated.
  ///
  /// In zh, this message translates to:
  /// **'已终止'**
  String get adminContractTerminated;

  /// No description provided for @adminContractTerminate.
  ///
  /// In zh, this message translates to:
  /// **'终止合同'**
  String get adminContractTerminate;

  /// No description provided for @adminContractNoData.
  ///
  /// In zh, this message translates to:
  /// **'暂无合同'**
  String get adminContractNoData;

  /// No description provided for @adminSubscriptionsTierLabel.
  ///
  /// In zh, this message translates to:
  /// **'套餐'**
  String get adminSubscriptionsTierLabel;

  /// No description provided for @adminSubscriptionsQuotaLabel.
  ///
  /// In zh, this message translates to:
  /// **'设备配额'**
  String get adminSubscriptionsQuotaLabel;

  /// No description provided for @adminApiAuthPrefixLabel.
  ///
  /// In zh, this message translates to:
  /// **'前缀'**
  String get adminApiAuthPrefixLabel;

  /// No description provided for @fenceUnsavedTitle.
  ///
  /// In zh, this message translates to:
  /// **'有未保存修改'**
  String get fenceUnsavedTitle;

  /// No description provided for @fenceUnsavedMessage.
  ///
  /// In zh, this message translates to:
  /// **'你有未保存的边界修改。请选择下一步。'**
  String get fenceUnsavedMessage;

  /// No description provided for @fenceUnsavedContinue.
  ///
  /// In zh, this message translates to:
  /// **'继续编辑'**
  String get fenceUnsavedContinue;

  /// No description provided for @fenceUnsavedDiscard.
  ///
  /// In zh, this message translates to:
  /// **'放弃更改'**
  String get fenceUnsavedDiscard;

  /// No description provided for @fenceUnsavedSaveExit.
  ///
  /// In zh, this message translates to:
  /// **'保存并退出'**
  String get fenceUnsavedSaveExit;

  /// No description provided for @tenantAdjustLicenseTitle.
  ///
  /// In zh, this message translates to:
  /// **'调整 License 配额'**
  String get tenantAdjustLicenseTitle;

  /// No description provided for @tenantAdjustLicenseUsed.
  ///
  /// In zh, this message translates to:
  /// **'当前已使用：{used}'**
  String tenantAdjustLicenseUsed(String used);

  /// No description provided for @tenantAdjustLicenseNew.
  ///
  /// In zh, this message translates to:
  /// **'新 License 配额'**
  String get tenantAdjustLicenseNew;

  /// No description provided for @tenantAdjustLicenseConfirm.
  ///
  /// In zh, this message translates to:
  /// **'确认调整'**
  String get tenantAdjustLicenseConfirm;

  /// No description provided for @tenantDeleteTitle.
  ///
  /// In zh, this message translates to:
  /// **'删除租户'**
  String get tenantDeleteTitle;

  /// No description provided for @tenantDeleteMessage.
  ///
  /// In zh, this message translates to:
  /// **'即将删除租户「{name}」。该操作不可撤销。'**
  String tenantDeleteMessage(String name);

  /// No description provided for @tenantDeleteReason.
  ///
  /// In zh, this message translates to:
  /// **'删除原因'**
  String get tenantDeleteReason;

  /// No description provided for @ranchHealthLatestAlerts.
  ///
  /// In zh, this message translates to:
  /// **'最新告警'**
  String get ranchHealthLatestAlerts;

  /// No description provided for @ranchHealthAllRead.
  ///
  /// In zh, this message translates to:
  /// **'全部已读 ({count})'**
  String ranchHealthAllRead(String count);

  /// No description provided for @ranchHealthDismissed.
  ///
  /// In zh, this message translates to:
  /// **'已忽略 ({count})'**
  String ranchHealthDismissed(String count);

  /// No description provided for @ranchHealthIgnoreAlert.
  ///
  /// In zh, this message translates to:
  /// **'忽略此告警'**
  String get ranchHealthIgnoreAlert;

  /// No description provided for @ranchHealthFenceInfo.
  ///
  /// In zh, this message translates to:
  /// **'围栏信息'**
  String get ranchHealthFenceInfo;

  /// No description provided for @ranchHealthDetail.
  ///
  /// In zh, this message translates to:
  /// **'健康详情'**
  String get ranchHealthDetail;

  /// No description provided for @ranchHealthDetailLink.
  ///
  /// In zh, this message translates to:
  /// **'{type}详情'**
  String ranchHealthDetailLink(String type);

  /// No description provided for @ranchLivestockDetailBtn.
  ///
  /// In zh, this message translates to:
  /// **'详情'**
  String get ranchLivestockDetailBtn;

  /// No description provided for @ranchLivestockRelatedAlerts.
  ///
  /// In zh, this message translates to:
  /// **'相关告警'**
  String get ranchLivestockRelatedAlerts;

  /// No description provided for @tenantLicenseInvalidInteger.
  ///
  /// In zh, this message translates to:
  /// **'请输入非负整数'**
  String get tenantLicenseInvalidInteger;

  /// No description provided for @tenantLicenseBelowUsed.
  ///
  /// In zh, this message translates to:
  /// **'新配额不能小于当前已使用量（{used}）'**
  String tenantLicenseBelowUsed(String used);

  /// No description provided for @tenantDeleteReasonRequired.
  ///
  /// In zh, this message translates to:
  /// **'请输入删除原因'**
  String get tenantDeleteReasonRequired;

  /// No description provided for @deviceInstallTo.
  ///
  /// In zh, this message translates to:
  /// **'安装到牲畜'**
  String get deviceInstallTo;

  /// No description provided for @deviceActivate.
  ///
  /// In zh, this message translates to:
  /// **'激活'**
  String get deviceActivate;

  /// No description provided for @deviceActivateSuccess.
  ///
  /// In zh, this message translates to:
  /// **'激活成功：{name}'**
  String deviceActivateSuccess(String name);

  /// No description provided for @deviceActivateFailed.
  ///
  /// In zh, this message translates to:
  /// **'激活失败: {error}'**
  String deviceActivateFailed(String error);

  /// No description provided for @deviceUnbind.
  ///
  /// In zh, this message translates to:
  /// **'解绑'**
  String get deviceUnbind;

  /// No description provided for @deviceViewLocation.
  ///
  /// In zh, this message translates to:
  /// **'查看位置'**
  String get deviceViewLocation;

  /// No description provided for @offlineTileNoRegions.
  ///
  /// In zh, this message translates to:
  /// **'暂无可用离线地图'**
  String get offlineTileNoRegions;

  /// No description provided for @offlineTileGenerate.
  ///
  /// In zh, this message translates to:
  /// **'生成离线地图'**
  String get offlineTileGenerate;

  /// No description provided for @offlineTileGeneratingHint.
  ///
  /// In zh, this message translates to:
  /// **'已请求生成，预计数分钟后完成，请稍后重新进入本页查看'**
  String get offlineTileGeneratingHint;

  /// No description provided for @offlineTileRecheck.
  ///
  /// In zh, this message translates to:
  /// **'重新检测'**
  String get offlineTileRecheck;

  /// No description provided for @offlineTileRegionsAvailable.
  ///
  /// In zh, this message translates to:
  /// **'可用区域（{count}）'**
  String offlineTileRegionsAvailable(String count);

  /// No description provided for @workerNewWorker.
  ///
  /// In zh, this message translates to:
  /// **'新建牧工'**
  String get workerNewWorker;

  /// No description provided for @workerName.
  ///
  /// In zh, this message translates to:
  /// **'姓名'**
  String get workerName;

  /// No description provided for @workerInitPassword.
  ///
  /// In zh, this message translates to:
  /// **'初始密码'**
  String get workerInitPassword;

  /// No description provided for @workerCreateSuccess.
  ///
  /// In zh, this message translates to:
  /// **'牧工创建成功'**
  String get workerCreateSuccess;

  /// No description provided for @workerCreateFailed.
  ///
  /// In zh, this message translates to:
  /// **'创建失败: {error}'**
  String workerCreateFailed(String error);

  /// No description provided for @fenceConflictTitle.
  ///
  /// In zh, this message translates to:
  /// **'围栏冲突: {name}'**
  String fenceConflictTitle(String name);

  /// No description provided for @fenceConflictDiscardMine.
  ///
  /// In zh, this message translates to:
  /// **'放弃我的修改'**
  String get fenceConflictDiscardMine;

  /// No description provided for @fenceConflictOverwrite.
  ///
  /// In zh, this message translates to:
  /// **'覆盖服务端版本'**
  String get fenceConflictOverwrite;

  /// No description provided for @fenceConflictServerVersion.
  ///
  /// In zh, this message translates to:
  /// **'服务端版本 (v{version})'**
  String fenceConflictServerVersion(String version);

  /// No description provided for @fenceConflictLocalVersion.
  ///
  /// In zh, this message translates to:
  /// **'您的修改 (离线编辑)'**
  String get fenceConflictLocalVersion;

  /// No description provided for @offlineTileTitle.
  ///
  /// In zh, this message translates to:
  /// **'离线地图管理'**
  String get offlineTileTitle;

  /// No description provided for @offlineTileDownload.
  ///
  /// In zh, this message translates to:
  /// **'下载'**
  String get offlineTileDownload;

  /// No description provided for @offlineTileDownloading.
  ///
  /// In zh, this message translates to:
  /// **'正在下载 {region}...'**
  String offlineTileDownloading(String region);

  /// No description provided for @offlineTileDownloadFailed.
  ///
  /// In zh, this message translates to:
  /// **'下载失败：{error}'**
  String offlineTileDownloadFailed(String error);

  /// No description provided for @offlineTileDownloadSuccess.
  ///
  /// In zh, this message translates to:
  /// **'下载完成'**
  String get offlineTileDownloadSuccess;

  /// No description provided for @offlineTileDelete.
  ///
  /// In zh, this message translates to:
  /// **'删除'**
  String get offlineTileDelete;

  /// No description provided for @offlineTileDeleteConfirm.
  ///
  /// In zh, this message translates to:
  /// **'确定删除此离线地图？删除后需要重新下载才能离线使用。'**
  String get offlineTileDeleteConfirm;

  /// No description provided for @offlineTileStorageUsed.
  ///
  /// In zh, this message translates to:
  /// **'已用空间：{used}'**
  String offlineTileStorageUsed(String used);

  /// No description provided for @offlineTileDownloadedRegions.
  ///
  /// In zh, this message translates to:
  /// **'已下载（{count}）'**
  String offlineTileDownloadedRegions(String count);

  /// No description provided for @offlineTileCancel.
  ///
  /// In zh, this message translates to:
  /// **'取消'**
  String get offlineTileCancel;

  /// No description provided for @offlineTileRedownload.
  ///
  /// In zh, this message translates to:
  /// **'更新'**
  String get offlineTileRedownload;

  /// No description provided for @offlineTileNoDownloaded.
  ///
  /// In zh, this message translates to:
  /// **'尚未下载任何离线地图'**
  String get offlineTileNoDownloaded;

  /// No description provided for @workerAddWorker.
  ///
  /// In zh, this message translates to:
  /// **'添加牧工'**
  String get workerAddWorker;

  /// No description provided for @workerNoFarm.
  ///
  /// In zh, this message translates to:
  /// **'暂无可管理牧场'**
  String get workerNoFarm;

  /// No description provided for @workerNoFarmDesc.
  ///
  /// In zh, this message translates to:
  /// **'当前账号尚未选择牧场。'**
  String get workerNoFarmDesc;

  /// No description provided for @workerNoWorkers.
  ///
  /// In zh, this message translates to:
  /// **'暂无牧工'**
  String get workerNoWorkers;

  /// No description provided for @workerNoWorkersDesc.
  ///
  /// In zh, this message translates to:
  /// **'点击右上角添加牧工'**
  String get workerNoWorkersDesc;

  /// No description provided for @workerLoadFailed.
  ///
  /// In zh, this message translates to:
  /// **'牧工加载失败'**
  String get workerLoadFailed;

  /// No description provided for @workerNameRequired.
  ///
  /// In zh, this message translates to:
  /// **'姓名不能为空'**
  String get workerNameRequired;

  /// No description provided for @workerPhoneRequired.
  ///
  /// In zh, this message translates to:
  /// **'手机号不能为空'**
  String get workerPhoneRequired;

  /// No description provided for @workerPasswordMinLength.
  ///
  /// In zh, this message translates to:
  /// **'密码至少3位'**
  String get workerPasswordMinLength;

  /// No description provided for @auditLogTitle.
  ///
  /// In zh, this message translates to:
  /// **'审计日志'**
  String get auditLogTitle;

  /// No description provided for @auditLogOperationType.
  ///
  /// In zh, this message translates to:
  /// **'操作类型'**
  String get auditLogOperationType;

  /// No description provided for @auditLogQuery.
  ///
  /// In zh, this message translates to:
  /// **'查询'**
  String get auditLogQuery;

  /// No description provided for @auditLogNoData.
  ///
  /// In zh, this message translates to:
  /// **'暂无审计日志'**
  String get auditLogNoData;

  /// No description provided for @auditLogTotalCount.
  ///
  /// In zh, this message translates to:
  /// **'共 {count} 条'**
  String auditLogTotalCount(String count);

  /// No description provided for @tileAdminTitle.
  ///
  /// In zh, this message translates to:
  /// **'瓦片管理'**
  String get tileAdminTitle;

  /// No description provided for @tileAdminNoRegions.
  ///
  /// In zh, this message translates to:
  /// **'暂无瓦片区域'**
  String get tileAdminNoRegions;

  /// No description provided for @tileAdminNoTasks.
  ///
  /// In zh, this message translates to:
  /// **'暂无瓦片任务'**
  String get tileAdminNoTasks;

  /// No description provided for @tileAdminNoFarmTiles.
  ///
  /// In zh, this message translates to:
  /// **'暂无牧场瓦片分配'**
  String get tileAdminNoFarmTiles;

  /// No description provided for @tileAdminStatusInfo.
  ///
  /// In zh, this message translates to:
  /// **'状态: {status} | 瓦片: {tiles} | {size}MB'**
  String tileAdminStatusInfo(String status, String tiles, String size);

  /// No description provided for @tileAdminRegionInfo.
  ///
  /// In zh, this message translates to:
  /// **'区域: {region} | 状态: {status}'**
  String tileAdminRegionInfo(String region, String status);

  /// No description provided for @featureGateTitle.
  ///
  /// In zh, this message translates to:
  /// **'功能门控管理'**
  String get featureGateTitle;

  /// No description provided for @featureGateNoData.
  ///
  /// In zh, this message translates to:
  /// **'该等级暂无功能门控'**
  String get featureGateNoData;

  /// No description provided for @featureGateLimit.
  ///
  /// In zh, this message translates to:
  /// **'限额'**
  String get featureGateLimit;

  /// No description provided for @featureGateRetentionDays.
  ///
  /// In zh, this message translates to:
  /// **'保留天数'**
  String get featureGateRetentionDays;

  /// No description provided for @featureGateUpdated.
  ///
  /// In zh, this message translates to:
  /// **'{key} 已更新'**
  String featureGateUpdated(String key);

  /// No description provided for @analyticsTitle.
  ///
  /// In zh, this message translates to:
  /// **'用量分析'**
  String get analyticsTitle;

  /// No description provided for @analyticsSelectRange.
  ///
  /// In zh, this message translates to:
  /// **'选择范围'**
  String get analyticsSelectRange;

  /// No description provided for @checkoutTitle.
  ///
  /// In zh, this message translates to:
  /// **'确认支付'**
  String get checkoutTitle;

  /// No description provided for @checkoutLivestockCount.
  ///
  /// In zh, this message translates to:
  /// **'请输入牲畜数量'**
  String get checkoutLivestockCount;

  /// No description provided for @checkoutHeadUnit.
  ///
  /// In zh, this message translates to:
  /// **'头'**
  String get checkoutHeadUnit;

  /// No description provided for @planTitle.
  ///
  /// In zh, this message translates to:
  /// **'选择套餐'**
  String get planTitle;

  /// No description provided for @farmCreationLatLabel.
  ///
  /// In zh, this message translates to:
  /// **'纬度 (WGS-84)'**
  String get farmCreationLatLabel;

  /// No description provided for @farmCreationLatHint.
  ///
  /// In zh, this message translates to:
  /// **'选区域后自动填充'**
  String get farmCreationLatHint;

  /// No description provided for @farmCreationLngLabel.
  ///
  /// In zh, this message translates to:
  /// **'经度 (WGS-84)'**
  String get farmCreationLngLabel;

  /// No description provided for @farmCreationLngHint.
  ///
  /// In zh, this message translates to:
  /// **'选区域后自动填充'**
  String get farmCreationLngHint;

  /// No description provided for @farmCreationNameLabel.
  ///
  /// In zh, this message translates to:
  /// **'牧场名称 *'**
  String get farmCreationNameLabel;

  /// No description provided for @farmCreationNameHint.
  ///
  /// In zh, this message translates to:
  /// **'请输入牧场名称'**
  String get farmCreationNameHint;

  /// No description provided for @farmCreationOwnerLabel.
  ///
  /// In zh, this message translates to:
  /// **'负责人'**
  String get farmCreationOwnerLabel;

  /// No description provided for @farmCreationOwnerHint.
  ///
  /// In zh, this message translates to:
  /// **'选择 owner（可选）'**
  String get farmCreationOwnerHint;

  /// No description provided for @farmCreationAreaLabel.
  ///
  /// In zh, this message translates to:
  /// **'面积（公顷）'**
  String get farmCreationAreaLabel;

  /// No description provided for @farmCreationAreaHint.
  ///
  /// In zh, this message translates to:
  /// **'选填'**
  String get farmCreationAreaHint;

  /// No description provided for @farmCreationTileLabel.
  ///
  /// In zh, this message translates to:
  /// **'瓦片区域'**
  String get farmCreationTileLabel;

  /// No description provided for @farmCreationTileHint.
  ///
  /// In zh, this message translates to:
  /// **'选择离线瓦片区域'**
  String get farmCreationTileHint;

  /// No description provided for @alertSummaryTitle.
  ///
  /// In zh, this message translates to:
  /// **'告警摘要'**
  String get alertSummaryTitle;

  /// No description provided for @alertSummaryCount.
  ///
  /// In zh, this message translates to:
  /// **'共 {count} 条'**
  String alertSummaryCount(String count);

  /// No description provided for @commonNoData.
  ///
  /// In zh, this message translates to:
  /// **'暂无数据'**
  String get commonNoData;

  /// No description provided for @tileAdminRegionsTab.
  ///
  /// In zh, this message translates to:
  /// **'区域管理'**
  String get tileAdminRegionsTab;

  /// No description provided for @tileAdminTasksTab.
  ///
  /// In zh, this message translates to:
  /// **'任务管理'**
  String get tileAdminTasksTab;

  /// No description provided for @tileAdminFarmTab.
  ///
  /// In zh, this message translates to:
  /// **'牧场分配'**
  String get tileAdminFarmTab;

  /// No description provided for @tileAdminCreateTask.
  ///
  /// In zh, this message translates to:
  /// **'新建瓦片任务'**
  String get tileAdminCreateTask;

  /// No description provided for @tileAdminReload.
  ///
  /// In zh, this message translates to:
  /// **'重新加载'**
  String get tileAdminReload;

  /// No description provided for @tileAdminRegionNameLabel.
  ///
  /// In zh, this message translates to:
  /// **'区域名称'**
  String get tileAdminRegionNameLabel;

  /// No description provided for @tileAdminBoundsHint.
  ///
  /// In zh, this message translates to:
  /// **'范围：最小经度, 最小纬度, 最大经度, 最大纬度'**
  String get tileAdminBoundsHint;

  /// No description provided for @tileAdminMinZoomLabel.
  ///
  /// In zh, this message translates to:
  /// **'最小层级'**
  String get tileAdminMinZoomLabel;

  /// No description provided for @tileAdminMaxZoomLabel.
  ///
  /// In zh, this message translates to:
  /// **'最大层级'**
  String get tileAdminMaxZoomLabel;

  /// No description provided for @tileAdminCreateSuccess.
  ///
  /// In zh, this message translates to:
  /// **'任务已创建，后台 worker 将自动生成瓦片'**
  String get tileAdminCreateSuccess;

  /// No description provided for @tileAdminCreateFailed.
  ///
  /// In zh, this message translates to:
  /// **'创建失败'**
  String get tileAdminCreateFailed;

  /// No description provided for @tileAdminTaskPending.
  ///
  /// In zh, this message translates to:
  /// **'等待 worker 处理'**
  String get tileAdminTaskPending;

  /// No description provided for @tileAdminTilesUnit.
  ///
  /// In zh, this message translates to:
  /// **'瓦片'**
  String get tileAdminTilesUnit;

  /// No description provided for @tileAdminErrorPrefix.
  ///
  /// In zh, this message translates to:
  /// **'错误：'**
  String get tileAdminErrorPrefix;

  /// No description provided for @tileAdminRunningFor.
  ///
  /// In zh, this message translates to:
  /// **'已运行 {duration}'**
  String tileAdminRunningFor(String duration);

  /// No description provided for @tileAdminDuration.
  ///
  /// In zh, this message translates to:
  /// **'用时 {duration}'**
  String tileAdminDuration(String duration);

  /// No description provided for @b2bFarmListTitle.
  ///
  /// In zh, this message translates to:
  /// **'旗下牧场'**
  String get b2bFarmListTitle;

  /// No description provided for @b2bFarmListOptional.
  ///
  /// In zh, this message translates to:
  /// **'以下选填'**
  String get b2bFarmListOptional;

  /// No description provided for @b2bFarmEditName.
  ///
  /// In zh, this message translates to:
  /// **'编辑牧场名称'**
  String get b2bFarmEditName;

  /// No description provided for @b2bFarmNotAssigned.
  ///
  /// In zh, this message translates to:
  /// **'未指定'**
  String get b2bFarmNotAssigned;

  /// No description provided for @b2bFarmCurrentOwner.
  ///
  /// In zh, this message translates to:
  /// **'当前负责人: {name}'**
  String b2bFarmCurrentOwner(String name);

  /// No description provided for @b2bFarmNewOwner.
  ///
  /// In zh, this message translates to:
  /// **'新负责人'**
  String get b2bFarmNewOwner;

  /// No description provided for @b2bFarmConfirmChange.
  ///
  /// In zh, this message translates to:
  /// **'确认变更'**
  String get b2bFarmConfirmChange;

  /// No description provided for @b2bFarmChangeSuccess.
  ///
  /// In zh, this message translates to:
  /// **'「{farm}」负责人已变更为 {owner}'**
  String b2bFarmChangeSuccess(String farm, String owner);

  /// No description provided for @b2bFarmRenameDemo.
  ///
  /// In zh, this message translates to:
  /// **'「{name}」重命名功能开发中'**
  String b2bFarmRenameDemo(String name);

  /// No description provided for @b2bFarmStatDevice.
  ///
  /// In zh, this message translates to:
  /// **'设备'**
  String get b2bFarmStatDevice;

  /// No description provided for @b2bFarmStatRanch.
  ///
  /// In zh, this message translates to:
  /// **'牧场'**
  String get b2bFarmStatRanch;

  /// No description provided for @b2bWorkerEditFarmInfo.
  ///
  /// In zh, this message translates to:
  /// **'编辑牧场信息'**
  String get b2bWorkerEditFarmInfo;

  /// No description provided for @b2bWorkerFarmUpdated.
  ///
  /// In zh, this message translates to:
  /// **'牧场信息已更新'**
  String get b2bWorkerFarmUpdated;

  /// No description provided for @b2bWorkerAssign.
  ///
  /// In zh, this message translates to:
  /// **'分配'**
  String get b2bWorkerAssign;

  /// No description provided for @b2bWorkerAssignTitle.
  ///
  /// In zh, this message translates to:
  /// **'分配牧工'**
  String get b2bWorkerAssignTitle;

  /// No description provided for @b2bWorkerAssignNone.
  ///
  /// In zh, this message translates to:
  /// **'没有可分配的牧工，请先点击「添加牧工」创建'**
  String get b2bWorkerAssignNone;

  /// No description provided for @b2bWorkerAssignConfirm.
  ///
  /// In zh, this message translates to:
  /// **'确认分配 ({count})'**
  String b2bWorkerAssignConfirm(String count);

  /// No description provided for @b2bWorkerRemoveTitle.
  ///
  /// In zh, this message translates to:
  /// **'移除牧工'**
  String get b2bWorkerRemoveTitle;

  /// No description provided for @b2bWorkerRemoveConfirm.
  ///
  /// In zh, this message translates to:
  /// **'确定将「{name}」从「{farm}」移除？'**
  String b2bWorkerRemoveConfirm(String name, String farm);

  /// No description provided for @b2bWorkerConfirm.
  ///
  /// In zh, this message translates to:
  /// **'确认'**
  String get b2bWorkerConfirm;

  /// No description provided for @b2bWorkerCreated.
  ///
  /// In zh, this message translates to:
  /// **'牧工「{name}」已创建并分配'**
  String b2bWorkerCreated(String name);

  /// No description provided for @b2bWorkerUpdated.
  ///
  /// In zh, this message translates to:
  /// **'牧工信息已更新'**
  String get b2bWorkerUpdated;

  /// No description provided for @b2bWorkerResetPwd.
  ///
  /// In zh, this message translates to:
  /// **'重置密码'**
  String get b2bWorkerResetPwd;

  /// No description provided for @b2bWorkerResetPwdTitle.
  ///
  /// In zh, this message translates to:
  /// **'重置「{name}」密码'**
  String b2bWorkerResetPwdTitle(String name);

  /// No description provided for @b2bWorkerNewPassword.
  ///
  /// In zh, this message translates to:
  /// **'新密码'**
  String get b2bWorkerNewPassword;

  /// No description provided for @b2bWorkerConfirmReset.
  ///
  /// In zh, this message translates to:
  /// **'确认重置'**
  String get b2bWorkerConfirmReset;

  /// No description provided for @b2bWorkerPwdReset.
  ///
  /// In zh, this message translates to:
  /// **'密码已重置'**
  String get b2bWorkerPwdReset;

  /// No description provided for @subComparisonTitle.
  ///
  /// In zh, this message translates to:
  /// **'功能对比'**
  String get subComparisonTitle;

  /// No description provided for @cmpFeatureFence.
  ///
  /// In zh, this message translates to:
  /// **'电子围栏'**
  String get cmpFeatureFence;

  /// No description provided for @cmpFeatureTempMonitor.
  ///
  /// In zh, this message translates to:
  /// **'瘤胃温度监测'**
  String get cmpFeatureTempMonitor;

  /// No description provided for @cmpFeaturePeristalticMonitor.
  ///
  /// In zh, this message translates to:
  /// **'瘤胃蠕动监测'**
  String get cmpFeaturePeristalticMonitor;

  /// No description provided for @cmpFeatureStats.
  ///
  /// In zh, this message translates to:
  /// **'数据统计'**
  String get cmpFeatureStats;

  /// No description provided for @cmpFeatureDashboard.
  ///
  /// In zh, this message translates to:
  /// **'看板概览'**
  String get cmpFeatureDashboard;

  /// No description provided for @cmpFeatureDataRetention.
  ///
  /// In zh, this message translates to:
  /// **'数据保留'**
  String get cmpFeatureDataRetention;

  /// No description provided for @cmpFeatureAlertHistory.
  ///
  /// In zh, this message translates to:
  /// **'告警历史'**
  String get cmpFeatureAlertHistory;

  /// No description provided for @cmpFeatureLivestockDetail.
  ///
  /// In zh, this message translates to:
  /// **'牲畜详情'**
  String get cmpFeatureLivestockDetail;

  /// No description provided for @cmpFeatureProfile.
  ///
  /// In zh, this message translates to:
  /// **'个人中心'**
  String get cmpFeatureProfile;

  /// No description provided for @cmpFeatureTenantAdmin.
  ///
  /// In zh, this message translates to:
  /// **'租户管理'**
  String get cmpFeatureTenantAdmin;

  /// No description provided for @cmpCellYears.
  ///
  /// In zh, this message translates to:
  /// **'{count}年'**
  String cmpCellYears(String count);

  /// No description provided for @cmpCellDays.
  ///
  /// In zh, this message translates to:
  /// **'{count}天'**
  String cmpCellDays(String count);

  /// No description provided for @cmpCellLifetime.
  ///
  /// In zh, this message translates to:
  /// **'永久'**
  String get cmpCellLifetime;

  /// No description provided for @cmpCellItems.
  ///
  /// In zh, this message translates to:
  /// **'{count}项'**
  String cmpCellItems(String count);

  /// No description provided for @fenceEditExit.
  ///
  /// In zh, this message translates to:
  /// **'退出编辑'**
  String get fenceEditExit;

  /// No description provided for @fenceEditToolMoveVertex.
  ///
  /// In zh, this message translates to:
  /// **'拖点'**
  String get fenceEditToolMoveVertex;

  /// No description provided for @fenceEditToolInsertVertex.
  ///
  /// In zh, this message translates to:
  /// **'插点'**
  String get fenceEditToolInsertVertex;

  /// No description provided for @fenceEditToolDeleteVertex.
  ///
  /// In zh, this message translates to:
  /// **'删点'**
  String get fenceEditToolDeleteVertex;

  /// No description provided for @fenceEditToolTranslate.
  ///
  /// In zh, this message translates to:
  /// **'平移'**
  String get fenceEditToolTranslate;

  /// No description provided for @fenceEditTitle.
  ///
  /// In zh, this message translates to:
  /// **'编辑围栏：{name}'**
  String fenceEditTitle(String name);

  /// No description provided for @fenceEditUndo.
  ///
  /// In zh, this message translates to:
  /// **'撤销'**
  String get fenceEditUndo;

  /// No description provided for @fenceEditRedo.
  ///
  /// In zh, this message translates to:
  /// **'重做'**
  String get fenceEditRedo;

  /// No description provided for @fenceFormEditTitle.
  ///
  /// In zh, this message translates to:
  /// **'编辑围栏'**
  String get fenceFormEditTitle;

  /// No description provided for @fenceFormNewTitle.
  ///
  /// In zh, this message translates to:
  /// **'新建围栏'**
  String get fenceFormNewTitle;

  /// No description provided for @fenceFormName.
  ///
  /// In zh, this message translates to:
  /// **'围栏名称'**
  String get fenceFormName;

  /// No description provided for @fenceFormNameRequired.
  ///
  /// In zh, this message translates to:
  /// **'请输入围栏名称'**
  String get fenceFormNameRequired;

  /// No description provided for @fenceFormType.
  ///
  /// In zh, this message translates to:
  /// **'围栏类型'**
  String get fenceFormType;

  /// No description provided for @fenceFormArea.
  ///
  /// In zh, this message translates to:
  /// **'面积：{area} 公顷'**
  String fenceFormArea(String area);

  /// No description provided for @fenceFormFinishDraw.
  ///
  /// In zh, this message translates to:
  /// **'完成绘制（{count}个顶点）'**
  String fenceFormFinishDraw(String count);

  /// No description provided for @fenceFormDrawEnd.
  ///
  /// In zh, this message translates to:
  /// **'结束'**
  String get fenceFormDrawEnd;

  /// No description provided for @fenceFormDrawStart.
  ///
  /// In zh, this message translates to:
  /// **'开始绘制'**
  String get fenceFormDrawStart;

  /// No description provided for @fenceFormBannerDragHint.
  ///
  /// In zh, this message translates to:
  /// **'松开鼠标或手指完成绘制'**
  String get fenceFormBannerDragHint;

  /// No description provided for @fenceFormBannerStartHint.
  ///
  /// In zh, this message translates to:
  /// **'在地图上拖拽以画出范围'**
  String get fenceFormBannerStartHint;

  /// No description provided for @fenceFormBannerPolyContinue.
  ///
  /// In zh, this message translates to:
  /// **'可继续点击添加顶点，或点下方「完成绘制」结束'**
  String get fenceFormBannerPolyContinue;

  /// No description provided for @fenceFormBannerPolyStart.
  ///
  /// In zh, this message translates to:
  /// **'点击地图添加顶点（至少3个）'**
  String get fenceFormBannerPolyStart;

  /// No description provided for @fenceFormFooterHint.
  ///
  /// In zh, this message translates to:
  /// **'点击地图右上角「开始绘制」后在地图上设置范围，或用手动录入'**
  String get fenceFormFooterHint;

  /// No description provided for @fenceFormFooterDrag.
  ///
  /// In zh, this message translates to:
  /// **'绘制模式：地图不可拖动；拖拽画出范围后松手完成'**
  String get fenceFormFooterDrag;

  /// No description provided for @fenceFormFooterPoly.
  ///
  /// In zh, this message translates to:
  /// **'绘制模式：点击添加顶点；移动指针可预览连线（多边形）'**
  String get fenceFormFooterPoly;

  /// No description provided for @fenceFormManualRectHint.
  ///
  /// In zh, this message translates to:
  /// **'请输入2个对角顶点（纬度,经度）'**
  String get fenceFormManualRectHint;

  /// No description provided for @fenceFormManualCircleHint.
  ///
  /// In zh, this message translates to:
  /// **'请输入圆心和边界点（纬度,经度），共2行'**
  String get fenceFormManualCircleHint;

  /// No description provided for @fenceFormManualPolyHint.
  ///
  /// In zh, this message translates to:
  /// **'请输入各顶点坐标（至少3个），每行一个'**
  String get fenceFormManualPolyHint;

  /// No description provided for @fenceFormManualMinPoints.
  ///
  /// In zh, this message translates to:
  /// **'至少需要 {count} 个有效坐标点'**
  String fenceFormManualMinPoints(String count);

  /// No description provided for @fenceSelectFence.
  ///
  /// In zh, this message translates to:
  /// **'选择围栏'**
  String get fenceSelectFence;

  /// No description provided for @fenceHeadCount.
  ///
  /// In zh, this message translates to:
  /// **'{count}头'**
  String fenceHeadCount(String count);

  /// No description provided for @fenceTemplateTitle.
  ///
  /// In zh, this message translates to:
  /// **'围栏模板'**
  String get fenceTemplateTitle;

  /// No description provided for @fenceTemplateDesc.
  ///
  /// In zh, this message translates to:
  /// **'快速生成常用围栏形状，可继续手动调整'**
  String get fenceTemplateDesc;

  /// No description provided for @fenceTemplateRectangle.
  ///
  /// In zh, this message translates to:
  /// **'矩形区域'**
  String get fenceTemplateRectangle;

  /// No description provided for @fenceTemplateCircle.
  ///
  /// In zh, this message translates to:
  /// **'圆形区域'**
  String get fenceTemplateCircle;

  /// No description provided for @fenceTemplateTrajectoryBuffer.
  ///
  /// In zh, this message translates to:
  /// **'轨迹缓冲区'**
  String get fenceTemplateTrajectoryBuffer;

  /// No description provided for @fenceLoadFailed.
  ///
  /// In zh, this message translates to:
  /// **'围栏加载失败'**
  String get fenceLoadFailed;

  /// No description provided for @fenceBoundaryMinPoints.
  ///
  /// In zh, this message translates to:
  /// **'边界至少需要 3 个点'**
  String get fenceBoundaryMinPoints;

  /// No description provided for @fenceBoundaryNoDuplicates.
  ///
  /// In zh, this message translates to:
  /// **'边界不能有连续重复点'**
  String get fenceBoundaryNoDuplicates;

  /// No description provided for @fenceBoundaryAreaPositive.
  ///
  /// In zh, this message translates to:
  /// **'边界面积必须大于 0'**
  String get fenceBoundaryAreaPositive;

  /// No description provided for @fenceBoundaryNoSelfIntersect.
  ///
  /// In zh, this message translates to:
  /// **'边界不能自交'**
  String get fenceBoundaryNoSelfIntersect;

  /// No description provided for @fenceUnnamed.
  ///
  /// In zh, this message translates to:
  /// **'未命名'**
  String get fenceUnnamed;

  /// No description provided for @alertCenterTitle.
  ///
  /// In zh, this message translates to:
  /// **'告警中心'**
  String get alertCenterTitle;

  /// No description provided for @alertCenterDesc.
  ///
  /// In zh, this message translates to:
  /// **'聚焦围栏越界、设备低电、信号丢失三类 P0 告警。'**
  String get alertCenterDesc;

  /// No description provided for @alertChipFenceBreach.
  ///
  /// In zh, this message translates to:
  /// **'越界告警'**
  String get alertChipFenceBreach;

  /// No description provided for @alertChipBatteryLow.
  ///
  /// In zh, this message translates to:
  /// **'电池低电'**
  String get alertChipBatteryLow;

  /// No description provided for @alertChipSignalLost.
  ///
  /// In zh, this message translates to:
  /// **'信号丢失'**
  String get alertChipSignalLost;

  /// No description provided for @alertStageActive.
  ///
  /// In zh, this message translates to:
  /// **'活跃'**
  String get alertStageActive;

  /// No description provided for @alertStageDismissed.
  ///
  /// In zh, this message translates to:
  /// **'已忽略'**
  String get alertStageDismissed;

  /// No description provided for @alertStageAutoResolved.
  ///
  /// In zh, this message translates to:
  /// **'已自动解除'**
  String get alertStageAutoResolved;

  /// No description provided for @alertP0FenceBreachDetail.
  ///
  /// In zh, this message translates to:
  /// **'耳标-001 · 北区围栏 · 距边界 24m'**
  String get alertP0FenceBreachDetail;

  /// No description provided for @alertP0BatteryLowDetail.
  ///
  /// In zh, this message translates to:
  /// **'设备-045 · 电量 12% · 建议今日更换'**
  String get alertP0BatteryLowDetail;

  /// No description provided for @alertP0SignalLostDetail.
  ///
  /// In zh, this message translates to:
  /// **'耳标-023 · 失联 18 分钟 · 最后位置东坡'**
  String get alertP0SignalLostDetail;

  /// No description provided for @b2bTabKpi.
  ///
  /// In zh, this message translates to:
  /// **'KPI 看板'**
  String get b2bTabKpi;

  /// No description provided for @b2bTabAlertActivity.
  ///
  /// In zh, this message translates to:
  /// **'告警动态'**
  String get b2bTabAlertActivity;

  /// No description provided for @b2bStatSubFarms.
  ///
  /// In zh, this message translates to:
  /// **'旗下牧场'**
  String get b2bStatSubFarms;

  /// No description provided for @b2bStatLivestockTotal.
  ///
  /// In zh, this message translates to:
  /// **'牲畜总数'**
  String get b2bStatLivestockTotal;

  /// No description provided for @b2bStatWorkers.
  ///
  /// In zh, this message translates to:
  /// **'总牧工'**
  String get b2bStatWorkers;

  /// No description provided for @b2bStatDeviceOnlineRate.
  ///
  /// In zh, this message translates to:
  /// **'设备在线率'**
  String get b2bStatDeviceOnlineRate;

  /// No description provided for @b2bStatDeviceTotal.
  ///
  /// In zh, this message translates to:
  /// **'设备总数'**
  String get b2bStatDeviceTotal;

  /// No description provided for @b2bNavLinkDevices.
  ///
  /// In zh, this message translates to:
  /// **'设备'**
  String get b2bNavLinkDevices;

  /// No description provided for @b2bNavLinkContracts.
  ///
  /// In zh, this message translates to:
  /// **'合同'**
  String get b2bNavLinkContracts;

  /// No description provided for @b2bNavLinkRevenue.
  ///
  /// In zh, this message translates to:
  /// **'对账'**
  String get b2bNavLinkRevenue;

  /// No description provided for @b2bContractActive.
  ///
  /// In zh, this message translates to:
  /// **'合同有效'**
  String get b2bContractActive;

  /// No description provided for @b2bContractPendingRenew.
  ///
  /// In zh, this message translates to:
  /// **'合同待续'**
  String get b2bContractPendingRenew;

  /// No description provided for @b2bUnknownFarm.
  ///
  /// In zh, this message translates to:
  /// **'未知牧场'**
  String get b2bUnknownFarm;

  /// No description provided for @b2bAlertTypeDefault.
  ///
  /// In zh, this message translates to:
  /// **'告警'**
  String get b2bAlertTypeDefault;

  /// No description provided for @b2bAlertTypeFenceBreach.
  ///
  /// In zh, this message translates to:
  /// **'围栏越界'**
  String get b2bAlertTypeFenceBreach;

  /// No description provided for @b2bAlertTypeHealth.
  ///
  /// In zh, this message translates to:
  /// **'健康异常'**
  String get b2bAlertTypeHealth;

  /// No description provided for @b2bAlertTypeDeviceOffline.
  ///
  /// In zh, this message translates to:
  /// **'设备离线'**
  String get b2bAlertTypeDeviceOffline;

  /// No description provided for @b2bLivestockLabel.
  ///
  /// In zh, this message translates to:
  /// **'牲畜 #{id}'**
  String b2bLivestockLabel(String id);

  /// No description provided for @alertFilterPending.
  ///
  /// In zh, this message translates to:
  /// **'未处理'**
  String get alertFilterPending;

  /// No description provided for @alertFilterHandled.
  ///
  /// In zh, this message translates to:
  /// **'已处理'**
  String get alertFilterHandled;

  /// No description provided for @feverCurrentTemp.
  ///
  /// In zh, this message translates to:
  /// **'当前温度'**
  String get feverCurrentTemp;

  /// No description provided for @feverBaselineTemp.
  ///
  /// In zh, this message translates to:
  /// **'基线温度'**
  String get feverBaselineTemp;

  /// No description provided for @feverStatus.
  ///
  /// In zh, this message translates to:
  /// **'状态'**
  String get feverStatus;

  /// No description provided for @feverCapabilityNote.
  ///
  /// In zh, this message translates to:
  /// **'系统能通知你体温异常，需线下排查确认原因'**
  String get feverCapabilityNote;

  /// No description provided for @feverDurationChartTitle.
  ///
  /// In zh, this message translates to:
  /// **'发热持续时长分析'**
  String get feverDurationChartTitle;

  /// No description provided for @feverDurationChartSubtitle.
  ///
  /// In zh, this message translates to:
  /// **'每日超阈值(>39.5°C)持续小时数'**
  String get feverDurationChartSubtitle;

  /// No description provided for @digestiveHeatmapTitle.
  ///
  /// In zh, this message translates to:
  /// **'24h 蠕动强度热力图'**
  String get digestiveHeatmapTitle;

  /// No description provided for @digestiveHeatmapSubtitle.
  ///
  /// In zh, this message translates to:
  /// **'颜色越深 = 强度越低（异常区域高亮红色）'**
  String get digestiveHeatmapSubtitle;

  /// No description provided for @estrusLockedTitle.
  ///
  /// In zh, this message translates to:
  /// **'发情检测详情'**
  String get estrusLockedTitle;

  /// No description provided for @estrusCapabilityNote.
  ///
  /// In zh, this message translates to:
  /// **'系统能检测发情高分牲畜，建议人工确认'**
  String get estrusCapabilityNote;

  /// No description provided for @metricScore.
  ///
  /// In zh, this message translates to:
  /// **'评分'**
  String get metricScore;

  /// No description provided for @metricStepIncrease.
  ///
  /// In zh, this message translates to:
  /// **'步数增幅'**
  String get metricStepIncrease;

  /// No description provided for @metricTempDelta.
  ///
  /// In zh, this message translates to:
  /// **'温差'**
  String get metricTempDelta;

  /// No description provided for @epidemicContactTitle.
  ///
  /// In zh, this message translates to:
  /// **'疫情接触追踪'**
  String get epidemicContactTitle;

  /// No description provided for @epidemicContactLockedMsg.
  ///
  /// In zh, this message translates to:
  /// **'疫情接触追踪需要 Premium 及以上订阅'**
  String get epidemicContactLockedMsg;

  /// No description provided for @epidemicContactUpgrade.
  ///
  /// In zh, this message translates to:
  /// **'升级到 Premium'**
  String get epidemicContactUpgrade;

  /// No description provided for @epidemicNoContacts.
  ///
  /// In zh, this message translates to:
  /// **'暂无接触记录'**
  String get epidemicNoContacts;

  /// No description provided for @epidemicSourceInfected.
  ///
  /// In zh, this message translates to:
  /// **'已确认染病'**
  String get epidemicSourceInfected;

  /// No description provided for @epidemicNotMarked.
  ///
  /// In zh, this message translates to:
  /// **'未标记'**
  String get epidemicNotMarked;

  /// No description provided for @epidemicMarkedAt.
  ///
  /// In zh, this message translates to:
  /// **'标记时间'**
  String get epidemicMarkedAt;

  /// No description provided for @epidemicUnknown.
  ///
  /// In zh, this message translates to:
  /// **'未知'**
  String get epidemicUnknown;

  /// No description provided for @epidemicRiskFormula.
  ///
  /// In zh, this message translates to:
  /// **'风险评分 = 时间衰减(40%) + 接触距离(35%) + 持续时长(25%)。≥70高风险，40-69中风险，<40低风险。'**
  String get epidemicRiskFormula;

  /// No description provided for @epidemicNetworkGraph.
  ///
  /// In zh, this message translates to:
  /// **'接触链拓扑图'**
  String get epidemicNetworkGraph;

  /// No description provided for @riskHigh.
  ///
  /// In zh, this message translates to:
  /// **'高风险'**
  String get riskHigh;

  /// No description provided for @riskMedium.
  ///
  /// In zh, this message translates to:
  /// **'中风险'**
  String get riskMedium;

  /// No description provided for @riskLow.
  ///
  /// In zh, this message translates to:
  /// **'低风险'**
  String get riskLow;

  /// No description provided for @contactWindow24h.
  ///
  /// In zh, this message translates to:
  /// **'24小时内接触'**
  String get contactWindow24h;

  /// No description provided for @contactWindow48h.
  ///
  /// In zh, this message translates to:
  /// **'48小时内接触'**
  String get contactWindow48h;

  /// No description provided for @contactWindow72h.
  ///
  /// In zh, this message translates to:
  /// **'72小时内接触'**
  String get contactWindow72h;

  /// No description provided for @contactCountSuffix.
  ///
  /// In zh, this message translates to:
  /// **'头'**
  String get contactCountSuffix;

  /// No description provided for @contactScoreLabel.
  ///
  /// In zh, this message translates to:
  /// **'评分'**
  String get contactScoreLabel;

  /// No description provided for @contactDistance.
  ///
  /// In zh, this message translates to:
  /// **'距离'**
  String get contactDistance;

  /// No description provided for @contactDuration.
  ///
  /// In zh, this message translates to:
  /// **'持续'**
  String get contactDuration;

  /// No description provided for @contactFactorTime.
  ///
  /// In zh, this message translates to:
  /// **'时间'**
  String get contactFactorTime;

  /// No description provided for @contactFactorDistance.
  ///
  /// In zh, this message translates to:
  /// **'距离'**
  String get contactFactorDistance;

  /// No description provided for @contactFactorDuration.
  ///
  /// In zh, this message translates to:
  /// **'时长'**
  String get contactFactorDuration;

  /// No description provided for @epidemicContactNote.
  ///
  /// In zh, this message translates to:
  /// **'基于GPS轨迹时空交叉分析，自动识别72小时内与染病牲畜密切接触的个体并评估感染风险。'**
  String get epidemicContactNote;

  /// No description provided for @viewContactTracing.
  ///
  /// In zh, this message translates to:
  /// **'查看接触追踪详情'**
  String get viewContactTracing;

  /// No description provided for @livestockBreed.
  ///
  /// In zh, this message translates to:
  /// **'品种'**
  String get livestockBreed;

  /// No description provided for @livestockAgeMonthsLabel.
  ///
  /// In zh, this message translates to:
  /// **'月龄'**
  String get livestockAgeMonthsLabel;

  /// No description provided for @livestockAgeMonthsValue.
  ///
  /// In zh, this message translates to:
  /// **'{count} 个月'**
  String livestockAgeMonthsValue(int count);

  /// No description provided for @livestockWeight.
  ///
  /// In zh, this message translates to:
  /// **'体重'**
  String get livestockWeight;

  /// No description provided for @deviceBatteryValue.
  ///
  /// In zh, this message translates to:
  /// **'电量 {percent}%'**
  String deviceBatteryValue(int percent);

  /// No description provided for @deviceSignalValue.
  ///
  /// In zh, this message translates to:
  /// **'信号 {value}'**
  String deviceSignalValue(String value);

  /// No description provided for @livestockBodyTemp.
  ///
  /// In zh, this message translates to:
  /// **'体温'**
  String get livestockBodyTemp;

  /// No description provided for @livestockActivity.
  ///
  /// In zh, this message translates to:
  /// **'活动量'**
  String get livestockActivity;

  /// No description provided for @livestockRumination.
  ///
  /// In zh, this message translates to:
  /// **'反刍频率'**
  String get livestockRumination;

  /// No description provided for @livestockRuminationValue.
  ///
  /// In zh, this message translates to:
  /// **'{value} 次/分'**
  String livestockRuminationValue(String value);

  /// No description provided for @feverLoadFailed.
  ///
  /// In zh, this message translates to:
  /// **'体温数据加载失败'**
  String get feverLoadFailed;

  /// No description provided for @feverNoRecords.
  ///
  /// In zh, this message translates to:
  /// **'暂无体温记录'**
  String get feverNoRecords;

  /// No description provided for @feverLegendActual.
  ///
  /// In zh, this message translates to:
  /// **'实测体温'**
  String get feverLegendActual;

  /// No description provided for @feverLegendBaseline.
  ///
  /// In zh, this message translates to:
  /// **'基线参考'**
  String get feverLegendBaseline;

  /// No description provided for @estrusLoadFailed.
  ///
  /// In zh, this message translates to:
  /// **'发情数据加载失败'**
  String get estrusLoadFailed;

  /// No description provided for @estrusNoScores.
  ///
  /// In zh, this message translates to:
  /// **'暂无发情评分'**
  String get estrusNoScores;

  /// No description provided for @estrusLegendScore.
  ///
  /// In zh, this message translates to:
  /// **'发情评分'**
  String get estrusLegendScore;

  /// No description provided for @estrusLegendThreshold.
  ///
  /// In zh, this message translates to:
  /// **'配种阈值'**
  String get estrusLegendThreshold;

  /// No description provided for @livestockLastLocation.
  ///
  /// In zh, this message translates to:
  /// **'最近位置：{location}'**
  String livestockLastLocation(String location);

  /// No description provided for @aiAnomalyTitle.
  ///
  /// In zh, this message translates to:
  /// **'AI 异常检测'**
  String get aiAnomalyTitle;

  /// No description provided for @aiAnomalyScoreLabel.
  ///
  /// In zh, this message translates to:
  /// **'异常指数'**
  String get aiAnomalyScoreLabel;

  /// No description provided for @aiAnomalyTypeNormal.
  ///
  /// In zh, this message translates to:
  /// **'正常'**
  String get aiAnomalyTypeNormal;

  /// No description provided for @aiAnomalyTypeCircadian.
  ///
  /// In zh, this message translates to:
  /// **'节律紊乱'**
  String get aiAnomalyTypeCircadian;

  /// No description provided for @aiAnomalyTypeAbrupt.
  ///
  /// In zh, this message translates to:
  /// **'突变'**
  String get aiAnomalyTypeAbrupt;

  /// No description provided for @aiAnomalyTypeMultivariate.
  ///
  /// In zh, this message translates to:
  /// **'多维联合异常'**
  String get aiAnomalyTypeMultivariate;

  /// No description provided for @aiAnomalyNoData.
  ///
  /// In zh, this message translates to:
  /// **'暂无异常数据'**
  String get aiAnomalyNoData;

  /// No description provided for @aiAnomalyEffSamples.
  ///
  /// In zh, this message translates to:
  /// **'有效样本'**
  String get aiAnomalyEffSamples;

  /// No description provided for @aiAnomalyAssessedAt.
  ///
  /// In zh, this message translates to:
  /// **'评估方式'**
  String get aiAnomalyAssessedAt;

  /// No description provided for @aiAnomalyViewHistory.
  ///
  /// In zh, this message translates to:
  /// **'异常指数趋势'**
  String get aiAnomalyViewHistory;

  /// No description provided for @aiAnomalyAlertThreshold.
  ///
  /// In zh, this message translates to:
  /// **'告警阈值'**
  String get aiAnomalyAlertThreshold;

  /// No description provided for @aiAnomalyRuleAlerts.
  ///
  /// In zh, this message translates to:
  /// **'规则告警'**
  String get aiAnomalyRuleAlerts;

  /// No description provided for @aiAnomalyAiAlerts.
  ///
  /// In zh, this message translates to:
  /// **'AI 异常'**
  String get aiAnomalyAiAlerts;

  /// No description provided for @aiAnomalyOverview.
  ///
  /// In zh, this message translates to:
  /// **'AI 异常概览'**
  String get aiAnomalyOverview;

  /// No description provided for @aiAnomalyAvgScore.
  ///
  /// In zh, this message translates to:
  /// **'平均指数'**
  String get aiAnomalyAvgScore;

  /// No description provided for @aiAnomalyAnomalyCount.
  ///
  /// In zh, this message translates to:
  /// **'异常数量'**
  String get aiAnomalyAnomalyCount;

  /// No description provided for @livestockListTitle.
  ///
  /// In zh, this message translates to:
  /// **'牲畜管理'**
  String get livestockListTitle;

  /// No description provided for @livestockSearchResult.
  ///
  /// In zh, this message translates to:
  /// **'搜索结果：{total} 条'**
  String livestockSearchResult(Object total);

  /// No description provided for @livestockShowAll.
  ///
  /// In zh, this message translates to:
  /// **'查看全部'**
  String get livestockShowAll;

  /// No description provided for @livestockSearchHint.
  ///
  /// In zh, this message translates to:
  /// **'搜索编号或品种'**
  String get livestockSearchHint;

  /// No description provided for @livestockPaginationInfo.
  ///
  /// In zh, this message translates to:
  /// **'第 {currentPage} / {totalPages} 页，共 {total} 条'**
  String livestockPaginationInfo(
    Object currentPage,
    Object totalPages,
    Object total,
  );

  /// No description provided for @livestockAddNew.
  ///
  /// In zh, this message translates to:
  /// **'新增牲畜'**
  String get livestockAddNew;

  /// No description provided for @livestockEdit.
  ///
  /// In zh, this message translates to:
  /// **'编辑牲畜'**
  String get livestockEdit;

  /// No description provided for @livestockFormFieldCode.
  ///
  /// In zh, this message translates to:
  /// **'编号'**
  String get livestockFormFieldCode;

  /// No description provided for @livestockFormFieldBreed.
  ///
  /// In zh, this message translates to:
  /// **'品种'**
  String get livestockFormFieldBreed;

  /// No description provided for @livestockFormFieldGender.
  ///
  /// In zh, this message translates to:
  /// **'性别'**
  String get livestockFormFieldGender;

  /// No description provided for @livestockFormFieldBirthDate.
  ///
  /// In zh, this message translates to:
  /// **'出生日期'**
  String get livestockFormFieldBirthDate;

  /// No description provided for @livestockFormFieldWeight.
  ///
  /// In zh, this message translates to:
  /// **'体重'**
  String get livestockFormFieldWeight;

  /// No description provided for @livestockCreateSuccess.
  ///
  /// In zh, this message translates to:
  /// **'牲畜创建成功'**
  String get livestockCreateSuccess;

  /// No description provided for @livestockUpdateSuccess.
  ///
  /// In zh, this message translates to:
  /// **'牲畜更新成功'**
  String get livestockUpdateSuccess;

  /// No description provided for @livestockBreedAngus.
  ///
  /// In zh, this message translates to:
  /// **'安格斯'**
  String get livestockBreedAngus;

  /// No description provided for @livestockBreedWagyu.
  ///
  /// In zh, this message translates to:
  /// **'和牛'**
  String get livestockBreedWagyu;

  /// No description provided for @livestockBreedSimmental.
  ///
  /// In zh, this message translates to:
  /// **'西门塔尔'**
  String get livestockBreedSimmental;

  /// No description provided for @livestockBreedLimousin.
  ///
  /// In zh, this message translates to:
  /// **'利木赞'**
  String get livestockBreedLimousin;

  /// No description provided for @livestockBreedOther.
  ///
  /// In zh, this message translates to:
  /// **'其他'**
  String get livestockBreedOther;

  /// No description provided for @livestockGenderMale.
  ///
  /// In zh, this message translates to:
  /// **'公'**
  String get livestockGenderMale;

  /// No description provided for @livestockGenderFemale.
  ///
  /// In zh, this message translates to:
  /// **'母'**
  String get livestockGenderFemale;

  /// No description provided for @deviceRegisterTitle.
  ///
  /// In zh, this message translates to:
  /// **'注册设备'**
  String get deviceRegisterTitle;

  /// No description provided for @deviceEditTitle.
  ///
  /// In zh, this message translates to:
  /// **'编辑设备'**
  String get deviceEditTitle;

  /// No description provided for @deviceFormFieldCode.
  ///
  /// In zh, this message translates to:
  /// **'设备编号'**
  String get deviceFormFieldCode;

  /// No description provided for @deviceFormFieldDevEui.
  ///
  /// In zh, this message translates to:
  /// **'LoRa EUI（选填）'**
  String get deviceFormFieldDevEui;

  /// No description provided for @deviceRegisterSuccess.
  ///
  /// In zh, this message translates to:
  /// **'设备注册成功'**
  String get deviceRegisterSuccess;

  /// No description provided for @deviceUpdateSuccess.
  ///
  /// In zh, this message translates to:
  /// **'设备更新成功'**
  String get deviceUpdateSuccess;

  /// No description provided for @installBindDevice.
  ///
  /// In zh, this message translates to:
  /// **'绑定设备'**
  String get installBindDevice;

  /// No description provided for @installSelectDevice.
  ///
  /// In zh, this message translates to:
  /// **'选择设备'**
  String get installSelectDevice;

  /// No description provided for @installNoAvailableDevices.
  ///
  /// In zh, this message translates to:
  /// **'没有可用设备'**
  String get installNoAvailableDevices;

  /// No description provided for @installSuccess.
  ///
  /// In zh, this message translates to:
  /// **'安装成功'**
  String get installSuccess;

  /// No description provided for @livestockNoDeviceBound.
  ///
  /// In zh, this message translates to:
  /// **'未绑定设备'**
  String get livestockNoDeviceBound;

  /// No description provided for @livestockDeleteConfirmTitle.
  ///
  /// In zh, this message translates to:
  /// **'确认删除？'**
  String get livestockDeleteConfirmTitle;

  /// No description provided for @livestockDeleteConfirmMsg.
  ///
  /// In zh, this message translates to:
  /// **'删除后将无法恢复。'**
  String get livestockDeleteConfirmMsg;

  /// No description provided for @livestockDeleteDeviceUnbind.
  ///
  /// In zh, this message translates to:
  /// **'设备 {deviceName} 将自动解绑'**
  String livestockDeleteDeviceUnbind(String deviceName);

  /// No description provided for @livestockDeleteArchiveNote.
  ///
  /// In zh, this message translates to:
  /// **'历史健康数据和轨迹将归档保留'**
  String get livestockDeleteArchiveNote;

  /// No description provided for @livestockDeleted.
  ///
  /// In zh, this message translates to:
  /// **'已删除，设备已自动解绑'**
  String get livestockDeleted;

  /// No description provided for @livestockTrajectoryTitle.
  ///
  /// In zh, this message translates to:
  /// **'移动轨迹'**
  String get livestockTrajectoryTitle;

  /// No description provided for @livestockTrajectoryPoints.
  ///
  /// In zh, this message translates to:
  /// **'轨迹点数'**
  String get livestockTrajectoryPoints;

  /// No description provided for @livestockTrajectoryDistance.
  ///
  /// In zh, this message translates to:
  /// **'移动距离'**
  String get livestockTrajectoryDistance;

  /// No description provided for @livestockTrajectoryRange.
  ///
  /// In zh, this message translates to:
  /// **'活动范围'**
  String get livestockTrajectoryRange;

  /// No description provided for @livestockTrajectoryEmpty.
  ///
  /// In zh, this message translates to:
  /// **'暂无轨迹数据'**
  String get livestockTrajectoryEmpty;

  /// No description provided for @livestockTrajectoryNoGps.
  ///
  /// In zh, this message translates to:
  /// **'请先绑定 GPS 设备'**
  String get livestockTrajectoryNoGps;

  /// No description provided for @livestockTrajectoryCurrentTime.
  ///
  /// In zh, this message translates to:
  /// **'当前'**
  String get livestockTrajectoryCurrentTime;

  /// No description provided for @livestockTrajectoryRange24h.
  ///
  /// In zh, this message translates to:
  /// **'最近24小时'**
  String get livestockTrajectoryRange24h;

  /// No description provided for @livestockTrajectoryRange7d.
  ///
  /// In zh, this message translates to:
  /// **'最近7天'**
  String get livestockTrajectoryRange7d;

  /// No description provided for @livestockTrajectoryRange30d.
  ///
  /// In zh, this message translates to:
  /// **'最近30天'**
  String get livestockTrajectoryRange30d;

  /// No description provided for @livestockTrajectoryRangeCustom.
  ///
  /// In zh, this message translates to:
  /// **'自定义日期'**
  String get livestockTrajectoryRangeCustom;

  /// No description provided for @livestockTrajectoryFollow.
  ///
  /// In zh, this message translates to:
  /// **'跟随'**
  String get livestockTrajectoryFollow;

  /// No description provided for @livestockTrajectoryFitAll.
  ///
  /// In zh, this message translates to:
  /// **'全览'**
  String get livestockTrajectoryFitAll;

  /// No description provided for @livestockTrajectoryPointUnit.
  ///
  /// In zh, this message translates to:
  /// **'点'**
  String get livestockTrajectoryPointUnit;

  /// No description provided for @livestockTrajectoryAccuracy.
  ///
  /// In zh, this message translates to:
  /// **'精度'**
  String get livestockTrajectoryAccuracy;

  /// No description provided for @livestockTrajectoryLoading.
  ///
  /// In zh, this message translates to:
  /// **'加载轨迹数据…'**
  String get livestockTrajectoryLoading;

  /// No description provided for @livestockTrajectoryPlay.
  ///
  /// In zh, this message translates to:
  /// **'播放'**
  String get livestockTrajectoryPlay;

  /// No description provided for @livestockTrajectoryPause.
  ///
  /// In zh, this message translates to:
  /// **'暂停'**
  String get livestockTrajectoryPause;

  /// No description provided for @livestockFormFieldCodeRequired.
  ///
  /// In zh, this message translates to:
  /// **'编号不能为空'**
  String get livestockFormFieldCodeRequired;

  /// No description provided for @livestockEditSyncNote.
  ///
  /// In zh, this message translates to:
  /// **'编号修改后，该牲畜在告警、轨迹、健康报告中的显示将同步更新'**
  String get livestockEditSyncNote;

  /// No description provided for @livestockGenderValueMale.
  ///
  /// In zh, this message translates to:
  /// **'雄'**
  String get livestockGenderValueMale;

  /// No description provided for @livestockGenderValueFemale.
  ///
  /// In zh, this message translates to:
  /// **'雌'**
  String get livestockGenderValueFemale;

  /// No description provided for @gpsQualityTitle.
  ///
  /// In zh, this message translates to:
  /// **'GPS 质量检查'**
  String get gpsQualityTitle;

  /// No description provided for @gpsQualityTabRtkCalibration.
  ///
  /// In zh, this message translates to:
  /// **'RTK 标定管理'**
  String get gpsQualityTabRtkCalibration;

  /// No description provided for @gpsQualityTabQualityReport.
  ///
  /// In zh, this message translates to:
  /// **'质量报告'**
  String get gpsQualityTabQualityReport;

  /// No description provided for @gpsQualityRtkPointList.
  ///
  /// In zh, this message translates to:
  /// **'RTK 真值点'**
  String get gpsQualityRtkPointList;

  /// No description provided for @gpsQualitySessionList.
  ///
  /// In zh, this message translates to:
  /// **'标定会话'**
  String get gpsQualitySessionList;

  /// No description provided for @gpsQualityAddRtkPoint.
  ///
  /// In zh, this message translates to:
  /// **'新增点位'**
  String get gpsQualityAddRtkPoint;

  /// No description provided for @gpsQualityAddSession.
  ///
  /// In zh, this message translates to:
  /// **'创建标定会话'**
  String get gpsQualityAddSession;

  /// No description provided for @gpsQualityLocationName.
  ///
  /// In zh, this message translates to:
  /// **'位置'**
  String get gpsQualityLocationName;

  /// No description provided for @gpsQualityPointLabel.
  ///
  /// In zh, this message translates to:
  /// **'点位编号'**
  String get gpsQualityPointLabel;

  /// No description provided for @gpsQualityLatitude.
  ///
  /// In zh, this message translates to:
  /// **'纬度'**
  String get gpsQualityLatitude;

  /// No description provided for @gpsQualityLongitude.
  ///
  /// In zh, this message translates to:
  /// **'经度'**
  String get gpsQualityLongitude;

  /// No description provided for @gpsQualityDevice.
  ///
  /// In zh, this message translates to:
  /// **'设备'**
  String get gpsQualityDevice;

  /// No description provided for @gpsQualityStartTime.
  ///
  /// In zh, this message translates to:
  /// **'开始时间'**
  String get gpsQualityStartTime;

  /// No description provided for @gpsQualityEndTime.
  ///
  /// In zh, this message translates to:
  /// **'结束时间'**
  String get gpsQualityEndTime;

  /// No description provided for @gpsQualityStatus.
  ///
  /// In zh, this message translates to:
  /// **'状态'**
  String get gpsQualityStatus;

  /// No description provided for @gpsQualityStatusInProgress.
  ///
  /// In zh, this message translates to:
  /// **'进行中'**
  String get gpsQualityStatusInProgress;

  /// No description provided for @gpsQualityStatusCompleted.
  ///
  /// In zh, this message translates to:
  /// **'已完成'**
  String get gpsQualityStatusCompleted;

  /// No description provided for @gpsQualityStatusCanceled.
  ///
  /// In zh, this message translates to:
  /// **'已取消'**
  String get gpsQualityStatusCanceled;

  /// No description provided for @gpsQualityEndSession.
  ///
  /// In zh, this message translates to:
  /// **'结束'**
  String get gpsQualityEndSession;

  /// No description provided for @gpsQualityCancelSession.
  ///
  /// In zh, this message translates to:
  /// **'取消'**
  String get gpsQualityCancelSession;

  /// No description provided for @gpsQualityEndSessionConfirm.
  ///
  /// In zh, this message translates to:
  /// **'确认结束会话？结束后将自动计算统计结果。'**
  String get gpsQualityEndSessionConfirm;

  /// No description provided for @gpsQualitySelectRtkPoint.
  ///
  /// In zh, this message translates to:
  /// **'选择 RTK 点位'**
  String get gpsQualitySelectRtkPoint;

  /// No description provided for @gpsQualitySelectDevice.
  ///
  /// In zh, this message translates to:
  /// **'选择设备'**
  String get gpsQualitySelectDevice;

  /// No description provided for @gpsQualityReportTitle.
  ///
  /// In zh, this message translates to:
  /// **'质量报告'**
  String get gpsQualityReportTitle;

  /// No description provided for @gpsQualityComparisonTitle.
  ///
  /// In zh, this message translates to:
  /// **'多设备对比'**
  String get gpsQualityComparisonTitle;

  /// No description provided for @gpsQualityExcludeSuspect.
  ///
  /// In zh, this message translates to:
  /// **'排除疑似移动点'**
  String get gpsQualityExcludeSuspect;

  /// No description provided for @gpsQualityTotalPoints.
  ///
  /// In zh, this message translates to:
  /// **'总点数'**
  String get gpsQualityTotalPoints;

  /// No description provided for @gpsQualityEffectivePoints.
  ///
  /// In zh, this message translates to:
  /// **'有效点数'**
  String get gpsQualityEffectivePoints;

  /// No description provided for @gpsQualitySuspectPoints.
  ///
  /// In zh, this message translates to:
  /// **'疑似移动'**
  String get gpsQualitySuspectPoints;

  /// No description provided for @gpsQualityMeanError.
  ///
  /// In zh, this message translates to:
  /// **'平均偏差'**
  String get gpsQualityMeanError;

  /// No description provided for @gpsQualityP50.
  ///
  /// In zh, this message translates to:
  /// **'P50 中位偏差'**
  String get gpsQualityP50;

  /// No description provided for @gpsQualityP95.
  ///
  /// In zh, this message translates to:
  /// **'P95 抖动半径'**
  String get gpsQualityP95;

  /// No description provided for @gpsQualityP99.
  ///
  /// In zh, this message translates to:
  /// **'P99'**
  String get gpsQualityP99;

  /// No description provided for @gpsQualityMaxError.
  ///
  /// In zh, this message translates to:
  /// **'最大偏差'**
  String get gpsQualityMaxError;

  /// No description provided for @gpsQualityJitterDiameter.
  ///
  /// In zh, this message translates to:
  /// **'抖动直径'**
  String get gpsQualityJitterDiameter;

  /// No description provided for @gpsQualityOutlierCount.
  ///
  /// In zh, this message translates to:
  /// **'野点数'**
  String get gpsQualityOutlierCount;

  /// No description provided for @gpsQualityGradeExcellent.
  ///
  /// In zh, this message translates to:
  /// **'优秀'**
  String get gpsQualityGradeExcellent;

  /// No description provided for @gpsQualityGradeUsable.
  ///
  /// In zh, this message translates to:
  /// **'可用'**
  String get gpsQualityGradeUsable;

  /// No description provided for @gpsQualityGradeMarginal.
  ///
  /// In zh, this message translates to:
  /// **'勉强可用'**
  String get gpsQualityGradeMarginal;

  /// No description provided for @gpsQualityGradeUnavailable.
  ///
  /// In zh, this message translates to:
  /// **'不可用'**
  String get gpsQualityGradeUnavailable;

  /// No description provided for @gpsQualityGradeStandard.
  ///
  /// In zh, this message translates to:
  /// **'等级标准'**
  String get gpsQualityGradeStandard;

  /// No description provided for @gpsQualityGradeExcellentDesc.
  ///
  /// In zh, this message translates to:
  /// **'P95 ≤ 15m 且有效点 ≥ 20'**
  String get gpsQualityGradeExcellentDesc;

  /// No description provided for @gpsQualityGradeUsableDesc.
  ///
  /// In zh, this message translates to:
  /// **'P95 ≤ 25m 且有效点 ≥ 20'**
  String get gpsQualityGradeUsableDesc;

  /// No description provided for @gpsQualityGradeMarginalDesc.
  ///
  /// In zh, this message translates to:
  /// **'25m < P95 ≤ 40m 且有效点 ≥ 10'**
  String get gpsQualityGradeMarginalDesc;

  /// No description provided for @gpsQualityGradeUnavailableDesc.
  ///
  /// In zh, this message translates to:
  /// **'P95 > 40m 或有效点 < 10'**
  String get gpsQualityGradeUnavailableDesc;

  /// No description provided for @gpsQualityNoData.
  ///
  /// In zh, this message translates to:
  /// **'暂无数据'**
  String get gpsQualityNoData;

  /// No description provided for @gpsQualityViewTrajectory.
  ///
  /// In zh, this message translates to:
  /// **'查看完整移动轨迹'**
  String get gpsQualityViewTrajectory;

  /// No description provided for @gpsQualityScatterChart.
  ///
  /// In zh, this message translates to:
  /// **'静止 GPS 散点图'**
  String get gpsQualityScatterChart;

  /// No description provided for @gpsQualityErrorHistogram.
  ///
  /// In zh, this message translates to:
  /// **'偏差分布'**
  String get gpsQualityErrorHistogram;

  /// No description provided for @gpsQualityCalibrationLocations.
  ///
  /// In zh, this message translates to:
  /// **'标定位置'**
  String get gpsQualityCalibrationLocations;

  /// No description provided for @gpsQualityRtkCoordinate.
  ///
  /// In zh, this message translates to:
  /// **'RTK 坐标'**
  String get gpsQualityRtkCoordinate;

  /// No description provided for @gpsQualityTestTime.
  ///
  /// In zh, this message translates to:
  /// **'测试时间'**
  String get gpsQualityTestTime;

  /// No description provided for @gpsQualityActions.
  ///
  /// In zh, this message translates to:
  /// **'操作'**
  String get gpsQualityActions;

  /// No description provided for @gpsQualityPointsUnit.
  ///
  /// In zh, this message translates to:
  /// **'个点位'**
  String get gpsQualityPointsUnit;

  /// No description provided for @gpsQualityCalibrated.
  ///
  /// In zh, this message translates to:
  /// **'标定'**
  String get gpsQualityCalibrated;

  /// No description provided for @gpsQualityPointUnitShort.
  ///
  /// In zh, this message translates to:
  /// **'点'**
  String get gpsQualityPointUnitShort;

  /// No description provided for @gpsQualitySessionUnitShort.
  ///
  /// In zh, this message translates to:
  /// **'会话'**
  String get gpsQualitySessionUnitShort;

  /// No description provided for @gpsQualityUncalibratedPointsUnit.
  ///
  /// In zh, this message translates to:
  /// **'个未标定点位'**
  String get gpsQualityUncalibratedPointsUnit;

  /// No description provided for @gpsQualityUncalibrated.
  ///
  /// In zh, this message translates to:
  /// **'未标定'**
  String get gpsQualityUncalibrated;

  /// No description provided for @gpsQualityCalibrate.
  ///
  /// In zh, this message translates to:
  /// **'标定'**
  String get gpsQualityCalibrate;

  /// No description provided for @gpsQualityNoSessionHint.
  ///
  /// In zh, this message translates to:
  /// **'暂无标定会话，点击「+ 创建标定会话」开始'**
  String get gpsQualityNoSessionHint;

  /// No description provided for @gpsQualityDelete.
  ///
  /// In zh, this message translates to:
  /// **'删除'**
  String get gpsQualityDelete;

  /// No description provided for @gpsQualityTipP50.
  ///
  /// In zh, this message translates to:
  /// **'偏差排序后第50百分位\n= 中位数，反映典型精度'**
  String get gpsQualityTipP50;

  /// No description provided for @gpsQualityTipP95.
  ///
  /// In zh, this message translates to:
  /// **'偏差排序后第95百分位\n围栏 STANDARD 档基准'**
  String get gpsQualityTipP95;

  /// No description provided for @gpsQualityTipMeanError.
  ///
  /// In zh, this message translates to:
  /// **'所有点到真值距离的\n算术平均'**
  String get gpsQualityTipMeanError;

  /// No description provided for @gpsQualityTipMaxError.
  ///
  /// In zh, this message translates to:
  /// **'离 RTK 真值最远的点'**
  String get gpsQualityTipMaxError;

  /// No description provided for @gpsQualityTipJitterDiameter.
  ///
  /// In zh, this message translates to:
  /// **'所有点两两 haversine 距离\n的最大值'**
  String get gpsQualityTipJitterDiameter;

  /// No description provided for @gpsQualityTipOutlier.
  ///
  /// In zh, this message translates to:
  /// **'偏差超过 max(P99, 3×P95, 30m) 的点'**
  String get gpsQualityTipOutlier;

  /// No description provided for @gpsQualityTipTotalPoints.
  ///
  /// In zh, this message translates to:
  /// **'会话时间窗口内有效 GPS 点总数'**
  String get gpsQualityTipTotalPoints;

  /// No description provided for @gpsQualityTipEffectivePoints.
  ///
  /// In zh, this message translates to:
  /// **'排除疑似移动点后的有效点数'**
  String get gpsQualityTipEffectivePoints;

  /// No description provided for @gpsQualityTipSuspectPoints.
  ///
  /// In zh, this message translates to:
  /// **'step_number > 0 的点数'**
  String get gpsQualityTipSuspectPoints;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'zh'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'zh':
      return AppLocalizationsZh();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
