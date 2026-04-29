const { Router } = require('express');
const { users } = require('../data/seed');
const {
  issueTokenPair,
  verifyAccessToken,
  refreshTokenPair,
  revokeRefreshToken,
} = require('../services/mockTokenService');

const router = Router();

function resolveRole(body = {}) {
  if (body.role && users[body.role]) return body.role;
  const account = typeof body.account === 'string' ? body.account.trim().toLowerCase() : '';
  if (users[account]) return account;
  return Object.values(users).find((user) =>
    [user.userId, user.mobile, user.name].filter(Boolean).some((value) =>
      String(value).toLowerCase() === account
    )
  )?.role || null;
}

function publicUser(user) {
  const { userId, tenantId, name, role, mobile, permissions } = user;
  return { userId, tenantId, name, role, mobile, permissions };
}

router.post('/login', (req, res) => {
  const role = resolveRole(req.body);
  if (!role) {
    return res.fail(422, 'VALIDATION_ERROR', 'role 或 account 必须映射到 owner / worker / platform_admin');
  }
  const tokens = issueTokenPair(role);
  const user = publicUser(users[role]);
  res.ok({
    token: tokens.accessToken,
    role,
    accessToken: tokens.accessToken,
    refreshToken: tokens.refreshToken,
    expiresAt: tokens.expiresAt,
    user,
  });
});

router.post('/refresh', (req, res) => {
  const { refreshToken } = req.body || {};
  if (!refreshToken) {
    return res.fail(422, 'VALIDATION_ERROR', 'refreshToken 必填');
  }
  const tokens = refreshTokenPair(refreshToken);
  if (!tokens) {
    return res.fail(401, 'AUTH_UNAUTHORIZED', 'refreshToken 无效或已过期');
  }
  const user = publicUser(verifyAccessToken(tokens.accessToken));
  res.ok({
    token: tokens.accessToken,
    role: user.role,
    accessToken: tokens.accessToken,
    refreshToken: tokens.refreshToken,
    expiresAt: tokens.expiresAt,
    user,
  });
});

router.post('/logout', (req, res) => {
  const { refreshToken } = req.body || {};
  if (refreshToken) {
    revokeRefreshToken(refreshToken);
  }
  res.ok({ success: true });
});

module.exports = router;
