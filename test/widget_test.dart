import 'package:flutter_test/flutter_test.dart';
import 'package:rythamo_charity/core/models/donation_offer_model.dart';

void main() {
  group('DonationItem', () {
    test('toMap converts DonationItem to Map correctly', () {
      // Arrange
      final item = DonationItem(
        name: 'Rice',
        category: 'Food',
        quantity: 10,
        unit: 'kg',
      );

      // Act
      final map = item.toMap();

      // Assert
      expect(map['name'], 'Rice');
      expect(map['category'], 'Food');
      expect(map['quantity'], 10);
      expect(map['unit'], 'kg');
    });

    test('fromMap creates DonationItem from Map correctly', () {
      // Arrange
      final map = {
        'name': 'Books',
        'category': 'Books',
        'quantity': 25,
        'unit': 'pieces',
      };

      // Act
      final item = DonationItem.fromMap(map);

      // Assert
      expect(item.name, 'Books');
      expect(item.category, 'Books');
      expect(item.quantity, 25);
      expect(item.unit, 'pieces');
    });

    test('fromMap handles missing fields with defaults', () {
      // Arrange
      final map = <String, dynamic>{};

      // Act
      final item = DonationItem.fromMap(map);

      // Assert
      expect(item.name, '');
      expect(item.category, '');
      expect(item.quantity, 0);
      expect(item.unit, '');
    });

    test('toMap and fromMap are symmetrical', () {
      // Arrange
      final original = DonationItem(
        name: 'Toys',
        category: 'Toys',
        quantity: 5,
        unit: 'boxes',
      );

      // Act
      final map = original.toMap();
      final reconstructed = DonationItem.fromMap(map);

      // Assert
      expect(reconstructed.name, original.name);
      expect(reconstructed.category, original.category);
      expect(reconstructed.quantity, original.quantity);
      expect(reconstructed.unit, original.unit);
    });
  });
}
