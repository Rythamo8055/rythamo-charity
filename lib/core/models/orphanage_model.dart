import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:math' as math;

class Orphanage {
  final String id;
  final String userId; // Reference to user account
  final String name;
  final GeoPoint location;
  final String address;
  final String phone;
  final String email;
  final String description;
  final List<String> photoUrls;
  final int capacity;
  final int currentOccupancy;
  final bool isVerified;
  final DateTime createdAt;
  final List<String> urgentNeeds;

  Orphanage({
    required this.id,
    required this.userId,
    required this.name,
    required this.location,
    required this.address,
    required this.phone,
    required this.email,
    required this.description,
    this.photoUrls = const [],
    required this.capacity,
    this.currentOccupancy = 0,
    this.isVerified = false,
    required this.createdAt,
    this.urgentNeeds = const [],
  });

  // Create from Firestore document
  factory Orphanage.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Orphanage(
      id: doc.id,
      userId: data['userId'] ?? '',
      name: data['name'] ?? '',
      location: data['location'] ?? const GeoPoint(0, 0),
      address: data['address'] ?? '',
      phone: data['phone'] ?? '',
      email: data['email'] ?? '',
      description: data['description'] ?? '',
      photoUrls: List<String>.from(data['photoUrls'] ?? []),
      capacity: data['capacity'] ?? 0,
      currentOccupancy: data['currentOccupancy'] ?? 0,
      isVerified: data['isVerified'] ?? false,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      urgentNeeds: List<String>.from(data['urgentNeeds'] ?? []),
    );
  }

  // Convert to Firestore document
  Map<String, dynamic> toFirestore() {
    return {
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
      'isVerified': isVerified,
      'createdAt': Timestamp.fromDate(createdAt),
      'urgentNeeds': urgentNeeds,
    };
  }

  // Calculate distance from a point (in kilometers)
  double distanceFrom(GeoPoint userLocation) {
    return _calculateDistance(
      userLocation.latitude,
      userLocation.longitude,
      location.latitude,
      location.longitude,
    );
  }

  // Haversine formula for distance calculation
  double _calculateDistance(double lat1, double lon1, double lat2, double lon2) {
    const double earthRadius = 6371; // km
    final double dLat = _toRadians(lat2 - lat1);
    final double dLon = _toRadians(lon2 - lon1);

    final double a = 
      math.sin(dLat / 2) * math.sin(dLat / 2) +
      math.cos(_toRadians(lat1)) * math.cos(_toRadians(lat2)) *
      math.sin(dLon / 2) * math.sin(dLon / 2);
    
    final double c = 2 * math.asin(math.sqrt(a));
    return earthRadius * c;
  }

  double _toRadians(double degree) {
    return degree * (math.pi / 180);
  }
}
