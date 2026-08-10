const cognito = require('../services/cognito');

async function admin(req, res, next) {
  try {
    if (!await cognito.isAdmin(req.user.username)) {
      return res.status(403).json({ error: 'admin access required' });
    }
    next();
  } catch (err) {
    next(err);
  }
}

module.exports = admin;
