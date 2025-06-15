import 'package:cloud_firestore/cloud_firestore.dart';

class LabelModel {
  final String id;
  final String name;
  final String color;
  final String createdBy;
  final DateTime createdAt;

  LabelModel({
    required this.id,
    required this.name,
    required this.color,
    required this.createdBy,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'color': color,
      'createdBy': createdBy,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  factory LabelModel.fromMap(String id, Map<String, dynamic> map) {
    return LabelModel(
      id: id,
      name: map['name'] ?? '',
      color: map['color'] ?? '#000000',
      createdBy: map['createdBy'] ?? '',
      createdAt: (map['createdAt'] as Timestamp).toDate(),
    );
  }

  factory LabelModel.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return LabelModel.fromMap(doc.id, data);
  }

  LabelModel copyWith({
    String? id,
    String? name,
    String? color,
    String? createdBy,
    DateTime? createdAt,
  }) {
    return LabelModel(
      id: id ?? this.id,
      name: name ?? this.name,
      color: color ?? this.color,
      createdBy: createdBy ?? this.createdBy,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}