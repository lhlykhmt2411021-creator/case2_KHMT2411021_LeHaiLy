const mongoose = require('mongoose');

async function connectDatabase() {
  const { MONGODB_URI } = process.env;

  if (!MONGODB_URI) {
    throw new Error('Thieu bien moi truong MONGODB_URI');
  }

  await mongoose.connect(MONGODB_URI);
}

module.exports = { connectDatabase };
