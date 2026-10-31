const bcrypt = require('bcryptjs');
const jwt = require('jsonwebtoken');
const User = require('../models/User');
const { validateRegisterInput, validateLoginInput, validateUpdateProfileInput, validateChangePasswordInput } =
  require('../validators/authValidator');

const DUPLICATE_EMAIL_MESSAGE = 'Email đã được sử dụng';
const INVALID_CREDENTIALS_MESSAGE = 'Email hoặc mật khẩu không đúng';
const SALT_ROUNDS = 10;

function signToken(user) {
  return jwt.sign({ sub: user._id.toString() }, process.env.JWT_SECRET, {
    expiresIn: process.env.JWT_EXPIRES_IN || '7d',
  });
}

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

async function login(req, res, next) {
  try {
    const { value, error } = validateLoginInput(req.body);
    if (error) {
      return res.status(400).json({ message: error });
    }

    const user = await User.findOne({ email: value.email });
    const isPasswordValid = user ? await bcrypt.compare(value.password, user.passwordHash) : false;

    if (!user || !isPasswordValid) {
      return res.status(401).json({ message: INVALID_CREDENTIALS_MESSAGE });
    }

    return res.status(200).json({ token: signToken(user), user: user.toPublicJSON() });
  } catch (err) {
    return next(err);
  }
}

async function me(req, res) {
  return res.status(200).json({ user: req.user.toPublicJSON() });
}

async function updateMe(req, res, next) {
  try {
    const { value, error } = validateUpdateProfileInput(req.body);
    if (error) {
      return res.status(400).json({ message: error });
    }

    req.user.fullName = value.fullName;
    req.user.avatarUrl = value.avatarUrl;
    await req.user.save();

    return res.status(200).json({ user: req.user.toPublicJSON() });
  } catch (err) {
    return next(err);
  }
}

async function changePassword(req, res, next) {
  try {
    const { value, error } = validateChangePasswordInput(req.body);
    if (error) {
      return res.status(400).json({ message: error });
    }

    const isCurrentPasswordValid = await bcrypt.compare(value.currentPassword, req.user.passwordHash);
    if (!isCurrentPasswordValid) {
      return res.status(400).json({ message: 'Mật khẩu hiện tại không đúng' });
    }

    req.user.passwordHash = await bcrypt.hash(value.newPassword, SALT_ROUNDS);
    await req.user.save();

    return res.status(200).json({ message: 'Đổi mật khẩu thành công' });
  } catch (err) {
    return next(err);
  }
}

module.exports = { register, login, me, updateMe, changePassword };
