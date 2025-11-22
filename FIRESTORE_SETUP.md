# Hướng dẫn cấu hình Firestore Security Rules

## 1. Firestore Security Rules hiện tại

Khi bạn chạy app lần đầu, Firebase yêu cầu Security Rules để bảo vệ dữ liệu.

### Cách set rules:

**Bước 1**: Vào Firebase Console
- URL: https://console.firebase.google.com
- Chọn project `elearnng-v2`

**Bước 2**: Vào **Firestore Database** → tab **Rules**

**Bước 3**: Replace toàn bộ rules với nội dung dưới (CHỈ dùng cho test/development):

```
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // Cho phép tất cả read/write (CHỈ dùng khi test)
    match /{document=**} {
      allow read, write: if true;
    }
  }
}
```

**Bước 4**: Nhấn "Publish"

### ⚠️ CẢNH BÁO:
- Rules trên cho phép **BẤT KỲ AI** đọc/ghi dữ liệu
- CHỈ dùng cho development/testing
- Trước khi deploy production, set rules cụ thể:

```
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // Chỉ cho phép user đã auth
    match /{document=**} {
      allow read, write: if request.auth != null;
    }
    
    // Hoặc chi tiết hơn:
    match /courses/{document=**} {
      allow read: if true;  // Public read
      allow write: if request.auth != null && request.auth.token.admin == true;  // Only admin can write
    }
    
    match /users/{userId} {
      allow read, write: if request.auth.uid == userId;  // User chỉ có thể write riêng mình
    }
  }
}
```

---

## 2. Thêm dữ liệu mẫu vào Firestore

### Cách 1: Dùng Firebase Console UI

**Bước 1**: Vào **Firestore Database** → **Data** tab

**Bước 2**: Nhấn **+ Create collection**
- Collection ID: `courses`
- Nhấn "Next"

**Bước 3**: Thêm document đầu tiên
- Document ID: để trống (auto-generate) hoặc nhập `course_1`
- Click "Add field" và thêm:

| Field | Type | Value |
|-------|------|-------|
| name | String | Lập trình Di động (Flutter) |
| instructor | String | ThS. Nguyễn Văn A |
| description | String | Học xây dựng ứng dụng đa nền tảng với Flutter & Firebase. |
| colorHex | String | #2196F3 |

**Bước 4**: Lặp lại thêm 2-3 courses khác:

```json
{
  "name": "Cấu trúc dữ liệu & Giải thuật",
  "instructor": "TS. Trần Thị B",
  "description": "Các giải thuật sắp xếp, tìm kiếm, cây nhị phân...",
  "colorHex": "#FF9800"
}
```

```json
{
  "name": "Trí tuệ nhân tạo (AI)",
  "instructor": "ThS. Lê Văn C",
  "description": "Nhập môn Machine Learning và Deep Learning cơ bản.",
  "colorHex": "#9C27B0"
}
```

```json
{
  "name": "Lập trình mạng",
  "instructor": "ThS. Phạm Văn D",
  "description": "Socket, TCP/IP, HTTP Protocol.",
  "colorHex": "#009688"
}
```

### Cách 2: Import JSON (nhanh hơn)

Firestore Console không hỗ trợ import JSON trực tiếp từ UI, nhưng bạn có thể:
- Dùng Firebase Admin SDK (NodeJS/Python)
- Dùng `firebase-import` CLI tool

Ví dụ (NodeJS):
```javascript
const admin = require('firebase-admin');
const serviceAccount = require('./path/to/serviceAccountKey.json');

admin.initializeApp({
  credential: admin.credential.cert(serviceAccount)
});

const db = admin.firestore();

const courses = [
  {
    name: 'Lập trình Di động (Flutter)',
    instructor: 'ThS. Nguyễn Văn A',
    description: 'Học xây dựng ứng dụng đa nền tảng với Flutter & Firebase.',
    colorHex: '#2196F3'
  },
  // ... more courses
];

Promise.all(courses.map(course => db.collection('courses').add(course)))
  .then(() => console.log('Data imported!'))
  .catch(err => console.error(err));
```

---

## 3. Kiểm tra connection từ app

### Log Firebase init:
```dart
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    print('✅ Firebase initialized successfully');
  } catch (e) {
    print('❌ Firebase initialization error: $e');
  }

  runApp(const ELearningApp());
}
```

### Kiểm tra Firestore connection:
```dart
// Thêm dòng này trong CourseListScreen build()
FirestoreService().getCoursesStream().listen((courses) {
  print('✅ Firestore sync: ${courses.length} courses');
});
```

### Xem logs:
- **Web (Chrome)**: F12 → Console tab
- **Android**: `flutter logs`
- **VS Code**: Output panel

---

## 4. Troubleshooting

### Lỗi: "Permission denied on read"
**Nguyên nhân**: Security Rules quá hạn chế
**Cách sửa**: Set rules cho phép `allow read: if true;` (test mode)

### Lỗi: "Operation timed out"
**Nguyên nhân**: Firebase không initialize đúng hoặc mất kết nối internet
**Cách sửa**: 
- Kiểm tra `firebase_options.dart` có project ID đúng
- Bật internet, restart app

### Lỗi: "Collection not found"
**Nguyên nhân**: Collection `courses` chưa tồn tại trong Firestore
**Cách sửa**: Tạo collection `courses` như hướng dẫn trên

### App hiển thị "Bạn chưa tham gia khóa học nào"
**Nguyên nhân**: Collection `courses` trống (chưa thêm document)
**Cách sửa**: Thêm documents vào collection `courses`

---

## 5. Cách xóa dữ liệu test

Nếu muốn xóa tất cả dữ liệu và bắt đầu lại:

**Cách 1**: Dùng Firebase Console
- Vào Firestore → Data
- Chọn collection `courses`
- Nhấn ⋮ → Delete collection

**Cách 2**: Dùng Firebase CLI
```bash
firebase firestore:delete courses --recursive
```

---

## 6. Monitoring

### Xem Firestore usage:
- Firebase Console → Firestore → Usage tab
- Kiểm tra số lần read/write/delete

### Xem realtime sync:
- Mở app 2 tab Chrome khác nhau
- Thêm document trong tab 1
- Tab 2 sẽ tự động update (nếu StreamBuilder hoạt động)

---

Sau khi hoàn tất, app sẽ:
✅ Cho phép đăng ký/đăng nhập Firebase Auth
✅ Hiển thị danh sách khóa học từ Firestore realtime
✅ Navigation đầy đủ (Login → CourseList → CourseDetail)
