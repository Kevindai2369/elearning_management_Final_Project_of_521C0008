# 📋 Hệ Thống E-Learning - Tóm Tắt Thiết Kế

## Tổng Quan

Ứng dụng Flutter E-Learning với hai vai trò chính: **Học sinh (Student)** và **Giảng viên (Instructor)**, tích hợp Firebase để lưu trữ dữ liệu và quản lý người dùng.

---

## Kiến Trúc Hệ Thống

```
┌─────────────────────────────────────────────────────────────┐
│                      ELEARNING APP                          │
├─────────────────────────────────────────────────────────────┤
│                                                              │
│  ┌──────────────────────────────────────────────────────┐   │
│  │              LOGIN/SIGNUP SCREEN                      │   │
│  │  ┌─────────────┐           ┌──────────────────────┐   │   │
│  │  │ Student     │           │ Instructor           │   │   │
│  │  │ - Email     │     OR     │ - Email              │   │   │
│  │  │ - Password  │           │ - Password           │   │   │
│  │  │ - Role      │           │ - Role               │   │   │
│  │  └─────────────┘           └──────────────────────┘   │   │
│  └──────────────────────────────────────────────────────┘   │
│                           ↓                                  │
│  ┌──────────────────────────────────────────────────────┐   │
│  │    ROLE-BASED ROUTING (AuthService Stream)          │   │
│  └──────────────────────────────────────────────────────┘   │
│         ↙                                         ↘           │
│                                                              │
│  ┌──────────────────────┐      ┌─────────────────────────┐ │
│  │  STUDENT DASHBOARD   │      │ INSTRUCTOR DASHBOARD    │ │
│  ├──────────────────────┤      ├─────────────────────────┤ │
│  │ - Enrolled Courses   │      │ - Created Courses       │ │
│  │ - Browse Courses     │      │ - Create New Course     │ │
│  │ - Materials          │      │ - Upload Materials      │ │
│  │ - Assignments        │      │ - Create Quizzes       │ │
│  │ - Quizzes            │      │ - Import Students (CSV) │ │
│  │ - View Grades        │      │ - Grade Assignments     │ │
│  │ - User Profile       │      │ - View Analytics        │ │
│  │ - Logout             │      │ - User Profile          │ │
│  │                      │      │ - Logout                │ │
│  └──────────────────────┘      └─────────────────────────┘ │
│                                                              │
└─────────────────────────────────────────────────────────────┘
```

---

## Cấu Trúc Cơ Sở Dữ Liệu (Firestore)

```
Firestore Database
│
├── users/                          (Lưu trữ thông tin người dùng)
│   ├── {uid}/
│   │   ├── email: string
│   │   ├── fullName: string
│   │   ├── role: "student" | "instructor"
│   │   ├── createdAt: timestamp
│   │   └── avatarUrl: string (optional)
│
├── courses/                         (Khóa học)
│   ├── {courseId}/
│   │   ├── name: string
│   │   ├── instructorId: string     ← UID của giảng viên
│   │   ├── instructorName: string
│   │   ├── description: string
│   │   ├── colorHex: string
│   │   ├── studentIds: [string]     ← Danh sách UID học sinh
│   │   ├── createdAt: timestamp
│   │   │
│   │   ├── materials/               (Tài liệu bài giảng)
│   │   │   ├── {materialId}/
│   │   │   │   ├── title: string
│   │   │   │   ├── description: string
│   │   │   │   ├── fileUrl: string  ← Firebase Storage URL
│   │   │   │   ├── fileName: string
│   │   │   │   ├── fileSize: number
│   │   │   │   ├── createdAt: timestamp
│   │   │   │   └── createdBy: string ← UID instructor
│   │   │
│   │   ├── assignments/             (Bài tập)
│   │   │   ├── {assignmentId}/
│   │   │   │   ├── title: string
│   │   │   │   ├── description: string
│   │   │   │   ├── fileUrl: string  ← Firebase Storage URL
│   │   │   │   ├── fileName: string
│   │   │   │   ├── dueDate: timestamp
│   │   │   │   ├── submissions: [   ← Danh sách nộp bài
│   │   │   │   │   {
│   │   │   │   │     studentId: string
│   │   │   │   │     fileUrl: string
│   │   │   │   │     fileName: string
│   │   │   │   │     submittedAt: timestamp
│   │   │   │   │     grade: number
│   │   │   │   │     feedback: string
│   │   │   │   │   }
│   │   │   │   │]
│   │   │   │   ├── createdAt: timestamp
│   │   │   │   └── createdBy: string
│   │   │
│   │   └── quizzes/                 (Bài Quiz)
│   │       ├── {quizId}/
│   │       │   ├── title: string
│   │       │   ├── description: string
│   │       │   ├── questions: [
│   │       │   │   {
│   │       │   │     id: string
│   │       │   │     question: string
│   │       │   │     type: "multiple_choice|true_false|short_answer"
│   │       │   │     options: [string]
│   │       │   │     correctAnswer: number
│   │       │   │     points: number
│   │       │   │   }
│   │       │   │]
│   │       │   ├── duration: number  ← phút
│   │       │   ├── dueDate: timestamp
│   │       │   ├── responses: [      ← Danh sách trả lời
│   │       │   │   {
│   │       │   │     studentId: string
│   │       │   │     answers: [number]
│   │       │   │     score: number
│   │       │   │     submittedAt: timestamp
│   │       │   │   }
│   │       │   │]
│   │       │   ├── createdAt: timestamp
│   │       │   └── createdBy: string
```

