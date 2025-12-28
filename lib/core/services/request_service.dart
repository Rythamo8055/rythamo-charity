import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/item_request_model.dart';

class RequestService {
  final FirebaseFirestore _firestore;

  RequestService({
    FirebaseFirestore? firestore,
  })  : _firestore = firestore ?? FirebaseFirestore.instance;

  // Create a new item request
  Future<void> createRequest({
    required String orphanageId,
    required String orphanageName,
    required String itemName,
    required String category,
    required int quantityNeeded,
    required String unit,
    String description = '',
    RequestPriority priority = RequestPriority.medium,
  }) async {
    await _firestore.collection('item_requests').add({
      'orphanageId': orphanageId,
      'orphanageName': orphanageName,
      'itemName': itemName,
      'category': category,
      'quantityNeeded': quantityNeeded,
      'quantityFulfilled': 0,
      'unit': unit,
      'description': description,
      'priority': priority.name,
      'status': RequestStatus.active.name,
      'createdAt': FieldValue.serverTimestamp(),
      'expiresAt': Timestamp.fromDate(DateTime.now().add(const Duration(days: 30))), // Default 30 days
    });
  }

  // Get all active requests (for browsing)
  Stream<List<ItemRequest>> getActiveRequests() {
    return _firestore
        .collection('item_requests')
        .where('status', isEqualTo: RequestStatus.active.name)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => ItemRequest.fromFirestore(doc)).toList());
  }

  // Get requests for a specific orphanage
  Stream<List<ItemRequest>> getOrphanageRequests(String orphanageId) {
    return _firestore
        .collection('item_requests')
        .where('orphanageId', isEqualTo: orphanageId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => ItemRequest.fromFirestore(doc)).toList());
  }

  // Delete a request
  Future<void> deleteRequest(String requestId) async {
    try {
      await _firestore.collection('item_requests').doc(requestId).delete();
      print('Successfully deleted request: $requestId');
    } catch (e) {
      print('Error deleting request $requestId: $e');
      rethrow;
    }
  }

  // Mark request as fulfilled (or update quantity)
  Future<void> updateFulfillment(String requestId, int quantityAdded) async {
    final docRef = _firestore.collection('item_requests').doc(requestId);
    
    await _firestore.runTransaction((transaction) async {
      final snapshot = await transaction.get(docRef);
      if (!snapshot.exists) return;

      final currentFulfilled = snapshot.data()?['quantityFulfilled'] ?? 0;
      final quantityNeeded = snapshot.data()?['quantityNeeded'] ?? 0;
      
      final newFulfilled = currentFulfilled + quantityAdded;
      
      final updates = <String, dynamic>{
        'quantityFulfilled': newFulfilled,
      };

      if (newFulfilled >= quantityNeeded) {
        updates['status'] = RequestStatus.fulfilled.name;
      }

      transaction.update(docRef, updates);
    });
  }
}
