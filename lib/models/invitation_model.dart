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
    if (status == InvitationStatus.pending && expiresAt == null) {
      if (kDebugMode) {
        print('Error: expiresAt is null for pending invitation with id: $id');
      }
      throw Exception('expiresAt must be set for pending invitations');
    }
    if (email.isEmpty || invitedBy.isEmpty || invitedByName.isEmpty) {
      throw Exception('email, invitedBy, and invitedByName must not be empty');
    }
  }

  Map<String, dynamic> toMap() {
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
      'expiresAt': expiresAt != null
          ? Timestamp.fromDate(expiresAt as DateTime)
          : null,
      'token': token,
    };
  }

  factory InvitationModel.fromMap(String id, Map<String, dynamic> map) {
    if (kDebugMode) {
      print(
        'Parsing InvitationModel from Firestore: id=$id, expiresAt=${map['expiresAt']}',
      );
    }
    final isPending =
        map['status']?.toString() == InvitationStatus.pending.value;
    final expiresAtValue = map['expiresAt'] != null
        ? (map['expiresAt'] as Timestamp).toDate()
        : (isPending
              ? DateTime.now()
              : null);
    final statusValue = isPending && expiresAtValue == null
        ? InvitationStatus
              .expired
        : InvitationStatus.fromString(map['status']?.toString() ?? 'pending');

    if (kDebugMode && isPending && map['expiresAt'] == null) {
      print(
        'Warning: expiresAt is null for pending invitation with id: $id, setting default expiresAt to now',
      );
    }

    return InvitationModel(
      id: id,
      email: map['email']?.toString() ?? '',
      invitedBy: map['invitedBy']?.toString() ?? '',
      invitedByName: map['invitedByName']?.toString() ?? '',
      status: statusValue,
      createdAt: map['createdAt'] != null
          ? (map['createdAt'] as Timestamp).toDate()
          : DateTime.now(),
      acceptedAt: map['acceptedAt'] != null
          ? (map['acceptedAt'] as Timestamp).toDate()
          : null,
      declinedAt: map['declinedAt'] != null
          ? (map['declinedAt'] as Timestamp).toDate()
          : null,
      expiresAt: expiresAtValue,
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
