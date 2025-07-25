import 'package:cloud_firestore/cloud_firestore.dart';

enum InvitationStatus {
  pending('pending', 'Pending'),
  accepted('accepted', 'Accepted'),
  declined('declined', 'Declined');

  const InvitationStatus(this.value, this.displayName);
  final String value;
  final String displayName;

  static InvitationStatus fromString(String value) {
    return InvitationStatus.values.firstWhere(
      (status) => status.value == value,
      orElse: () => InvitationStatus.pending,
    );
  }
}

class InvitationModel {
  final String id;
  final String email;
  final String invitedBy;
  final String invitedByName;
  final InvitationStatus status;
  final DateTime createdAt;
  final DateTime? acceptedAt;
  final String? token; // For verification

  InvitationModel({
    required this.id,
    required this.email,
    required this.invitedBy,
    required this.invitedByName,
    required this.status,
    required this.createdAt,
    this.acceptedAt,
    this.token,
  });

  Map<String, dynamic> toMap() {
    return {
      'email': email,
      'invitedBy': invitedBy,
      'invitedByName': invitedByName,
      'status': status.value,
      'createdAt': Timestamp.fromDate(createdAt),
      'acceptedAt': acceptedAt != null ? Timestamp.fromDate(acceptedAt!) : null,
      'token': token,
    };
  }

  factory InvitationModel.fromMap(String id, Map<String, dynamic> map) {
    return InvitationModel(
      id: id,
      email: map['email'] ?? '',
      invitedBy: map['invitedBy'] ?? '',
      invitedByName: map['invitedByName'] ?? '',
      status: InvitationStatus.fromString(map['status'] ?? 'pending'),
      createdAt: (map['createdAt'] as Timestamp).toDate(),
      acceptedAt: map['acceptedAt'] != null
          ? (map['acceptedAt'] as Timestamp).toDate()
          : null,
      token: map['token'],
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
    String? token,
  }) {
    return InvitationModel(
      id: id ?? this.id,
      email: email ?? this.email,
      invitedBy: invitedBy ?? this.invitedBy,
      invitedByName: invitedByName ?? this.invitedByName,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      acceptedAt: acceptedAt ?? this.acceptedAt,
      token: token ?? this.token,
    );
  }
}
