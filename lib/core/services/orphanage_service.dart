import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/orphanage_model.dart';

class OrphanageService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Create orphanage profile
  Future<String> createOrphanageProfile({
    required String userId,
    required String name,
    required GeoPoint location,
    required String address,
    required String phone,
    required String email,
    required String description,
    List<String> photoUrls = const [],
    required int capacity,
    int currentOccupancy = 0,
  }) async {
    final docRef = await _firestore.collection('orphanages').add({
      'userId': userId,
      'name': name,
      'location': location,
      'address': address,
      'phone': phone,
      'email': email,
      'description': description,
      'photoUrls': photoUrls,
      'capacity': capacity,
      'currentOccupancy': currentOccupancy,
      'isVerified': false,
      'createdAt': FieldValue.serverTimestamp(),
      'urgentNeeds': [],
    });
    return docRef.id;
  }

  // Get nearby orphanages within radius
  Stream<List<Orphanage>> getNearbyOrphanages(GeoPoint userLocation, double radiusKm) {
    // Note: This is a simplified version. For production, use GeoFlutterFire or similar
    // for proper geospatial queries. For now, we fetch all and filter client-side.
    return _firestore
        .collection('orphanages')
        .where('isVerified', isEqualTo: true)
        .snapshots()
        .map((snapshot) {
      final orphanages = snapshot.docs
          .map((doc) => Orphanage.fromFirestore(doc))
          .toList();

      // Filter by distance
      return orphanages
          .where((orphanage) => orphanage.distanceFrom(userLocation) <= radiusKm)
          .toList()
        ..sort((a, b) => a.distanceFrom(userLocation).compareTo(b.distanceFrom(userLocation)));
    });
  }

  // Get nearby orphanages as a Future (for one-time queries)
  Future<List<Orphanage>> getNearbyOrphanagesFuture(GeoPoint userLocation, double radiusKm) async {
    final snapshot = await _firestore
        .collection('orphanages')
        .where('isVerified', isEqualTo: true)
        .get();

    final orphanages = snapshot.docs
        .map((doc) => Orphanage.fromFirestore(doc))
        .toList();

    // Filter by distance
    final nearby = orphanages
        .where((orphanage) => orphanage.distanceFrom(userLocation) <= radiusKm)
        .toList()
      ..sort((a, b) => a.distanceFrom(userLocation).compareTo(b.distanceFrom(userLocation)));

    return nearby;
  }

  // Get all orphanages (for map display)
  Stream<List<Orphanage>> getAllOrphanages() {
    return _firestore
        .collection('orphanages')
        .where('isVerified', isEqualTo: true)
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => Orphanage.fromFirestore(doc)).toList());
  }

  // Get orphanage by ID
  Future<Orphanage?> getOrphanageById(String id) async {
    final doc = await _firestore.collection('orphanages').doc(id).get();
    if (doc.exists) {
      return Orphanage.fromFirestore(doc);
    }
    return null;
  }

  // Get orphanage by user ID (for orphanage account)
  Future<Orphanage?> getOrphanageByUserId(String userId) async {
    final querySnapshot = await _firestore
        .collection('orphanages')
        .where('userId', isEqualTo: userId)
        .limit(1)
        .get();

    if (querySnapshot.docs.isNotEmpty) {
      return Orphanage.fromFirestore(querySnapshot.docs.first);
    }
    return null;
  }

  // Update orphanage profile
  Future<void> updateOrphanageProfile(String id, Map<String, dynamic> data) async {
    await _firestore.collection('orphanages').doc(id).update(data);
  }

  // Update urgent needs
  Future<void> updateUrgentNeeds(String orphanageId, List<String> needs) async {
    await _firestore.collection('orphanages').doc(orphanageId).update({
      'urgentNeeds': needs,
    });
  }

  // Get orphanage stream by user ID (for dashboard)
  Stream<Orphanage?> getMyOrphanageStream(String userId) {
    return _firestore
        .collection('orphanages')
        .where('userId', isEqualTo: userId)
        .limit(1)
        .snapshots()
        .map((snapshot) {
      if (snapshot.docs.isNotEmpty) {
        return Orphanage.fromFirestore(snapshot.docs.first);
      }
      return null;
    });
  }

  // Delete orphanage (admin only)
  Future<void> deleteOrphanage(String id) async {
    await _firestore.collection('orphanages').doc(id).delete();
  }
}
