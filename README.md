# Case Study 2 - Task Manager

- MSSV: KHMT2411021
- Họ tên: Lê Hải Lý

Ứng dụng quản lý và giao công việc nhóm, gồm REST API Node.js/Express/MongoDB và ứng dụng Flutter.

## Công nghệ

- Backend: Node.js, Express, Mongoose, JWT, bcryptjs
- Frontend: Flutter (http, shared_preferences)
- Database: MongoDB Atlas, database `task_manager`

## Cấu trúc

```
api/          REST API (Node.js/Express)
TaskManager/  Ứng dụng Flutter
```

## Chạy API

```powershell
cd api
npm install
copy .env.example .env   # rồi điền giá trị thật
npm start                # hoặc npm run dev
```

Biến môi trường trong `api/.env`:

| Biến | Ý nghĩa |
| --- | --- |
| `PORT` | Cổng chạy API, mặc định 3000 |
| `MONGODB_URI` | Chuỗi kết nối MongoDB, phải có tên database `task_manager` |
| `JWT_SECRET` | Khóa ký JWT |
| `JWT_EXPIRES_IN` | Hạn của token, mặc định `7d` |

Không commit file `.env` lên repository.

## Chạy ứng dụng Flutter

```powershell
cd TaskManager
flutter pub get
flutter run
```

Base URL API nằm trong `lib/utils/constants.dart`:

- Máy ảo Android: `http://10.0.2.2:3000/api`
- Thiết bị thật hoặc desktop: đổi sang IP LAN của máy chạy API

## API đã làm

Base URL: `http://localhost:3000/api`

### Xác thực

| Method | Endpoint | Mô tả |
| --- | --- | --- |
| POST | `/auth/register` | Đăng ký tài khoản (fullName, email, password) |
| POST | `/auth/login` | Đăng nhập, trả `{ token, user }` |
| GET | `/auth/me` | Lấy thông tin người dùng hiện tại (cần Bearer token) |
| PUT | `/auth/me` | Cập nhật họ tên và ảnh đại diện (cần Bearer token) |
| PUT | `/auth/change-password` | Đổi mật khẩu, cần `currentPassword` và `newPassword` (cần Bearer token) |

### Người dùng

| Method | Endpoint | Mô tả |
| --- | --- | --- |
| GET | `/users/search?q=` | Tìm người dùng theo họ tên hoặc email (tối đa 20 kết quả) |
| GET | `/users/:id` | Xem thông tin công khai của một người dùng |

### Công việc

| Method | Endpoint | Mô tả |
| --- | --- | --- |
| GET | `/tasks?scope=created\|assigned\|shared` | Danh sách công việc người dùng có quyền truy cập |
| GET | `/tasks/:id` | Chi tiết công việc kèm người tạo, người phụ trách, người được giao, người được chia sẻ và vai trò của người gọi |

Các API công việc đều yêu cầu Bearer token. Người dùng chỉ đọc được công việc do mình tạo, được giao hoặc được chia sẻ.

## Phần chưa làm

- Thêm, sửa, xóa công việc; cập nhật trạng thái
- Giao việc cho nhiều người, chỉ định người phụ trách chính
- Chia sẻ công việc và quản lý quyền viewer/editor
- Tìm kiếm, lọc, sắp xếp công việc
- Thông báo trong ứng dụng và gửi email
- Thống kê, lịch sử hoạt động
