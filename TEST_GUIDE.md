# Test & Debug Guide cho E-Learning Firebase App

## 1. Authentication (Đăng nhập / Đăng ký)

### Cách test:
1. **Đăng ký tài khoản mới**:
   - Nhập email: `test@example.com` (format bắt buộc: chứa @)
   - Nhập mật khẩu: ít nhất 6 ký tự (ví dụ: `password123`)
   - Nhấn nút "Đăng Ký Tài Khoản Mới"
   - App sẽ hiển thị thông báo "Đăng ký thành công!"
   - Các trường sẽ được xóa, sau đó đăng nhập với tài khoản mới

2. **Đăng nhập**:
   - Nhập email + mật khẩu vừa tạo
   - Nhấn "Đăng Nhập"
   - Nếu thành công: sẽ chuyển tới CourseListScreen

### Lỗi thường gặp & cách khắc phục:
- "Email không hợp lệ" → Đảm bảo email chứa `@`
- "Mật khẩu quá yếu" → Dùng mật khẩu ≥6 ký tự
- "Email đã được đăng ký" → Email này đã tồn tại, dùng email khác hoặc đăng nhập
- "Email/mật khẩu không chính xác" → Kiểm tra lại email hoặc reset mật khẩu

---

## 2. Firestore Integration

### Hiện tại:
- App sử dụng `StreamBuilder` để fetch danh sách khóa học từ Firestore collection `courses`
- Nếu collection trống → hiển thị "Bạn chưa tham gia khóa học nào"

### Cách thêm dữ liệu mẫu vào Firestore:

**Bước 1**: Vào Firebase Console (https://console.firebase.google.com)
- Chọn project `elearnng-v2`
- Vào **Firestore Database** → **+ Create collection**

**Bước 2**: Tạo collection `courses`
- Collection ID: `courses`
- Nhấn "Next"

**Bước 3**: Thêm tài liệu mẫu
Nhấn "Add document" và nhập dữ liệu:

```
Document ID: (auto-generate hoặc tự đặt tên)
Fields:
  - name (string): "Lập trình Di động (Flutter)"
  - instructor (string): "ThS. Nguyễn Văn A"
  - description (string): "Học xây dựng ứng dụng đa nền tảng với Flutter & Firebase."
  - colorHex (string): "#2196F3"
```

Thêm thêm 2-3 khóa học khác:
```
2. name: "Cấu trúc dữ liệu & Giải thuật", instructor: "TS. Trần Thị B", description: "...", colorHex: "#FF9800"
3. name: "Trí tuệ nhân tạo (AI)", instructor: "ThS. Lê Văn C", description: "...", colorHex: "#9C27B0"
```

**Bước 4**: Refresh app
- Hot reload hoặc restart app
- CourseListScreen sẽ hiển thị danh sách khóa học từ Firestore

---

## 3. Navigation & UI Testing

### Test các chức năng:

1. **AppBar (Thanh trên cùng)**:
   - ✅ Hiển thị email đăng nhập ở góc phải
   - ✅ Nút "+" để tham gia khóa học (placeholder: hiển thị snackbar)

2. **Drawer (Menu bên trái)**:
   - ✅ Nhấn icon menu (≡) bên trái
   - ✅ Hiển thị email + avatar
   - ✅ Menu items: Lớp học, Lịch biểu, Cài đặt
   - ✅ Nút "Đăng xuất" (đỏ) → logout & quay về LoginScreen

3. **Course Card**:
   - ✅ Hiển thị tên khóa học, giảng viên, mô tả
   - ✅ Màu nền từ `colorHex` trong Firestore
   - ✅ Nhấn card → vào CourseDetailScreen

4. **FloatingActionButton**:
   - ✅ Nút chat ở dưới góc phải
   - ✅ Nhấn vào → hiển thị snackbar (placeholder)

---

## 4. Course Detail Screen Testing

### Tabs:
1. **"Bảng tin"** (Tab 1):
   - ✅ Hiển thị thông báo mẫu
   - ✅ Ô "Chia sẻ với lớp học..." (placeholder)

2. **"Bài tập"** (Tab 2):
   - ✅ Hiển thị "Chưa có bài tập nào"

3. **"Mọi người"** (Tab 3):
   - ✅ Hiển thị "Danh sách thành viên lớp"

### Info Button (ℹ️):
- ✅ Nhấn → hiển thị Dialog với thông tin khóa học
- ✅ Dialog hiển thị: Tên, Giảng viên, Mô tả

---

## 5. Error Handling & Edge Cases

### Test scenarios:
1. **Network Error**: 
   - Tắt internet → App sẽ hiển thị error state với nút "Thử lại"
   - Bật internet → Nhấn "Thử lại" → reload dữ liệu

2. **Firestore Empty**:
   - Xóa tất cả documents trong collection `courses`
   - App sẽ hiển thị "Bạn chưa tham gia khóa học nào"

3. **Firebase Auth Down**:
   - App sẽ catch lỗi và hiển thị thông báo lỗi rõ ràng

---

## 6. Code Quality Checklist

- ✅ Imports: Tất cả imports từ Firebase packages được sử dụng
- ✅ Models: `Course` có methods `toMap()`, `fromMap()`, `getColor()`
- ✅ Services: `AuthService`, `FirestoreService` với error handling
- ✅ UI: Login, CourseList, CourseDetail screens
- ✅ State Management: StreamBuilder cho real-time data từ Firestore
- ✅ Localization: Tiếng Việt cho tất cả UI text

---

## 7. Debugging Tips

### Xem logs:
```bash
flutter run -d chrome  # Run app
# Hoặc check browser console (F12)
```

### Hot reload:
- Ctrl+S hoặc nhấn "r" để hot reload
- "R" (shift+r) để hot restart

### Firestore Rules (Security):
Nếu gặp lỗi permission khi đọc/ghi Firestore:
- Vào Firebase Console → Firestore → Rules
- Set to test mode (cho phép read/write):
```
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    match /{document=**} {
      allow read, write: if true;
    }
  }
}
```

---

## 8. Next Steps (Tương lai)

- [ ] Thêm chức năng tạo/tham gia khóa học
- [ ] Thêm chức năng upload assignment
- [ ] Thêm real-time messaging
- [ ] Thêm push notifications
- [ ] Storage: Upload avatar/documents
