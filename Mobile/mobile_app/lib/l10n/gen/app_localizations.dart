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

  String get deviceTypeGps;
  String get deviceTypeRumenCapsule;
  String get deviceTypeAccelerometer;
  String get subscriptionTierBasic;
  String get subscriptionTierStandard;
  String get subscriptionTierPremium;
  String get subscriptionTierEnterprise;

  String get commonLoadFailed;
  String commonDeleteFailed(String error);
  String get commonConfirmDelete;
  String get commonConfirmLogout;
  String get commonConfirmLogoutMessage;
  String get ranchFenceList;
  String get ranchNewFence;
  String get ranchNoFence;
  String get ranchCollapseFenceList;
  String get ranchEditBoundary;
  String ranchFenceDeleted(String name);
  String ranchConfirmDeleteFence(String name);
  String get ranchFenceActive;
  String get ranchFenceInactive;
  String ranchLivestockCountHead(String count);

  String get dashboardNoData;
  String get dashboardTodayOverview;
  String get dashboardFarmOverview;
  String get dashboardNoFarm;
  String get dashboardCreateFirstFarmDesc;
  String get dashboardCreateFirstFarm;
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
