# 🎓 E-Learning Platform

A comprehensive Flutter-based Learning Management System (LMS) with Firebase backend, supporting role-based access for Students and Instructors.

## ✨ Features

### 👨‍🎓 Student Features
- ✅ Browse and enroll in courses
- ✅ View course materials (PDF, DOC, DOCX)
- ✅ Submit assignments with file uploads
- ✅ Take quizzes with auto-grading
- ✅ View grades and feedback
- ✅ Participate in course discussions
- ✅ Favorite courses

### 👨‍🏫 Instructor Features
- ✅ Create and manage courses
- ✅ Upload course materials
- ✅ Create assignments with file attachments
- ✅ Create quizzes with multiple-choice questions
- ✅ Grade student submissions
- ✅ Import student lists via CSV
- ✅ Manage enrolled students
- ✅ View quiz responses and analytics

### 🔧 Technical Features
- ✅ Firebase Authentication (Email/Password)
- ✅ Cloud Firestore for real-time data
- ✅ Firebase Storage for file uploads
- ✅ Role-based access control (Student/Instructor)
- ✅ Real-time updates with StreamBuilder
- ✅ Responsive Material Design UI
- ✅ Vietnamese language support

## 🚀 Getting Started

### Prerequisites

- Flutter SDK (^3.9.0)
- Firebase account
- Dart SDK

### Installation

1. **Clone the repository**
   ```bash
   git clone <your-repo-url>
   cd elearningfinal
   ```

2. **Install dependencies**
   ```bash
   flutter pub get
   ```

3. **Configure Firebase**
   ```bash
   # Install FlutterFire CLI
   dart pub global activate flutterfire_cli
   
   # Configure Firebase for your project
   flutterfire configure
   ```

4. **Setup Firestore Security Rules**
   - Go to Firebase Console → Firestore → Rules
   - Use the rules from `firestore.rules` file

5. **Setup Storage Security Rules**
   - Go to Firebase Console → Storage → Rules
   - Use the rules from `storage.rules` file

6. **Run the app**
   ```bash
   flutter run -d chrome    # Web
   flutter run -d android   # Android
   flutter run -d windows   # Windows
   ```

## 📁 Project Structure

```
lib/
├── main.dart                    # App entry point
├── firebase_options.dart        # Firebase configuration
├── models/                      # Data models
│   ├── user_model.dart
│   ├── course.dart
│   ├── assignment_model.dart
│   ├── quiz_model.dart
│   ├── material_model.dart
│   └── comment_model.dart
├── services/                    # Business logic
│   ├── auth_service.dart
│   ├── firestore_service.dart
│   └── storage_service.dart
├── screens/                     # UI screens
│   ├── auth/
│   ├── student/
│   ├── instructor/
│   ├── course/
│   └── profile/
├── widgets/                     # Reusable widgets
│   ├── common/
│   └── course/
└── utils/                       # Utilities
    ├── app_theme.dart
    ├── csv_handler.dart
    └── file_handler.dart
```

## 🛠️ Technologies Used

- **Flutter** - UI framework
- **Firebase Auth** - Authentication
- **Cloud Firestore** - NoSQL database
- **Firebase Storage** - File storage
- **Material Design** - UI components

## 📦 Key Dependencies

```yaml
dependencies:
  firebase_core: ^4.2.1
  cloud_firestore: ^6.1.0
  firebase_auth: ^6.1.2
  firebase_storage: ^13.0.4
  file_picker: ^10.3.7
  csv: ^6.0.0
  url_launcher: ^6.1.10
  timeago: ^3.7.0
```

## 🎯 Usage

### For Students
1. Sign up with email and select "Student" role
2. Browse available courses
3. Enroll in courses
4. Access materials, submit assignments, take quizzes
5. View grades and participate in discussions

### For Instructors
1. Sign up with email and select "Instructor" role
2. Create new courses
3. Upload materials and create assignments/quizzes
4. Import student lists via CSV
5. Grade submissions and view analytics

## 🌐 Live Demo

**Deployed on Firebase Hosting:** [https://elearnng-v2.web.app](https://elearnng-v2.web.app)

## 📸 Screenshots

*(Add screenshots here)*

## 🤝 Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

## 📄 License

This project is licensed under the MIT License.

## 👥 Team

Dai Tuan Kiet - 521C0008 from Ton Duc Thang University

## 📞 Contact

For questions or support, please contact: *daituankiet69@gmail.com*

---

Made with ❤️ using Flutter and Firebase
