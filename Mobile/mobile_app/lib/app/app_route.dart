enum AppRoute {
  login('/login', 'login', '登录'),
  twin('/twin', 'twin', '孪生'),
  alerts('/alerts', 'alerts', '告警'),
  mine('/mine', 'mine', '我的'),
  fence('/fence', 'fence', '围栏'),
  admin('/admin', 'admin', '后台'),
  platformAdmin('/ops/admin', 'platform-admin', '平台后台'),
  livestockDetail('/livestock/:id', 'livestock-detail', '牲畜详情'),
  devices('/devices', 'devices', '设备管理'),
  fenceForm('/fence/form', 'fence-form', '围栏表单'),
  stats('/stats', 'stats', '数据统计'),
  twinFever('/twin/fever', 'twin-fever', '发热预警'),
  twinFeverDetail('/twin/fever/:livestockId', 'twin-fever-detail', '发热详情'),
  twinDigestive('/twin/digestive', 'twin-digestive', '消化管理'),
  twinDigestiveDetail(
    '/twin/digestive/:livestockId',
    'twin-digestive-detail',
    '消化详情',
  ),
  twinEstrus('/twin/estrus', 'twin-estrus', '发情识别'),
  twinEstrusDetail(
    '/twin/estrus/:livestockId',
    'twin-estrus-detail',
    '发情详情',
  ),
  twinEpidemic('/twin/epidemic', 'twin-epidemic', '疫病防控'),
  b2bAdmin('/b2b/admin', 'b2b-admin', 'B端控制台'),
  b2bAdminFarms('/b2b/admin/farms', 'b2b-admin-farms', '牧场管理'),
  b2bAdminContract('/b2b/admin/contract', 'b2b-admin-contract', '合同信息'),
  subscription('/subscription', 'subscription', '订阅管理'),
  checkout('/subscription/checkout', 'checkout', '确认支付'),
  subscriptionPlan('/subscription/plans', 'subscription-plan', '套餐选择'),
  workerManagement('/mine/workers', 'worker-management', '牧工管理'),
  platformContracts('/admin/contracts', 'platform-contracts', '合同管理'),
  platformRevenue('/admin/revenue', 'platform-revenue', '对账看板'),
  platformSubscriptions('/admin/subscriptions', 'platform-subscriptions', '订阅服务管理'),
  platformApiAuth('/admin/api-auth', 'platform-api-auth', 'API授权管理'),
  b2bAdminRevenue('/b2b/admin/revenue', 'b2b-admin-revenue', '对账'),
  b2bWorkerManagement('/b2b/admin/workers', 'b2b-worker-management', '牧工管理'),
  b2bAdminRevenueDetail('/b2b/admin/revenue/:id', 'b2b-admin-revenue-detail', '对账详情'),
  b2bWorkerDetail('/b2b/admin/workers/:farmId', 'b2b-worker-detail', '牧工详情'),
  mineApiAuth('/mine/api-auth', 'mine-api-auth', 'API授权管理');

  const AppRoute(this.path, this.routeName, this.label);

  final String path;
  final String routeName;
  final String label;
}
