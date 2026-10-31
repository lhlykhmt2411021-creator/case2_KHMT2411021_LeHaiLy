const mongoose = require('mongoose');

async function connectDatabase() {
  const { MONGODB_URI } = process.env;

  if (!MONGODB_URI) {
    throw new Error('Thieu bien moi truong MONGODB_URI');
  }

  await mongoose.connect(MONGODB_URI);
  console.log(`Da ket noi MongoDB: ${mongoose.connection.host}/${mongoose.connection.name}`);
}

module.exports = { connectDatabase };
