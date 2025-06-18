import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';

import '../../screens/search/provider_detail.dart';

class TopRatedProviders extends StatelessWidget {
  const TopRatedProviders({Key? key}) : super(key: key);

  Future<String> _getProviderImageUrl(String providerId) async {
    try {
      // First try to get URL from Firestore
      final providerDoc = await FirebaseFirestore.instance
          .collection('service_providers')
          .doc(providerId)
          .get();

      if (providerDoc.exists) {
        final profileImageUrl = providerDoc.data()?['profileImageUrl'];
        if (profileImageUrl != null && profileImageUrl.toString().isNotEmpty) {
          return profileImageUrl.toString();
        }
      }

      // If not found in Firestore, try Firebase Storage
      final ref = FirebaseStorage.instance
          .ref()
          .child('profile_images')
          .child('${providerId}.jpg');

      final url = await ref.getDownloadURL().timeout(
        const Duration(seconds: 5),
        onTimeout: () {
          return '';
        },
      );
      return url;
    } catch (e) {
      return 'https://randomuser.me/api/portraits/lego/1.jpg';
    }
  }

  @override
  Widget build(BuildContext context) {
    // Get the current theme
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('service_providers')
            .orderBy('rating', descending: true)
            .limit(5)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Padding(
              padding: EdgeInsets.all(16.0),
              child: CircularProgressIndicator(),
            );
          }
          if (snapshot.hasError) {
            return Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(
                'Error: ${snapshot.error}',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.error,
                ),
              ),
            );
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ProviderCard(
                  name: 'John Smith',
                  profession: 'Electrician',
                  rating: 4.9,
                  reviews: 128,
                  imageUrl: 'https://randomuser.me/api/portraits/men/32.jpg',
                  id: '',
                  isDarkMode: isDarkMode,
                ),
                ProviderCard(
                  name: 'Sarah Johnson',
                  profession: 'House Cleaner',
                  rating: 4.8,
                  reviews: 95,
                  imageUrl: 'https://randomuser.me/api/portraits/women/67.jpg',
                  id: '',
                  isDarkMode: isDarkMode,
                ),
              ],
            );
          }
          return Column(
            mainAxisSize: MainAxisSize.min,
            children: snapshot.data!.docs.map((doc) {
              var data = doc.data() as Map<String, dynamic>;
              return FutureBuilder<String>(
                future: _getProviderImageUrl(doc.id),
                builder: (context, imageSnapshot) {
                  if (imageSnapshot.connectionState ==
                      ConnectionState.waiting) {
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: CircularProgressIndicator(
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                    );
                  }

                  String imageUrl = imageSnapshot.data ??
                      'https://randomuser.me/api/portraits/lego/1.jpg';

                  return ProviderCard(
                    name: data['fullName'] ?? 'Name not available',
                    profession: data['category'] ?? 'Category not set',
                    rating: (data['rating'] ?? 0.0).toDouble(),
                    reviews: data['review'] ?? 0,
                    imageUrl: imageUrl,
                    id: doc.id,
                    isDarkMode: isDarkMode,
                  );
                },
              );
            }).toList(),
          );
        },
      ),
    );
  }
}

class ProviderCard extends StatelessWidget {
  final String id;
  final String name;
  final String profession;
  final double rating;
  final int reviews;
  final String imageUrl;
  final bool isDarkMode;

  const ProviderCard({
    Key? key,
    required this.id,
    required this.name,
    required this.profession,
    required this.rating,
    required this.reviews,
    required this.imageUrl,
    required this.isDarkMode,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SizedBox(
      child: Container(
        width: double.infinity,
        constraints: const BoxConstraints(minHeight: 80),
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(12.0),
        decoration: BoxDecoration(
          color: isDarkMode ? theme.cardColor : Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: isDarkMode ? Colors.black26 : Colors.grey.withOpacity(0.2),
              spreadRadius: 2,
              blurRadius: 5,
            ),
          ],
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: 30,
              backgroundColor:
                  isDarkMode ? theme.colorScheme.surface : Colors.grey[200],
              backgroundImage:
                  imageUrl.isNotEmpty ? NetworkImage(imageUrl) : null,
              onBackgroundImageError:
                  imageUrl.isNotEmpty ? (exception, stackTrace) {} : null,
              child: imageUrl.isEmpty
                  ? Icon(Icons.person,
                      size: 30,
                      color: isDarkMode
                          ? theme.colorScheme.onSurface
                          : Colors.grey)
                  : null,
            ),
            const SizedBox(width: 20),
            Expanded(
              flex: 3,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name.isNotEmpty ? name : 'Name not available',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: theme.textTheme.bodyLarge?.color,
                    ),
                  ),
                  Text(
                    profession.isNotEmpty ? profession : 'Category not set',
                    style: TextStyle(
                      color: theme.textTheme.bodyMedium?.color,
                    ),
                  ),
                  Row(
                    children: [
                      const Icon(Icons.star, color: Colors.amber, size: 16),
                      Text(
                        '${rating.toStringAsFixed(1)} ($reviews review)',
                        style: TextStyle(
                          color: theme.textTheme.bodySmall?.color,
                        ),
                      ),
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
                      builder: (context) => ProviderDetailScreen(
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
                  backgroundColor: theme.colorScheme.primary,
                  foregroundColor: theme.colorScheme.onPrimary,
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
      ),
    );
  }
}
