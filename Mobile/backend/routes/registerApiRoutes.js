const authRoutes = require('./auth');
const meRoutes = require('./me');
const dashboardRoutes = require('./dashboard');
const mapRoutes = require('./map');
const alertsRoutes = require('./alerts');
const fencesRoutes = require('./fences');
const tenantsRoutes = require('./tenants');
const profileRoutes = require('./profile');
const twinRoutes = require('./twin');
const devicesRoutes = require('./devices');

function registerApiRoutes(app, prefix) {
  app.use(`${prefix}/auth`, authRoutes);
  app.use(`${prefix}/me`, meRoutes);
  app.use(`${prefix}/dashboard`, dashboardRoutes);
  app.use(`${prefix}/map`, mapRoutes);
  app.use(`${prefix}/alerts`, alertsRoutes);
  app.use(`${prefix}/fences`, fencesRoutes);
  app.use(`${prefix}/tenants`, tenantsRoutes);
  app.use(`${prefix}/profile`, profileRoutes);
  app.use(`${prefix}/twin`, twinRoutes);
  app.use(`${prefix}/devices`, devicesRoutes);
}

module.exports = { registerApiRoutes };
