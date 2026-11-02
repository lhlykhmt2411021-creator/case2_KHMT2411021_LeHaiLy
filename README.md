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
| `SMTP_HOST`, `SMTP_PORT` | Máy chủ SMTP dùng để gửi email thông báo |
| `SMTP_SECURE` | `true` nếu dùng kết nối TLS ngay từ đầu (thường là cổng 465) |
| `SMTP_USER`, `SMTP_PASS` | Tài khoản đăng nhập SMTP |
| `MAIL_FROM` | Địa chỉ người gửi, mặc định lấy `SMTP_USER` |

Nếu chưa cấu hình `SMTP_HOST`/`SMTP_PORT`, hệ thống vẫn tạo bản ghi email log với trạng thái `skipped` và lỗi "Chưa cấu hình SMTP" thay vì làm hỏng thao tác nghiệp vụ.

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
| POST | `/tasks` | Tạo công việc (title, description, priority, startDate, dueDate) |
| GET | `/tasks/:id` | Chi tiết công việc kèm người tạo, người phụ trách, người được giao, người được chia sẻ và vai trò của người gọi |
| PUT | `/tasks/:id` | Sửa thông tin công việc (người tạo hoặc editor) |
| PATCH | `/tasks/:id/status` | Đổi trạng thái (người tạo, editor, người được giao) |
| DELETE | `/tasks/:id` | Xóa công việc (chỉ người tạo) |
| GET | `/tasks/:id/activities` | Lịch sử hoạt động của công việc |
| GET | `/tasks/:id/assignees` | Danh sách người được giao và người phụ trách chính |
| POST | `/tasks/:id/assignees` | Giao việc cho một hoặc nhiều người (`userIds`, `primaryAssigneeId`) — chỉ người tạo |
| PATCH | `/tasks/:id/assignees/:userId` | Đặt người phụ trách chính — chỉ người tạo |
| DELETE | `/tasks/:id/assignees/:userId` | Hủy giao việc — chỉ người tạo |
| GET | `/tasks/:id/shares` | Danh sách người được chia sẻ kèm quyền |
| POST | `/tasks/:id/shares` | Chia sẻ công việc (`userIds`, `permission`: `viewer`/`editor`) — chỉ người tạo |
| PATCH | `/tasks/:id/shares/:shareId` | Đổi quyền chia sẻ — chỉ người tạo |
| DELETE | `/tasks/:id/shares/:shareId` | Thu hồi quyền chia sẻ — chỉ người tạo |
| GET | `/tasks/:id/email-logs` | Lịch sử gửi email của công việc — chỉ người tạo |

Các API công việc đều yêu cầu Bearer token. Người dùng chỉ đọc được công việc do mình tạo, được giao hoặc được chia sẻ. Người tạo quản lý giao việc/chia sẻ; editor sửa nội dung và đổi trạng thái; người được giao đổi trạng thái; người được chia sẻ chỉ xem hoặc chỉnh sửa theo quyền.

### Thông báo

| Method | Endpoint | Mô tả |
| --- | --- | --- |
| GET | `/notifications?isRead=&limit=` | Danh sách thông báo của người dùng, kèm `unreadCount` |
| GET | `/notifications/unread-count` | Chỉ trả về số thông báo chưa đọc |
| PATCH | `/notifications/:id/read` | Đánh dấu một thông báo đã đọc |
| PATCH | `/notifications/read-all` | Đánh dấu tất cả thông báo đã đọc |

### Email

| Method | Endpoint | Mô tả |
| --- | --- | --- |
| POST | `/email-logs/:id/retry` | Gửi lại email đã ghi log (tối đa 3 lần gửi), chỉ người tạo công việc |

Thông báo trong ứng dụng được tạo khi: được giao việc, bị hủy giao, được chia sẻ, đổi quyền chia sẻ, bị thu hồi quyền, công việc đổi trạng thái, đổi hạn hoàn thành hoặc bị xóa. Email được gửi cho người được giao / người được chia sẻ ở các sự kiện giao việc, chia sẻ, đổi hạn và hoàn thành; mỗi lần gửi đều ghi vào collection `email_logs` với trạng thái `sent`, `failed` hoặc `skipped`.

## Phần chưa làm

- Tìm kiếm, lọc, sắp xếp công việc
- Thống kê trên giao diện
