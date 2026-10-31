const EMAIL_REGEX = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;

function normalizeEmail(email) {
  return typeof email === 'string' ? email.trim().toLowerCase() : '';
}

function validateRegisterInput(body = {}) {
  const fullName = typeof body.fullName === 'string' ? body.fullName.trim() : '';
  const email = normalizeEmail(body.email);
  const password = typeof body.password === 'string' ? body.password : '';

  if (!fullName) {
    return { error: 'Họ tên không được để trống' };
  }
  if (!EMAIL_REGEX.test(email)) {
    return { error: 'Email không hợp lệ' };
  }
  if (password.length < 6) {
    return { error: 'Mật khẩu phải có ít nhất 6 ký tự' };
  }

  return { value: { fullName, email, password } };
}

module.exports = { EMAIL_REGEX, normalizeEmail, validateRegisterInput };
