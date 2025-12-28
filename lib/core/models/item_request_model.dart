import 'package:cloud_firestore/cloud_firestore.dart';

enum RequestPriority { low, medium, high, urgent }
enum RequestStatus { active, fulfilled, expired }

class ItemRequest {
  final String id;
  final String orphanageId;
  final String orphanageName;
  final String itemName;
  final String category;
  final int quantityNeeded;
  final int quantityFulfilled;
  final String unit;
  final String description;
  final RequestPriority priority;
  final RequestStatus status;
  final DateTime createdAt;
  final DateTime? expiresAt;

  ItemRequest({
    required this.id,
    required this.orphanageId,
    required this.orphanageName,
    required this.itemName,
    required this.category,
    required this.quantityNeeded,
    this.quantityFulfilled = 0,
    required this.unit,
    this.description = '',
    this.priority = RequestPriority.medium,
    this.status = RequestStatus.active,
    required this.createdAt,
    this.expiresAt,
  });

  factory ItemRequest.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return ItemRequest(
      id: doc.id,
      orphanageId: data['orphanageId'] ?? '',
      orphanageName: data['orphanageName'] ?? 'Unknown Orphanage',
      itemName: data['itemName'] ?? '',
      category: data['category'] ?? 'Other',
      quantityNeeded: data['quantityNeeded'] ?? 0,
      quantityFulfilled: data['quantityFulfilled'] ?? 0,
      unit: data['unit'] ?? 'units',
      description: data['description'] ?? '',
      priority: _parsePriority(data['priority']),
      status: _parseStatus(data['status']),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      expiresAt: (data['expiresAt'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'orphanageId': orphanageId,
      'orphanageName': orphanageName,
      'itemName': itemName,
      'category': category,
      'quantityNeeded': quantityNeeded,
      'quantityFulfilled': quantityFulfilled,
      'unit': unit,
      'description': description,
      'priority': priority.name,
      'status': status.name,
      'createdAt': Timestamp.fromDate(createdAt),
      'expiresAt': expiresAt != null ? Timestamp.fromDate(expiresAt!) : null,
    };
  }

  static RequestPriority _parsePriority(String? priority) {
    return RequestPriority.values.firstWhere(
      (e) => e.name == priority,
      orElse: () => RequestPriority.medium,
    );
  }

  static RequestStatus _parseStatus(String? status) {
    return RequestStatus.values.firstWhere(
      (e) => e.name == status,
      orElse: () => RequestStatus.active,
    );
  }
  
  double get progress => quantityNeeded > 0 ? (quantityFulfilled / quantityNeeded).clamp(0.0, 1.0) : 0.0;
}
