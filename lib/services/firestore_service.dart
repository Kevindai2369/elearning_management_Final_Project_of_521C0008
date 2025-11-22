import 'package:cloud_firestore/cloud_firestore.dart';

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // Read a document once
  Future<DocumentSnapshot<Map<String, dynamic>>> getDoc(
      String collection, String docId) async {
    return await _db.collection(collection).doc(docId).get();
  }

  // Stream a collection
  Stream<QuerySnapshot<Map<String, dynamic>>> streamCollection(
      String collection) {
    return _db.collection(collection).snapshots();
  }

  // Create or update a document
  Future<void> setDoc(String collection, String docId, Map<String, dynamic> data,
      {bool merge = false}) async {
    await _db.collection(collection).doc(docId).set(data, SetOptions(merge: merge));
  }

  // Add a new document with generated id
  Future<DocumentReference<Map<String, dynamic>>> addDoc(
      String collection, Map<String, dynamic> data) async {
    return await _db.collection(collection).add(data);
  }
}
