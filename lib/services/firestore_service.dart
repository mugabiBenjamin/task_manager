import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../core/constants/firebase_constants.dart';
import '../core/enums/invitation_status.dart';

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
      if (collectionPath == FirebaseConstants.invitationsCollection) {
        if (data['status'] == InvitationStatus.pending.value &&
            data['expiresAt'] == null) {
          if (kDebugMode) {
            print(
              'Error: expiresAt is null for pending invitation in $collectionPath',
            );
          }
          throw Exception('expiresAt must be set for pending invitations');
        }
      }
      if (kDebugMode) {
        print('Creating document in $collectionPath with data: $data');
      }
      final docRef = await _getCollection(collectionPath).add(data);
      final docId = docRef.id;
      final createdDoc = await getDocument(collectionPath, docId);
      if (createdDoc == null) {
        throw Exception('Failed to verify created document: $docId');
      }
      if (collectionPath == FirebaseConstants.invitationsCollection) {
        if (createdDoc['expiresAt'] == null &&
            createdDoc['status'] == InvitationStatus.pending.value) {
          if (kDebugMode) {
            print('Warning: expiresAt is null in created document: $docId');
          }
          throw Exception(
            'Failed to write expiresAt field for document: $docId',
          );
        }
        if (kDebugMode) {
          print(
            'Verified document $docId with expiresAt: ${createdDoc['expiresAt']}',
          );
        }
      }
      return docId;
    } catch (e) {
      if (e.toString().contains('permission-denied')) {
        if (kDebugMode) {
          print(
            'Permission denied when creating document in $collectionPath: $e',
          );
        }
        throw Exception(
          'Permission denied: Unable to create document in $collectionPath. Check Firestore security rules.',
        );
      }
      if (kDebugMode) {
        print('Failed to create document in $collectionPath: $e');
      }
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
      if (collectionPath == FirebaseConstants.invitationsCollection) {
        if (data['status'] == InvitationStatus.pending.value &&
            data['expiresAt'] == null) {
          if (kDebugMode) {
            print(
              'Error: expiresAt is null for pending invitation $documentId in $collectionPath',
            );
          }
          throw Exception('expiresAt must be set for pending invitations');
        }
      }
      if (kDebugMode) {
        print(
          'Setting document $documentId in $collectionPath with data: $data',
        );
      }
      await _getCollection(collectionPath).doc(documentId).set(data);
      if (collectionPath == FirebaseConstants.invitationsCollection) {
        final updatedDoc = await getDocument(collectionPath, documentId);
        if (updatedDoc == null) {
          throw Exception('Failed to verify set document: $documentId');
        }
        if (kDebugMode) {
          print('Verified set document $documentId with data: $updatedDoc');
        }
      }
    } catch (e) {
      if (e.toString().contains('permission-denied')) {
        if (kDebugMode) {
          print(
            'Permission denied when setting document $documentId in $collectionPath: $e',
          );
        }
        throw Exception(
          'Permission denied: Unable to set document $documentId in $collectionPath. Check Firestore security rules.',
        );
      }
      if (kDebugMode) {
        print('Failed to set document $documentId in $collectionPath: $e');
      }
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
      if (kDebugMode) {
        print(
          'Retrieved document $documentId from $collectionPath: ${doc.exists ? doc.data() : null}',
        );
      }
      return doc.exists ? doc.data() as Map<String, dynamic> : null;
    } catch (e) {
      if (e.toString().contains('permission-denied')) {
        if (kDebugMode) {
          print(
            'Permission denied when getting document $documentId from $collectionPath: $e',
          );
        }
        throw Exception(
          'Permission denied: Unable to get document $documentId from $collectionPath. Check Firestore security rules.',
        );
      }
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
      if (collectionPath == FirebaseConstants.invitationsCollection) {
        if (data['status'] == InvitationStatus.pending.value &&
            data['expiresAt'] == null) {
          if (kDebugMode) {
            print(
              'Error: expiresAt is null for pending invitation $documentId in $collectionPath',
            );
          }
          throw Exception('expiresAt must be set for pending invitations');
        }
      }
      if (kDebugMode) {
        print(
          'Updating document $documentId in $collectionPath with data: $data',
        );
      }
      await _getCollection(collectionPath).doc(documentId).update(data);
      if (collectionPath == FirebaseConstants.invitationsCollection) {
        final updatedDoc = await getDocument(collectionPath, documentId);
        if (updatedDoc == null) {
          throw Exception('Failed to verify updated document: $documentId');
        }
        if (kDebugMode) {
          print('Verified updated document $documentId with data: $updatedDoc');
        }
      }
    } catch (e) {
      if (e.toString().contains('permission-denied')) {
        if (kDebugMode) {
          print(
            'Permission denied when updating document $documentId in $collectionPath: $e',
          );
        }
        throw Exception(
          'Permission denied: Unable to update document $documentId in $collectionPath. Check Firestore security rules.',
        );
      }
      if (kDebugMode) {
        print('Failed to update document $documentId in $collectionPath: $e');
      }
      throw Exception(
        'Failed to update document $documentId in $collectionPath: $e',
      );
    }
  }

  // Delete a document
  Future<void> deleteDocument(String collectionPath, String documentId) async {
    try {
      if (kDebugMode) {
        print('Deleting document $documentId from $collectionPath');
      }
      await _getCollection(collectionPath).doc(documentId).delete();
    } catch (e) {
      if (e.toString().contains('permission-denied')) {
        if (kDebugMode) {
          print(
            'Permission denied when deleting document $documentId from $collectionPath: $e',
          );
        }
        throw Exception(
          'Permission denied: Unable to delete document $documentId from $collectionPath. Check Firestore security rules.',
        );
      }
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
      if (kDebugMode) {
        print('Streaming collection: $collectionPath');
      }
      return query.snapshots().map((snapshot) {
        final docs = snapshot.docs
            .map((doc) => {...doc.data() as Map<String, dynamic>, 'id': doc.id})
            .toList();
        if (kDebugMode) {
          print('Streamed ${docs.length} documents from $collectionPath');
        }
        return docs;
      });
    } catch (e) {
      if (e.toString().contains('permission-denied')) {
        if (kDebugMode) {
          print(
            'Permission denied when streaming collection $collectionPath: $e',
          );
        }
        throw Exception(
          'Permission denied: Unable to stream collection $collectionPath. Check Firestore security rules.',
        );
      }
      throw Exception('Failed to stream collection $collectionPath: $e');
    }
  }

  // Stream a document
  Stream<Map<String, dynamic>?> streamDocument(
    String collectionPath,
    String documentId,
  ) {
    try {
      if (kDebugMode) {
        print('Streaming document $documentId from $collectionPath');
      }
      return _getCollection(collectionPath).doc(documentId).snapshots().map((
        doc,
      ) {
        final data = doc.exists
            ? {...doc.data() as Map<String, dynamic>, 'id': doc.id}
            : null;
        if (kDebugMode) {
          print('Streamed document $documentId: $data');
        }
        return data;
      });
    } catch (e) {
      if (e.toString().contains('permission-denied')) {
        if (kDebugMode) {
          print(
            'Permission denied when streaming document $documentId from $collectionPath: $e',
          );
        }
        throw Exception(
          'Permission denied: Unable to stream document $documentId from $collectionPath. Check Firestore security rules.',
        );
      }
      throw Exception(
        'Failed to stream document $documentId from $collectionPath: $e',
      );
    }
  }

  Future<void> cleanupInvalidInvitations() async {
    try {
      final invalidInvitations = await _firestore
          .collection(FirebaseConstants.invitationsCollection)
          .where('status', isEqualTo: InvitationStatus.pending.value)
          .where('expiresAt', isNull: true)
          .get();

      if (kDebugMode) {
        print(
          'Found ${invalidInvitations.docs.length} invalid pending invitations with null expiresAt',
        );
      }

      for (final doc in invalidInvitations.docs) {
        final docId = doc.id;
        if (kDebugMode) {
          print('Cleaning up invalid invitation: $docId');
        }
        await _firestore
            .collection(FirebaseConstants.invitationsCollection)
            .doc(docId)
            .delete();
        if (kDebugMode) {
          print('Deleted invalid invitation: $docId');
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('Failed to cleanup invalid invitations: $e');
      }
      throw Exception('Failed to cleanup invalid invitations: $e');
    }
  }
}
