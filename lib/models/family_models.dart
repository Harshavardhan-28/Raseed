import 'package:cloud_firestore/cloud_firestore.dart';

class Family {
  final String id;
  final String name;
  final String createdBy;
  final DateTime createdAt;
  final List<String> memberIds;
  final Map<String, String> memberRoles; // userId -> role (admin/member)

  Family({
    required this.id,
    required this.name,
    required this.createdBy,
    required this.createdAt,
    required this.memberIds,
    required this.memberRoles,
  });

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'createdBy': createdBy,
      'createdAt': createdAt,
      'memberIds': memberIds,
      'memberRoles': memberRoles,
    };
  }

  factory Family.fromMap(String id, Map<String, dynamic> map) {
    return Family(
      id: id,
      name: map['name'] ?? '',
      createdBy: map['createdBy'] ?? '',
      createdAt: (map['createdAt'] as Timestamp).toDate(),
      memberIds: List<String>.from(map['memberIds'] ?? []),
      memberRoles: Map<String, String>.from(map['memberRoles'] ?? {}),
    );
  }
}

class FamilyInvitation {
  final String id;
  final String familyId;
  final String inviterUserId;
  final String inviterName;
  final String inviteeEmail;
  final String status; // pending, accepted, declined
  final DateTime createdAt;
  final DateTime? respondedAt;

  FamilyInvitation({
    required this.id,
    required this.familyId,
    required this.inviterUserId,
    required this.inviterName,
    required this.inviteeEmail,
    required this.status,
    required this.createdAt,
    this.respondedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'familyId': familyId,
      'inviterUserId': inviterUserId,
      'inviterName': inviterName,
      'inviteeEmail': inviteeEmail,
      'status': status,
      'createdAt': createdAt,
      'respondedAt': respondedAt,
    };
  }

  factory FamilyInvitation.fromMap(String id, Map<String, dynamic> map) {
    return FamilyInvitation(
      id: id,
      familyId: map['familyId'] ?? '',
      inviterUserId: map['inviterUserId'] ?? '',
      inviterName: map['inviterName'] ?? '',
      inviteeEmail: map['inviteeEmail'] ?? '',
      status: map['status'] ?? 'pending',
      createdAt: (map['createdAt'] as Timestamp).toDate(),
      respondedAt:
          map['respondedAt'] != null
              ? (map['respondedAt'] as Timestamp).toDate()
              : null,
    );
  }
}
