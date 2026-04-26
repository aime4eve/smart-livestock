const crypto = require('node:crypto');
const { users } = require('../data/seed');

const refreshTokens = new Map();

function base64UrlJson(value) {
  return Buffer.from(JSON.stringify(value)).toString('base64url');
}

function issueAccessToken(role) {
  const user = users[role];
  if (!user) return null;
  const header = base64UrlJson({ alg: 'mock', typ: 'JWT' });
  const payload = base64UrlJson({
    userId: user.userId,
    tenantId: user.tenantId,
    role: user.role,
    permissions: user.permissions,
    exp: Math.floor(Date.now() / 1000) + 3600,
    jti: crypto.randomUUID(),
  });
  return `${header}.${payload}.mock-signature`;
}

function verifyAccessToken(token) {
  const parts = token.split('.');
  if (parts.length !== 3 || parts[2] !== 'mock-signature') return null;
  try {
    const payload = JSON.parse(Buffer.from(parts[1], 'base64url').toString('utf8'));
    if (!payload.exp || payload.exp < Math.floor(Date.now() / 1000)) return null;
    return users[payload.role] || null;
  } catch (_) {
    return null;
  }
}

function issueTokenPair(role) {
  const accessToken = issueAccessToken(role);
  if (!accessToken) return null;
  const refreshToken = crypto.randomUUID();
  refreshTokens.set(refreshToken, { role, expiresAt: Date.now() + 7 * 24 * 60 * 60 * 1000 });
  return {
    accessToken,
    refreshToken,
    expiresAt: new Date(Date.now() + 3600 * 1000).toISOString(),
  };
}

function refreshTokenPair(refreshToken) {
  const record = refreshTokens.get(refreshToken);
  if (!record || record.expiresAt < Date.now()) return null;
  refreshTokens.delete(refreshToken);
  return issueTokenPair(record.role);
}

function revokeRefreshToken(refreshToken) {
  refreshTokens.delete(refreshToken);
}

module.exports = {
  issueTokenPair,
  verifyAccessToken,
  refreshTokenPair,
  revokeRefreshToken,
};
