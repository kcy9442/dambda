const express = require('express');
const cors = require('cors');
const promClient = require('prom-client');
const config = require('./config');
const authRoutes = require('./routes/auth');
const productsRoutes = require('./routes/products');
const reviewsRoutes = require('./routes/reviews');
const adminRoutes = require('./routes/admin');
const searchRoutes = require('./routes/search');

const app = express();
const metrics = new promClient.Registry();

promClient.collectDefaultMetrics({
  register: metrics,
  prefix: 'dambda_',
});

const requestDuration = new promClient.Histogram({
  name: 'dambda_http_request_duration_seconds',
  help: 'HTTP request duration in seconds',
  labelNames: ['method', 'route', 'status_code'],
  registers: [metrics],
});

app.disable('x-powered-by');
app.use((req, res, next) => {
  res.set({
    'X-Content-Type-Options': 'nosniff',
    'X-Frame-Options': 'DENY',
    'Referrer-Policy': 'no-referrer',
    'Cache-Control': 'no-store',
  });
  next();
});
app.use(cors());
app.use(express.json({ limit: '256kb', strict: true }));

app.use((req, res, next) => {
  // ALB health checks do not pass through CloudFront. All application routes
  // require the secret header injected by the CloudFront API origin.
  const isLocalMetrics = req.path === '/metrics' &&
    (req.ip === '127.0.0.1' || req.ip === '::1' || req.ip === '::ffff:127.0.0.1');
  if (req.path === '/' || isLocalMetrics) return next();
  const expected = config.originVerifySecret;
  const received = req.get('x-dambda-origin-verify');
  if (!expected || received !== expected) {
    return res.status(403).json({ error: 'cloudfront origin verification failed' });
  }
  next();
});

app.use((req, res, next) => {
  const startedAt = process.hrtime.bigint();

  res.on('finish', () => {
    const elapsedSeconds = Number(process.hrtime.bigint() - startedAt) / 1e9;
    const route = req.route?.path || req.baseUrl || 'unmatched';
    requestDuration.labels(req.method, route, String(res.statusCode)).observe(elapsedSeconds);
  });

  next();
});

// ALB 타겟그룹 헬스체크가 무인증으로 이 경로를 침
app.get('/', (req, res) => {
  res.status(200).json({ status: 'ok' });
});

// ADOT collector in the same ECS task scrapes this Prometheus endpoint.
// It contains only process and HTTP performance metrics, never request bodies
// or user data.
app.get('/metrics', async (req, res, next) => {
  try {
    res.set('Content-Type', metrics.contentType);
    res.end(await metrics.metrics());
  } catch (error) {
    next(error);
  }
});

app.use('/auth', authRoutes);
app.use('/products', productsRoutes);
app.use('/products/:productId/reviews', reviewsRoutes);
app.use('/admin', adminRoutes);
app.use('/search', searchRoutes);

// 라우트에서 처리 안 한 예외의 최종 방어선 (asyncHandler가 여기로 넘겨줌) -
// 이게 없으면 하나의 요청에서 난 에러가 서버 프로세스 전체를 죽임
app.use((err, req, res, next) => {
  console.error(err);
  res.status(500).json({ error: 'internal server error' });
});

app.listen(config.port, () => {
  console.log(`dambda-backend listening on port ${config.port}`);
});
