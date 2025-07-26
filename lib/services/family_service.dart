import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/family_models.dart';

class FamilyService {
  static final _firestore = FirebaseFirestore.instance;
  static final _auth = FirebaseAuth.instance;

  // Create a new family
  static Future<String> createFamily(String familyName) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('User not authenticated');

    final familyRef = _firestore.collection('families').doc();
    final family = Family(
      id: familyRef.id,
      name: familyName,
      createdBy: user.uid,
      createdAt: DateTime.now(),
      memberIds: [user.uid],
      memberRoles: {user.uid: 'admin'},
    );

    await familyRef.set(family.toMap());

    // Update user document with family ID
    await _firestore.collection('users').doc(user.uid).update({
      'familyId': familyRef.id,
    });

    return familyRef.id;
  }

  // Send invitation
  static Future<void> sendInvitation(
    String familyId,
    String inviteeEmail,
  ) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('User not authenticated');

    // Check if user is already invited or is a member
    final existingInvitation =
        await _firestore
            .collection('family_invitations')
            .where('familyId', isEqualTo: familyId)
            .where('inviteeEmail', isEqualTo: inviteeEmail)
            .where('status', isEqualTo: 'pending')
            .get();

    if (existingInvitation.docs.isNotEmpty) {
      throw Exception('Invitation already sent to this email');
    }

    // Check if user is already a member
    final userQuery =
        await _firestore
            .collection('users')
            .where('email', isEqualTo: inviteeEmail)
            .where('familyId', isEqualTo: familyId)
            .get();

    if (userQuery.docs.isNotEmpty) {
      throw Exception('User is already a family member');
    }

    final invitation = FamilyInvitation(
      id: '',
      familyId: familyId,
      inviterUserId: user.uid,
      inviterName: user.displayName ?? user.email ?? 'Unknown',
      inviteeEmail: inviteeEmail,
      status: 'pending',
      createdAt: DateTime.now(),
    );

    await _firestore.collection('family_invitations').add(invitation.toMap());
  }

  // Get pending invitations for current user
  static Stream<List<FamilyInvitation>> getPendingInvitations() {
    final user = _auth.currentUser;
    if (user == null) return Stream.value([]);

    return _firestore
        .collection('family_invitations')
        .where('inviteeEmail', isEqualTo: user.email)
        .where('status', isEqualTo: 'pending')
        .snapshots()
        .map(
          (snapshot) =>
              snapshot.docs
                  .map((doc) => FamilyInvitation.fromMap(doc.id, doc.data()))
                  .toList(),
        );
  }

  // Accept invitation
  static Future<void> acceptInvitation(String invitationId) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('User not authenticated');

    final invitationDoc =
        await _firestore
            .collection('family_invitations')
            .doc(invitationId)
            .get();

    if (!invitationDoc.exists) {
      throw Exception('Invitation not found');
    }

    final invitation = FamilyInvitation.fromMap(
      invitationDoc.id,
      invitationDoc.data()!,
    );

    // Add user to family
    await _firestore.collection('families').doc(invitation.familyId).update({
      'memberIds': FieldValue.arrayUnion([user.uid]),
      'memberRoles.${user.uid}': 'member',
    });

    // Update user document
    await _firestore.collection('users').doc(user.uid).update({
      'familyId': invitation.familyId,
    });

    // Update invitation status
    await _firestore.collection('family_invitations').doc(invitationId).update({
      'status': 'accepted',
      'respondedAt': DateTime.now(),
    });
  }

  // Decline invitation
  static Future<void> declineInvitation(String invitationId) async {
    await _firestore.collection('family_invitations').doc(invitationId).update({
      'status': 'declined',
      'respondedAt': DateTime.now(),
    });
  }

  // Get user's family
  static Future<Family?> getUserFamily() async {
    final user = _auth.currentUser;
    if (user == null) return null;

    final userDoc = await _firestore.collection('users').doc(user.uid).get();
    final familyId = userDoc.data()?['familyId'];

    if (familyId == null) return null;

    final familyDoc =
        await _firestore.collection('families').doc(familyId).get();
    if (!familyDoc.exists) return null;

    return Family.fromMap(familyDoc.id, familyDoc.data()!);
  }

  // Get family members
  static Future<List<Map<String, dynamic>>> getFamilyMembers(
    String familyId,
  ) async {
    final family = await _firestore.collection('families').doc(familyId).get();
    if (!family.exists) return [];

    final memberIds = List<String>.from(family.data()?['memberIds'] ?? []);
    final List<Map<String, dynamic>> members = [];

    for (final memberId in memberIds) {
      final userDoc = await _firestore.collection('users').doc(memberId).get();
      if (userDoc.exists) {
        final userData = userDoc.data()!;
        userData['id'] = memberId;
        members.add(userData);
      }
    }

    return members;
  }

  // Leave family
  static Future<void> leaveFamily() async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('User not authenticated');

    final userDoc = await _firestore.collection('users').doc(user.uid).get();
    final familyId = userDoc.data()?['familyId'];

    if (familyId == null) return;

    // Remove user from family
    await _firestore.collection('families').doc(familyId).update({
      'memberIds': FieldValue.arrayRemove([user.uid]),
      'memberRoles.${user.uid}': FieldValue.delete(),
    });

    // Update user document
    await _firestore.collection('users').doc(user.uid).update({
      'familyId': FieldValue.delete(),
    });
  }
}
