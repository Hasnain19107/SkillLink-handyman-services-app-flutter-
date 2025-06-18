import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';

class SearchProvider {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Search providers by query

  Future<List<Map<String, dynamic>>> searchProviders(String query,
      {String? category, int limit = 10}) async {
    try {
      // Create a list to store results
      List<Map<String, dynamic>> results = [];
      Set<String> addedIds = {};

      // If category is provided, search within that category
      if (category != null && category.isNotEmpty) {
        final categorySnapshot = await _firestore
            .collection('service_providers') // Changed from 'providers'
            .where('category', isEqualTo: category.toLowerCase())
            .limit(limit)
            .get();

        // If no results, try with profession field
        if (categorySnapshot.docs.isEmpty) {
          final professionSnapshot = await _firestore
              .collection('service_providers')
              .where('profession', isEqualTo: category.toLowerCase())
              .limit(limit)
              .get();

          for (var doc in professionSnapshot.docs) {
            if (!addedIds.contains(doc.id)) {
              addedIds.add(doc.id);
              results.add(_mapProviderData(doc));
            }
          }
        } else {
          for (var doc in categorySnapshot.docs) {
            if (!addedIds.contains(doc.id)) {
              addedIds.add(doc.id);
              results.add(_mapProviderData(doc));
            }
          }
        }
      }

      // If query is provided, search by keywords
      if (query.isNotEmpty) {
        // Search by keywords (exact match)
        final keywordSnapshot = await _firestore
            .collection('service_providers')
            .where('searchKeywords', arrayContains: query.toLowerCase())
            .limit(limit)
            .get();

        for (var doc in keywordSnapshot.docs) {
          if (!addedIds.contains(doc.id)) {
            addedIds.add(doc.id);
            results.add(_mapProviderData(doc));
          }
        }

        // Search by name (partial match)
        final nameSnapshot = await _firestore
            .collection('service_providers')
            .orderBy('fullName')
            .startAt([query.toLowerCase()])
            .endAt([query.toLowerCase() + '\uf8ff'])
            .limit(limit)
            .get();

        for (var doc in nameSnapshot.docs) {
          if (!addedIds.contains(doc.id)) {
            addedIds.add(doc.id);
            results.add(_mapProviderData(doc));
          }
        }

        // Search by services offered
        final servicesSnapshot = await _firestore
            .collection('service_providers')
            .where('services', arrayContains: query.toLowerCase())
            .limit(limit)
            .get();

        for (var doc in servicesSnapshot.docs) {
          if (!addedIds.contains(doc.id)) {
            addedIds.add(doc.id);
            results.add(_mapProviderData(doc));
          }
        }

        // If still no results and query is at least 3 characters, try a more general search
        if (results.isEmpty && query.length >= 3) {
          // Try searching by profession
          final professionSnapshot = await _firestore
              .collection('service_providers')
              .where('profession', isGreaterThanOrEqualTo: query.toLowerCase())
              .where('profession',
                  isLessThanOrEqualTo: query.toLowerCase() + '\uf8ff')
              .limit(limit)
              .get();

          for (var doc in professionSnapshot.docs) {
            if (!addedIds.contains(doc.id)) {
              addedIds.add(doc.id);
              results.add(_mapProviderData(doc));
            }
          }
        }
      }

      // Sort results by rating (highest first)
      results
          .sort((a, b) => (b['rating'] ?? 0.0).compareTo(a['rating'] ?? 0.0));

      return results;
    } catch (e) {
      print('Error searching providers: $e');
      return [];
    }
  }

  // Get provider by ID
  Future<Map<String, dynamic>?> getProviderById(String id) async {
    try {
      final doc =
          await _firestore.collection('service_providers').doc(id).get();
      if (doc.exists) {
        return _mapProviderData(doc);
      }
      return null;
    } catch (e) {
      print('Error getting provider: $e');
      return null;
    }
  }

  // Get nearby providers based on location
  Future<List<Map<String, dynamic>>> getNearbyProviders(
      double latitude, double longitude,
      {double radiusKm = 10, int limit = 10}) async {
    try {
      // This is a simplified approach - for a real app, you'd use GeoFirestore or similar
      // to perform proper geospatial queries
      final snapshot =
          await _firestore.collection('providers').limit(limit).get();

      List<Map<String, dynamic>> results = [];
      for (var doc in snapshot.docs) {
        final data = doc.data();
        if (data.containsKey('location') &&
            data['location'] != null &&
            data['location']['latitude'] != null &&
            data['location']['longitude'] != null) {
          // Calculate distance (simplified)
          final providerLat = data['location']['latitude'];
          final providerLng = data['location']['longitude'];

          // Simple distance calculation (not accurate for long distances)
          final distance =
              _calculateDistance(latitude, longitude, providerLat, providerLng);

          if (distance <= radiusKm) {
            final providerData = _mapProviderData(doc);
            providerData['distance'] = distance;
            results.add(providerData);
          }
        }
      }

      // Sort by distance
      results.sort(
          (a, b) => (a['distance'] ?? 0.0).compareTo(b['distance'] ?? 0.0));

      return results;
    } catch (e) {
      print('Error getting nearby providers: $e');
      return [];
    }
  }

  // Helper method to calculate distance between two points (simplified)
  double _calculateDistance(
      double lat1, double lon1, double lat2, double lon2) {
    // This is a very simplified distance calculation
    // For a real app, use the Haversine formula or a geospatial library
    const double earthRadius = 6371; // in kilometers

    double dLat = _degreesToRadians(lat2 - lat1);
    double dLon = _degreesToRadians(lon2 - lon1);

    double a = sin(dLat / 2) * sin(dLat / 2) +
        sin(dLon / 2) * sin(dLon / 2) * cos(lat1) * cos(lat2);
    double c = 2 * atan2(sqrt(a), sqrt(1 - a));

    return earthRadius * c;
  }

  double _degreesToRadians(double degrees) {
    return degrees * (3.14159265359 / 180);
  }

  // Helper method to map Firestore document to provider data
  Map<String, dynamic> _mapProviderData(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return {
      'id': doc.id,
      'name': data['fullName'] ?? data['name'] ?? 'Unknown',
      'category': data['category'] ?? data['profession'] ?? 'General',
      'rating': data['rating'] ?? 0.0,
      'imageUrl': data['profileImageUrl'] ?? data['imageUrl'] ?? '',
      'services': data['services'] ?? [],
      'description': data['description'] ?? '',
      'location': data['location'],
      'contactInfo': data['contactInfo'],
      'availability': data['availability'],
      'reviews': data['reviews'] ?? [],
    };
  }

  // Helper method to generate search keywords for a provider
  List<String> generateSearchKeywords(
      String name, String category, List<String> services) {
    Set<String> keywords = {};

    // Add name and its parts
    final nameParts = name.toLowerCase().split(' ');
    keywords.addAll(nameParts);

    // Add category and its parts
    final categoryParts = category.toLowerCase().split(' ');
    keywords.addAll(categoryParts);

    // Add services and their parts
    for (String service in services) {
      keywords.add(service.toLowerCase());
      keywords.addAll(service.toLowerCase().split(' '));
    }

    // Generate prefixes for name (for partial matching)
    for (String part in nameParts) {
      for (int i = 1; i <= part.length; i++) {
        keywords.add(part.substring(0, i));
      }
    }

    return keywords.toList();
  }
}
