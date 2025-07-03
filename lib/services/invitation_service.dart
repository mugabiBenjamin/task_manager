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
  final FirestoreService _firestoreService;
  UserService? _userService;

  InvitationService({
    required FirestoreService firestoreService,
    UserService? userService,
  }) : _firestoreService = firestoreService,
       _userService = userService;

  void setUserService(UserService userService) {
    _userService = userService;
  }

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

  Future<bool> sendInvitation({
    required String email,
    required String invitedBy,
    required String invitedByName,
    required String inviterEmail,
  }) async {
    final emailLower = email.toLowerCase().trim();
    try {
      if (!_isValidEmail(email)) {
        throw Exception('Invalid email format');
      }

      if (_userService == null) {
        if (kDebugMode) {
          print('Error: _userService is null, cannot proceed with invitation');
        }
        throw Exception('UserService not initialized');
      }

      final existingUsers = await _userService!.searchUsers(email);
      if (existingUsers.any((user) => user.email.toLowerCase() == emailLower)) {
        throw Exception('User with this email already exists');
      }

      final existingInvitations = await getInvitationsByEmail(emailLower);

      for (final invitation in existingInvitations) {
        if (kDebugMode) {
          print(
            'Existing invitation: id=${invitation.id}, email=${invitation.email}, status=${invitation.status}, expiresAt=${invitation.expiresAt}',
          );
        }
        if (invitation.status == InvitationStatus.pending) {
          if (invitation.expiresAt == null ||
              invitation.expiresAt!.isBefore(DateTime.now())) {
            try {
              await _firestoreService.deleteDocument(
                FirebaseConstants.invitationsCollection,
                invitation.id,
              );
              if (kDebugMode) {
                print('Deleted invalid/expired invitation ${invitation.id}');
              }
            } catch (e) {
              if (kDebugMode) {
                print('Failed to delete invitation ${invitation.id}: $e');
              }
              continue; // Skip to next invitation on permission error
            }
          } else {
            if (kDebugMode) {
              print('Invitation already sent to $emailLower');
            }
            throw Exception('Invitation already sent to this email');
          }
        } else if (invitation.status == InvitationStatus.declined ||
            invitation.status == InvitationStatus.expired) {
          // CHANGED: Added try-catch to handle permission errors gracefully
          try {
            await _firestoreService.deleteDocument(
              FirebaseConstants.invitationsCollection,
              invitation.id,
            );
            if (kDebugMode) {
              print(
                'Deleted declined/expired invitation for $emailLower: ${invitation.id}',
              );
            }
          } catch (e) {
            if (kDebugMode) {
              print('Failed to delete invitation ${invitation.id}: $e');
            }
            continue; // Skip to next invitation on permission error
          }
        }
      }

      final token = _generateToken();
      final invitation = InvitationModel(
        id: '',
        email: emailLower,
        invitedBy: invitedBy,
        invitedByName: invitedByName,
        status: InvitationStatus.pending,
        createdAt: DateTime.now(),
        // CHANGED: Ensured expiresAt is always set
        expiresAt: DateTime.now().add(const Duration(days: 7)),
        token: token,
      );

      if (kDebugMode) {
        print(
          'Creating invitation for $emailLower: expiresAt=${invitation.expiresAt}, token=$token',
        );
      }

      try {
        await _firestoreService.getDocument(
          FirebaseConstants.invitationsCollection,
          'test-existence',
        );
      } catch (e) {
        if (kDebugMode) {
          print(
            'Invitations collection may not exist, creating dummy document: $e',
          );
        }
        await _firestoreService.setDocument(
          FirebaseConstants.invitationsCollection,
          'init-dummy',
          {
            'status': InvitationStatus.expired.value,
            'email': 'dummy@taskmanager.com',
            'invitedBy': invitedBy,
            'createdAt': Timestamp.now(),
            'expiresAt': Timestamp.now(),
            'token': 'dummy-token',
          },
        );
        if (kDebugMode) {
          print('Created dummy document to initialize invitations collection');
        }
      }

      final invitationId = await _firestoreService.createDocument(
        FirebaseConstants.invitationsCollection,
        invitation.toMap(),
      );
      if (invitationId.isEmpty) {
        throw Exception(
          'Failed to create invitation document: empty ID returned',
        );
      }
      final createdDoc = await _firestoreService.getDocument(
        FirebaseConstants.invitationsCollection,
        invitationId,
      );
      if (kDebugMode) {
        print('Created invitation document: $createdDoc');
      }
      if (createdDoc == null || createdDoc['expiresAt'] == null) {
        throw Exception('Failed to write expiresAt to Firestore');
      }

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
        try {
          await _firestoreService.deleteDocument(
            FirebaseConstants.invitationsCollection,
            invitationId,
          );
        } catch (e) {
          if (kDebugMode) {
            print(
              'Failed to delete invitation $invitationId after email failure: $e',
            );
          }
        }
        throw Exception('Failed to send invitation email');
      }
      if (kDebugMode) {
        print('Invitation sent successfully to: $emailLower');
      }
      return true;
    } catch (e) {
      if (kDebugMode) {
        print('Error sending invitation to $emailLower: $e');
      }
      throw Exception('$e');
    }
  }

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
      final validInvitations = <InvitationModel>[];
      for (final data in invitations) {
        if (kDebugMode) {
          print(
            'Invitation data: id=${data['id']}, expiresAt=${data['expiresAt']}',
          );
        }
        if (data['status'] == InvitationStatus.pending.value &&
            data['expiresAt'] == null) {
          if (kDebugMode) {
            print(
              'Skipping invalid pending invitation with id: ${data['id']} due to null expiresAt',
            );
          }
          try {
            await _firestoreService.deleteDocument(
              FirebaseConstants.invitationsCollection,
              data['id'],
            );
            if (kDebugMode) {
              print('Deleted invalid invitation ${data['id']}');
            }
          } catch (e) {
            if (kDebugMode) {
              print('Failed to delete invalid invitation ${data['id']}: $e');
            }
            continue; // Skip to next invitation on permission error
          }
          continue;
        }
        try {
          validInvitations.add(InvitationModel.fromMap(data['id'], data));
        } catch (e) {
          if (kDebugMode) {
            print('Error parsing invitation with id: ${data['id']}: $e');
          }
        }
      }
      return validInvitations;
    } catch (e) {
      if (kDebugMode) {
        print('Error fetching invitations for $email: $e');
      }
      throw Exception('Failed to get invitations: $e');
    }
  }

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
      if (invitationData['status'] == InvitationStatus.pending.value &&
          invitationData['expiresAt'] == null) {
        if (kDebugMode) {
          print(
            'Invalid pending invitation with id: ${invitationData['id']} due to null expiresAt',
          );
        }
        // CHANGED: Added try-catch to handle permission errors gracefully
        try {
          await _firestoreService.deleteDocument(
            FirebaseConstants.invitationsCollection,
            invitationData['id'],
          );
          if (kDebugMode) {
            print('Deleted invalid invitation ${invitationData['id']}');
          }
        } catch (e) {
          if (kDebugMode) {
            print(
              'Failed to delete invalid invitation ${invitationData['id']}: $e',
            );
          }
        }
        throw Exception('Invalid invitation: expiresAt is null');
      }

      final invitation = InvitationModel.fromMap(
        invitationData['id'],
        invitationData,
      );

      if (invitation.expiresAt == null ||
          invitation.expiresAt!.isBefore(DateTime.now())) {
        if (kDebugMode) {
          print(
            'Invitation expired for token: $token, expiresAt: ${invitation.expiresAt}',
          );
        }
        try {
          await _firestoreService.deleteDocument(
            FirebaseConstants.invitationsCollection,
            invitation.id,
          );
          if (kDebugMode) {
            print('Deleted expired invitation ${invitation.id}');
          }
        } catch (e) {
          if (kDebugMode) {
            print('Failed to delete expired invitation ${invitation.id}: $e');
          }
        }
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

      if (_userService == null) {
        if (kDebugMode) {
          print(
            'Error: _userService is null, cannot create user for invitation',
          );
        }
        throw Exception('UserService not initialized');
      }

      if (kDebugMode) {
        print(
          '_userService for user creation is ${_userService != null ? "available" : "null"}',
        );
      }
      try {
        await _userService!.getOrCreateUser(
          invitation.email,
          invitation.email,
          displayName,
        );
      } catch (e) {
        if (kDebugMode) {
          print('Failed to create user for accepted invitation: $e');
        }
        // Continue anyway as invitation is already accepted
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
      if (invitationData['status'] == InvitationStatus.pending.value &&
          invitationData['expiresAt'] == null) {
        if (kDebugMode) {
          print(
            'Invalid pending invitation with id: ${invitationData['id']} due to null expiresAt',
          );
        }
        try {
          await _firestoreService.deleteDocument(
            FirebaseConstants.invitationsCollection,
            invitationData['id'],
          );
          if (kDebugMode) {
            print('Deleted invalid invitation ${invitationData['id']}');
          }
        } catch (e) {
          if (kDebugMode) {
            print(
              'Failed to delete invalid invitation ${invitationData['id']}: $e',
            );
          }
        }
        throw Exception('Invalid invitation: expiresAt is null');
      }

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

  Future<void> cleanupExpiredInvitations() async {
    try {
      final cutoffDate = DateTime.now();

      final expiredInvitations = await _firestoreService
          .streamCollection(
            FirebaseConstants.invitationsCollection,
            queryBuilder: (query) => query
                .where(
                  FirebaseConstants.statusField,
                  isEqualTo: InvitationStatus.pending.value,
                )
                .where(
                  FirebaseConstants.expiresAtField,
                  isLessThan: Timestamp.fromDate(cutoffDate),
                ),
          )
          .first;

      for (final invitationData in expiredInvitations) {
        if (kDebugMode) {
          print('Cleaning up expired invitation: ${invitationData['id']}');
        }
        try {
          await _firestoreService.deleteDocument(
            FirebaseConstants.invitationsCollection,
            invitationData['id'],
          );
          if (kDebugMode) {
            print('Deleted expired invitation ${invitationData['id']}');
          }
        } catch (e) {
          if (kDebugMode) {
            print(
              'Failed to delete expired invitation ${invitationData['id']}: $e',
            );
          }
          continue; // Skip to next invitation on permission error
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('Failed to cleanup expired invitations: $e');
      }
    }
  }

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

  Future<List<Map<String, dynamic>>> getUsersAvailableForAssignment(
    String searchQuery,
  ) async {
    try {
      final List<Map<String, dynamic>> availableUsers = [];

      if (_userService == null) {
        if (kDebugMode) {
          print('Error: _userService is null, cannot search for users');
        }
        throw Exception('UserService not initialized');
      }

      final registeredUsers = await _userService!.searchUsers(searchQuery);
      for (final user in registeredUsers) {
        availableUsers.add({
          'id': user.id,
          'email': user.email,
          'displayName': user.displayName,
          'isRegistered': true,
        });
      }

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
