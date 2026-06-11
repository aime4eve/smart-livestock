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

  @override
  String get commonLoadFailed => '加载失败';

  @override
  String commonDeleteFailed(String error) => '删除失败: $error';

  @override
  String get commonConfirmDelete => '确认删除';

  @override
  String get commonConfirmLogout => '确认退出';

  @override
  String get commonConfirmLogoutMessage => '确定要退出登录吗？';

  @override
  String get ranchFenceList => '围栏列表';

  @override
  String get ranchNewFence => '新建围栏';

  @override
  String get ranchNoFence => '暂无围栏';

  @override
  String get ranchCollapseFenceList => '收起围栏列表';

  @override
  String get ranchEditBoundary => '编辑边界';

  @override
  String ranchFenceDeleted(String name) => '已删除「$name」';

  @override
  String ranchConfirmDeleteFence(String name) => '确认删除「$name」？删除后无法恢复。';

  @override
  String get ranchFenceActive => '启用';

  @override
  String get ranchFenceInactive => '停用';

  @override
  String ranchLivestockCountHead(String count) => '$count头';

  @override
  String get dashboardNoData => '暂无看板数据';

  @override
  String get dashboardTodayOverview => '今日牧场概览';

  @override
  String get dashboardFarmOverview => '牧场概览';

  @override
  String get dashboardNoFarm => '您还没有牧场';

  @override
  String get dashboardCreateFirstFarmDesc => '创建您的第一个牧场，开始管理牲畜';

  @override
  String get dashboardCreateFirstFarm => '创建第一个牧场';

  @override
  String get twinRealtimeOverview => '牧场实时概览';

  @override
  String get twinHealthScenarios => '健康场景';

  @override
  String get twinPendingTasks => '待处理任务';

  @override
  String get mineAccountNormal => '账户正常';

  @override
  String get mineAccountDisabled => '账户已停用';

  @override
  String mineProfileName(String name) => '姓名：$name';

  @override
  String mineProfilePhone(String phone) => '手机号：$phone';

  @override
  String mineProfileRole(String role) => '角色：$role';

  @override
  String get minePersonalDevices => '个人设备与工具';

  @override
  String get mineDeviceManagementDesc => '查看和管理绑定的 IoT 设备';

  @override
  String get mineOfflineMapDesc => '下载和管理离线瓦片数据';

  @override
  String get mineHelpSupportDesc => '查看设备绑定、帮助文档与联系客服入口';

  @override
  String get mineHelpSupportComingSoon => '帮助与支持页面开发中...';

  @override
  String get mineBusinessManagement => '业务管理';

  @override
  String get mineSubscriptionManagementDesc => '查看和升级订阅套餐';

  @override
  String get mineRevenueBoardDesc => '查看各周期分润对账数据';

  @override
  String get mineSubscriptionServiceDesc => '管理订阅套餐和业务服务';

  @override
  String get mineAdvancedManagement => '高级管理';

  @override
  String get mineWorkerManagementDesc => '查看和移除当前牧场牧工';

  @override
  String get mineApiAuthManagementDesc => '管理 API Key 和第三方访问授权';

  @override
  String get mineDevicesTitle => '设备管理';

  @override
  String get mineOfflineMapTitle => '离线地图管理';

  @override
  String get mineHelpSupportTitle => '帮助与支持';

  @override
  String get mineSubscriptionTitle => '订阅管理';

  @override
  String get mineRevenueBoardTitle => '对账看板';

  @override
  String get mineSubscriptionServiceTitle => '订阅服务管理';

  @override
  String get mineWorkerTitle => '牧工管理';

  @override
  String get mineApiAuthTitle => 'API授权管理';

  @override
  String get commonLogoutButton => '退出';

  @override
  String get statsAnalysis => '统计分析';

  @override
  String get statsTemperatureTrend => '体温趋势 (7日)';

  @override
  String get statsHealthRateTrend => '健康率趋势 (7日)';

  @override
  String get statsAlertTrend => '告警趋势 (7日)';

  @override
  String get statsLivestock => '牲畜';

  @override
  String get statsHealthRate => '健康率';

  @override
  String get statsAlerts => '告警';

  @override
  String get statsCritical => '严重';

  @override
  String get statsAvgTemp => '均温';

  @override
  String get statsMotility => '蠕动';

  @override
  String get statsHealthDistribution => '健康分布';

  @override
  String get fencePleaseSelectFarm => '请先选择一个牧场';

  @override
  String get alertsNoAlerts => '暂无告警';

  @override
  String get alertsNoAlertsDesc => '当前没有触发中的 P0 告警。';

  @override
  String get alertsConfirm => '确认';

  @override
  String get alertsHandle => '处理';

  @override
  String get alertsArchive => '归档';

  @override
  String get alertsBatchHandle => '批量处理';

  @override
  String get alertsBatchDemo => '演示：批量处理待接入';

  @override
  String get livestockDetailTitle => '牲畜详情';

  @override
  String get livestockBindDevices => '绑定设备';

  @override
  String get livestockHealthData => '健康数据';

  @override
  String get livestockLocation => '位置信息';

  @override
  String get livestockViewTrajectory => '查看完整轨迹';

  @override
  String get feverWarningTitle => '发热预警';

  @override
  String get feverNoData => '暂无体温异常数据';

  @override
  String get digestiveTitle => '消化管理';

  @override
  String get digestiveNoData => '暂无消化异常数据';

  @override
  String digestiveItemSubtitle(String breed, String frequency, String dropPercent) =>
      '$breed  蠕动 $frequency次/分  ↓$dropPercent%';

  @override
  String get estrusTitle => '发情识别';

  @override
  String get estrusNoData => '暂无发情数据';

  @override
  String estrusItemSubtitle(String breed, String genderIcon, String stepInfo) =>
      '$breed $genderIcon $stepInfo';

  @override
  String get epidemicTitle => '疫病防控';

  @override
  String get epidemicHerdHealth => '群体健康指标';

  @override
  String get epidemicContactTracing => '接触追踪';

  @override
  String epidemicRiskLevel(String level) => '风险等级: $level';

  @override
  String get epidemicAvgTemperature => '平均体温';

  @override
  String get epidemicAbnormalRate => '异常率';

  @override
  String get epidemicAbnormalCount => '异常数';

  @override
  String get feverDetailTitle => '体温详情';

  @override
  String get feverDetailChartTitle => '72小时温度曲线';

  @override
  String get digestiveDetailTitle => '消化详情';

  @override
  String get digestiveDetailChartTitle => '24小时蠕动曲线';

  @override
  String get estrusDetailTitle => '发情详情';

  @override
  String get estrusDetailChartTitle => '7天评分趋势';

  @override
  String get devicesManagement => '设备管理';

  @override
  String get devicesAddDemo => '演示：添加新设备待接入';

  @override
  String get devicesNoDevices => '暂无设备';

  @override
  String devicesUnbindDemo(String name) => '演示：解绑 $name';

  @override
  String devicesViewLocationDemo(String name) => '演示：查看 $name 位置';

  @override
  String devicesInstallSuccess(String name) => '安装成功：$name';

  @override
  String devicesInstallFailed(String error) => '安装失败: $error';

  @override
  String devicesInstallTo(String name) => '安装到牲畜 — $name';

  @override
  String get devicesNoMatchingLivestock => '无匹配牲畜';

  @override
  String get devicesOverview => '设备概览';

  @override
  String get devicesStatTotal => '总数';

  @override
  String get devicesSearchHint => '搜索耳标/品种';

  @override
  String get adminAnalytics => '用量分析';

  @override
  String get adminAnalyticsDesc => 'API 调用量统计与趋势分析';

  @override
  String get adminFeatureGates => '功能门控';

  @override
  String get adminFeatureGatesDesc => '管理各等级功能配额';

  @override
  String get adminAuditLog => '审计日志';

  @override
  String get adminAuditLogDesc => '查看系统操作记录';

  @override
  String get adminTileManagement => '瓦片管理';

  @override
  String get adminTileManagementDesc => '管理离线瓦片区域和任务';

  @override
  String get adminTitle => '后台管理';

  @override
  String get adminSubtitle => '管理控制台 - 业务数据与订阅概览';

  @override
  String get fenceFormManualEntry => '手动录入坐标';

  @override
  String get fenceFormApply => '应用';

  @override
  String get fenceFormVersionConflict => '版本冲突';

  @override
  String get fenceFormVersionConflictDesc => '该围栏已被其他操作修改，是否强制覆盖？';

  @override
  String get fenceFormForceUpdate => '强制更新';

  @override
  String fenceFormForceUpdateFailed(String error) => '强制更新失败: $error';

  @override
  String fenceFormSaveFailed(String error) => '保存失败: $error';

  @override
  String get fenceFormRectangle => '矩形';

  @override
  String get fenceFormCircle => '圆形';

  @override
  String get fenceFormPolygon => '多边形';

  @override
  String get fenceFormReset => '重置';

  @override
  String get fenceFormManualInput => '手动录入';

  @override
  String get fenceFormEnableAlarm => '启用告警';

  @override
  String get fenceFormEnableStatus => '启用状态';

  @override
  String get fenceFormSaveFence => '保存围栏';

  @override String get b2bRevenueTitle => '对账';
  @override String get b2bRevenueNoData => '暂无对账数据，系统将在每月1日自动生成结算周期';
  @override String get b2bContractTitle => '合同信息';
  @override String get b2bContractTerms => '合同条款';
  @override String get b2bContractServiceStatus => '订阅服务状态';
  @override String get b2bContractRenew => '联系续签';
  @override String get b2bDashboardTitle => '运营概览';
  @override String get b2bDashboardMonthlyRevenue => '本月营收';
  @override String get b2bDashboardPendingAlerts => '待处理告警';
  @override String get b2bDashboardNoPendingAlerts => '暂无待处理告警';
  @override String get b2bRevenueDetailConfirmOk => '对账确认成功';
  @override String get b2bRevenueDetailConfirmFailed => '确认失败，请重试';
  @override String get b2bRevenueDetailTitle => '对账明细';
  @override String get b2bRevenueDetailDeviceFee => '设备费用合计';
  @override String get b2bRevenueDetailConfirmStatus => '确认状态';
  @override String get b2bRevenueDetailConfirmButton => '确认对账';

  @override String get b2bFarmCreationEnterName => '请输入牧场名称';
  @override String get b2bFarmCreationSelectPoint => '请在地图上选点或输入经纬度';
  @override String b2bFarmCreationSuccess(String name) => '牧场「$name」创建成功';
  @override String get b2bFarmCreationFailed => '创建失败，请重试';
  @override String get b2bFarmCreationTitle => '新建牧场';
  @override String get b2bFarmCreationButton => '创建牧场';
  @override String get b2bFarmCreationNotSpecified => '— 暂不指定 —';
  @override String get b2bFarmCreationUserLoadFailed => '加载用户列表失败';
  @override String get b2bFarmCreationSelectTile => '请先选择瓦片区域';
  @override String get wizardExitConfirm => '牧场已创建。退出后将进入主页面，您可以稍后设置围栏。';
  @override String get wizardContinueSetup => '继续设置';
  @override String get wizardNextStep => '下一步';
  @override String get wizardEnterRanch => '进入牧场';
  @override String get wizardCreateFailedNoId => '创建牧场失败：未获取到牧场ID';
  @override String get wizardCreateFailed => '创建牧场失败，请重试';
  @override String get wizardFenceMinVertices => '围栏至少需要 3 个顶点';
  @override String get wizardSetupLater => '稍后设置';

  @override String get subscriptionUpgradeTier => '升级套餐';
  @override String get subscriptionRenew => '续费';
  @override String get subscriptionConfirmCancel => '确认取消';
  @override String get subscriptionCancelWarning => '取消订阅后，当前周期结束后将无法使用付费功能。确定要取消吗？';
  @override String get subscriptionKeepSubscription => '暂不取消';
  @override String get subscriptionCancelled => '订阅已取消';
  @override String get subscriptionCurrentTier => '当前套餐';
  @override String get subscriptionSelectTier => '选择此套餐';
  @override String get subscriptionRenewNow => '立即续费';
  @override String subscriptionUpgradeTo(String tier) => '升级到$tier';
  @override String get subscriptionFeature => '功能';

  @override String get subscriptionStatusTrial => '试用中';
  @override String get subscriptionStatusActive => '已订阅';
  @override String get subscriptionStatusCancelled => '已取消';
  @override String get subscriptionStatusExpired => '已过期';

  @override String get adminSubscriptionsNoData => '暂无订阅服务';
  @override String get adminSubscriptionsRevoke => '撤销';
  @override String get adminSubscriptionsRenew => '续期';
  @override String get adminApiAuthCreateKey => '创建 Key';
  @override String get adminApiAuthNoKeys => '暂无 API Key';
  @override String get adminApiAuthDescription => '管理 API Key 的创建、启用和撤销';
  @override String get adminApiAuthName => '名称';
  @override String get adminApiAuthDescriptionOptional => '描述（可选）';
  @override String get adminApiAuthScopes => '权限范围:';
  @override String get adminApiAuthCreate => '创建';
  @override String get adminApiAuthKeyCreated => 'Key 已创建';
  @override String get adminApiAuthKeyWarning => '请立即保存此 Key，关闭后将无法再次查看。';
  @override String get adminApiAuthSaved => '已保存';
  @override String get adminRevenueNoData => '暂无对账周期';
  @override String get adminContractActive => '生效中';
  @override String get adminContractDraft => '待签署';
  @override String get adminContractTerminated => '已终止';
  @override String get adminContractTerminate => '终止合同';
  @override String get adminContractNoData => '暂无合同';

  @override String get adminSubscriptionsTierLabel => '套餐';
  @override String get adminSubscriptionsQuotaLabel => '设备配额';

  @override String get adminApiAuthPrefixLabel => '前缀';
  @override String get fenceUnsavedTitle => '有未保存修改';
  @override String get fenceUnsavedMessage => '你有未保存的边界修改。请选择下一步。';
  @override String get fenceUnsavedContinue => '继续编辑';
  @override String get fenceUnsavedDiscard => '放弃更改';
  @override String get fenceUnsavedSaveExit => '保存并退出';
  @override String get tenantAdjustLicenseTitle => '调整 License 配额';
  @override String tenantAdjustLicenseUsed(String used) => '当前已使用：$used';
  @override String get tenantAdjustLicenseNew => '新 License 配额';
  @override String get tenantAdjustLicenseConfirm => '确认调整';
  @override String get tenantDeleteTitle => '删除租户';
  @override String tenantDeleteMessage(String name) => '即将删除租户「$name」。该操作不可撤销。';
  @override String get tenantDeleteReason => '删除原因';
  @override String get ranchHealthLatestAlerts => '最新告警';
  @override String ranchHealthAllRead(String count) => '全部已读 ($count)';
  @override String ranchHealthDismissed(String count) => '已忽略 ($count)';
  @override String get ranchHealthIgnoreAlert => '忽略此告警';
  @override String get ranchHealthFenceInfo => '围栏信息';
  @override String get ranchHealthDetail => '健康详情';
  @override String ranchHealthDetailLink(String type) => '$type详情';
  @override String get ranchLivestockDetailBtn => '详情';
  @override String get ranchLivestockRelatedAlerts => '相关告警';

  @override String get tenantLicenseInvalidInteger => '请输入非负整数';
  @override String tenantLicenseBelowUsed(String used) => '新配额不能小于当前已使用量（$used）';
  @override String get tenantDeleteReasonRequired => '请输入删除原因';

  @override String get deviceInstallTo => '安装到牲畜';
  @override String get deviceUnbind => '解绑';
  @override String get deviceViewLocation => '查看位置';
  @override String get offlineTileNoRegions => '暂无可用离线地图';
  @override String offlineTileRegionsAvailable(String count) => '可用区域（$count）';
  @override String get workerNewWorker => '新建牧工';
  @override String get workerName => '姓名';
  @override String get workerInitPassword => '初始密码';
  @override String get workerCreateSuccess => '牧工创建成功';
  @override String workerCreateFailed(String error) => '创建失败: $error';
  @override String fenceConflictTitle(String name) => '围栏冲突: $name';
  @override String get fenceConflictDiscardMine => '放弃我的修改';
  @override String get fenceConflictOverwrite => '覆盖服务端版本';

  @override String fenceConflictServerVersion(String version) => '服务端版本 (v$version)';
  @override String get fenceConflictLocalVersion => '您的修改 (离线编辑)';

  @override String get offlineTileTitle => '离线地图管理';

  @override String get workerAddWorker => '添加牧工';
  @override String get workerNoFarm => '暂无可管理牧场';
  @override String get workerNoFarmDesc => '当前账号尚未选择牧场。';
  @override String get workerNoWorkers => '暂无牧工';
  @override String get workerNoWorkersDesc => '点击右上角添加牧工';
  @override String get workerLoadFailed => '牧工加载失败';
  @override String get workerNameRequired => '姓名不能为空';
  @override String get workerPhoneRequired => '手机号不能为空';
  @override String get workerPasswordMinLength => '密码至少3位';
}
