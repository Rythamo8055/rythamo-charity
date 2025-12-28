import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/donation_offer_model.dart';

class DonationService {
  final FirebaseFirestore _firestore;
  final FirebaseStorage _storage;

  DonationService({
    FirebaseFirestore? firestore,
    FirebaseStorage? storage,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _storage = storage ?? FirebaseStorage.instance;

  // Create a new donation offer
  Future<void> createDonationOffer({
    required String donorId,
    required String donorName,
    required String orphanageId,
    required String orphanageName,
    String? orphanageAddress,
    required List<DonationItem> items,
    GeoPoint? pickupLocation,
    required String pickupAddress,
    required DateTime preferredPickupTime,
    required String deliveryOption,
    required String notes,
    List<File> photos = const [],
  }) async {
    // 1. Upload photos first if any
    List<String> photoUrls = [];
    if (photos.isNotEmpty) {
      photoUrls = await _uploadPhotos(photos, donorId);
    }

    // 2. Create offer document
    await _firestore.collection('donation_offers').add({
      'donorId': donorId,
      'donorName': donorName,
      'orphanageId': orphanageId,
      'orphanageName': orphanageName,
      'orphanageAddress': orphanageAddress,
      'items': items.map((i) => i.toMap()).toList(),
      'pickupLocation': pickupLocation,
      'pickupAddress': pickupAddress,
      'preferredPickupTime': Timestamp.fromDate(preferredPickupTime),
      'deliveryOption': deliveryOption,
      'photoUrls': photoUrls,
      'notes': notes,
      'status': OfferStatus.pending.name,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  // Upload photos to Firebase Storage
  Future<List<String>> _uploadPhotos(List<File> photos, String userId) async {
    List<String> urls = [];
    for (var photo in photos) {
      final String fileName = '${DateTime.now().millisecondsSinceEpoch}_${photo.path.split('/').last}';
      final Reference ref = _storage.ref().child('donations/$userId/$fileName');
      final UploadTask task = ref.putFile(photo);
      final TaskSnapshot snapshot = await task;
      final String url = await snapshot.ref.getDownloadURL();
      urls.add(url);
    }
    return urls;
  }

  // Get offers for a specific donor
  Stream<List<DonationOffer>> getUserDonations(String userId) {
    return _firestore
        .collection('donation_offers')
        .where('donorId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => DonationOffer.fromFirestore(doc)).toList());
  }

  // Get offers for a specific orphanage
  Stream<List<DonationOffer>> getOrphanageOffers(String orphanageId) {
    return _firestore
        .collection('donation_offers')
        .where('orphanageId', isEqualTo: orphanageId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => DonationOffer.fromFirestore(doc)).toList());
  }

  // Accept an offer
  Future<void> acceptOffer(String offerId) async {
    await _firestore.collection('donation_offers').doc(offerId).update({
      'status': OfferStatus.accepted.name,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  // Reject an offer
  Future<void> rejectOffer(String offerId, String reason) async {
    await _firestore.collection('donation_offers').doc(offerId).update({
      'status': OfferStatus.rejected.name,
      'rejectionReason': reason,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  // Update an existing donation offer
  Future<void> updateDonationOffer({
    required String offerId,
    required List<DonationItem> items,
    required String pickupAddress,
    required DateTime preferredPickupTime,
    required String deliveryOption,
    required String notes,
    List<File> newPhotos = const [],
    List<String> existingPhotoUrls = const [],
  }) async {
    // 1. Upload new photos if any
    List<String> newPhotoUrls = [];
    if (newPhotos.isNotEmpty) {
      // We need the userId to store photos in the correct path. 
      // Since we don't have it here, we can fetch the offer first or pass it.
      // For simplicity, we'll use the current user's ID from Auth.
      final userId = FirebaseAuth.instance.currentUser?.uid;
      if (userId != null) {
        newPhotoUrls = await _uploadPhotos(newPhotos, userId);
      }
    }

    // 2. Combine URLs
    final List<String> allPhotoUrls = [...existingPhotoUrls, ...newPhotoUrls];

    // 3. Update offer document
    await _firestore.collection('donation_offers').doc(offerId).update({
      'items': items.map((i) => i.toMap()).toList(),
      'pickupAddress': pickupAddress,
      'preferredPickupTime': Timestamp.fromDate(preferredPickupTime),
      'deliveryOption': deliveryOption,
      'photoUrls': allPhotoUrls,
      'notes': notes,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  // Delete a donation offer
  Future<void> deleteDonationOffer(String offerId) async {
    await _firestore.collection('donation_offers').doc(offerId).delete();
  }

  // Mark offer as completed (delivered/picked up)
  Future<void> completeOffer(String offerId) async {
    await _firestore.collection('donation_offers').doc(offerId).update({
      'status': OfferStatus.completed.name,
      'updatedAt': FieldValue.serverTimestamp(),
    });
    
    // TODO: Update donor stats (total donations, lives impacted)
  }
}
