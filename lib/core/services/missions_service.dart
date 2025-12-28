import 'package:cloud_firestore/cloud_firestore.dart';

class MissionsService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Collection References
  CollectionReference get _missionsCollection => _firestore.collection('missions');
  CollectionReference get _activityCollection => _firestore.collection('recent_activity');

  // Stream of Missions
  Stream<QuerySnapshot> getMissions() {
    return _missionsCollection.orderBy('urgency', descending: true).snapshots();
  }

  // Stream of Recent Activity (The Pulse)
  Stream<QuerySnapshot> getRecentActivity() {
    return _activityCollection.orderBy('timestamp', descending: true).limit(10).snapshots();
  }

  // Add a Mission (Seeding/Testing)
  Future<void> addMission(Map<String, dynamic> missionData) async {
    await _missionsCollection.add(missionData);
  }

  // Update Mission
  Future<void> updateMission(String missionId, Map<String, dynamic> data) async {
    await _missionsCollection.doc(missionId).update(data);
  }

  // Delete Mission
  Future<void> deleteMission(String missionId) async {
    await _missionsCollection.doc(missionId).delete();
  }

  // Deploy Supplies
  Future<void> deploySupplies(String missionId, String missionTitle, String category) async {
    // 1. Add to Recent Activity
    await _activityCollection.add({
      'title': "Supplies deployed for $missionTitle",
      'time': "Just now", // In a real app, use server timestamp and format on client
      'timestamp': FieldValue.serverTimestamp(),
      'category': category,
    });
  }

  // --- Profile Management ---
  CollectionReference get _profileCollection => _firestore.collection('profile');

  // Get User Profile (Single doc for simplicity)
  Stream<DocumentSnapshot> getUserProfile() {
    return _profileCollection.doc('current_user').snapshots();
  }

  // Update User Profile
  Future<void> updateUserProfile(Map<String, dynamic> data) async {
    await _profileCollection.doc('current_user').set(data, SetOptions(merge: true));
  }
}

