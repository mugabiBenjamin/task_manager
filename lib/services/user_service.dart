import '../core/constants/firebase_constants.dart';
import '../models/user_model.dart';
import 'firestore_service.dart';

class UserService {
  final FirestoreService _firestoreService = FirestoreService();

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
          .map((data) => data != null ? UserModel.fromMap(data['id'], data) : null);
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
                .where(FirebaseConstants.emailField, isGreaterThanOrEqualTo: query)
                .where(FirebaseConstants.emailField, isLessThanOrEqualTo: '$query\uf8ff')
                .limit(10),
          )
          .first;
      return snapshot.map((data) => UserModel.fromMap(data['id'], data)).toList();
    } catch (e) {
      throw Exception('Failed to search users: $e');
    }
  }
}