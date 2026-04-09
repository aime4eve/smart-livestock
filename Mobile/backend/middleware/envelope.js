const { v4: uuidv4 } = require('crypto');

/**
 * Generate a simple request ID
 */
function requestId() {
  const ts = Date.now().toString(36);
  const rand = Math.random().toString(36).slice(2, 8);
  return `req_${ts}_${rand}`;
}

/**
 * Success envelope: { code: "OK", message, requestId, data }
 */
function ok(data, message = 'success') {
  return {
    code: 'OK',
    message,
    requestId: requestId(),
    data,
  };
}

/**
 * Error envelope: { code, message, requestId }
 */
function fail(code, message, status) {
  return {
    code,
    message,
    requestId: requestId(),
  };
}

/**
 * Middleware to attach envelope helpers to res
 */
function envelopeMiddleware(req, res, next) {
  res.ok = (data, message) => res.json(ok(data, message));
  res.fail = (status, code, message) => res.status(status).json(fail(code, message));
  next();
}

module.exports = { envelopeMiddleware, ok, fail, requestId };
