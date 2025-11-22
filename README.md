# elearningfinal

A new Flutter project.

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Lab: Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Cookbook: Useful Flutter samples](https://docs.flutter.dev/cookbook)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.

## Firebase setup (Firestore, Authentication, Storage)

This project includes example service wrappers in `lib/services/` for:

- Authentication: `lib/services/auth_service.dart`
- Firestore database: `lib/services/firestore_service.dart`
- Storage: `lib/services/storage_service.dart`

Follow these steps to configure Firebase for this project:

1. Install FlutterFire CLI (if you haven't):

	```powershell
	dart pub global activate flutterfire_cli
	```

2. Add Firebase dependencies (already added to `pubspec.yaml`):

	- `firebase_core`
	- `cloud_firestore`
	- `firebase_auth`
	- `firebase_storage`

	Then run:

	```powershell
	flutter pub get
	```

3. Configure Firebase for your project using FlutterFire CLI. From the project root run:

	```powershell
	flutterfire configure
	```

	This will guide you to select your Firebase project and generate
	`lib/firebase_options.dart` with the correct `FirebaseOptions` for each platform.

4. Android and iOS platform files

	- Android: put the downloaded `google-services.json` in `android/app/`.
	  Ensure `android/build.gradle` and `android/app/build.gradle` include the
	  Google services plugin as documented by Firebase (the FlutterFire CLI
	  automates most of this).

	- iOS: put the downloaded `GoogleService-Info.plist` in `ios/Runner/`.

5. Run the app:

	```powershell
	flutter run
	```

Notes:

- I added a small stub `lib/firebase_options.dart` that will throw a clear
  error if you haven't generated the real file yet — run `flutterfire configure` to
  generate it.
- After configuration, `main()` will initialize Firebase at startup.
- The services are minimal examples; adapt them to your app's error handling,
  authentication flows, and security rules.

If you want, tôi có thể tiếp tục và: 

- Thêm ví dụ màn hình đăng nhập/đăng ký sử dụng `AuthService`.
- Thêm ví dụ đọc/ghi tài liệu Firestore trong UI.
- Thêm ví dụ upload file lên Storage (với chọn file từ thiết bị).

Cho tôi biết bạn muốn mình làm tiếp phần nào nhé.
