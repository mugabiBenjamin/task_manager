import 'dart:math';
import '../models/invitation_model.dart';
import '../core/constants/firebase_constants.dart';
import 'firestore_service.dart';
import 'email_service.dart';
import 'user_service.dart';

class InvitationService {
  final FirestoreService _firestoreService = FirestoreService();
  final UserService _userService = UserService();

  // Generate random token for invitation
  String _generateToken() {
    const chars =
        'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    final random = Random.secure();
    return String.fromCharCodes(
      Iterable.generate(
        32,
        (_) => chars.codeUnitAt(random.nextInt(chars.length)),
      ),
    );
  }

  // Send invitation email
  Future<bool> sendInvitation({
    required String email,
    required String invitedBy,
    required String invitedByName,
  }) async {
    try {
      // Check if user already exists
      final existingUsers = await _userService.searchUsers(email);
      if (existingUsers.any(
        (user) => user.email.toLowerCase() == email.toLowerCase(),
      )) {
        throw Exception('User with this email already exists');
      }

      // Check if invitation already sent
      final existingInvitations = await getInvitationsByEmail(email);
      if (existingInvitations.any(
        (inv) => inv.status == InvitationStatus.pending,
      )) {
        throw Exception('Invitation already sent to this email');
      }

      // Create invitation
      final token = _generateToken();
      final invitation = InvitationModel(
        id: '', // Will be set by Firestore
        email: email.toLowerCase().trim(),
        invitedBy: invitedBy,
        invitedByName: invitedByName,
        status: InvitationStatus.pending,
        createdAt: DateTime.now(),
        token: token,
      );

      // Save to Firestore
      final invitationId = await _firestoreService.createDocument(
        'invitations', // Add this to your firebase_constants
        invitation.toMap(),
      );

      // Send email
      final emailSent = await EmailService.sendInvitationEmail(
        recipientEmail: email,
        inviterName: invitedByName,
        inviterEmail: '', // You might want to pass inviter's email
        invitationToken: token,
        appUrl: 'https://yourapp.com', // Replace with your app URL
      );

      if (!emailSent) {
        // If email fails, delete the invitation
        await _firestoreService.deleteDocument('invitations', invitationId);
        throw Exception('Failed to send invitation email');
      }

      return true;
    } catch (e) {
      throw Exception('Failed to send invitation: $e');
    }
  }

  // Get invitations by email
  Future<List<InvitationModel>> getInvitationsByEmail(String email) async {
    try {
      final invitations = await _firestoreService
          .streamCollection(
            'invitations',
            queryBuilder: (query) =>
                query.where('email', isEqualTo: email.toLowerCase().trim()),
          )
          .first;

      return invitations
          .map((data) => InvitationModel.fromMap(data['id'], data))
          .toList();
    } catch (e) {
      throw Exception('Failed to get invitations: $e');
    }
  }

  // Accept invitation and create user account
  Future<bool> acceptInvitation(String token, String displayName) async {
    try {
      // Find invitation by token
      final invitations = await _firestoreService
          .streamCollection(
            'invitations',
            queryBuilder: (query) => query
                .where('token', isEqualTo: token)
                .where('status', isEqualTo: 'pending'),
          )
          .first;

      if (invitations.isEmpty) {
        throw Exception('Invalid or expired invitation');
      }

      final invitationData = invitations.first;
      final invitation = InvitationModel.fromMap(
        invitationData['id'],
        invitationData,
      );

      // Check if invitation is not expired (optional - you can add expiry logic)
      final daysSinceInvitation = DateTime.now()
          .difference(invitation.createdAt)
          .inDays;
      if (daysSinceInvitation > 7) {
        // 7 days expiry
        throw Exception('Invitation has expired');
      }

      // Update invitation status
      await _firestoreService.updateDocument('invitations', invitation.id, {
        'status': InvitationStatus.accepted.value,
        'acceptedAt': DateTime.now(),
      });

      return true;
    } catch (e) {
      throw Exception('Failed to accept invitation: $e');
    }
  }

  // Get pending invitations sent by user
  Stream<List<InvitationModel>> getPendingInvitationsByUser(String userId) {
    return _firestoreService
        .streamCollection(
          'invitations',
          queryBuilder: (query) => query
              .where('invitedBy', isEqualTo: userId)
              .where('status', isEqualTo: 'pending')
              .orderBy('createdAt', descending: true),
        )
        .map(
          (invitations) => invitations
              .map((data) => InvitationModel.fromMap(data['id'], data))
              .toList(),
        );
  }

  // Get users available for assignment (registered users + accepted invitations)
  Future<List<Map<String, dynamic>>> getUsersAvailableForAssignment(
    String searchQuery,
  ) async {
    try {
      final List<Map<String, dynamic>> availableUsers = [];

      // Get registered users
      final registeredUsers = await _userService.searchUsers(searchQuery);
      for (final user in registeredUsers) {
        availableUsers.add({
          'id': user.id,
          'email': user.email,
          'displayName': user.displayName,
          'isRegistered': true,
        });
      }

      // Get accepted invitations (users who accepted but haven't registered yet)
      if (searchQuery.isNotEmpty) {
        final acceptedInvitations = await _firestoreService
            .streamCollection(
              'invitations',
              queryBuilder: (query) => query
                  .where('status', isEqualTo: 'accepted')
                  .where(
                    'email',
                    isGreaterThanOrEqualTo: searchQuery.toLowerCase(),
                  )
                  .where(
                    'email',
                    isLessThanOrEqualTo: '${searchQuery.toLowerCase()}\uf8ff',
                  ),
            )
            .first;

        for (final invitationData in acceptedInvitations) {
          final invitation = InvitationModel.fromMap(
            invitationData['id'],
            invitationData,
          );
          // Check if this email is not already in registered users
          if (!availableUsers.any(
            (user) => user['email'] == invitation.email,
          )) {
            availableUsers.add({
              'id':
                  invitation.email, // Use email as ID for non-registered users
              'email': invitation.email,
              'displayName': invitation.email.split(
                '@',
              )[0], // Use email prefix as display name
              'isRegistered': false,
            });
          }
        }
      }

      return availableUsers;
    } catch (e) {
      throw Exception('Failed to get available users: $e');
    }
  }
}
