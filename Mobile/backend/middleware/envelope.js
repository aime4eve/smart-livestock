/**
 * Generate a simple request ID
 */
function requestIdFallback() {
  const ts = Date.now().toString(36);
  const rand = Math.random().toString(36).slice(2, 8);
  return `req_${ts}_${rand}`;
}

/**
 * Success envelope: { code: "OK", message, requestId, data }
 */
function ok(data, message = 'success', requestId = requestIdFallback()) {
  return {
    code: 'OK',
    message,
    requestId,
    data,
  };
}

/**
 * Error envelope: { code, message, requestId }
 */
function fail(code, message, requestId = requestIdFallback()) {
  return {
    code,
    message,
    requestId,
  };
}

/**
 * Middleware to attach envelope helpers to res
 */
function envelopeMiddleware(req, res, next) {
  res.ok = (data, message) => res.json(ok(data, message, req.requestId));
  res.fail = (status, code, message) =>
    res.status(status).json(fail(code, message, req.requestId));
  next();
}

module.exports = { envelopeMiddleware, ok, fail, requestIdFallback };