---

## Tính Năng Chi Tiết

### 👨‍🎓 STUDENT (Học Sinh)

#### 1. Đăng Ký Khóa Học
```
1. Chọn vai trò "Học sinh" khi đăng ký
2. Nhập: Email, Mật khẩu, Họ tên
3. Lưu vào Firestore users/{uid} với role: "student"
4. Tự động route đến StudentDashboard
```

#### 2. Xem Khóa Học Đã Đăng Ký
```
StreamBuilder → FirestoreService.getStudentCoursesStream(userId)
↓
WHERE studentIds CONTAINS userId
↓
Hiển thị danh sách khóa học
```

#### 3. Duyệt & Đăng Ký Khóa Học Mới
```
BrowseCoursesScreen
├─ Tìm kiếm theo tên khóa học/giảng viên
├─ Xem chi tiết khóa học
└─ Bấm "Đăng Ký" → FirestoreService.enrollStudentInCourse()
   └─ Thêm studentId vào courses/{courseId}.studentIds array
```

#### 4. Xem Tài Liệu Bài Giảng
```
CourseDetailScreen → Materials Tab
├─ StreamBuilder → getCourseMaterialsStream(courseId)
├─ Hiển thị danh sách PDF/DOC
└─ Tải file từ Firebase Storage URL
```

#### 5. Làm Bài Quiz
```
CourseDetailScreen → Quizzes Tab
├─ Xem danh sách quiz
├─ Bấm vào quiz → QuizDetailScreen
├─ Trả lời các câu hỏi multiple choice
├─ Bấm Submit → Lưu vào courses/{courseId}/quizzes/{quizId}.responses
└─ Hiển thị điểm ngay lập tức
```

#### 6. Nộp Bài Tập
```
CourseDetailScreen → Assignments Tab
├─ Xem danh sách bài tập
├─ Tải file assignment (PDF/DOC)
├─ Chọn file đáp án (.rar/.zip < 50MB)
├─ Upload lên Firebase Storage
└─ Lưu metadata vào courses/{courseId}/assignments/{assignmentId}.submissions
   └─ Chờ giảng viên chấm điểm
```

#### 7. Xem Kết Quả
```
StudentProfileScreen → My Grades
├─ Xem điểm quiz
├─ Xem điểm assignment + feedback từ giảng viên
└─ Phân tích tiến độ học tập
```

---

### 👨‍🏫 INSTRUCTOR (Giảng Viên)

#### 1. Đăng Ký Tài Khoản
```
1. Chọn vai trò "Giảng viên" khi đăng ký
2. Nhập: Email, Mật khẩu, Họ tên
3. Lưu vào Firestore users/{uid} với role: "instructor"
4. Tự động route đến InstructorDashboard
```

#### 2. Tạo Khóa Học
```
InstructorDashboard → FAB (+ button)
├─ CreateCourseScreen
├─ Nhập: Tên khóa học, Mô tả, Chọn màu sắc
├─ Bấm "Tạo" → FirestoreService.addCourse()
└─ Lưu vào courses/{courseId} với:
   ├─ instructorId: current user UID
   ├─ instructorName: from users/{uid}
   ├─ studentIds: [] (trống ban đầu)
   └─ createdAt: timestamp
```

#### 3. Upload Tài Liệu Bài Giảng
```
CourseManagementScreen → Materials Tab
├─ Chọn file PDF/DOC (< 50MB)
├─ Upload lên Firebase Storage: courses/{courseId}/materials/file.pdf
├─ Lưu metadata vào courses/{courseId}/materials/{materialId}
│  ├─ fileUrl: Firebase Storage URL
│  ├─ fileName: tên file
│  ├─ fileSize: dung lượng
│  └─ createdBy: instructor UID
└─ Student có thể download từ FileUrl
```

