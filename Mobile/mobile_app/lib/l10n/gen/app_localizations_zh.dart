// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Chinese (`zh`).
class AppLocalizationsZh extends AppLocalizations {
  AppLocalizationsZh([String locale = 'zh']) : super(locale);

  @override
  String get commonConfirm => '确认';

  @override
  String get commonCancel => '取消';

  @override
  String get commonSave => '保存';

  @override
  String get commonDelete => '删除';

  @override
  String get commonEdit => '编辑';

  @override
  String get commonBack => '返回';

  @override
  String get commonLoading => '加载中...';

  @override
  String get commonRetry => '重试';

  @override
  String get commonError => '出错了';

  @override
  String get commonSuccess => '成功';

  @override
  String get commonSearch => '搜索';

  @override
  String get commonLogout => '退出登录';

  @override
  String get commonSubmit => '提交';

  @override
  String get commonClose => '关闭';

  @override
  String get commonAll => '全部';

  @override
  String get commonNone => '无';

  @override
  String get commonUnknown => '未知';

  @override
  String get settingsLanguage => '语言';

  @override
  String get settingsLanguageZh => '中文';

  @override
  String get settingsLanguageEn => 'English';

  @override
  String get settingsLanguageSystem => '跟随系统';

  @override
  String get settingsTitle => '设置';

  @override
  String get errorAuthFailed => '认证失败';

  @override
  String get errorServer => '服务器异常';

  @override
  String get errorTenantDisabled => '租户已禁用';

  @override
  String get errorLoginFailed => '登录失败';

  @override
  String get errorLoginCheckInput => '登录失败，请检查手机号和密码';

  @override
  String get navLogin => '登录';

  @override
  String get navRanch => '牧场';

  @override
  String get navTwin => '数智孪生';

  @override
  String get navAlerts => '告警';

  @override
  String get navMine => '我的';

  @override
  String get navFence => '围栏';

  @override
  String get navAdmin => '后台';

  @override
  String get navOverview => '概览';

  @override
  String get navFarmManagement => '牧场管理';

  @override
  String get navContractInfo => '合同信息';

  @override
  String get navRevenue => '对账';

  @override
  String get platformAdminTitle => '平台管理';

  @override
  String get farmEmptyGuidance => '暂无关联牧场，请联系管理员为您分配牧场。';

  @override
  String get authAppTitle => '智慧畜牧';

  @override
  String get authSubtitle => '智能畜牧管理平台';

  @override
  String get authPhoneLabel => '手机号';

  @override
  String get authPhoneHint => '请输入手机号';

  @override
  String get authPasswordLabel => '密码';

  @override
  String get authPasswordHint => '请输入密码';

  @override
  String get authLoginButton => '登录';

  @override
  String authLoginFailed(String error) {
    return '登录失败: $error';
  }

  @override
  String get deviceStatusOnline => '在线';

  @override
  String get deviceStatusOffline => '离线';

  @override
  String get deviceStatusLowBattery => '低电';

  @override
  String get livestockHealthHealthy => '健康';

  @override
  String get livestockHealthWatch => '关注';

  @override
  String get livestockHealthAbnormal => '异常';

  @override
  String get authLoginFormTitle => '账号登录';

  @override
  String get authOnlineMode => '在线模式';

  @override
  String get authPhoneInvalid => '请输入正确的11位手机号';

  @override
  String get authLoginDescription => '登录您的牧场账户，管理牲畜、围栏与告警。';

  @override
  String get deviceTypeGps => 'GPS定位器';

  @override
  String get deviceTypeRumenCapsule => '瘤胃胶囊';

  @override
  String get deviceTypeAccelerometer => '加速度计';

  @override
  String get subscriptionTierBasic => '基础版';

  @override
  String get subscriptionTierStandard => '标准版';

  @override
  String get subscriptionTierPremium => '高级版';

  @override
  String get subscriptionTierEnterprise => '企业版';
}
