import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../core/enums/invitation_status.dart';

class InvitationModel {
  final String id;
  final String email;
  final String invitedBy;
  final String invitedByName;
  final InvitationStatus status;
  final DateTime createdAt;
  final DateTime? acceptedAt;
  final DateTime? declinedAt;
  final DateTime? expiresAt;
  final String? token;

  InvitationModel({
    required this.id,
    required this.email,
    required this.invitedBy,
    required this.invitedByName,
    required this.status,
    required this.createdAt,
    this.acceptedAt,
    this.declinedAt,
    this.expiresAt,
    this.token,
  }) {
    // ADDED: Validate input to ensure expiresAt is set when status is pending
    if (status == InvitationStatus.pending && expiresAt == null) {
      if (kDebugMode) {
        print('Warning: expiresAt is null for pending invitation with id: $id');
      }
      // Optionally throw an exception or set a default value
      // throw Exception('expiresAt must be set for pending invitations');
    }
    // ADDED: Validate non-empty required fields
    if (email.isEmpty || invitedBy.isEmpty || invitedByName.isEmpty) {
      throw Exception('email, invitedBy, and invitedByName must not be empty');
    }
  }

  Map<String, dynamic> toMap() {
    // ADDED: Log the expiresAt value before conversion
    if (kDebugMode) {
      print('Converting InvitationModel to map: expiresAt=$expiresAt');
    }
    return {
      'email': email,
      'invitedBy': invitedBy,
      'invitedByName': invitedByName,
      'status': status.value,
      'createdAt': Timestamp.fromDate(createdAt),
      'acceptedAt': acceptedAt != null ? Timestamp.fromDate(acceptedAt!) : null,
      'declinedAt': declinedAt != null ? Timestamp.fromDate(declinedAt!) : null,
      // CHANGED: Explicitly cast expiresAt to DateTime to satisfy type checker
      'expiresAt': expiresAt != null
          ? Timestamp.fromDate(expiresAt as DateTime)
          : null,
      'token': token,
    };
  }

  factory InvitationModel.fromMap(String id, Map<String, dynamic> map) {
    // ADDED: Log Firestore data to catch null expiresAt
    if (kDebugMode) {
      print(
        'Parsing InvitationModel from Firestore: id=$id, expiresAt=${map['expiresAt']}',
      );
      if (map['expiresAt'] == null &&
          map['status'] == InvitationStatus.pending.value) {
        print('Warning: expiresAt is null for pending invitation with id: $id');
      }
    }
    return InvitationModel(
      id: id,
      email: map['email']?.toString() ?? '',
      invitedBy: map['invitedBy']?.toString() ?? '',
      invitedByName: map['invitedByName']?.toString() ?? '',
      status: InvitationStatus.fromString(
        map['status']?.toString() ?? 'pending',
      ),
      createdAt: map['createdAt'] != null
          ? (map['createdAt'] as Timestamp).toDate()
          : DateTime.now(), // ADDED: Fallback for null createdAt
      acceptedAt: map['acceptedAt'] != null
          ? (map['acceptedAt'] as Timestamp).toDate()
          : null,
      declinedAt: map['declinedAt'] != null
          ? (map['declinedAt'] as Timestamp).toDate()
          : null,
      expiresAt: map['expiresAt'] != null
          ? (map['expiresAt'] as Timestamp).toDate()
          : null,
      token: map['token']?.toString(),
    );
  }

  InvitationModel copyWith({
    String? id,
    String? email,
    String? invitedBy,
    String? invitedByName,
    InvitationStatus? status,
    DateTime? createdAt,
    DateTime? acceptedAt,
    DateTime? declinedAt,
    DateTime? expiresAt,
    String? token,
  }) {
    // ADDED: Log when expiresAt is updated
    if (kDebugMode && expiresAt != null && expiresAt != this.expiresAt) {
      print('Updating expiresAt for invitation id=$id: new value=$expiresAt');
    }
    return InvitationModel(
      id: id ?? this.id,
      email: email ?? this.email,
      invitedBy: invitedBy ?? this.invitedBy,
      invitedByName: invitedByName ?? this.invitedByName,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      acceptedAt: acceptedAt ?? this.acceptedAt,
      declinedAt: declinedAt ?? this.declinedAt,
      expiresAt: expiresAt ?? this.expiresAt,
      token: token ?? this.token,
    );
  }
}
