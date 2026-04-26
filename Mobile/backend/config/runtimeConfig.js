function parseBool(value, fallback = false) {
  if (value === undefined) return fallback;
  return value === 'true' || value === true;
}

function buildRuntimeConfig(env = process.env) {
  const nodeEnv = env.NODE_ENV || 'development';
  const allowedEnvs = (env.MOCK_TOKEN_ALLOWED_ENVS || 'dev,development,staging')
    .split(',')
    .map((item) => item.trim())
    .filter(Boolean);
  const breakGlass = parseBool(env.MOCK_TOKEN_BREAK_GLASS);
  const breakGlassExpiresAt = env.MOCK_TOKEN_BREAK_GLASS_EXPIRES_AT || null;
  const requestedMockToken = parseBool(env.ENABLE_MOCK_TOKEN);

  let enableMockToken = requestedMockToken && allowedEnvs.includes(nodeEnv);

  if (nodeEnv === 'production' && requestedMockToken) {
    const expiresAt = breakGlassExpiresAt ? Date.parse(breakGlassExpiresAt) : Number.NaN;
    const isValidBreakGlass = breakGlass && Number.isFinite(expiresAt) && expiresAt > Date.now();
    if (!isValidBreakGlass) {
      throw new Error('mock-token cannot be enabled in production without unexpired break-glass');
    }
    enableMockToken = true;
  }

  return {
    nodeEnv,
    enableMockToken,
    allowedMockTokenEnvs: allowedEnvs,
    exposeDebugHeaders: parseBool(env.EXPOSE_API_DEBUG_HEADERS, nodeEnv !== 'production'),
  };
}

module.exports = { buildRuntimeConfig };