#### 4. Nhập Danh Sách Học Sinh (CSV)
```
CourseManagementScreen → Students Tab → Import CSV
├─ Tạo file CSV: email, fullName
│  ├─ student1@example.com, Nguyễn Văn A
│  ├─ student2@example.com, Trần Thị B
│  └─ ...
├─ Upload file
├─ Parse CSV → Validate email
└─ Thêm các email vào courses/{courseId}.studentIds array
   └─ Học sinh tự động thấy khóa học trong danh sách
```

#### 5. Tạo Bài Quiz
```
CourseManagementScreen → Quizzes Tab → Create Quiz
├─ Nhập: Tiêu đề, Mô tả, Thời hạn
├─ Thêm câu hỏi (Multiple choice)
│  ├─ Câu hỏi
│  ├─ Các option
│  ├─ Đáp án đúng
│  └─ Điểm
├─ Bấm "Tạo" → Lưu vào courses/{courseId}/quizzes/{quizId}
│  └─ questions: [...]
│  └─ responses: [] (trống ban đầu)
└─ Student làm quiz → Tự động tính điểm
```

#### 6. Tạo Bài Tập
```
CourseManagementScreen → Assignments Tab → Create Assignment
├─ Nhập: Tiêu đề, Mô tả, Deadline
├─ Upload file đề bài (PDF/DOC < 50MB)
│  └─ Lưu vào Firebase Storage
├─ Bấm "Tạo" → Lưu vào courses/{courseId}/assignments/{assignmentId}
│  ├─ fileUrl: Firebase Storage URL
│  ├─ dueDate: deadline
│  └─ submissions: [] (trống ban đầu)
└─ Student xem, tải đề và upload bài làm
```

#### 7. Chấm Điểm & Feedback
```
CourseManagementScreen → Assignments Tab → Submissions
├─ Xem danh sách student đã nộp
│  ├─ Tên student
│  ├─ Thời gian nộp
│  └─ File nộp
├─ Tải file kiểm tra
├─ Nhập điểm + feedback
├─ Bấm "Submit" → Cập nhật vào submissions
│  └─ courses/{courseId}/assignments/{assignmentId}.submissions[i].grade
│  └─ courses/{courseId}/assignments/{assignmentId}.submissions[i].feedback
└─ Student nhận thông báo và xem kết quả
```

#### 8. Xem Analytics
```
CourseManagementScreen → Analytics Tab
├─ Tổng học sinh: count(studentIds)
├─ Quiz completion: % làm quiz
├─ Assignment submission: % nộp bài
├─ Average score: trung bình điểm
└─ Student performance ranking
```

---

## Tính Năng Đã Hoàn Thành ✅

- ✅ Firebase Authentication (Email/Password)
- ✅ User Model với Role (Student/Instructor)
- ✅ Firestore Integration
- ✅ Role-Based Dashboard Routing
- ✅ StudentDashboard với enrolled courses
- ✅ InstructorDashboard với created courses
- ✅ User Drawer với profile info
- ✅ Login/SignUp screens với role selection
- ✅ Error handling & validation (tiếng Việt)

---

## Tính Năng Cần Phát Triển 🔄

### Priority 1 (High)
- [ ] BrowseCoursesScreen (Student duyệt khóa học)
- [ ] Enroll/Unenroll functionality
- [ ] Upload/Download materials
- [ ] CreateCourseScreen (Instructor)

### Priority 2 (Medium)
- [ ] Quiz system (Create, Take, Grade)
- [ ] Assignment system (Upload, Submit, Grade)
- [ ] CSV import students

### Priority 3 (Low)
- [ ] Announcements
- [ ] Discussion forum
- [ ] Push notifications
- [ ] Analytics dashboard
- [ ] Video streaming

---

## File Structure

