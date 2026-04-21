const express = require('express');
const cors = require('cors');

const { envelopeMiddleware } = require('./middleware/envelope');

const authRoutes = require('./routes/auth');
const meRoutes = require('./routes/me');
const dashboardRoutes = require('./routes/dashboard');
const mapRoutes = require('./routes/map');
const alertsRoutes = require('./routes/alerts');
const fencesRoutes = require('./routes/fences');
const tenantsRoutes = require('./routes/tenants');
const profileRoutes = require('./routes/profile');
const twinRoutes = require('./routes/twin');
const devicesRoutes = require('./routes/devices');

const app = express();
const PORT = 3001;

// Middleware
app.use(cors());
app.use(express.json());
app.use(envelopeMiddleware);

// Routes
app.use('/api/auth', authRoutes);
app.use('/api/me', meRoutes);
app.use('/api/dashboard', dashboardRoutes);
app.use('/api/map', mapRoutes);
app.use('/api/alerts', alertsRoutes);
app.use('/api/fences', fencesRoutes);
app.use('/api/tenants', tenantsRoutes);
app.use('/api/profile', profileRoutes);
app.use('/api/twin', twinRoutes);
app.use('/api/devices', devicesRoutes);

// 404 fallback
app.use((req, res) => {
  res.fail(404, 'RESOURCE_NOT_FOUND', `路由不存在: ${req.method} ${req.path}`);
});

// Known routes (printed at startup for convenience)
const ROUTE_TABLE = [
  ['POST',   '/api/auth/login'],
  ['GET',    '/api/me'],
  ['GET',    '/api/dashboard/summary'],
  ['GET',    '/api/map/trajectories'],
  ['GET',    '/api/alerts'],
  ['POST',   '/api/alerts/:id/ack'],
  ['POST',   '/api/alerts/:id/handle'],
  ['POST',   '/api/alerts/:id/archive'],
  ['POST',   '/api/alerts/batch-handle'],
  ['GET',    '/api/fences'],
  ['GET',    '/api/fences/:id'],
  ['POST',   '/api/fences'],
  ['PUT',    '/api/fences/:id'],
  ['DELETE', '/api/fences/:id'],
  ['GET',    '/api/tenants'],
  ['GET',    '/api/tenants/:id'],
  ['POST',   '/api/tenants'],
  ['PUT',    '/api/tenants/:id'],
  ['DELETE', '/api/tenants/:id'],
  ['POST',   '/api/tenants/:id/status'],
  ['POST',   '/api/tenants/:id/license'],
  ['GET',    '/api/profile'],
  ['GET',    '/api/twin/overview'],
  ['GET',    '/api/twin/fever/list'],
  ['GET',    '/api/twin/fever/:id'],
  ['GET',    '/api/twin/digestive/list'],
  ['GET',    '/api/twin/digestive/:id'],
  ['GET',    '/api/twin/estrus/list'],
  ['GET',    '/api/twin/estrus/:id'],
  ['GET',    '/api/twin/epidemic/summary'],
  ['GET',    '/api/twin/epidemic/contacts'],
  ['GET',    '/api/devices'],
];

// Start server
app.listen(PORT, () => {
  console.log(`\n  Mock API Server running at http://localhost:${PORT}\n`);
  console.log('  Registered routes:');
  ROUTE_TABLE.forEach(([method, path]) =>
    console.log(`  ${method.padEnd(7)} ${path}`)
  );
  console.log('');
});
