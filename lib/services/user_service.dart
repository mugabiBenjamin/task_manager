import 'package:cloud_firestore/cloud_firestore.dart';
import '../core/constants/firebase_constants.dart';
import '../models/user_model.dart';
import 'firestore_service.dart';

class UserService {
  final FirestoreService _firestoreService = FirestoreService();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Get user by ID
  Future<UserModel?> getUserById(String userId) async {
    try {
      final data = await _firestoreService.getDocument(
        FirebaseConstants.usersCollection,
        userId,
      );
      if (data != null) {
        return UserModel.fromMap(userId, data);
      }
      return null;
    } catch (e) {
      throw Exception('Failed to get user: $e');
    }
  }

  // Update user profile
  Future<void> updateUser(String userId, Map<String, dynamic> updates) async {
    try {
      await _firestoreService.updateDocument(
        FirebaseConstants.usersCollection,
        userId,
        updates,
      );
    } catch (e) {
      throw Exception('Failed to update user: $e');
    }
  }

  // Get multiple users by IDs
  Future<List<UserModel>> getUsersByIds(List<String> userIds) async {
    try {
      final List<UserModel> users = [];
      for (String userId in userIds) {
        final user = await getUserById(userId);
        if (user != null) {
          users.add(user);
        }
      }
      return users;
    } catch (e) {
      throw Exception('Failed to get users: $e');
    }
  }

  // Stream user data
  Stream<UserModel?> getUserStream(String userId) {
    try {
      return _firestoreService
          .streamDocument(FirebaseConstants.usersCollection, userId)
          .map(
            (data) => data != null ? UserModel.fromMap(data['id'], data) : null,
          );
    } catch (e) {
      throw Exception('Failed to stream user: $e');
    }
  }

  // Search users by email or display name
  Future<List<UserModel>> searchUsers(String query) async {
    try {
      final snapshot = await _firestoreService
          .streamCollection(
            FirebaseConstants.usersCollection,
            queryBuilder: (q) => q
                .where(
                  FirebaseConstants.emailField,
                  isGreaterThanOrEqualTo: query,
                )
                .where(
                  FirebaseConstants.emailField,
                  isLessThanOrEqualTo: '$query\uf8ff',
                )
                .limit(10),
          )
          .first;
      return snapshot
          .map((data) => UserModel.fromMap(data['id'], data))
          .toList();
    } catch (e) {
      throw Exception('Failed to search users: $e');
    }
  }

  Future<UserModel> createUserDocument(
    String userId,
    String email,
    String displayName,
  ) async {
    try {
      final userData = {
        'email': email,
        'displayName': displayName,
        'createdAt': Timestamp.now(),
        'isEmailVerified': false,
      };

      await _firestoreService.setDocument(
        FirebaseConstants.usersCollection,
        userId,
        userData,
      );

      return UserModel.fromMap(userId, userData);
    } catch (e) {
      throw Exception('Failed to create user document: $e');
    }
  }

  Future<UserModel?> getOrCreateUser(
    String userId,
    String email,
    String displayName,
  ) async {
    try {
      // Try to get existing user first
      final existingUser = await getUserById(userId);
      if (existingUser != null) {
        return existingUser;
      }

      // Create new user document if doesn't exist
      return await createUserDocument(userId, email, displayName);
    } catch (e) {
      throw Exception('Failed to get or create user: $e');
    }
  }

  Future<void> deleteUser(String userId) async {
    try {
      final batch = _firestore.batch();

      // Delete user document
      final userDoc = _firestore
          .collection(FirebaseConstants.usersCollection)
          .doc(userId);
      batch.delete(userDoc);

      // Delete user's tasks (if you have tasks collection)
      final tasksQuery = await _firestore
          .collection('tasks')
          .where('createdBy', isEqualTo: userId)
          .get();

      for (var doc in tasksQuery.docs) {
        batch.delete(doc.reference);
      }

      await batch.commit();
    } catch (e) {
      throw Exception('Failed to delete user data: $e');
    }
  }
}
