const EMAIL_REGEX = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
const URL_REGEX = /^https?:\/\/\S+$/i;
const MAX_FULL_NAME_LENGTH = 100;
const MAX_AVATAR_URL_LENGTH = 500;

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

function validateLoginInput(body = {}) {
  const email = normalizeEmail(body.email);
  const password = typeof body.password === 'string' ? body.password : '';

  if (!email || !password) {
    return { error: 'Vui lòng nhập email và mật khẩu' };
  }

  return { value: { email, password } };
}

function validateUpdateProfileInput(body = {}) {
  const fullName = typeof body.fullName === 'string' ? body.fullName.trim() : '';
  const avatarUrl = typeof body.avatarUrl === 'string' ? body.avatarUrl.trim() : '';

  if (!fullName) {
    return { error: 'Họ tên không được để trống' };
  }
  if (fullName.length > MAX_FULL_NAME_LENGTH) {
    return { error: `Họ tên không được vượt quá ${MAX_FULL_NAME_LENGTH} ký tự` };
  }
  if (avatarUrl && !URL_REGEX.test(avatarUrl)) {
    return { error: 'Đường dẫn ảnh đại diện phải bắt đầu bằng http hoặc https' };
  }
  if (avatarUrl.length > MAX_AVATAR_URL_LENGTH) {
    return { error: 'Đường dẫn ảnh đại diện quá dài' };
  }

  return { value: { fullName, avatarUrl } };
}

module.exports = {
  EMAIL_REGEX,
  normalizeEmail,
  validateRegisterInput,
  validateLoginInput,
  validateUpdateProfileInput,
};
