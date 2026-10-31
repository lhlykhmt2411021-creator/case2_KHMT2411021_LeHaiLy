const bcrypt = require('bcryptjs');
const User = require('../models/User');
const { validateRegisterInput } = require('../validators/authValidator');

const DUPLICATE_EMAIL_MESSAGE = 'Email đã được sử dụng';
const SALT_ROUNDS = 10;

async function register(req, res, next) {
  try {
    const { value, error } = validateRegisterInput(req.body);
    if (error) {
      return res.status(400).json({ message: error });
    }

    const existingUser = await User.findOne({ email: value.email });
    if (existingUser) {
      return res.status(409).json({ message: DUPLICATE_EMAIL_MESSAGE });
    }

    const passwordHash = await bcrypt.hash(value.password, SALT_ROUNDS);
    const user = await User.create({
      fullName: value.fullName,
      email: value.email,
      passwordHash,
    });

    return res.status(201).json({ user: user.toPublicJSON() });
  } catch (err) {
    if (err.code === 11000) {
      return res.status(409).json({ message: DUPLICATE_EMAIL_MESSAGE });
    }
    return next(err);
  }
}

module.exports = { register };
