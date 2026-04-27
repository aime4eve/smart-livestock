const express = require('express');
const cors = require('cors');

const { buildRuntimeConfig } = require('./config/runtimeConfig');
const { envelopeMiddleware } = require('./middleware/envelope');
const { requestContext } = require('./middleware/requestContext');
const { registerApiRoutes } = require('./routes/registerApiRoutes');

const app = express();
const PORT = 3001;
const runtimeConfig = buildRuntimeConfig();

// Middleware
app.use(cors());
app.use(express.json());
app.use(requestContext(runtimeConfig));
app.use(envelopeMiddleware);

// Routes
registerApiRoutes(app, '/api');
registerApiRoutes(app, '/api/v1');

// 404 fallback
app.use((req, res) => {
  res.fail(404, 'RESOURCE_NOT_FOUND', `路由不存在: ${req.method} ${req.path}`);
});

// Known routes (printed at startup for convenience)
const API_PREFIXES = ['/api', '/api/v1'];
const ROUTE_DEFINITIONS = [
  ['POST',   '/auth/login'],
  ['GET',    '/me'],
  ['GET',    '/dashboard/summary'],
  ['GET',    '/map/trajectories'],
  ['GET',    '/alerts'],
  ['POST',   '/alerts/:id/ack'],
  ['POST',   '/alerts/:id/handle'],
  ['POST',   '/alerts/:id/archive'],
  ['POST',   '/alerts/batch-handle'],
  ['GET',    '/fences'],
  ['GET',    '/fences/:id'],
  ['POST',   '/fences'],
  ['PUT',    '/fences/:id'],
  ['DELETE', '/fences/:id'],
  ['GET',    '/tenants'],
  ['GET',    '/tenants/:id'],
  ['POST',   '/tenants'],
  ['PUT',    '/tenants/:id'],
  ['DELETE', '/tenants/:id'],
  ['POST',   '/tenants/:id/status'],
  ['POST',   '/tenants/:id/license'],
  ['GET',    '/tenants/:id/devices'],
  ['GET',    '/tenants/:id/logs'],
  ['GET',    '/tenants/:id/stats'],
  ['GET',    '/profile'],
  ['GET',    '/twin/overview'],
  ['GET',    '/twin/fever/list'],
  ['GET',    '/twin/fever/:id'],
  ['GET',    '/twin/digestive/list'],
  ['GET',    '/twin/digestive/:id'],
  ['GET',    '/twin/estrus/list'],
  ['GET',    '/twin/estrus/:id'],
  ['GET',    '/twin/epidemic/summary'],
  ['GET',    '/twin/epidemic/contacts'],
  ['GET',    '/devices'],
];
const ROUTE_TABLE = API_PREFIXES.flatMap((prefix) =>
  ROUTE_DEFINITIONS.map(([method, path]) => [method, `${prefix}${path}`])
);

// Start server
if (require.main === module) {
  app.listen(PORT, () => {
    console.log(`\n  Mock API Server running at http://localhost:${PORT}\n`);
    console.log('  Registered routes:');
    ROUTE_TABLE.forEach(([method, path]) =>
      console.log(`  ${method.padEnd(7)} ${path}`)
    );
    console.log('');
  });
}

module.exports = { app };
