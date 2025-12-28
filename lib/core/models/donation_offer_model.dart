import 'package:cloud_firestore/cloud_firestore.dart';

enum OfferStatus { pending, accepted, rejected, completed }

class DonationItem {
  final String name;
  final String category;
  final int quantity;
  final String unit; // e.g., 'kg', 'boxes', 'pieces'

  DonationItem({
    required this.name,
    required this.category,
    required this.quantity,
    required this.unit,
  });

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'category': category,
      'quantity': quantity,
      'unit': unit,
    };
  }

  factory DonationItem.fromMap(Map<String, dynamic> map) {
    return DonationItem(
      name: map['name'] ?? '',
      category: map['category'] ?? '',
      quantity: map['quantity'] ?? 0,
      unit: map['unit'] ?? '',
    );
  }
}

class DonationOffer {
  final String id;
  final String donorId;
  final String donorName; // Denormalized for easy display
  final String orphanageId;
  final String orphanageName; // Denormalized
  final String? orphanageAddress; // For custom/unlisted orphanages
  final List<DonationItem> items;
  final GeoPoint? pickupLocation;
  final String pickupAddress;
  final DateTime preferredPickupTime;
  final String deliveryOption; // 'self-delivery' or 'pickup-requested'
  final List<String> photoUrls;
  final String notes;
  final OfferStatus status;
  final String? rejectionReason;
  final DateTime createdAt;
  final DateTime? updatedAt;

  DonationOffer({
    required this.id,
    required this.donorId,
    required this.donorName,
    required this.orphanageId,
    required this.orphanageName,
    this.orphanageAddress,
    required this.items,
    this.pickupLocation,
    required this.pickupAddress,
    required this.preferredPickupTime,
    required this.deliveryOption,
    this.photoUrls = const [],
    this.notes = '',
    this.status = OfferStatus.pending,
    this.rejectionReason,
    required this.createdAt,
    this.updatedAt,
  });

  factory DonationOffer.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return DonationOffer(
      id: doc.id,
      donorId: data['donorId'] ?? '',
      donorName: data['donorName'] ?? 'Anonymous',
      orphanageId: data['orphanageId'] ?? '',
      orphanageName: data['orphanageName'] ?? 'Unknown Orphanage',
      orphanageAddress: data['orphanageAddress'],
      items: (data['items'] as List<dynamic>?)
              ?.map((item) => DonationItem.fromMap(item))
              .toList() ??
          [],
      pickupLocation: data['pickupLocation'],
      pickupAddress: data['pickupAddress'] ?? '',
      preferredPickupTime: (data['preferredPickupTime'] as Timestamp?)?.toDate() ?? DateTime.now(),
      deliveryOption: data['deliveryOption'] ?? 'self-delivery',
      photoUrls: List<String>.from(data['photoUrls'] ?? []),
      notes: data['notes'] ?? '',
      status: _parseStatus(data['status']),
      rejectionReason: data['rejectionReason'],
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'donorId': donorId,
      'donorName': donorName,
      'orphanageId': orphanageId,
      'orphanageName': orphanageName,
      'orphanageAddress': orphanageAddress,
      'items': items.map((item) => item.toMap()).toList(),
      'pickupLocation': pickupLocation,
      'pickupAddress': pickupAddress,
      'preferredPickupTime': Timestamp.fromDate(preferredPickupTime),
      'deliveryOption': deliveryOption,
      'photoUrls': photoUrls,
      'notes': notes,
      'status': status.name,
      'rejectionReason': rejectionReason,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': updatedAt != null ? Timestamp.fromDate(updatedAt!) : null,
    };
  }

  static OfferStatus _parseStatus(String? status) {
    return OfferStatus.values.firstWhere(
      (e) => e.name == status,
      orElse: () => OfferStatus.pending,
    );
  }
}
