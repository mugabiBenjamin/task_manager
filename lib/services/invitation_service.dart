import 'dart:math';
import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../core/constants/firebase_constants.dart';
import '../core/enums/invitation_status.dart';
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

  bool _isValidEmail(String email) {
    return RegExp(
      r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
    ).hasMatch(email);
  }

  // Send invitation email with EmailJS
  Future<bool> sendInvitation({
    required String email,
    required String invitedBy,
    required String invitedByName,
    required String inviterEmail,
  }) async {
    try {
      // Validate email format
      if (!_isValidEmail(email)) {
        throw Exception('Invalid email format');
      }

      if (_userService != null) {
        final existingUsers = await _userService!.searchUsers(email);
        if (existingUsers.any(
          (user) => user.email.toLowerCase() == email.toLowerCase(),
        )) {
          throw Exception('User with this email already exists');
        }
      }

      final emailLower = email.toLowerCase().trim();
      final existingInvitations = await getInvitationsByEmail(emailLower);

      for (final invitation in existingInvitations) {
        if (invitation.status == InvitationStatus.pending) {
          if (invitation.expiresAt!.isBefore(DateTime.now())) {
            // Mark as expired
            await _firestoreService.updateDocument(
              FirebaseConstants.invitationsCollection,
              invitation.id,
              {
                FirebaseConstants.statusField: InvitationStatus.expired.value,
                'expiresAt': Timestamp.fromDate(DateTime.now()),
              },
            );
          } else {
            if (kDebugMode) {
              print('Invitation already sent to $emailLower');
            }
            throw Exception('Invitation already sent to this email');
          }
        } else if (invitation.status == InvitationStatus.declined ||
            invitation.status == InvitationStatus.expired) {
          // Delete declined or expired invitation
          await _firestoreService.deleteDocument(
            FirebaseConstants.invitationsCollection,
            invitation.id,
          );
          if (kDebugMode) {
            print(
              'Deleted declined/expired invitation for $emailLower: ${invitation.id}',
            );
          }
        }
      }

      final token = _generateToken();
      final invitation = InvitationModel(
        id: '', // ID will be set by Firestore
        email: emailLower,
        invitedBy: invitedBy,
        invitedByName: invitedByName,
        status: InvitationStatus.pending,
        createdAt: DateTime.now(),
        expiresAt: DateTime.now().add(const Duration(days: 7)),
        token: token,
      );

      if (kDebugMode) {
        print(
          'Attempting to create invitation document for email: $emailLower',
        );
      }
      final invitationId = await _firestoreService.createDocument(
        FirebaseConstants.invitationsCollection,
        invitation.toMap(),
      );
      final verificationLink =
          'https://task-pages-opal.vercel.app/invitation.html?token=$token';
      if (kDebugMode) {
        print('Sending invitation email to: $emailLower with token: $token');
      }
      final emailSent = await EmailService.sendInvitationEmail(
        recipientEmail: emailLower,
        inviterName: invitedByName,
        inviterEmail: inviterEmail,
        invitationToken: token,
        verificationLink: verificationLink,
      );

      if (!emailSent) {
        if (kDebugMode) {
          print('Email sending failed, deleting invitation: $invitationId');
        }
        await _firestoreService.deleteDocument(
          FirebaseConstants.invitationsCollection,
          invitationId,
        );
        throw Exception('Failed to send invitation email');
      }
      if (kDebugMode) {
        print('Invitation sent successfully to: $emailLower');
      }
      return true;
    } catch (e) {
      if (kDebugMode) {
        var emailLower = email.toLowerCase().trim();
        print('Error sending invitation to $emailLower: $e');
      }
      throw Exception('$e');
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
      if (kDebugMode) {
        print('Found ${invitations.length} invitations for email: $email');
      }
      return invitations
          .map((data) => InvitationModel.fromMap(data['id'], data))
          .toList();
    } catch (e) {
      if (kDebugMode) {
        print('Error fetching invitations for $email: $e');
      }
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

      if (invitation.expiresAt!.isBefore(DateTime.now())) {
        if (kDebugMode) {
          print('Invitation expired for token: $token');
        }
        await _firestoreService.updateDocument(
          FirebaseConstants.invitationsCollection,
          invitation.id,
          {
            FirebaseConstants.statusField: InvitationStatus.expired.value,
            'expiresAt': Timestamp.fromDate(DateTime.now()),
          },
        );
        throw Exception('Invitation has expired');
      }

      if (kDebugMode) {
        print('Updating invitation status to accepted for token: $token');
      }
      await _firestoreService.updateDocument(
        FirebaseConstants.invitationsCollection,
        invitation.id,
        {
          FirebaseConstants.statusField: InvitationStatus.accepted.value,
          'acceptedAt': Timestamp.fromDate(DateTime.now()),
        },
      );

      // Create user asynchronously
      if (_userService != null) {
        unawaited(
          _userService!.getOrCreateUser(
            invitation.email,
            invitation.email,
            displayName,
          ),
        );
      }

      if (kDebugMode) {
        print('Invitation accepted successfully for token: $token');
      }
      return true;
    } catch (e) {
      if (kDebugMode) {
        print('Error accepting invitation for token: $token: $e');
      }
      throw Exception('Failed to accept invitation: $e');
    }
  }

  // Decline invitation
  Future<bool> declineInvitation(String token) async {
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

      if (kDebugMode) {
        print('Declining invitation for token: $token');
      }
      await _firestoreService.updateDocument(
        FirebaseConstants.invitationsCollection,
        invitation.id,
        {
          FirebaseConstants.statusField: InvitationStatus.declined.value,
          'declinedAt': Timestamp.fromDate(DateTime.now()),
        },
      );

      if (kDebugMode) {
        print('Invitation declined successfully for token: $token');
      }
      return true;
    } catch (e) {
      if (kDebugMode) {
        print('Error declining invitation for token: $token: $e');
      }
      throw Exception('Failed to decline invitation: $e');
    }
  }

  // Cleanup expired invitations
  Future<void> cleanupExpiredInvitations() async {
    try {
      final cutoffDate = DateTime.now().subtract(const Duration(days: 7));

      final expiredInvitations = await _firestoreService
          .streamCollection(
            FirebaseConstants.invitationsCollection,
            queryBuilder: (query) => query
                .where(
                  FirebaseConstants.statusField,
                  isEqualTo: InvitationStatus.pending.value,
                )
                .where(
                  FirebaseConstants.createdAtField,
                  isLessThan: Timestamp.fromDate(cutoffDate),
                ),
          )
          .first;

      for (final invitationData in expiredInvitations) {
        if (kDebugMode) {
          print('Cleaning up expired invitation: ${invitationData['id']}');
        }
        await _firestoreService.updateDocument(
          FirebaseConstants.invitationsCollection,
          invitationData['id'],
          {
            FirebaseConstants.statusField: InvitationStatus.expired.value,
            'expiresAt': Timestamp.fromDate(DateTime.now()),
          },
        );
      }
    } catch (e) {
      if (kDebugMode) {
        print('Failed to cleanup expired invitations: $e');
      }
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

      // Get registered users
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

      if (kDebugMode) {
        print(
          'Found ${availableUsers.length} users for assignment query: $searchQuery',
        );
      }
      return availableUsers;
    } catch (e) {
      if (kDebugMode) {
        print('Error fetching available users: $e');
      }
      throw Exception('Failed to get available users: $e');
    }
  }
}
