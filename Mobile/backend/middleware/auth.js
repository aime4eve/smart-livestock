const { users } = require('../data/seed');
const { buildRuntimeConfig } = require('../config/runtimeConfig');
const { verifyAccessToken } = require('../services/mockTokenService');

/**
 * Map token -> role for simple mock auth
 */
const TOKEN_MAP = {
  'mock-token-owner': 'owner',
  'mock-token-worker': 'worker',
  'mock-token-ops': 'ops',
  'mock-token-b2b-admin': 'b2b_admin',
  'mock-token-api-consumer': 'api_consumer',
};

/**
 * Extract role from Bearer token
 */
function extractBearerToken(req) {
  const auth = req.headers.authorization || '';
  if (!auth.startsWith('Bearer ')) return null;
  return auth.slice(7);
}

/**
 * Auth middleware: sets req.userRole and req.user
 */
// Routes that don't require authentication
const PUBLIC_PATHS = ['/auth/login', '/auth/refresh', '/auth/logout'];

function authMiddleware(req, res, next) {
  // Skip auth for public paths
  if (PUBLIC_PATHS.some((p) => req.path.endsWith(p))) {
    return next();
  }

  const token = extractBearerToken(req);
  if (!token) {
    return res.fail(401, 'AUTH_UNAUTHORIZED', '未登录或 token 失效');
  }

  const jwtUser = verifyAccessToken(token);
  if (jwtUser) {
    const runtimeConfig = buildRuntimeConfig(process.env);
    req.userRole = jwtUser.role;
    req.user = jwtUser;
    req.authMode = 'jwt';
    if (runtimeConfig.exposeDebugHeaders) {
      res.setHeader('X-Auth-Mode', req.authMode);
    }
    return next();
  }

  const runtimeConfig = buildRuntimeConfig(process.env);
  const role = runtimeConfig.enableMockToken ? TOKEN_MAP[token] : null;
  if (!role) {
    return res.fail(401, 'AUTH_UNAUTHORIZED', '未登录或 token 失效');
  }
  req.userRole = role;
  req.user = users[role];
  req.authMode = 'mock';
  if (runtimeConfig.exposeDebugHeaders) {
    res.setHeader('X-Auth-Mode', req.authMode);
  }
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

module.exports = { authMiddleware, requirePermission, TOKEN_MAP, extractBearerToken };
