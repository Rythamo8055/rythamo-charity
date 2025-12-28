import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:rythamo_charity/core/services/donation_service.dart';
import 'package:rythamo_charity/core/models/donation_offer_model.dart';
import '../setup/test_helpers.mocks.dart';

void main() {
  late FakeFirebaseFirestore mockFirestore;
  late MockFirebaseStorage mockStorage;
  late DonationService donationService;

  setUp(() {
    mockFirestore = FakeFirebaseFirestore();
    mockStorage = MockFirebaseStorage();
    donationService = DonationService(
      firestore: mockFirestore,
      storage: mockStorage,
    );
  });

  group('DonationService Tests', () {
    final testItem = DonationItem(
      name: 'Test Item',
      quantity: 1,
      category: 'Food',
      unit: 'kg',
    );

    test('createDonationOffer adds document to Firestore', () async {
      // Act
      await donationService.createDonationOffer(
        donorId: 'donor_123',
        donorName: 'John Doe',
        orphanageId: 'orphanage_456',
        orphanageName: 'Happy Home',
        items: [testItem],
        pickupAddress: '123 Main St',
        preferredPickupTime: DateTime.now(),
        deliveryOption: 'pickup',
        notes: 'Test notes',
      );

      // Assert
      final snapshot = await mockFirestore.collection('donation_offers').get();
      expect(snapshot.docs.length, 1);
      final data = snapshot.docs.first.data();
      expect(data['donorId'], 'donor_123');
      expect(data['orphanageId'], 'orphanage_456');
      expect(data['status'], 'pending');
      expect((data['items'] as List).length, 1);
    });

    test('getUserDonations returns correct stream', () async {
      // Arrange
      await mockFirestore.collection('donation_offers').add({
        'donorId': 'donor_123',
        'orphanageId': 'orphanage_456',
        'items': [testItem.toMap()],
        'status': 'pending',
        'createdAt': Timestamp.now(),
        'pickupAddress': '123 Main St',
        'preferredPickupTime': Timestamp.now(),
        'deliveryOption': 'pickup',
        'notes': '',
        'photoUrls': [],
      });

      // Act
      final stream = donationService.getUserDonations('donor_123');

      // Assert
      expect(stream, emits(isA<List<DonationOffer>>()));
      final offers = await stream.first;
      expect(offers.length, 1);
      expect(offers.first.donorId, 'donor_123');
    });

    test('acceptOffer updates status to accepted', () async {
      // Arrange
      final docRef = await mockFirestore.collection('donation_offers').add({
        'status': 'pending',
        // Add other required fields if model validation is strict, 
        // but for this update test, Firestore just needs the doc to exist.
      });

      // Act
      await donationService.acceptOffer(docRef.id);

      // Assert
      final doc = await docRef.get();
      expect(doc.data()!['status'], 'accepted');
    });
  });
}
