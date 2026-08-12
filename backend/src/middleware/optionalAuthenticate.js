const cognito = require('../services/cognito');

async function optionalAuthenticate(req, res, next) {
  const header = req.headers.authorization || '';
  const [scheme, token] = header.split(' ');
  if (!header) return next();
  if (scheme !== 'Bearer' || !token) {
    return res.status(401).json({ error: 'invalid bearer token' });
  }

  try {
    req.user = await cognito.getUserByAccessToken(token);
    next();
  } catch (_) {
    res.status(401).json({ error: 'invalid or expired token' });
  }
}

module.exports = optionalAuthenticate;
