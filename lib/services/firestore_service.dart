import 'package:cloud_firestore/cloud_firestore.dart';
import '../core/constants/firebase_constants.dart';

class FirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Get a collection reference
  CollectionReference _getCollection(String collectionPath) {
    return _firestore.collection(collectionPath);
  }

  // Create a document with auto-generated ID
  Future<String> createDocument(
    String collectionPath,
    Map<String, dynamic> data,
  ) async {
    try {
      final docRef = await _getCollection(collectionPath).add(data);
      return docRef.id;
    } catch (e) {
      throw Exception('Failed to create document in $collectionPath: $e');
    }
  }

  // Create or update a document with specific ID
  Future<void> setDocument(
    String collectionPath,
    String documentId,
    Map<String, dynamic> data,
  ) async {
    try {
      await _getCollection(collectionPath).doc(documentId).set(data);
    } catch (e) {
      throw Exception(
        'Failed to set document $documentId in $collectionPath: $e',
      );
    }
  }

  // Read a document by ID
  Future<Map<String, dynamic>?> getDocument(
    String collectionPath,
    String documentId,
  ) async {
    try {
      final doc = await _getCollection(collectionPath).doc(documentId).get();
      return doc.exists ? doc.data() as Map<String, dynamic> : null;
    } catch (e) {
      throw Exception(
        'Failed to get document $documentId from $collectionPath: $e',
      );
    }
  }

  // Update a document
  Future<void> updateDocument(
    String collectionPath,
    String documentId,
    Map<String, dynamic> data,
  ) async {
    try {
      data[FirebaseConstants.updatedAtField] = Timestamp.now();
      await _getCollection(collectionPath).doc(documentId).update(data);
    } catch (e) {
      throw Exception(
        'Failed to update document $documentId in $collectionPath: $e',
      );
    }
  }

  // Delete a document
  Future<void> deleteDocument(String collectionPath, String documentId) async {
    try {
      await _getCollection(collectionPath).doc(documentId).delete();
    } catch (e) {
      throw Exception(
        'Failed to delete document $documentId from $collectionPath: $e',
      );
    }
  }

  // Stream a collection
  Stream<List<Map<String, dynamic>>> streamCollection(
    String collectionPath, {
    Query Function(Query)? queryBuilder,
  }) {
    try {
      Query query = _getCollection(collectionPath);
      if (queryBuilder != null) {
        query = queryBuilder(query);
      }
      return query.snapshots().map(
        (snapshot) => snapshot.docs
            .map((doc) => {...doc.data() as Map<String, dynamic>, 'id': doc.id})
            .toList(),
      );
    } catch (e) {
      throw Exception('Failed to stream collection $collectionPath: $e');
    }
  }

  // Stream a document
  Stream<Map<String, dynamic>?> streamDocument(
    String collectionPath,
    String documentId,
  ) {
    try {
      return _getCollection(collectionPath)
          .doc(documentId)
          .snapshots()
          .map(
            (doc) => doc.exists
                ? {...doc.data() as Map<String, dynamic>, 'id': doc.id}
                : null,
          );
    } catch (e) {
      throw Exception(
        'Failed to stream document $documentId from $collectionPath: $e',
      );
    }
  }
}
