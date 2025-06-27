import 'package:cloud_firestore/cloud_firestore.dart';
import '../core/constants/firebase_constants.dart';
import '../models/user_model.dart';
import 'firestore_service.dart';
import 'invitation_service.dart';

class UserService {
  final FirestoreService _firestoreService = FirestoreService();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  InvitationService? _invitationService;

  UserService({InvitationService? invitationService})
    : _invitationService = invitationService;

  void setInvitationService(InvitationService invitationService) {
    _invitationService = invitationService;
  }

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

  // Get users available for task assignment
  Future<List<Map<String, dynamic>>> getAvailableUsersForTask(
    String searchQuery,
  ) async {
    try {
      final List<Map<String, dynamic>> availableUsers = [];

      // Get registered users
      final registeredUsers = await searchUsers(searchQuery);
      for (final user in registeredUsers) {
        availableUsers.add({
          'id': user.id,
          'email': user.email,
          'displayName': user.displayName,
          'isRegistered': true,
        });
      }

      // Add null check before using _invitationService
      if (_invitationService != null) {
        final acceptedUsers = await _invitationService!
            .getUsersAvailableForAssignment(searchQuery);
        for (final user in acceptedUsers) {
          if (!availableUsers.any((u) => u['email'] == user['email'])) {
            availableUsers.add(user);
          }
        }
      }

      return availableUsers;
    } catch (e) {
      throw Exception('Failed to get available users for task: $e');
    }
  }

  // Update email notification preference
  Future<void> updateEmailNotificationPreference(
    String userId,
    bool enabled,
  ) async {
    try {
      await updateUser(userId, {'emailNotifications': enabled});
    } catch (e) {
      throw Exception('Failed to update email preferences: $e');
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

  // Create user document
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

  // Get or create user
  Future<UserModel?> getOrCreateUser(
    String userId,
    String email,
    String displayName,
  ) async {
    try {
      final existingUser = await getUserById(userId);
      if (existingUser != null) {
        return existingUser;
      }
      return await createUserDocument(userId, email, displayName);
    } catch (e) {
      throw Exception('Failed to get or create user: $e');
    }
  }

  // Delete user
  Future<void> deleteUser(String userId) async {
    try {
      final batch = _firestore.batch();
      final userDoc = _firestore
          .collection(FirebaseConstants.usersCollection)
          .doc(userId);
      batch.delete(userDoc);

      final tasksQuery = await _firestore
          .collection(FirebaseConstants.tasksCollection)
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
