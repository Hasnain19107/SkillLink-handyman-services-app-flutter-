import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';

import '../../screens/bookings/booking_service.dart';

class CategoryProvidersList extends StatefulWidget {
  final String category;

  const CategoryProvidersList({
    Key? key,
    required this.category,
  }) : super(key: key);

  @override
  State<CategoryProvidersList> createState() => _CategoryProvidersListState();
}

class _CategoryProvidersListState extends State<CategoryProvidersList> {
  bool _isLoading = true;
  List<Map<String, dynamic>> _providers = [];
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _loadProviders();
  }

  Future<void> _loadProviders() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = '';
      });

      // Try multiple approaches to find providers

      // 1. First try: exact match on 'category' field (lowercase)
      var snapshot1 = await FirebaseFirestore.instance
          .collection('service_providers')
          .where('category', isEqualTo: widget.category.toLowerCase())
          .get();

      // 2. Second try: exact match on 'profession' field (lowercase)
      var snapshot2 = await FirebaseFirestore.instance
          .collection('service_providers')
          .where('profession', isEqualTo: widget.category.toLowerCase())
          .get();

      // 3. Third try: exact match on 'category' field (original case)
      var snapshot3 = await FirebaseFirestore.instance
          .collection('service_providers')
          .where('category', isEqualTo: widget.category)
          .get();

      // 4. Fourth try: check if category is in an array field 'services'
      var snapshot4 = await FirebaseFirestore.instance
          .collection('service_providers')
          .where('services', arrayContains: widget.category.toLowerCase())
          .get();

      // 5. Fifth try: use a text search approach
      var allProvidersSnapshot = await FirebaseFirestore.instance
          .collection('service_providers')
          .get();

      // Combine results, avoiding duplicates
      final Set<String> addedIds = {};
      final List<Map<String, dynamic>> results = [];

      // Helper function to process snapshots
      void processSnapshot(QuerySnapshot snapshot, String source) {
        print('Found ${snapshot.docs.length} providers from $source');
        for (var doc in snapshot.docs) {
          if (!addedIds.contains(doc.id)) {
            addedIds.add(doc.id);
            final data = doc.data() as Map<String, dynamic>;

            // Debug print to check the data
            print(
                'Provider data: ${doc.id} - fullName: ${data['fullName']}, name: ${data['name']}');

            // Directly use fullName since we can see it exists in the data
            final fullName = data['fullName'] ?? 'Unknown';

            results.add({
              'id': doc.id,
              'fullName': fullName, // This should now contain "Hasnain Gujjar"
              'category': data['category'] ?? data['profession'] ?? 'General',
              'rating': (data['rating'] ?? 0.0).toDouble(),
              'review': data['review'] ?? 0,
              'imageUrl': data['profileImageUrl'] ?? data['imageUrl'] ?? '',
            });

            // Debug print to verify the data being added to results
            print('Added provider to results with fullName: $fullName');
          }
        }
      }

      // Process all snapshots
      processSnapshot(snapshot1, 'category lowercase');
      processSnapshot(snapshot2, 'profession lowercase');
      processSnapshot(snapshot3, 'category original case');
      processSnapshot(snapshot4, 'services array');

      // Process all providers for text search
      for (var doc in allProvidersSnapshot.docs) {
        if (addedIds.contains(doc.id)) continue;

        final data = doc.data();
        bool matchFound = false;

        // Check various fields for partial matches
        final fieldsToCheck = [
          'category',
          'profession',
          'description',
          'services'
        ];
        for (var field in fieldsToCheck) {
          if (data.containsKey(field)) {
            var value = data[field];
            if (value is String &&
                value.toLowerCase().contains(widget.category.toLowerCase())) {
              matchFound = true;
              break;
            } else if (value is List) {
              for (var item in value) {
                if (item is String &&
                    item
                        .toLowerCase()
                        .contains(widget.category.toLowerCase())) {
                  matchFound = true;
                  break;
                }
              }
            }
          }
        }

        if (matchFound) {
          addedIds.add(doc.id);
          final fullName = data['fullName'] ??
              data['name'] ??
              data['provider_name'] ??
              'Unknown';

          results.add({
            'id': doc.id,
            'fullName': fullName,
            'category': data['category'] ?? data['profession'] ?? 'General',
            'rating': (data['rating'] ?? 0.0).toDouble(),
            'review': data['review'] ?? 0,
            'imageUrl': data['profileImageUrl'] ?? data['imageUrl'] ?? '',
          });
        }
      }

      // Sort by rating
      results.sort(
          (a, b) => (b['rating'] as double).compareTo(a['rating'] as double));

      setState(() {
        _providers = results;
        _isLoading = false;
      });

      print('Final provider count: ${_providers.length}');
    } catch (e) {
      print('Error loading providers: $e');
      setState(() {
        _errorMessage = 'Error loading providers: $e';
        _isLoading = false;
      });
    }
  }

  Future<String> _getProviderImageUrl(
      String providerId, String? existingUrl) async {
    // If we already have an image URL from the document, use it
    if (existingUrl != null && existingUrl.isNotEmpty) {
      return existingUrl;
    }

    try {
      // Get reference to the image in Firebase Storage
      final ref = FirebaseStorage.instance
          .ref()
          .child('profile_images') // Changed from 'providers_images'
          .child('$providerId.jpg');

      // Get download URL with timeout
      final url = await ref.getDownloadURL().timeout(
        const Duration(seconds: 5),
        onTimeout: () {
          print('Image load timeout');
          throw TimeoutException('Failed to load image');
        },
      );
      return url;
    } catch (e) {
      print('Error loading provider image: $e');
      return 'https://randomuser.me/api/portraits/lego/1.jpg';
    }
  }

  @override
  Widget build(BuildContext context) {
    Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.category} Providers'),
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _errorMessage.isNotEmpty
                ? Center(child: Text(_errorMessage))
                : _providers.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.search_off,
                              size: 64,
                              color: Colors.grey[400],
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'No ${widget.category} providers found',
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Try searching for a different category',
                              style: TextStyle(
                                color: Colors.grey[600],
                              ),
                            ),
                            const SizedBox(height: 24),
                            ElevatedButton(
                              onPressed: _loadProviders,
                              child: const Text('Retry'),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        itemCount: _providers.length,
                        itemBuilder: (context, index) {
                          final provider = _providers[index];

                          return FutureBuilder<String>(
                            future: _getProviderImageUrl(
                              provider['id'] ?? '', // Add null check
                              provider['imageUrl']
                                  as String?, // Proper type casting
                            ),
                            builder: (context, imageSnapshot) {
                              if (imageSnapshot.connectionState ==
                                  ConnectionState.waiting) {
                                return const Padding(
                                  padding: EdgeInsets.symmetric(vertical: 8.0),
                                  child: Center(
                                    child: CircularProgressIndicator(),
                                  ),
                                );
                              }

                              final String imageUrl = imageSnapshot.data ??
                                  'https://randomuser.me/api/portraits/lego/1.jpg';

                              return ProviderCard(
                                name: provider['fullName']?.toString() ??
                                    'Unknown', // Add null check
                                profession: provider['category']?.toString() ??
                                    'General', // Add null check
                                rating: double.parse(
                                    ((provider['rating'] as num?)?.toDouble() ??
                                            0.0)
                                        .toStringAsFixed(2)),
                                reviews:
                                    (provider['review'] as num?)?.toInt() ??
                                        0, // Add null check
                                imageUrl: imageUrl,
                                id: provider['id']?.toString() ??
                                    '', // Add null check
                              );
                            },
                          );
                        },
                      ),
      ),
    );
  }
}

