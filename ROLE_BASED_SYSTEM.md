# Hệ Thống Quản Lý Vai Trò (Role-Based System)

## Tổng Quan

Ứng dụng E-Learning hỗ trợ hai vai trò chính: **Học sinh (Student)** và **Giảng viên (Instructor)** với các quyền và tính năng khác nhau.

---

## 1. Kiến Trúc Vai Trò

### 1.1 Mô Hình Dữ Liệu

#### Users Collection
```
users/
├── {uid}/
│   ├── email: string
│   ├── fullName: string
│   ├── role: "student" | "instructor"
│   ├── createdAt: ISO8601 datetime
│   └── avatarUrl: string (optional)
```

#### Courses Collection
```
courses/
├── {courseId}/
│   ├── name: string
│   ├── instructorId: string (UID of instructor)
│   ├── instructorName: string
│   ├── description: string
│   ├── colorHex: string (e.g., "#2196F3")
│   ├── studentIds: array[string] (UIDs of enrolled students)
│   ├── createdAt: ISO8601 datetime
│   ├── materials/
│   ├── assignments/
│   ├── quizzes/
│   └── announcements/
```

---

## 2. Vai Trò Học Sinh (Student)

### 2.1 Chức Năng Chính

| Chức Năng | Mô Tả | Trạng Thái |
|-----------|-------|-----------|
| Xem khóa học | Xem danh sách các khóa học đã đăng ký | ✅ Hoàn thành |
| Đăng ký khóa học | Tìm kiếm và đăng ký khóa học mới | 🔄 Cần thêm |
| Trả lời Quiz | Làm bài quiz do giảng viên tạo | 🔄 Cần thêm |
| Tải tài liệu | Tải file PDF/DOC từ assignment | 🔄 Cần thêm |
| Upload bài làm | Upload file (.rar, .zip) dưới 50MB | 🔄 Cần thêm |
| Xem điểm | Xem kết quả quiz và đánh giá assignment | 🔄 Cần thêm |

### 2.2 Quy Trình Đăng Ký Khóa Học

1. Student truy cập "Duyệt Khóa Học"
2. Chọn khóa học muốn tham gia
3. Bấm "Đăng Ký"
4. Khóa học được thêm vào danh sách "Khóa Học Của Tôi"

### 2.3 Cấu Trúc Folder Student

```
StudentDashboard/
├── StudentDashboard (home screen)
│   └── StreamBuilder<List<Course>> - Khóa học đã đăng ký
├── BrowseCoursesScreen (cần thêm)
│   └── StreamBuilder<List<Course>> - Tất cả khóa học
├── CourseDetailScreen (cần thêm)
│   ├── MaterialsTab
│   ├── AssignmentsTab
│   │   ├── Xem danh sách assignment
│   │   ├── Tải file (download)
│   │   └── Upload file (upload) <50MB
│   ├── QuizzesTab
│   │   ├── Xem danh sách quiz
│   │   └── Trả lời quiz (interactive form)
│   └── PeopleTab
├── QuizDetailScreen (cần thêm)
│   ├── Quiz Questions
│   └── Submit Answers
└── ProfileScreen (cần thêm)
    ├── Thông tin cá nhân
    └── Cài đặt
```

---

## 3. Vai Trò Giảng Viên (Instructor)

### 3.1 Chức Năng Chính

| Chức Năng | Mô Tả | Trạng Thái |
|-----------|-------|-----------|
| Tạo khóa học | Tạo khóa học mới | 🔄 Cần thêm |
| Tạo ghi chú | Tạo/chỉnh sửa nội dung bài giảng | 🔄 Cần thêm |
| Upload tài liệu | Upload PDF/DOC dưới 50MB | 🔄 Cần thêm |
| Upload CSV | Upload file CSV danh sách học sinh | 🔄 Cần thêm |
| Tạo Quiz | Tạo bài trắc nghiệm | 🔄 Cần thêm |
| Upload Assignment | Tạo assignment với file PDF/DOC | 🔄 Cần thêm |
| Xem submission | Xem file bài làm từ student | 🔄 Cần thêm |
| Chấm điểm | Chấm và bình luận bài làm | 🔄 Cần thêm |

