function createRequestId() {
  const ts = Date.now().toString(36);
  const rand = Math.random().toString(36).slice(2, 8);
  return `req_${ts}_${rand}`;
}

function requestContext(runtimeConfig) {
  return (req, res, next) => {
    req.requestId = req.headers['x-request-id'] || createRequestId();
    req.apiVersion = req.path.startsWith('/api/v1') ? 'v1' : 'legacy';
    res.setHeader('X-Request-Id', req.requestId);
    if (runtimeConfig.exposeDebugHeaders) {
      res.setHeader('X-Api-Version', req.apiVersion);
    }
    next();
  };
}

module.exports = { requestContext, createRequestId };
