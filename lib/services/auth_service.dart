import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Sign in with email & password
  Future<UserCredential> signIn(String email, String password) async {
    return await _auth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
  }

  // Create account with email & password (lưu role)
  Future<UserCredential> signUp(
    String email,
    String password,
    String fullName,
    String role, // 'student' hoặc 'instructor'
  ) async {
    final userCredential = await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );

    // Lưu thông tin user vào Firestore
    await _firestore.collection('users').doc(userCredential.user!.uid).set({
      'email': email,
      'fullName': fullName,
      'role': role,
      'createdAt': DateTime.now().toIso8601String(),
      'avatarUrl': null,
    });

    return userCredential;
  }

  // Sign out
  Future<void> signOut() async {
    await _auth.signOut();
  }

  // Get current user
  User? get currentUser => _auth.currentUser;

  // Stream của current auth state
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // Lấy thông tin user từ Firestore
  Future<Map<String, dynamic>?> getUserData(String uid) async {
    try {
      final doc = await _firestore.collection('users').doc(uid).get();
      return doc.data();
    } catch (e) {
      debugPrint('Error getting user data: $e');
      return null;
    }
  }

  // Stream user data (để watch changes)
  Stream<Map<String, dynamic>?> getUserDataStream(String uid) {
    return _firestore.collection('users').doc(uid).snapshots().map((doc) => doc.data());
  }
}
