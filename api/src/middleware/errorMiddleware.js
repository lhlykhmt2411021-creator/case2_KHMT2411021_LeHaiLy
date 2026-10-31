function notFoundHandler(req, res) {
  res.status(404).json({ message: 'Không tìm thấy endpoint' });
}

function errorMiddleware(err, req, res, next) {
  if (res.headersSent) {
    return next(err);
  }

  let status = err.statusCode || err.status || 500;
  let message = err.message;

  if (err.name === 'ValidationError') {
    status = 400;
    message = 'Dữ liệu không hợp lệ';
  } else if (err.name === 'CastError') {
    status = 400;
    message = 'Id không hợp lệ';
  } else if (err.code === 11000) {
    status = 409;
    message = 'Dữ liệu đã tồn tại';
  }

  if (status >= 500) {
    console.error('[error]', err);
    return res.status(500).json({ message: 'Đã có lỗi xảy ra, vui lòng thử lại sau' });
  }

  return res.status(status).json({ message });
}

module.exports = { notFoundHandler, errorMiddleware };
