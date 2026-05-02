const authRoutes = require('./auth');
const meRoutes = require('./me');
const dashboardRoutes = require('./dashboard');
const mapRoutes = require('./map');
const alertsRoutes = require('./alerts');
const fencesRoutes = require('./fences');
const { router: tenantsRoutes } = require('./tenants');
const profileRoutes = require('./profile');
const twinRoutes = require('./twin');
const devicesRoutes = require('./devices');
const subscriptionRoutes = require('./subscription');
const b2bDashboardRoutes = require('./b2bDashboard');
const farmRoutes = require('./farmRoutes');
const workerRoutes = require('./workerRoutes');
const subscriptionServiceRoutes = require('./subscriptionServiceRoutes');
const revenueRoutes = require('./revenueRoutes');

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
  app.use(`${prefix}/subscription`, subscriptionRoutes);
  app.use(`${prefix}/b2b`, b2bDashboardRoutes);
  app.use(`${prefix}/farm`, farmRoutes);
  app.use(`${prefix}/farms`, workerRoutes);
  app.use(`${prefix}/subscription-services`, subscriptionServiceRoutes);
  app.use(`${prefix}/revenue`, revenueRoutes);
}

module.exports = { registerApiRoutes };
