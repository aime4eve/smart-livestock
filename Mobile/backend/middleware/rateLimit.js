// backend/middleware/rateLimit.js
// In-memory sliding window rate limiter by apiTier

// Rate limits per tier
const RATE_LIMITS = {
  free:     { perMinute: 10 },
  growth:   { perMinute: 100 },
  scale:    { perMinute: 1000 },
};

// Store: { apiTenantId: [timestamp, ...] }
const _windows = {};

function rateLimitMiddleware(req, res, next) {
  const tier = req.apiTier || 'free';
  const tenantId = req.apiConsumer?.tenantId || 'anonymous';
  const limit = RATE_LIMITS[tier]?.perMinute || 10;

  const now = Date.now();
  const windowMs = 60_000;

  if (!_windows[tenantId]) _windows[tenantId] = [];
  // Remove expired entries
  _windows[tenantId] = _windows[tenantId].filter((ts) => now - ts < windowMs);

  const count = _windows[tenantId].length;
  const remaining = Math.max(0, limit - count - 1);

  // Set rate limit headers
  res.set('X-RateLimit-Limit', String(limit));
  res.set('X-RateLimit-Remaining', String(remaining));

  if (count >= limit) {
    const oldest = _windows[tenantId][0];
    const resetMs = oldest + windowMs - now;
    const resetSeconds = Math.ceil(resetMs / 1000);
    res.set('X-RateLimit-Reset', String(resetSeconds));
    return res.fail(429, 'RATE_LIMITED', '请求频率超限，请稍后重试');
  }

  _windows[tenantId].push(now);
  const oldest = _windows[tenantId][0];
  const resetMs = oldest + windowMs - now;
  res.set('X-RateLimit-Reset', String(Math.ceil(resetMs / 1000)));

  next();
}

// For testing
function resetWindows() {
  for (const key of Object.keys(_windows)) delete _windows[key];
}

module.exports = { rateLimitMiddleware, resetWindows };