### 3.2 Quy Trình Tạo Khóa Học

1. Instructor bấm "+" (FAB) hoặc "Tạo Khóa Học Mới"
2. Nhập thông tin: Tên khóa học, mô tả, màu sắc
3. Bấm "Tạo"
4. Khóa học được thêm vào danh sách

### 3.3 Quy Trình Upload CSV Danh Sách Học Sinh

1. Tạo file CSV với format:
   ```
   email,fullName
   student1@example.com,Nguyễn Văn A
   student2@example.com,Trần Thị B
   ```
2. Vào khóa học → "Quản Lý Học Sinh"
3. Bấm "Nhập từ CSV"
4. Hệ thống tự động thêm các email vào danh sách

### 3.4 Cấu Trúc Folder Instructor

```
InstructorDashboard/
├── InstructorDashboard (home screen)
│   └── StreamBuilder<List<Course>> - Khóa học tạo bởi
├── CreateCourseScreen (cần thêm)
│   ├── Form nhập liệu
│   └── Xác nhận tạo
├── CourseManagementScreen (cần thêm)
│   ├── MaterialsTab
│   │   ├── Danh sách tài liệu
│   │   └── Upload file <50MB
│   ├── AssignmentsTab
│   │   ├── Danh sách assignment
│   │   ├── Upload file PDF/DOC
│   │   └── Xem submission từ student
│   ├── QuizzesTab
│   │   ├── Danh sách quiz
│   │   └── Tạo/chỉnh sửa quiz
│   ├── StudentsTab
│   │   ├── Danh sách học sinh
│   │   ├── Upload CSV
│   │   └── Quản lý enrollment
│   └── AnalyticsTab
│       └── Thống kê học tập
└── ProfileScreen (cần thêm)
    ├── Thông tin cá nhân
    └── Cài đặt
```

---

## 4. Cấu Trúc Dữ Liệu Chi Tiết

### 4.1 User Model

```dart
class UserModel {
  final String uid;
  final String email;
  final String fullName;
  final UserRole role; // student | instructor
  final DateTime createdAt;
  final String? avatarUrl;
}

enum UserRole { student, instructor }
```

**Firestore Document:**
```json
{
  "email": "student@example.com",
  "fullName": "Nguyễn Văn A",
  "role": "student",
  "createdAt": "2025-01-15T10:30:00Z",
  "avatarUrl": null
}
```

### 4.2 Course Model

```dart
class Course {
  final String id;
  final String name;
  final String instructorId;     // UID của giảng viên
  final String instructorName;
  final String description;
  final String colorHex;
  final List<String> studentIds; // Danh sách UID học sinh
  final DateTime createdAt;
}
```

**Firestore Document:**
```json
{
  "name": "Lập Trình Dart",
  "instructorId": "uid_instructor_123",
  "instructorName": "Thầy Bình",
  "description": "Khóa học cơ bản về Dart",
  "colorHex": "#2196F3",
  "studentIds": ["uid_student_1", "uid_student_2"],
  "createdAt": "2025-01-10T09:00:00Z"
}
```

### 4.3 Material Collection (Tài liệu)

```json
courses/{courseId}/materials/{materialId}
{
  "title": "Bài 1: Giới Thiệu Dart",
  "description": "...",
  "fileUrl": "https://storage.googleapis.com/...",
  "fileName": "lesson1.pdf",
  "fileSize": 1024000,
  "createdAt": "2025-01-10T09:00:00Z",
  "createdBy": "uid_instructor_123"
}
```

### 4.4 Assignment Collection

