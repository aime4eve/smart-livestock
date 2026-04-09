const { users } = require('../data/seed');

/**
 * Map token -> role for simple mock auth
 */
const TOKEN_MAP = {
  'mock-token-owner': 'owner',
  'mock-token-worker': 'worker',
  'mock-token-ops': 'ops',
};

/**
 * Extract role from Bearer token
 */
function extractRole(req) {
  const auth = req.headers.authorization || '';
  if (!auth.startsWith('Bearer ')) return null;
  const token = auth.slice(7);
  return TOKEN_MAP[token] || null;
}

/**
 * Auth middleware: sets req.userRole and req.user
 */
function authMiddleware(req, res, next) {
  const role = extractRole(req);
  if (!role) {
    return res.fail(401, 'AUTH_UNAUTHORIZED', '未登录或 token 失效');
  }
  req.userRole = role;
  req.user = users[role];
  next();
}

/**
 * Permission checker middleware factory
 */
function requirePermission(permission) {
  return (req, res, next) => {
    if (!req.user) {
      return res.fail(401, 'AUTH_UNAUTHORIZED', '未登录或 token 失效');
    }
    if (!req.user.permissions.includes(permission)) {
      return res.fail(403, 'AUTH_FORBIDDEN', '无权访问资源');
    }
    next();
  };
}

module.exports = { authMiddleware, requirePermission, TOKEN_MAP };
