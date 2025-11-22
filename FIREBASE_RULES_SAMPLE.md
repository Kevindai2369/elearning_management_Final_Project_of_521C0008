Firestore rules (example)

These rules are suggestions — copy them into the Firebase Console > Firestore > Rules and adapt to your project structure and testing requirements.

// Firestore rules (start)
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {

    // Users: users can read their own profile, and authenticated users can read basic profiles
    match /users/{userId} {
      allow read: if request.auth != null;
      allow write: if request.auth != null && request.auth.uid == userId;
    }

    // Courses: public read, instructors can write their own courses
    match /courses/{courseId} {
      allow read: if true;
      allow create: if request.auth != null && request.auth.token.email_verified == true; // optional
      allow update: if request.auth != null && resource.data.instructorId == request.auth.uid;
      allow delete: if request.auth != null && resource.data.instructorId == request.auth.uid;

      // assignments subcollection
      match /assignments/{assignmentId} {
        allow read: if request.auth != null;

        // Allow instructor (owner) to create/update/delete assignment
        allow create: if request.auth != null && get(/databases/$(database)/documents/courses/$(courseId)).data.instructorId == request.auth.uid;
        allow update: if request.auth != null && get(/databases/$(database)/documents/courses/$(courseId)).data.instructorId == request.auth.uid;
        allow delete: if request.auth != null && get(/databases/$(database)/documents/courses/$(courseId)).data.instructorId == request.auth.uid;

        // Allow students to submit: writes only to submissions.<theirUid> map entry
        // and only if they are enrolled in the course. Instructors (owner) can update for grading.
        allow update: if request.auth != null && (
          // instructor may update (grading)
          (get(/databases/$(database)/documents/courses/$(courseId)).data.instructorId == request.auth.uid)
          ||
          // student: must be enrolled and only modify their own submission entry
          (
            request.resource.data.keys().hasAny(['submissions'])
            && (request.auth.uid in get(/databases/$(database)/documents/courses/$(courseId)).data.studentIds)
            && request.resource.data.submissions[request.auth.uid] == request.resource.data.submissions[request.auth.uid]
          )
        );
      }

      // materials subcollection
      match /materials/{materialId} {
        allow read: if request.auth != null;
        allow write: if request.auth != null && get(/databases/$(database)/documents/courses/$(courseId)).data.instructorId == request.auth.uid;
      }
    }
  }
}

Storage rules (example)

rules_version = '2';
service firebase.storage {
  match /b/{bucket}/o {
    // Submissions: only authenticated users can upload to their own submission path and instructors can read
    match /submissions/{courseId}/{assignmentId}/{fileName} {
      // Allow read to authenticated users (instructors and students)
      allow read: if request.auth != null;
      // Allow write only for authenticated users whose UID matches the filename prefix (we store files as '{uid}_{timestamp}.ext')
      allow write: if request.auth != null && fileName.startsWith(request.auth.uid + '_');
      // Note: Storage rules cannot inspect Firestore documents. Enrollment checks should be enforced in Firestore rules above.
    }
  }
}

Notes:
- These are templates. Firestore rules use path-based checks and `get()` to load sibling documents; adjust paths to your exact structure.
- Test thoroughly in the Firebase Rules simulator and staging environment before deploying to production.
- Consider adding validation (file size, MIME) using custom claims or Cloud Functions for strict enforcement.
