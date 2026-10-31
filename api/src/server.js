require('dotenv').config();

const app = require('./app');
const { connectDatabase } = require('./config/database');

const port = process.env.PORT || 3000;

async function startServer() {
  try {
    await connectDatabase();
    app.listen(port, () => {
      console.log(`API dang chay tai cong ${port}`);
    });
  } catch (error) {
    console.error('Khong the khoi dong API:', error.message);
    process.exit(1);
  }
}

startServer();
