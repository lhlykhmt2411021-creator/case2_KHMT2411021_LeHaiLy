const mongoose = require('mongoose');
const User = require('../models/User');

const SEARCH_LIMIT = 20;

function escapeRegex(text) {
  return text.replace(/[.*+?^${}()|[\]\\]/g, '\\$&');
}

function toPublicUser(user) {
  return {
    id: user._id.toString(),
    fullName: user.fullName,
    email: user.email,
    avatarUrl: user.avatarUrl || '',
  };
}

async function searchUsers(req, res, next) {
  try {
    const q = typeof req.query.q === 'string' ? req.query.q.trim() : '';
    if (!q) {
      return res.status(400).json({ message: 'Vui lòng nhập từ khóa tìm kiếm' });
    }

    const pattern = new RegExp(escapeRegex(q), 'i');
    const users = await User.find({ $or: [{ fullName: pattern }, { email: pattern }] })
      .sort({ fullName: 1 })
      .limit(SEARCH_LIMIT)
      .select('fullName email avatarUrl');

    return res.status(200).json({ users: users.map(toPublicUser) });
  } catch (err) {
    return next(err);
  }
}

async function getUserById(req, res, next) {
  try {
    const { id } = req.params;
    if (!mongoose.Types.ObjectId.isValid(id)) {
      return res.status(400).json({ message: 'Id không hợp lệ' });
    }

    const user = await User.findById(id).select('fullName email avatarUrl');
    if (!user) {
      return res.status(404).json({ message: 'Không tìm thấy người dùng' });
    }

    return res.status(200).json({ user: toPublicUser(user) });
  } catch (err) {
    return next(err);
  }
}

module.exports = { searchUsers, getUserById };