```json
courses/{courseId}/assignments/{assignmentId}
{
  "title": "Bài Tập 1",
  "description": "Viết chương trình tính tổng",
  "fileUrl": "https://storage.googleapis.com/...",
  "fileName": "assignment1.pdf",
  "dueDate": "2025-01-20T23:59:59Z",
  "submissions": [
    {
      "studentId": "uid_student_1",
      "fileUrl": "https://...",
      "fileName": "submission.zip",
      "submittedAt": "2025-01-20T10:00:00Z",
      "grade": 8.5,
      "feedback": "Tốt, nhưng cần cải thiện..."
    }
  ],
  "createdAt": "2025-01-10T09:00:00Z"
}
```

### 4.5 Quiz Collection

```json
courses/{courseId}/quizzes/{quizId}
{
  "title": "Quiz 1",
  "description": "Kiểm tra kiến thức chương 1",
  "questions": [
    {
      "id": "q1",
      "question": "Dart là gì?",
      "type": "multiple_choice",
      "options": ["A. Ngôn ngữ lập trình", "B. Database", ...],
      "correctAnswer": 0,
      "points": 1
    }
  ],
  "duration": 30,
  "dueDate": "2025-01-25T23:59:59Z",
  "responses": [
    {
      "studentId": "uid_student_1",
      "answers": [0, 1, 0],
      "score": 8,
      "submittedAt": "2025-01-25T10:00:00Z"
    }
  ],
  "createdAt": "2025-01-10T09:00:00Z"
}
```

---

## 5. Firestore Security Rules

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // Users collection
    match /users/{userId} {
      allow read: if request.auth.uid == userId;
      allow write: if request.auth.uid == userId;
    }

    // Courses collection - public read, write only by instructor
    match /courses/{courseId} {
      allow read: if true; // Tất cả có thể xem
      allow write: if request.auth.uid == resource.data.instructorId;
      allow create: if get(/databases/$(database)/documents/users/$(request.auth.uid)).data.role == 'instructor';

      // Subcollections
      match /materials/{materialId} {
        allow read: if request.auth.uid in resource.parent.data.studentIds || 
                       request.auth.uid == resource.parent.data.instructorId;
        allow write: if request.auth.uid == resource.parent.data.instructorId;
      }

      match /assignments/{assignmentId} {
        allow read: if request.auth.uid in resource.parent.data.studentIds || 
                       request.auth.uid == resource.parent.data.instructorId;
        allow write: if request.auth.uid == resource.parent.data.instructorId;
      }

      match /quizzes/{quizId} {
        allow read: if request.auth.uid in resource.parent.data.studentIds || 
                       request.auth.uid == resource.parent.data.instructorId;
        allow write: if request.auth.uid == resource.parent.data.instructorId;
      }
    }
  }
}
```

---

## 6. Luồng Đăng Ký & Đăng Nhập

### 6.1 Flow SignUp

```
User selects role (Student/Instructor)
    ↓
Enter: Full Name, Email, Password
    ↓
[Client validation]
- Check email format
- Check password ≥6 chars
- Confirm passwords match
    ↓
[Firebase Auth] signUp(email, password)
    ↓
[Firestore] Save user to users/{uid} with role
    ↓
Success → Return to Login tab
```

### 6.2 Flow SignIn

```
Enter: Email, Password
    ↓
[Client validation]
- Check email format
    ↓
[Firebase Auth] signIn(email, password)
    ↓
[Firestore] Fetch user role from users/{uid}
    ↓
Route to appropriate dashboard
  ├─ Student → StudentDashboard
  └─ Instructor → InstructorDashboard
```

---

## 7. Hướng Dẫn Phát Triển Các Tính Năng Tiếp Theo

### 7.1 Tạo CourseDetailScreen cho Student

```dart
// Cần implement:
1. BrowseCoursesScreen - Tìm kiếm khóa học
2. StudentCourseDetailScreen
   - Materials tab (xem tài liệu)
   - Assignments tab (xem & submit)
   - Quizzes tab (làm bài)
   - People tab (xem danh sách)
