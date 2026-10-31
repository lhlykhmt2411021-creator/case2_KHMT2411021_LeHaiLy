const jwt = require('jsonwebtoken');
const User = require('../models/User');

const UNAUTHORIZED_MESSAGE = 'Phiên đăng nhập không hợp lệ hoặc đã hết hạn';

async function authMiddleware(req, res, next) {
  const header = req.headers.authorization || '';
  const [scheme, token] = header.split(' ');

  if (scheme !== 'Bearer' || !token) {
    return res.status(401).json({ message: 'Bạn cần đăng nhập để thực hiện thao tác này' });
  }

  try {
    const payload = jwt.verify(token, process.env.JWT_SECRET);
    const user = await User.findById(payload.sub);
    if (!user) {
      return res.status(401).json({ message: UNAUTHORIZED_MESSAGE });
    }

    req.user = user;
    return next();
  } catch (err) {
    return res.status(401).json({ message: UNAUTHORIZED_MESSAGE });
  }
}

module.exports = authMiddleware;
