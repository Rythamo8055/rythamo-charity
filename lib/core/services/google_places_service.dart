import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/orphanage_model.dart';

class GooglePlacesService {
  final String apiKey;

  GooglePlacesService({required this.apiKey});

  Future<List<Orphanage>> searchOrphanages(GeoPoint location, double radiusKm) async {
    if (apiKey == 'YOUR_API_KEY') {
      print('Warning: Google Places API Key not set.');
      return [];
    }

    final radiusMeters = (radiusKm * 1000).toInt();
    final url = Uri.parse(
        'https://maps.googleapis.com/maps/api/place/nearbysearch/json'
        '?location=${location.latitude},${location.longitude}'
        '&radius=$radiusMeters'
        '&keyword=orphanage'
        '&key=$apiKey');

    try {
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final results = data['results'] as List;

        return results.map((place) {
          final loc = place['geometry']['location'];
          return Orphanage(
            id: place['place_id'],
            userId: 'google_place', // Placeholder for non-registered orphanages
            name: place['name'],
            email: '', // Not available from Places API
            phone: '', // Requires Place Details API
            address: place['vicinity'] ?? '',
            description: 'Found via Google Maps',
            location: GeoPoint(loc['lat'], loc['lng']),
            isVerified: false,
            createdAt: DateTime.now(),
            urgentNeeds: [],
            photoUrls: place['photos'] != null 
                ? [(place['photos'][0]['photo_reference'] as String)] 
                : [],
            capacity: 0, // Placeholder
          );
        }).toList();
      } else {
        print('Google Places API Error: ${response.statusCode} ${response.body}');
        return [];
      }
    } catch (e) {
      print('Error searching Google Places: $e');
      return [];
    }
  }
}
