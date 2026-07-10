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
  String get deviceTypeEarTag => '耳标';

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
  String commonDeleteFailed(String error) {
    return '删除失败: $error';
  }

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
  String ranchFenceDeleted(String name) {
    return '已删除「$name」';
  }

  @override
  String ranchConfirmDeleteFence(String name) {
    return '确认删除「$name」？删除后无法恢复。';
  }

  @override
  String get ranchFenceActive => '启用';

  @override
  String get ranchFenceInactive => '停用';

  @override
  String ranchLivestockCountHead(String count) {
    return '$count头';
  }

  @override
  String ranchPeekInFence(String percent) {
    return '归栏 $percent%';
  }

  @override
  String ranchPeekHealth(String percent) {
    return '健康 $percent%';
  }

  @override
  String ranchPeekAlertCount(String count) {
    return '$count条告警';
  }

  @override
  String get ranchSectionFenceAlerts => '围栏告警';

  @override
  String get ranchSectionFenceNormal => '围栏正常';

  @override
  String get ranchSectionHealthAlerts => '健康告警';

  @override
  String get ranchSectionLivestockHealthy => '牲畜健康';

  @override
  String get ranchSectionFenceAlertDetail => '围栏告警详情';

  @override
  String get ranchSectionHealthAlertDetail => '健康告警详情';

  @override
  String get ranchCapabilityFenceNote => '系统能检测围栏越界，定位精度取决于GPS信号';

  @override
  String get ranchCapabilityHealthNote => '系统能通知你健康异常，需线下排查确认';

  @override
  String get ranchAlertTypeFenceBreach => '越界';

  @override
  String get ranchAlertTypeFenceApproach => '接近围栏';

  @override
  String get ranchAlertTypeZoneApproach => '接近区域';

  @override
  String get ranchAlertTypeFever => '发热';

  @override
  String get ranchAlertTypeDigestive => '消化异常';

  @override
  String get ranchAlertTypeEstrus => '发情';

  @override
  String get ranchAlertTypeEpidemic => '疫病';

  @override
  String get ranchAlertTypeShortApproach => '接近';

  @override
  String get ranchAlertTypeShortZone => '区域';

  @override
  String get ranchAlertTypeShortDigestive => '消化';

  @override
  String get ranchAlertTypeEstrusHighScore => '发情高分';

  @override
  String get ranchAlertTypeEpidemicRisk => '疫病风险';

  @override
  String get ranchHealthStatusCritical => '严重';

  @override
  String get ranchHealthStatusWarning => '预警';

  @override
  String get ranchHealthStatusNormal => '正常';

  @override
  String get ranchAlertStatusActive => '活跃';

  @override
  String get ranchAlertStatusDismissed => '已忽略';

  @override
  String get ranchAlertStatusAutoResolved => '已自动解除';

  @override
  String get ranchAlertStatusHandled => '已处理';

  @override
  String get ranchAlertStatusArchived => '已归档';

  @override
  String ranchTimeMinutesAgo(int minutes) {
    return '$minutes分钟前';
  }

  @override
  String ranchTimeHoursAgo(int hours) {
    return '$hours小时前';
  }

  @override
  String ranchTimeDaysAgo(int days) {
    return '$days天前';
  }

  @override
  String get ranchTimeUnknown => '未知';

  @override
  String get ranchFieldStatus => '状态';

  @override
  String get ranchFieldPrimaryAlert => '主要异常';

  @override
  String get ranchFieldLocation => '位置';

  @override
  String get ranchFieldType => '类型';

  @override
  String get ranchFieldDistanceToFence => '距围栏';

  @override
  String get ranchFieldDirection => '方向';

  @override
  String get ranchFieldOccurredTime => '发生时间';

  @override
  String get ranchFieldTime => '时间';

  @override
  String get ranchFieldAbnormalType => '异常类型';

  @override
  String get ranchActionDismiss => '忽略';

  @override
  String ranchFenceBreachCount(String count) {
    return '越界 $count 头';
  }

  @override
  String ranchFenceApproachCount(String count) {
    return '接近 $count 头';
  }

  @override
  String ranchAutoResolvedCount(String count) {
    return '已自动解除 ($count)';
  }

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
  String mineProfileName(String name) {
    return '姓名：$name';
  }

  @override
  String mineProfilePhone(String phone) {
    return '手机号：$phone';
  }

  @override
  String mineProfileRole(String role) {
    return '角色：$role';
  }

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
  String digestiveItemSubtitle(
    String breed,
    String frequency,
    String dropPercent,
  ) {
    return '$breed  蠕动 $frequency次/分  ↓$dropPercent%';
  }

  @override
  String get estrusTitle => '发情识别';

  @override
  String get estrusNoData => '暂无发情数据';

  @override
  String estrusItemSubtitle(String breed, String genderIcon, String stepInfo) {
    return '$breed $genderIcon $stepInfo';
  }

  @override
  String get epidemicTitle => '疫病防控';

  @override
  String get epidemicHerdHealth => '群体健康指标';

  @override
  String get epidemicContactTracing => '接触追踪';

  @override
  String epidemicRiskLevel(String level) {
    return '风险等级: $level';
  }

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
  String get digestiveCurrentFreq => '当前频率';

  @override
  String get digestiveBaselineFreq => '基线频率';

  @override
  String get digestiveStatus => '状态';

  @override
  String get digestiveFreqUnit => '次/分';

  @override
  String get digestiveCapabilityNote => '系统能通知你消化异常，需线下排查确认原因';

  @override
  String get estrusDetailTitle => '发情详情';

  @override
  String get estrusDetailChartTitle => '7天评分趋势';

  @override
  String get devicesManagement => '设备管理';

  @override
  String get deviceSearchHint => '搜索设备编号';

  @override
  String deviceSearchResult(Object total) {
    return '搜索结果：$total 条';
  }

  @override
  String get deviceShowAll => '查看全部';

  @override
  String devicePaginationInfo(
    Object currentPage,
    Object totalPages,
    Object total,
  ) {
    return '第 $currentPage / $totalPages 页，共 $total 条';
  }

  @override
  String get devicesAddDemo => '演示：添加新设备待接入';

  @override
  String get devicesNoDevices => '暂无设备';

  @override
  String devicesUnbindDemo(String name) {
    return '演示：解绑 $name';
  }

  @override
  String deviceUnbindConfirm(String name) {
    return '确定要解绑设备 $name 吗？解绑后该设备将不再关联牲畜。';
  }

  @override
  String deviceUnbindSuccess(String name) {
    return '解绑成功：$name';
  }

  @override
  String deviceUnbindFailed(String error) {
    return '解绑失败: $error';
  }

  @override
  String devicesViewLocationDemo(String name) {
    return '演示：查看 $name 位置';
  }

  @override
  String devicesInstallSuccess(String name) {
    return '安装成功：$name';
  }

  @override
  String devicesInstallFailed(String error) {
    return '安装失败: $error';
  }

  @override
  String devicesInstallTo(String name) {
    return '安装到牲畜 — $name';
  }

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
  String fenceFormForceUpdateFailed(String error) {
    return '强制更新失败: $error';
  }

  @override
  String fenceFormSaveFailed(String error) {
    return '保存失败: $error';
  }

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

  @override
  String get b2bRevenueTitle => '对账';

  @override
  String get b2bRevenueNoData => '暂无对账数据，系统将在每月1日自动生成结算周期';

  @override
  String get b2bContractTitle => '合同信息';

  @override
  String get b2bContractTerms => '合同条款';

  @override
  String get b2bContractServiceStatus => '订阅服务状态';

  @override
  String get b2bContractRenew => '联系续签';

  @override
  String get b2bDashboardTitle => '运营概览';

  @override
  String get b2bDashboardMonthlyRevenue => '本月营收';

  @override
  String get b2bDashboardPendingAlerts => '待处理告警';

  @override
  String get b2bDashboardNoPendingAlerts => '暂无待处理告警';

  @override
  String get b2bRevenueDetailConfirmOk => '对账确认成功';

  @override
  String get b2bRevenueDetailConfirmFailed => '确认失败，请重试';

  @override
  String get b2bRevenueDetailTitle => '对账明细';

  @override
  String get b2bRevenueDetailDeviceFee => '设备费用合计';

  @override
  String get b2bRevenueDetailConfirmStatus => '确认状态';

  @override
  String get b2bRevenueDetailConfirmButton => '确认对账';

  @override
  String get b2bFarmCreationEnterName => '请输入牧场名称';

  @override
  String get b2bFarmCreationSelectPoint => '请在地图上选点或输入经纬度';

  @override
  String b2bFarmCreationSuccess(String name) {
    return '牧场「$name」创建成功';
  }

  @override
  String get b2bFarmCreationFailed => '创建失败，请重试';

  @override
  String get b2bFarmCreationTitle => '新建牧场';

  @override
  String get b2bFarmCreationButton => '创建牧场';

  @override
  String get b2bFarmCreationNotSpecified => '— 暂不指定 —';

  @override
  String get b2bFarmCreationUserLoadFailed => '加载用户列表失败';

  @override
  String get b2bFarmCreationSelectTile => '请先选择瓦片区域';

  @override
  String get wizardExitConfirm => '牧场已创建。退出后将进入主页面，您可以稍后设置围栏。';

  @override
  String get wizardContinueSetup => '继续设置';

  @override
  String get wizardNextStep => '下一步';

  @override
  String get wizardEnterRanch => '进入牧场';

  @override
  String get wizardCreateFailedNoId => '创建牧场失败：未获取到牧场ID';

  @override
  String get wizardCreateFailed => '创建牧场失败，请重试';

  @override
  String get wizardFenceMinVertices => '围栏至少需要 3 个顶点';

  @override
  String get wizardSetupLater => '稍后设置';

  @override
  String get subscriptionUpgradeTier => '升级套餐';

  @override
  String get subscriptionRenew => '续费';

  @override
  String get subscriptionConfirmCancel => '确认取消';

  @override
  String get subscriptionCancelWarning => '取消订阅后，当前周期结束后将无法使用付费功能。确定要取消吗？';

  @override
  String get subscriptionKeepSubscription => '暂不取消';

  @override
  String get subscriptionCancelled => '订阅已取消';

  @override
  String get subscriptionCurrentTier => '当前套餐';

  @override
  String get subscriptionSelectTier => '选择此套餐';

  @override
  String get subscriptionRenewNow => '立即续费';

  @override
  String subscriptionUpgradeTo(String tier) {
    return '升级到$tier';
  }

  @override
  String get subFeatureGpsLocation => 'GPS定位';

  @override
  String subFeatureFenceCount(String count) {
    return '电子围栏($count个)';
  }

  @override
  String get subFeatureFenceUnlimited => '电子围栏(不限)';

  @override
  String subFeatureAlertHistoryDays(String count) {
    return '告警历史($count天)';
  }

  @override
  String get subFeatureAlertHistory1Year => '告警历史(1年)';

  @override
  String subFeatureDataRetentionDays(String count) {
    return '数据保留($count天)';
  }

  @override
  String get subFeatureDataRetention365 => '数据保留(365天)';

  @override
  String get subFeatureDataRetention3Year => '数据保留(3年)';

  @override
  String get subFeatureDashboardBasic => '基础看板';

  @override
  String get subFeatureDashboardAdvanced => '高级看板';

  @override
  String get subFeatureTrajectory => '历史轨迹';

  @override
  String get subFeatureDeviceManagement => '设备管理';

  @override
  String get subFeatureHealthScore => '健康评分';

  @override
  String get subFeatureEstrusDetect => '发情检测';

  @override
  String get subFeatureEpidemicAlert => '疫病预警';

  @override
  String get subFeatureDedicatedSupport => '专属客服';

  @override
  String get subFeatureGaitAnalysis => '步态分析';

  @override
  String get subFeatureBehaviorStats => '行为统计';

  @override
  String get subFeatureApiAccess => 'API访问';

  @override
  String get subCurrentTier => '当前套餐';

  @override
  String get subCustomPricing => '按需定价';

  @override
  String subPerMonth(String price) {
    return '¥$price/月';
  }

  @override
  String subLivestockLimit(String count) {
    return '最多$count头牲畜';
  }

  @override
  String get subLivestockUnlimited => '不限牲畜数量';

  @override
  String subExcessFee(String price) {
    return '超出部分 ¥$price/头/月';
  }

  @override
  String subFeatureCountSuffix(String count) {
    return '等$count项功能';
  }

  @override
  String get subSelectedPlan => '已选择套餐';

  @override
  String get subLivestockCountLabel => '牲畜数量';

  @override
  String get subFeeBreakdown => '费用明细';

  @override
  String subPlanFee(String tier) {
    return '套餐费（$tier）';
  }

  @override
  String subTrialEndsAt(String date, Object days) {
    return '试用期至 $date（剩余$days天）';
  }

  @override
  String subValidUntil(String date) {
    return '有效期至 $date';
  }

  @override
  String subExpiresOn(String date) {
    return '订阅将于 $date 到期';
  }

  @override
  String get subSubscriptionCancelled => '订阅已取消';

  @override
  String get subRenewalUrgent => '您的订阅即将到期';

  @override
  String subTrialRenewHint(String days) {
    return '试用期还有$days天到期，立即续费保留所有数据';
  }

  @override
  String subRenewHint(String days) {
    return '订阅还有$days天到期';
  }

  @override
  String get subSelectPlanHint => '选择适合您牧场的套餐方案';

  @override
  String subExcessDeviceFee(String count, Object price) {
    return '超出设备费（超出$count头 × ¥$price/头）';
  }

  @override
  String get subLockedNeedDevice => '该功能需要安装相应设备';

  @override
  String subLockedUpgradeTier(String tier) {
    return '该功能需要升级到$tier';
  }

  @override
  String get subServiceManagement => '订阅服务管理';

  @override
  String get subServiceManagementDesc => '管理所有租户的订阅服务';

  @override
  String get subUnknownService => '未知服务';

  @override
  String subServicePeriod(String start, String end) {
    return '期限: $start ~ $end';
  }

  @override
  String get subTotal => '合计';

  @override
  String subConfirmPay(String amount) {
    return '确认支付 ¥$amount';
  }

  @override
  String subYuanSuffix(String amount) {
    return '¥$amount 元';
  }

  @override
  String subSubscribeSuccess(String tier) {
    return '已成功订阅$tier';
  }

  @override
  String subExcessDeviceFeeWithin(String quota) {
    return '超出设备费（在$quota额度内）';
  }

  @override
  String get subCancelSubscription => '取消订阅';

  @override
  String get b2bContractNumber => '编号';

  @override
  String get b2bContractSigner => '签约人';

  @override
  String get b2bContractBillingMode => '计费模式';

  @override
  String get b2bContractTierLevel => '套餐等级';

  @override
  String get b2bContractRevenueShare => '分润比例';

  @override
  String get b2bContractEffectiveDate => '生效日期';

  @override
  String get b2bContractExpiryDate => '到期日期';

  @override
  String get b2bContractDeployMode => '部署方式';

  @override
  String get b2bContractDeviceQuota => '设备配额';

  @override
  String get b2bContractHeartbeat => '心跳';

  @override
  String get b2bContractExpiryTime => '到期时间';

  @override
  String get b2bContractContactPlatform => '联系平台';

  @override
  String get b2bContractContactPlatformDesc => '咨询续签或变更';

  @override
  String get b2bContractDownload => '下载合同';

  @override
  String get b2bContractDownloadDesc => '导出 PDF（占位）';

  @override
  String get b2bContractComingSoon => '功能开发中';

  @override
  String get b2bContractChatComingSoon => '在线客服功能即将上线';

  @override
  String get b2bContractPdfComingSoon => '合同 PDF 下载功能即将上线';

  @override
  String get b2bContractGotIt => '知道了';

  @override
  String get b2bContractClose => '关闭';

  @override
  String get b2bContractStatusActive => '生效中';

  @override
  String get b2bContractStatusSuspended => '已暂停';

  @override
  String get b2bContractStatusExpired => '已过期';

  @override
  String get b2bContractModeRevenueShare => '分润模式';

  @override
  String get b2bContractModeLicensed => '授权模式';

  @override
  String get b2bContractDeployCloud => '云端';

  @override
  String get b2bContractDeployOnPremise => '本地部署';

  @override
  String get b2bContractHealthRunning => '正常运行';

  @override
  String get b2bContractHealthDegraded => '性能降级';

  @override
  String get b2bContractHealthDown => '服务中断';

  @override
  String get b2bContractUnknown => '未知';

  @override
  String get b2bContractExpiryLabel => '合同到期日';

  @override
  String b2bContractDaysLeft(String date, Object days) {
    return '$date  ·  剩余 $days 天';
  }

  @override
  String b2bContractExpiredOn(String date) {
    return '$date  ·  已过期';
  }

  @override
  String get subPlanFeeLabel => '套餐费';

  @override
  String subDeviceFee(String count, Object price) {
    return '设备费（$count头 × ¥$price/头）';
  }

  @override
  String get subscriptionFeature => '功能';

  @override
  String get subscriptionStatusTrial => '试用中';

  @override
  String get subscriptionStatusActive => '已订阅';

  @override
  String get subscriptionStatusCancelled => '已取消';

  @override
  String get subscriptionStatusExpired => '已过期';

  @override
  String get adminSubscriptionsNoData => '暂无订阅服务';

  @override
  String get adminSubscriptionsRevoke => '撤销';

  @override
  String get adminSubscriptionsRenew => '续期';

  @override
  String get adminApiAuthCreateKey => '创建 Key';

  @override
  String get adminApiAuthNoKeys => '暂无 API Key';

  @override
  String get adminApiAuthDescription => '管理 API Key 的创建、启用和撤销';

  @override
  String get adminApiAuthName => '名称';

  @override
  String get adminApiAuthDescriptionOptional => '描述（可选）';

  @override
  String get adminApiAuthScopes => '权限范围:';

  @override
  String get adminApiAuthCreate => '创建';

  @override
  String get adminApiAuthKeyCreated => 'Key 已创建';

  @override
  String get adminApiAuthKeyWarning => '请立即保存此 Key，关闭后将无法再次查看。';

  @override
  String get adminApiAuthSaved => '已保存';

  @override
  String get adminRevenueNoData => '暂无对账周期';

  @override
  String get adminContractActive => '生效中';

  @override
  String get adminContractDraft => '待签署';

  @override
  String get adminContractTerminated => '已终止';

  @override
  String get adminContractTerminate => '终止合同';

  @override
  String get adminContractNoData => '暂无合同';

  @override
  String get adminSubscriptionsTierLabel => '套餐';

  @override
  String get adminSubscriptionsQuotaLabel => '设备配额';

  @override
  String get adminApiAuthPrefixLabel => '前缀';

  @override
  String get fenceUnsavedTitle => '有未保存修改';

  @override
  String get fenceUnsavedMessage => '你有未保存的边界修改。请选择下一步。';

  @override
  String get fenceUnsavedContinue => '继续编辑';

  @override
  String get fenceUnsavedDiscard => '放弃更改';

  @override
  String get fenceUnsavedSaveExit => '保存并退出';

  @override
  String get tenantAdjustLicenseTitle => '调整 License 配额';

  @override
  String tenantAdjustLicenseUsed(String used) {
    return '当前已使用：$used';
  }

  @override
  String get tenantAdjustLicenseNew => '新 License 配额';

  @override
  String get tenantAdjustLicenseConfirm => '确认调整';

  @override
  String get tenantDeleteTitle => '删除租户';

  @override
  String tenantDeleteMessage(String name) {
    return '即将删除租户「$name」。该操作不可撤销。';
  }

  @override
  String get tenantDeleteReason => '删除原因';

  @override
  String get ranchHealthLatestAlerts => '最新告警';

  @override
  String ranchHealthAllRead(String count) {
    return '全部已读 ($count)';
  }

  @override
  String ranchHealthDismissed(String count) {
    return '已忽略 ($count)';
  }

  @override
  String get ranchHealthIgnoreAlert => '忽略此告警';

  @override
  String get ranchHealthFenceInfo => '围栏信息';

  @override
  String get ranchHealthDetail => '健康详情';

  @override
  String ranchHealthDetailLink(String type) {
    return '$type详情';
  }

  @override
  String get ranchLivestockDetailBtn => '详情';

  @override
  String get ranchLivestockRelatedAlerts => '相关告警';

  @override
  String get tenantLicenseInvalidInteger => '请输入非负整数';

  @override
  String tenantLicenseBelowUsed(String used) {
    return '新配额不能小于当前已使用量（$used）';
  }

  @override
  String get tenantDeleteReasonRequired => '请输入删除原因';

  @override
  String get deviceInstallTo => '安装到牲畜';

  @override
  String get deviceActivate => '激活';

  @override
  String deviceActivateSuccess(String name) {
    return '激活成功：$name';
  }

  @override
  String deviceActivateFailed(String error) {
    return '激活失败: $error';
  }

  @override
  String get deviceUnbind => '解绑';

  @override
  String get deviceViewLocation => '查看位置';

  @override
  String get offlineTileNoRegions => '暂无可用离线地图';

  @override
  String get offlineTileGenerate => '生成离线地图';

  @override
  String get offlineTileGeneratingHint => '已请求生成，预计数分钟后完成，请稍后重新进入本页查看';

  @override
  String get offlineTileRecheck => '重新检测';

  @override
  String offlineTileRegionsAvailable(String count) {
    return '可用区域（$count）';
  }

  @override
  String get workerNewWorker => '新建牧工';

  @override
  String get workerName => '姓名';

  @override
  String get workerInitPassword => '初始密码';

  @override
  String get workerCreateSuccess => '牧工创建成功';

  @override
  String workerCreateFailed(String error) {
    return '创建失败: $error';
  }

  @override
  String fenceConflictTitle(String name) {
    return '围栏冲突: $name';
  }

  @override
  String get fenceConflictDiscardMine => '放弃我的修改';

  @override
  String get fenceConflictOverwrite => '覆盖服务端版本';

  @override
  String fenceConflictServerVersion(String version) {
    return '服务端版本 (v$version)';
  }

  @override
  String get fenceConflictLocalVersion => '您的修改 (离线编辑)';

  @override
  String get offlineTileTitle => '离线地图管理';

  @override
  String get offlineTileDownload => '下载';

  @override
  String offlineTileDownloading(String region) {
    return '正在下载 $region...';
  }

  @override
  String offlineTileDownloadFailed(String error) {
    return '下载失败：$error';
  }

  @override
  String get offlineTileDownloadSuccess => '下载完成';

  @override
  String get offlineTileDelete => '删除';

  @override
  String get offlineTileDeleteConfirm => '确定删除此离线地图？删除后需要重新下载才能离线使用。';

  @override
  String offlineTileStorageUsed(String used) {
    return '已用空间：$used';
  }

  @override
  String offlineTileDownloadedRegions(String count) {
    return '已下载（$count）';
  }

  @override
  String get offlineTileCancel => '取消';

  @override
  String get offlineTileRedownload => '更新';

  @override
  String get offlineTileNoDownloaded => '尚未下载任何离线地图';

  @override
  String get workerAddWorker => '添加牧工';

  @override
  String get workerNoFarm => '暂无可管理牧场';

  @override
  String get workerNoFarmDesc => '当前账号尚未选择牧场。';

  @override
  String get workerNoWorkers => '暂无牧工';

  @override
  String get workerNoWorkersDesc => '点击右上角添加牧工';

  @override
  String get workerLoadFailed => '牧工加载失败';

  @override
  String get workerNameRequired => '姓名不能为空';

  @override
  String get workerPhoneRequired => '手机号不能为空';

  @override
  String get workerPasswordMinLength => '密码至少3位';

  @override
  String get auditLogTitle => '审计日志';

  @override
  String get auditLogOperationType => '操作类型';

  @override
  String get auditLogQuery => '查询';

  @override
  String get auditLogNoData => '暂无审计日志';

  @override
  String auditLogTotalCount(String count) {
    return '共 $count 条';
  }

  @override
  String get tileAdminTitle => '瓦片管理';

  @override
  String get tileAdminNoRegions => '暂无瓦片区域';

  @override
  String get tileAdminNoTasks => '暂无瓦片任务';

  @override
  String get tileAdminNoFarmTiles => '暂无牧场瓦片分配';

  @override
  String tileAdminStatusInfo(String status, String tiles, String size) {
    return '状态: $status | 瓦片: $tiles | ${size}MB';
  }

  @override
  String tileAdminRegionInfo(String region, String status) {
    return '区域: $region | 状态: $status';
  }

  @override
  String get featureGateTitle => '功能门控管理';

  @override
  String get featureGateNoData => '该等级暂无功能门控';

  @override
  String get featureGateLimit => '限额';

  @override
  String get featureGateRetentionDays => '保留天数';

  @override
  String featureGateUpdated(String key) {
    return '$key 已更新';
  }

  @override
  String get analyticsTitle => '用量分析';

  @override
  String get analyticsSelectRange => '选择范围';

  @override
  String get checkoutTitle => '确认支付';

  @override
  String get checkoutLivestockCount => '请输入牲畜数量';

  @override
  String get checkoutHeadUnit => '头';

  @override
  String get planTitle => '选择套餐';

  @override
  String get farmCreationLatLabel => '纬度 (WGS-84)';

  @override
  String get farmCreationLatHint => '选区域后自动填充';

  @override
  String get farmCreationLngLabel => '经度 (WGS-84)';

  @override
  String get farmCreationLngHint => '选区域后自动填充';

  @override
  String get farmCreationNameLabel => '牧场名称 *';

  @override
  String get farmCreationNameHint => '请输入牧场名称';

  @override
  String get farmCreationOwnerLabel => '负责人';

  @override
  String get farmCreationOwnerHint => '选择 owner（可选）';

  @override
  String get farmCreationAreaLabel => '面积（公顷）';

  @override
  String get farmCreationAreaHint => '选填';

  @override
  String get farmCreationTileLabel => '瓦片区域';

  @override
  String get farmCreationTileHint => '选择离线瓦片区域';

  @override
  String get alertSummaryTitle => '告警摘要';

  @override
  String alertSummaryCount(String count) {
    return '共 $count 条';
  }

  @override
  String get commonNoData => '暂无数据';

  @override
  String get tileAdminRegionsTab => '区域管理';

  @override
  String get tileAdminTasksTab => '任务管理';

  @override
  String get tileAdminFarmTab => '牧场分配';

  @override
  String get tileAdminCreateTask => '新建瓦片任务';

  @override
  String get tileAdminReload => '重新加载';

  @override
  String get tileAdminRegionNameLabel => '区域名称';

  @override
  String get tileAdminBoundsHint => '范围：最小经度, 最小纬度, 最大经度, 最大纬度';

  @override
  String get tileAdminMinZoomLabel => '最小层级';

  @override
  String get tileAdminMaxZoomLabel => '最大层级';

  @override
  String get tileAdminCreateSuccess => '任务已创建，后台 worker 将自动生成瓦片';

  @override
  String get tileAdminCreateFailed => '创建失败';

  @override
  String get tileAdminTaskPending => '等待 worker 处理';

  @override
  String get tileAdminTilesUnit => '瓦片';

  @override
  String get tileAdminErrorPrefix => '错误：';

  @override
  String tileAdminRunningFor(String duration) {
    return '已运行 $duration';
  }

  @override
  String tileAdminDuration(String duration) {
    return '用时 $duration';
  }

  @override
  String get b2bFarmListTitle => '旗下牧场';

  @override
  String get b2bFarmListOptional => '以下选填';

  @override
  String get b2bFarmEditName => '编辑牧场名称';

  @override
  String get b2bFarmNotAssigned => '未指定';

  @override
  String b2bFarmCurrentOwner(String name) {
    return '当前负责人: $name';
  }

  @override
  String get b2bFarmNewOwner => '新负责人';

  @override
  String get b2bFarmConfirmChange => '确认变更';

  @override
  String b2bFarmChangeSuccess(String farm, String owner) {
    return '「$farm」负责人已变更为 $owner';
  }

  @override
  String b2bFarmRenameDemo(String name) {
    return '「$name」重命名功能开发中';
  }

  @override
  String get b2bFarmStatDevice => '设备';

  @override
  String get b2bFarmStatRanch => '牧场';

  @override
  String get b2bWorkerEditFarmInfo => '编辑牧场信息';

  @override
  String get b2bWorkerFarmUpdated => '牧场信息已更新';

  @override
  String get b2bWorkerAssign => '分配';

  @override
  String get b2bWorkerAssignTitle => '分配牧工';

  @override
  String get b2bWorkerAssignNone => '没有可分配的牧工，请先点击「添加牧工」创建';

  @override
  String b2bWorkerAssignConfirm(String count) {
    return '确认分配 ($count)';
  }

  @override
  String get b2bWorkerRemoveTitle => '移除牧工';

  @override
  String b2bWorkerRemoveConfirm(String name, String farm) {
    return '确定将「$name」从「$farm」移除？';
  }

  @override
  String get b2bWorkerConfirm => '确认';

  @override
  String b2bWorkerCreated(String name) {
    return '牧工「$name」已创建并分配';
  }

  @override
  String get b2bWorkerUpdated => '牧工信息已更新';

  @override
  String get b2bWorkerResetPwd => '重置密码';

  @override
  String b2bWorkerResetPwdTitle(String name) {
    return '重置「$name」密码';
  }

  @override
  String get b2bWorkerNewPassword => '新密码';

  @override
  String get b2bWorkerConfirmReset => '确认重置';

  @override
  String get b2bWorkerPwdReset => '密码已重置';

  @override
  String get subComparisonTitle => '功能对比';

  @override
  String get cmpFeatureFence => '电子围栏';

  @override
  String get cmpFeatureTempMonitor => '瘤胃温度监测';

  @override
  String get cmpFeaturePeristalticMonitor => '瘤胃蠕动监测';

  @override
  String get cmpFeatureStats => '数据统计';

  @override
  String get cmpFeatureDashboard => '看板概览';

  @override
  String get cmpFeatureDataRetention => '数据保留';

  @override
  String get cmpFeatureAlertHistory => '告警历史';

  @override
  String get cmpFeatureLivestockDetail => '牲畜详情';

  @override
  String get cmpFeatureProfile => '个人中心';

  @override
  String get cmpFeatureTenantAdmin => '租户管理';

  @override
  String cmpCellYears(String count) {
    return '$count年';
  }

  @override
  String cmpCellDays(String count) {
    return '$count天';
  }

  @override
  String get cmpCellLifetime => '永久';

  @override
  String cmpCellItems(String count) {
    return '$count项';
  }

  @override
  String get fenceEditExit => '退出编辑';

  @override
  String get fenceEditToolMoveVertex => '拖点';

  @override
  String get fenceEditToolInsertVertex => '插点';

  @override
  String get fenceEditToolDeleteVertex => '删点';

  @override
  String get fenceEditToolTranslate => '平移';

  @override
  String fenceEditTitle(String name) {
    return '编辑围栏：$name';
  }

  @override
  String get fenceEditUndo => '撤销';

  @override
  String get fenceEditRedo => '重做';

  @override
  String get fenceFormEditTitle => '编辑围栏';

  @override
  String get fenceFormNewTitle => '新建围栏';

  @override
  String get fenceFormName => '围栏名称';

  @override
  String get fenceFormNameRequired => '请输入围栏名称';

  @override
  String get fenceFormType => '围栏类型';

  @override
  String fenceFormArea(String area) {
    return '面积：$area 公顷';
  }

  @override
  String fenceFormFinishDraw(String count) {
    return '完成绘制（$count个顶点）';
  }

  @override
  String get fenceFormDrawEnd => '结束';

  @override
  String get fenceFormDrawStart => '开始绘制';

  @override
  String get fenceFormBannerDragHint => '松开鼠标或手指完成绘制';

  @override
  String get fenceFormBannerStartHint => '在地图上拖拽以画出范围';

  @override
  String get fenceFormBannerPolyContinue => '可继续点击添加顶点，或点下方「完成绘制」结束';

  @override
  String get fenceFormBannerPolyStart => '点击地图添加顶点（至少3个）';

  @override
  String get fenceFormFooterHint => '点击地图右上角「开始绘制」后在地图上设置范围，或用手动录入';

  @override
  String get fenceFormFooterDrag => '绘制模式：地图不可拖动；拖拽画出范围后松手完成';

  @override
  String get fenceFormFooterPoly => '绘制模式：点击添加顶点；移动指针可预览连线（多边形）';

  @override
  String get fenceFormManualRectHint => '请输入2个对角顶点（纬度,经度）';

  @override
  String get fenceFormManualCircleHint => '请输入圆心和边界点（纬度,经度），共2行';

  @override
  String get fenceFormManualPolyHint => '请输入各顶点坐标（至少3个），每行一个';

  @override
  String fenceFormManualMinPoints(String count) {
    return '至少需要 $count 个有效坐标点';
  }

  @override
  String get fenceSelectFence => '选择围栏';

  @override
  String fenceHeadCount(String count) {
    return '$count头';
  }

  @override
  String get fenceTemplateTitle => '围栏模板';

  @override
  String get fenceTemplateDesc => '快速生成常用围栏形状，可继续手动调整';

  @override
  String get fenceTemplateRectangle => '矩形区域';

  @override
  String get fenceTemplateCircle => '圆形区域';

  @override
  String get fenceTemplateTrajectoryBuffer => '轨迹缓冲区';

  @override
  String get fenceLoadFailed => '围栏加载失败';

  @override
  String get fenceBoundaryMinPoints => '边界至少需要 3 个点';

  @override
  String get fenceBoundaryNoDuplicates => '边界不能有连续重复点';

  @override
  String get fenceBoundaryAreaPositive => '边界面积必须大于 0';

  @override
  String get fenceBoundaryNoSelfIntersect => '边界不能自交';

  @override
  String get fenceUnnamed => '未命名';

  @override
  String get alertCenterTitle => '告警中心';

  @override
  String get alertCenterDesc => '聚焦围栏越界、设备低电、信号丢失三类 P0 告警。';

  @override
  String get alertChipFenceBreach => '越界告警';

  @override
  String get alertChipBatteryLow => '电池低电';

  @override
  String get alertChipSignalLost => '信号丢失';

  @override
  String get alertStageActive => '活跃';

  @override
  String get alertStageDismissed => '已忽略';

  @override
  String get alertStageAutoResolved => '已自动解除';

  @override
  String get alertP0FenceBreachDetail => '耳标-001 · 北区围栏 · 距边界 24m';

  @override
  String get alertP0BatteryLowDetail => '设备-045 · 电量 12% · 建议今日更换';

  @override
  String get alertP0SignalLostDetail => '耳标-023 · 失联 18 分钟 · 最后位置东坡';

  @override
  String get b2bTabKpi => 'KPI 看板';

  @override
  String get b2bTabAlertActivity => '告警动态';

  @override
  String get b2bStatSubFarms => '旗下牧场';

  @override
  String get b2bStatLivestockTotal => '牲畜总数';

  @override
  String get b2bStatWorkers => '总牧工';

  @override
  String get b2bStatDeviceOnlineRate => '设备在线率';

  @override
  String get b2bStatDeviceTotal => '设备总数';

  @override
  String get b2bNavLinkDevices => '设备';

  @override
  String get b2bNavLinkContracts => '合同';

  @override
  String get b2bNavLinkRevenue => '对账';

  @override
  String get b2bContractActive => '合同有效';

  @override
  String get b2bContractPendingRenew => '合同待续';

  @override
  String get b2bUnknownFarm => '未知牧场';

  @override
  String get b2bAlertTypeDefault => '告警';

  @override
  String get b2bAlertTypeFenceBreach => '围栏越界';

  @override
  String get b2bAlertTypeHealth => '健康异常';

  @override
  String get b2bAlertTypeDeviceOffline => '设备离线';

  @override
  String b2bLivestockLabel(String id) {
    return '牲畜 #$id';
  }

  @override
  String get alertFilterPending => '未处理';

  @override
  String get alertFilterHandled => '已处理';

  @override
  String get feverCurrentTemp => '当前温度';

  @override
  String get feverBaselineTemp => '基线温度';

  @override
  String get feverStatus => '状态';

  @override
  String get feverCapabilityNote => '系统能通知你体温异常，需线下排查确认原因';

  @override
  String get feverDurationChartTitle => '发热持续时长分析';

  @override
  String get feverDurationChartSubtitle => '每日超阈值(>39.5°C)持续小时数';

  @override
  String get digestiveHeatmapTitle => '24h 蠕动强度热力图';

  @override
  String get digestiveHeatmapSubtitle => '颜色越深 = 强度越低（异常区域高亮红色）';

  @override
  String get estrusLockedTitle => '发情检测详情';

  @override
  String get estrusCapabilityNote => '系统能检测发情高分牲畜，建议人工确认';

  @override
  String get metricScore => '评分';

  @override
  String get metricStepIncrease => '步数增幅';

  @override
  String get metricTempDelta => '温差';

  @override
  String get epidemicContactTitle => '疫情接触追踪';

  @override
  String get epidemicContactLockedMsg => '疫情接触追踪需要 Premium 及以上订阅';

  @override
  String get epidemicContactUpgrade => '升级到 Premium';

  @override
  String get epidemicNoContacts => '暂无接触记录';

  @override
  String get epidemicSourceInfected => '已确认染病';

  @override
  String get epidemicNotMarked => '未标记';

  @override
  String get epidemicMarkedAt => '标记时间';

  @override
  String get epidemicUnknown => '未知';

  @override
  String get epidemicRiskFormula =>
      '风险评分 = 时间衰减(40%) + 接触距离(35%) + 持续时长(25%)。≥70高风险，40-69中风险，<40低风险。';

  @override
  String get epidemicNetworkGraph => '接触链拓扑图';

  @override
  String get riskHigh => '高风险';

  @override
  String get riskMedium => '中风险';

  @override
  String get riskLow => '低风险';

  @override
  String get contactWindow24h => '24小时内接触';

  @override
  String get contactWindow48h => '48小时内接触';

  @override
  String get contactWindow72h => '72小时内接触';

  @override
  String get contactCountSuffix => '头';

  @override
  String get contactScoreLabel => '评分';

  @override
  String get contactDistance => '距离';

  @override
  String get contactDuration => '持续';

  @override
  String get contactFactorTime => '时间';

  @override
  String get contactFactorDistance => '距离';

  @override
  String get contactFactorDuration => '时长';

  @override
  String get epidemicContactNote =>
      '基于GPS轨迹时空交叉分析，自动识别72小时内与染病牲畜密切接触的个体并评估感染风险。';

  @override
  String get viewContactTracing => '查看接触追踪详情';

  @override
  String get livestockBreed => '品种';

  @override
  String get livestockAgeMonthsLabel => '月龄';

  @override
  String livestockAgeMonthsValue(int count) {
    return '$count 个月';
  }

  @override
  String get livestockWeight => '体重';

  @override
  String deviceBatteryValue(int percent) {
    return '电量 $percent%';
  }

  @override
  String deviceSignalValue(String value) {
    return '信号 $value';
  }

  @override
  String get livestockBodyTemp => '体温';

  @override
  String get livestockActivity => '活动量';

  @override
  String get livestockRumination => '反刍频率';

  @override
  String livestockRuminationValue(String value) {
    return '$value 次/分';
  }

  @override
  String get feverLoadFailed => '体温数据加载失败';

  @override
  String get feverNoRecords => '暂无体温记录';

  @override
  String get feverLegendActual => '实测体温';

  @override
  String get feverLegendBaseline => '基线参考';

  @override
  String get estrusLoadFailed => '发情数据加载失败';

  @override
  String get estrusNoScores => '暂无发情评分';

  @override
  String get estrusLegendScore => '发情评分';

  @override
  String get estrusLegendThreshold => '配种阈值';

  @override
  String livestockLastLocation(String location) {
    return '最近位置：$location';
  }

  @override
  String get aiAnomalyTitle => 'AI 异常检测';

  @override
  String get aiAnomalyScoreLabel => '异常指数';

  @override
  String get aiAnomalyTypeNormal => '正常';

  @override
  String get aiAnomalyTypeCircadian => '节律紊乱';

  @override
  String get aiAnomalyTypeAbrupt => '突变';

  @override
  String get aiAnomalyTypeMultivariate => '多维联合异常';

  @override
  String get aiAnomalyNoData => '暂无异常数据';

  @override
  String get aiAnomalyEffSamples => '有效样本';

  @override
  String get aiAnomalyAssessedAt => '评估方式';

  @override
  String get aiAnomalyViewHistory => '异常指数趋势';

  @override
  String get aiAnomalyAlertThreshold => '告警阈值';

  @override
  String get aiAnomalyRuleAlerts => '规则告警';

  @override
  String get aiAnomalyAiAlerts => 'AI 异常';

  @override
  String get aiAnomalyOverview => 'AI 异常概览';

  @override
  String get aiAnomalyAvgScore => '平均指数';

  @override
  String get aiAnomalyAnomalyCount => '异常数量';

  @override
  String get livestockListTitle => '牲畜管理';

  @override
  String livestockSearchResult(Object total) {
    return '搜索结果：$total 条';
  }

  @override
  String get livestockShowAll => '查看全部';

  @override
  String get livestockSearchHint => '搜索编号或品种';

  @override
  String livestockPaginationInfo(
    Object currentPage,
    Object totalPages,
    Object total,
  ) {
    return '第 $currentPage / $totalPages 页，共 $total 条';
  }

  @override
  String get livestockAddNew => '新增牲畜';

  @override
  String get livestockEdit => '编辑牲畜';

  @override
  String get livestockFormFieldCode => '编号';

  @override
  String get livestockFormFieldBreed => '品种';

  @override
  String get livestockFormFieldGender => '性别';

  @override
  String get livestockFormFieldBirthDate => '出生日期';

  @override
  String get livestockFormFieldWeight => '体重';

  @override
  String get livestockCreateSuccess => '牲畜创建成功';

  @override
  String get livestockUpdateSuccess => '牲畜更新成功';

  @override
  String get livestockBreedAngus => '安格斯';

  @override
  String get livestockBreedWagyu => '和牛';

  @override
  String get livestockBreedSimmental => '西门塔尔';

  @override
  String get livestockBreedLimousin => '利木赞';

  @override
  String get livestockBreedOther => '其他';

  @override
  String get livestockGenderMale => '公';

  @override
  String get livestockGenderFemale => '母';

  @override
  String get deviceRegisterTitle => '注册设备';

  @override
  String get deviceEditTitle => '编辑设备';

  @override
  String get deviceFormFieldCode => '设备编号';

  @override
  String get deviceFormFieldDevEui => 'LoRa EUI（选填）';

  @override
  String get deviceRegisterSuccess => '设备注册成功';

  @override
  String get deviceUpdateSuccess => '设备更新成功';

  @override
  String get installBindDevice => '绑定设备';

  @override
  String get installSelectDevice => '选择设备';

  @override
  String get installNoAvailableDevices => '没有可用设备';

  @override
  String get installSuccess => '安装成功';

  @override
  String get livestockNoDeviceBound => '未绑定设备';

  @override
  String get livestockDeleteConfirmTitle => '确认删除？';

  @override
  String get livestockDeleteConfirmMsg => '删除后将无法恢复。';

  @override
  String livestockDeleteDeviceUnbind(String deviceName) {
    return '设备 $deviceName 将自动解绑';
  }

  @override
  String get livestockDeleteArchiveNote => '历史健康数据和轨迹将归档保留';

  @override
  String get livestockDeleted => '已删除，设备已自动解绑';

  @override
  String get livestockTrajectoryTitle => '移动轨迹';

  @override
  String get livestockTrajectoryPoints => '轨迹点数';

  @override
  String get livestockTrajectoryDistance => '移动距离';

  @override
  String get livestockTrajectoryRange => '活动范围';

  @override
  String get livestockTrajectoryEmpty => '暂无轨迹数据';

  @override
  String get livestockTrajectoryNoGps => '请先绑定 GPS 设备';

  @override
  String get livestockRange24h => '24小时';

  @override
  String get livestockRange7d => '7天';

  @override
  String get livestockRange30d => '30天';

  @override
  String get livestockFormFieldCodeRequired => '编号不能为空';

  @override
  String get livestockEditSyncNote => '编号修改后，该牲畜在告警、轨迹、健康报告中的显示将同步更新';

  @override
  String get livestockGenderValueMale => '雄';

  @override
  String get livestockGenderValueFemale => '雌';
}
