import 'package:flutter_test/flutter_test.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:rythamo_charity/core/services/request_service.dart';
import 'package:rythamo_charity/core/models/item_request_model.dart';

void main() {
  late FakeFirebaseFirestore mockFirestore;
  late RequestService requestService;

  setUp(() {
    mockFirestore = FakeFirebaseFirestore();
    requestService = RequestService(firestore: mockFirestore);
  });

  group('RequestService Tests', () {
    test('createRequest adds document to Firestore', () async {
      // Act
      await requestService.createRequest(
        orphanageId: 'orphanage_123',
        orphanageName: 'Happy Home',
        itemName: 'Rice',
        category: 'Food',
        quantityNeeded: 10,
        unit: 'kg',
        description: 'Need rice',
        priority: RequestPriority.high,
      );

      // Assert
      final snapshot = await mockFirestore.collection('item_requests').get();
      expect(snapshot.docs.length, 1);
      final data = snapshot.docs.first.data();
      expect(data['orphanageId'], 'orphanage_123');
      expect(data['itemName'], 'Rice');
      expect(data['priority'], 'high');
      expect(data['status'], 'active');
    });

    test('getOrphanageRequests returns correct stream', () async {
      // Arrange
      await mockFirestore.collection('item_requests').add({
        'orphanageId': 'orphanage_123',
        'itemName': 'Rice',
        'category': 'Food',
        'quantityNeeded': 10,
        'quantityFulfilled': 0,
        'unit': 'kg',
        'description': 'Need rice',
        'priority': 'high',
        'status': 'active',
        'createdAt': Timestamp.now(),
        'expiresAt': Timestamp.now(),
      });

      // Act
      final stream = requestService.getOrphanageRequests('orphanage_123');

      // Assert
      expect(stream, emits(isA<List<ItemRequest>>()));
      final requests = await stream.first;
      expect(requests.length, 1);
      expect(requests.first.itemName, 'Rice');
    });

    test('getActiveRequests returns only active requests', () async {
      // Arrange
      // Active request
      await mockFirestore.collection('item_requests').add({
        'status': 'active',
        'createdAt': Timestamp.now(),
        'itemName': 'Active Item',
        // Add other fields to satisfy model
        'orphanageId': '1', 'orphanageName': 'A', 'category': 'C',
        'quantityNeeded': 1, 'quantityFulfilled': 0, 'unit': 'u',
        'description': '', 'priority': 'medium', 'expiresAt': Timestamp.now(),
      });
      // Fulfilled request
      await mockFirestore.collection('item_requests').add({
        'status': 'fulfilled',
        'createdAt': Timestamp.now(),
        'itemName': 'Fulfilled Item',
        // Add other fields
        'orphanageId': '1', 'orphanageName': 'A', 'category': 'C',
        'quantityNeeded': 1, 'quantityFulfilled': 1, 'unit': 'u',
        'description': '', 'priority': 'medium', 'expiresAt': Timestamp.now(),
      });

      // Act
      final stream = requestService.getActiveRequests();

      // Assert
      final requests = await stream.first;
      expect(requests.length, 1);
      expect(requests.first.itemName, 'Active Item');
    });
  });
}