3. File upload/download functions
```

### 7.2 Tạo CourseManagementScreen cho Instructor

```dart
// Cần implement:
1. CreateCourseScreen - Tạo khóa học
2. InstructorCourseDetailScreen
   - Materials tab (upload tài liệu)
   - Assignments tab (upload & chấm)
   - Quizzes tab (tạo & xem kết quả)
   - Students tab (quản lý enrollment, import CSV)
3. Analytics dashboard
```

### 7.3 Các Models Cần Thêm

```dart
class Material {
  final String id;
  final String courseId;
  final String title;
  final String description;
  final String fileUrl;
  final String fileName;
  final int fileSize; // bytes
  final DateTime createdAt;
}

class Assignment {
  final String id;
  final String courseId;
  final String title;
  final String description;
  final String fileUrl;
  final String fileName;
  final DateTime dueDate;
  final List<Submission> submissions;
  final DateTime createdAt;
}

class Quiz {
  final String id;
  final String courseId;
  final String title;
  final String description;
  final List<Question> questions;
  final int duration; // minutes
  final DateTime dueDate;
  final List<QuizResponse> responses;
  final DateTime createdAt;
}

class Question {
  final String id;
  final String question;
  final String type; // 'multiple_choice', 'short_answer', etc
  final List<String> options;
  final int correctAnswer;
  final double points;
}
```

---

## 8. File Structure Hiện Tại

```
lib/
├── main.dart                    # ✅ Updated - Role-based routing
├── models/
│   ├── user_model.dart          # ✅ NEW - UserModel & UserRole
│   └── course.dart              # ✅ Updated - Added instructor fields
├── services/
│   ├── auth_service.dart        # ✅ Updated - Save role on signup
│   ├── firestore_service.dart   # ✅ Updated - Student/Instructor methods
│   └── storage_service.dart
└── firebase_options.dart        # ✅ Firebase config
```

---

## 9. Testing Checklist

### 9.1 Authentication
- [ ] Student signup and login
- [ ] Instructor signup and login
- [ ] Error handling (invalid email, weak password, etc)
- [ ] Logout functionality

### 9.2 Role-Based Routing
- [ ] Student sees StudentDashboard
- [ ] Instructor sees InstructorDashboard
- [ ] Role persists across app restarts

### 9.3 Course Management (Student)
- [ ] View enrolled courses
- [ ] See "No courses" message when empty
- [ ] Drawer shows correct user info
- [ ] Logout button works

### 9.4 Course Management (Instructor)
- [ ] View created courses
- [ ] See "No courses" message when empty
- [ ] FAB to create course
- [ ] Drawer shows correct user info (orange color)

---

## 10. Firestore Setup untuk Testing

### Tạo Sample Data

```json
// Tạo users collection với test data
users/
├── student_uid_1/
│   ├── email: "student1@example.com"
│   ├── fullName: "Nguyễn Văn A"
│   ├── role: "student"
│   └── createdAt: "2025-01-15T10:00:00Z"

├── instructor_uid_1/
│   ├── email: "instructor@example.com"
│   ├── fullName: "Thầy Bình"
│   ├── role: "instructor"
│   └── createdAt: "2025-01-10T09:00:00Z"

// Tạo courses collection
courses/
├── course_1/
│   ├── name: "Lập Trình Dart"
│   ├── instructorId: "instructor_uid_1"
│   ├── instructorName: "Thầy Bình"
│   ├── description: "Khóa học cơ bản Dart cho Flutter"
│   ├── colorHex: "#2196F3"
│   ├── studentIds: ["student_uid_1"]
│   └── createdAt: "2025-01-10T09:00:00Z"
```

---

## 11. Liên Hệ & Support

Để thêm tính năng hoặc báo lỗi, vui lòng:
1. Check TEST_GUIDE.md cho hướng dẫn kiểm thử
2. Check FIRESTORE_SETUP.md cho cấu hình Firestore
3. Tạo issue với chi tiết lỗi và bước tái hiện

---

**Last Updated:** 22/01/2025
**Status:** 🔄 Development in progress
