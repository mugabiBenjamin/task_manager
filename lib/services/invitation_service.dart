import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../core/constants/firebase_constants.dart';
import '../models/invitation_model.dart';
import 'firestore_service.dart';
import 'email_service.dart';
import 'user_service.dart';

class InvitationService {
  final FirestoreService _firestoreService = FirestoreService();
  UserService? _userService;

  InvitationService({UserService? userService}) : _userService = userService;

  void setUserService(UserService userService) {
    _userService = userService;
  }

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

  // Send invitation email with EmailJS
  Future<bool> sendInvitation({
    required String email,
    required String invitedBy,
    required String invitedByName,
    required String inviterEmail,
  }) async {
    try {
      if (_userService != null) {
        final existingUsers = await _userService!.searchUsers(email);
        if (existingUsers.any(
          (user) => user.email.toLowerCase() == email.toLowerCase(),
        )) {
          throw Exception('User with this email already exists');
        }
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
        id: '',
        email: email.toLowerCase().trim(),
        invitedBy: invitedBy,
        invitedByName: invitedByName,
        status: InvitationStatus.pending,
        createdAt: DateTime.now(),
        token: token,
      );

      // Save to Firestore
      final invitationId = await _firestoreService.createDocument(
        FirebaseConstants.invitationsCollection,
        invitation.toMap(),
      );

      // Send email via EmailJS
      final verificationLink =
          'https://task-manager-1763e.web.app/accept-invitation?token=$token';
      final emailSent = await EmailService.sendInvitationEmail(
        recipientEmail: email,
        inviterName: invitedByName,
        inviterEmail: inviterEmail,
        invitationToken: token,
        verificationLink: verificationLink,
      );

      if (!emailSent) {
        await _firestoreService.deleteDocument(
          FirebaseConstants.invitationsCollection,
          invitationId,
        );
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
            FirebaseConstants.invitationsCollection,
            queryBuilder: (query) => query.where(
              FirebaseConstants.emailField,
              isEqualTo: email.toLowerCase().trim(),
            ),
          )
          .first;

      return invitations
          .map((data) => InvitationModel.fromMap(data['id'], data))
          .toList();
    } catch (e) {
      throw Exception('Failed to get invitations: $e');
    }
  }

  // Accept invitation
  Future<bool> acceptInvitation(String token, String displayName) async {
    try {
      final invitations = await _firestoreService
          .streamCollection(
            FirebaseConstants.invitationsCollection,
            queryBuilder: (query) => query
                .where('token', isEqualTo: token)
                .where(
                  FirebaseConstants.statusField,
                  isEqualTo: InvitationStatus.pending.value,
                ),
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

      // Check invitation expiry (7 days)
      final daysSinceInvitation = DateTime.now()
          .difference(invitation.createdAt)
          .inDays;
      if (daysSinceInvitation > 7) {
        throw Exception('Invitation has expired');
      }

      // Update invitation status
      await _firestoreService.updateDocument(
        FirebaseConstants.invitationsCollection,
        invitation.id,
        {
          FirebaseConstants.statusField: InvitationStatus.accepted.value,
          'acceptedAt': Timestamp.fromDate(DateTime.now()),
        },
      );

      // Create user document if not exists
      await _userService?.getOrCreateUser(
        invitation.email, // Use email as temporary ID
        invitation.email,
        displayName,
      );

      if (_userService != null) {
        await _userService!.getOrCreateUser(
          invitation.email,
          invitation.email,
          displayName,
        );
      }

      return true;
    } catch (e) {
      throw Exception('Failed to accept invitation: $e');
    }
  }

  // Get pending invitations sent by user
  Stream<List<InvitationModel>> getPendingInvitationsByUser(String userId) {
    return _firestoreService
        .streamCollection(
          FirebaseConstants.invitationsCollection,
          queryBuilder: (query) => query
              .where(FirebaseConstants.invitedByField, isEqualTo: userId)
              .where(
                FirebaseConstants.statusField,
                isEqualTo: InvitationStatus.pending.value,
              )
              .orderBy(FirebaseConstants.createdAtField, descending: true),
        )
        .map(
          (invitations) => invitations
              .map((data) => InvitationModel.fromMap(data['id'], data))
              .toList(),
        );
  }

  // Get users available for assignment
  Future<List<Map<String, dynamic>>> getUsersAvailableForAssignment(
    String searchQuery,
  ) async {
    try {
      final List<Map<String, dynamic>> availableUsers = [];

      if (_userService != null) {
        final registeredUsers = await _userService!.searchUsers(searchQuery);
        for (final user in registeredUsers) {
          availableUsers.add({
            'id': user.id,
            'email': user.email,
            'displayName': user.displayName,
            'isRegistered': true,
          });
        }
      }

      // Get registered users
      final registeredUsers =
          await _userService?.searchUsers(searchQuery) ?? [];
      for (final user in registeredUsers) {
        availableUsers.add({
          'id': user.id,
          'email': user.email,
          'displayName': user.displayName,
          'isRegistered': true,
        });
      }

      // Get accepted invitations
      if (searchQuery.isNotEmpty) {
        final acceptedInvitations = await _firestoreService
            .streamCollection(
              FirebaseConstants.invitationsCollection,
              queryBuilder: (query) => query
                  .where(
                    FirebaseConstants.statusField,
                    isEqualTo: InvitationStatus.accepted.value,
                  )
                  .where(
                    FirebaseConstants.emailField,
                    isGreaterThanOrEqualTo: searchQuery.toLowerCase(),
                  )
                  .where(
                    FirebaseConstants.emailField,
                    isLessThanOrEqualTo: '${searchQuery.toLowerCase()}\uf8ff',
                  ),
            )
            .first;

        for (final invitationData in acceptedInvitations) {
          final invitation = InvitationModel.fromMap(
            invitationData['id'],
            invitationData,
          );
          if (!availableUsers.any(
            (user) => user['email'] == invitation.email,
          )) {
            availableUsers.add({
              'id': invitation.email,
              'email': invitation.email,
              'displayName': invitation.invitedByName.isNotEmpty
                  ? invitation.invitedByName
                  : invitation.email.split('@')[0],
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
