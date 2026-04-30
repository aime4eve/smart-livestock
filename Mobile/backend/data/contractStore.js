// 合同内存 Store
// Phase 2a: 合同为只读展示，无创建/编辑

const _contracts = [
  {
    id: 'contract_001',
    partnerTenantId: 'tenant_p001',
    status: 'active',
    effectiveTier: 'standard',
    revenueShareRatio: 0.15,
    startedAt: '2026-01-01T00:00:00+08:00',
    expiresAt: '2027-01-01T00:00:00+08:00',
    signedBy: '王五',
  },
];

function getByPartnerTenantId(partnerTenantId) {
  return _contracts.find((c) => c.partnerTenantId === partnerTenantId) ?? null;
}

module.exports = { getByPartnerTenantId };