// Reuse your existing ProviderCard class
class ProviderCard extends StatelessWidget {
  final String id;
  final String name;
  final String profession;
  final double rating;
  final int reviews;
  final String imageUrl;

  const ProviderCard({
    Key? key,
    required this.id,
    required this.name,
    required this.profession,
    required this.rating,
    required this.reviews,
    required this.imageUrl,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      width: double.infinity,
      constraints: const BoxConstraints(minHeight: 80),
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12.0),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.2),
            spreadRadius: 2,
            blurRadius: 5,
          ),
        ],
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 30,
            backgroundImage: NetworkImage(imageUrl),
            onBackgroundImageError: (exception, stackTrace) {
              // Show default image on error
              NetworkImage('https://randomuser.me/api/portraits/lego/1.jpg');
            },
            child: imageUrl.isEmpty ? const Icon(Icons.person, size: 30) : null,
          ),
          const SizedBox(width: 20),
          Expanded(
            flex: 3,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: const TextStyle(fontWeight: FontWeight.bold)),
                Text(profession),
                Row(
                  children: [
                    Icon(Icons.star, color: Colors.yellow, size: 16),
                    Text('$rating ($reviews review)'),
                  ],
                ),
              ],
            ),
          ),
          Expanded(
            flex: 1,
            child: ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => BookingServiceScreen(
                      providerId: id,
                      providerData: {
                        'fullName': name,
                        'category': profession,
                        'rating': rating,
                        'review': reviews,
                        'imageUrl': imageUrl,
                      },
                    ),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                minimumSize: const Size(60, 30),
                textStyle: const TextStyle(fontSize: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text('Book'),
            ),
          ),
        ],
      ),
    );
  }
}
