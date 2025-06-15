import 'package:cloud_firestore/cloud_firestore.dart';
import '../core/constants/firebase_constants.dart';
import '../models/label_model.dart';
import 'firestore_service.dart';

class LabelService {
  final FirestoreService _firestoreService = FirestoreService();

  // Create a new label
  Future<String> createLabel(LabelModel label) async {
    try {
      final data = label.toMap();
      data[FirebaseConstants.createdAtField] = Timestamp.now();
      return await _firestoreService.createDocument(
        FirebaseConstants.labelsCollection,
        data,
      );
    } catch (e) {
      throw Exception('Failed to create label: $e');
    }
  }

  // Get a label by ID
  Future<LabelModel?> getLabelById(String labelId) async {
    try {
      final data = await _firestoreService.getDocument(
        FirebaseConstants.labelsCollection,
        labelId,
      );
      if (data != null) {
        return LabelModel.fromMap(labelId, data);
      }
      return null;
    } catch (e) {
      throw Exception('Failed to get label: $e');
    }
  }

  // Update a label
  Future<void> updateLabel(String labelId, Map<String, dynamic> updates) async {
    try {
      await _firestoreService.updateDocument(
        FirebaseConstants.labelsCollection,
        labelId,
        updates,
      );
    } catch (e) {
      throw Exception('Failed to update label: $e');
    }
  }

  // Delete a label
  Future<void> deleteLabel(String labelId) async {
    try {
      await _firestoreService.deleteDocument(
        FirebaseConstants.labelsCollection,
        labelId,
      );
    } catch (e) {
      throw Exception('Failed to delete label: $e');
    }
  }

  // Stream labels for a user
  Stream<List<LabelModel>> getLabelsByUser(String userId) {
    try {
      return _firestoreService
          .streamCollection(
            FirebaseConstants.labelsCollection,
            queryBuilder: (query) => query
                .where(FirebaseConstants.createdByField, isEqualTo: userId)
                .orderBy(FirebaseConstants.createdAtField, descending: true),
          )
          .map((snapshot) =>
              snapshot.map((data) => LabelModel.fromMap(data['id'], data)).toList());
    } catch (e) {
      throw Exception('Failed to stream labels: $e');
    }
  }
}