```
lib/
├── main.dart                          ✅ Role-based routing
├── firebase_options.dart              ✅ Firebase config
│
├── models/
│   ├── user_model.dart                ✅ NEW
│   ├── course.dart                    ✅ Updated
│   ├── material.dart                  🔄 To add
│   ├── assignment.dart                🔄 To add
│   ├── quiz.dart                      🔄 To add
│   └── submission.dart                🔄 To add
│
├── services/
│   ├── auth_service.dart              ✅ Updated
│   ├── firestore_service.dart         ✅ Updated
│   └── storage_service.dart           ✅ Ready
│
├── screens/
│   ├── auth/
│   │   └── login_screen.dart          ✅ In main.dart
│   │
│   ├── student/
│   │   ├── student_dashboard.dart     ✅ In main.dart
│   │   ├── browse_courses_screen.dart 🔄 To add
│   │   ├── course_detail_screen.dart  🔄 To add
│   │   ├── materials_tab.dart         🔄 To add
│   │   ├── assignments_tab.dart       🔄 To add
│   │   ├── quizzes_tab.dart           🔄 To add
│   │   └── quiz_detail_screen.dart    🔄 To add
│   │
│   ├── instructor/
│   │   ├── instructor_dashboard.dart  ✅ In main.dart
│   │   ├── create_course_screen.dart  🔄 To add
│   │   ├── course_management_screen.dart 🔄 To add
│   │   ├── upload_material_screen.dart 🔄 To add
│   │   ├── create_quiz_screen.dart    🔄 To add
│   │   └── manage_assignments_screen.dart 🔄 To add
│   │
│   └── shared/
│       ├── profile_screen.dart        🔄 To add
│       └── settings_screen.dart       🔄 To add
│
├── utils/
│   ├── file_handler.dart              🔄 To add
│   └── csv_handler.dart               🔄 To add
│
├── widgets/
│   ├── course_card.dart               🔄 To add
│   └── assignment_card.dart           🔄 To add
│
└── constants/
    ├── app_colors.dart                🔄 To add
    └── app_strings.dart               🔄 To add

docs/
├── ROLE_BASED_SYSTEM.md               ✅ Created
├── IMPLEMENTATION_GUIDE.md            ✅ Created
├── TEST_GUIDE.md                      ✅ Created
├── FIRESTORE_SETUP.md                 ✅ Created
└── README.md                          ✅ Updated
```

---

## Testing Checklist

### Authentication
- [ ] Student signup with validation
- [ ] Instructor signup with validation
- [ ] Login with correct credentials
- [ ] Error messages (invalid email, weak password, etc)
- [ ] Role persists across app restarts

### Dashboard
- [ ] Student sees StudentDashboard
- [ ] Instructor sees InstructorDashboard
- [ ] Drawer shows correct user info
- [ ] Logout functionality works

### Course Management
- [ ] Student can browse courses
- [ ] Student can enroll in course
- [ ] Instructor can create course
- [ ] Instructor can see created courses
- [ ] Course appears in student's list after enrollment

### File Management
- [ ] Instructor can upload materials (< 50MB)
- [ ] Student can download materials
- [ ] Instructor can create assignments
- [ ] Student can upload submissions (< 50MB, .rar/.zip)

### Quiz & Grading
- [ ] Instructor can create quiz
- [ ] Student can take quiz
- [ ] System calculates score correctly
- [ ] Instructor can grade assignments
- [ ] Student can see grades and feedback

---

## Firestore Security Rules

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // Users - Only user can access their own data
    match /users/{userId} {
      allow read, write: if request.auth.uid == userId;
    }

    // Courses - Public read, instructor write
    match /courses/{courseId} {
      allow read: if true;
      allow write: if request.auth.uid == resource.data.instructorId;
      allow create: if get(/databases/$(database)/documents/users/$(request.auth.uid)).data.role == 'instructor';

      // Subcollections - materials, assignments, quizzes
      match /{subcollection=**} {
        allow read: if request.auth.uid in resource.parent.data.studentIds || 
                       request.auth.uid == resource.parent.data.instructorId;
        allow write: if request.auth.uid == resource.parent.data.instructorId;
      }
    }
  }
}
```

---

## Hướng Dẫn Bắt Đầu

1. **Clone project**
   ```bash
   git clone <repo>
   cd elearningfinal
   ```

2. **Install dependencies**
   ```bash
   flutter pub get
   ```

3. **Configure Firebase**
   ```bash
   flutterfire configure
   ```

4. **Set Firestore Rules** (Dev/Test mode)
   - Firebase Console → Firestore → Rules → Set to allow all

5. **Run app**
   ```bash
   flutter run -d chrome  # Web
   flutter run -d android # Android
   ```

6. **Test authentication**
   - SignUp as Student: test1@example.com / password123
   - SignUp as Instructor: instructor@example.com / password123
   - Login và verify dashboard routing

---

## Liên Hệ & Support

Xem các file documentation chi tiết:
- **ROLE_BASED_SYSTEM.md** - Tổng quan hệ thống
- **IMPLEMENTATION_GUIDE.md** - Chi tiết phát triển từng feature
- **TEST_GUIDE.md** - Hướng dẫn test
- **FIRESTORE_SETUP.md** - Cấu hình Firestore

---

**Last Updated:** 22/01/2025  
**Status:** 🔄 In Development
