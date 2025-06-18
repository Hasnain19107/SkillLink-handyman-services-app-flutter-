import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart'; // For date formatting
import 'package:shimmer/shimmer.dart'; // For shimmer loading effect

class ProviderReviewsScreen extends StatefulWidget {
  final String providerId;

  const ProviderReviewsScreen({Key? key, required this.providerId})
      : super(key: key);

  @override
  _ProviderReviewsScreenState createState() => _ProviderReviewsScreenState();
}

class _ProviderReviewsScreenState extends State<ProviderReviewsScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  void initState() {
    super.initState();
    _updateProviderRatingAndReviews();
  }

  Future<void> _updateProviderRatingAndReviews() async {
    try {
      QuerySnapshot reviewsSnapshot = await _firestore
          .collection('ratings_reviews')
          .where('providerId', isEqualTo: widget.providerId)
          .get();

      int totalReviews = reviewsSnapshot.docs.length;
      double totalRating = 0.0;
      for (var doc in reviewsSnapshot.docs) {
        final reviewData = doc.data() as Map<String, dynamic>;
        totalRating += (reviewData['rating'] ?? 0.0).toDouble();
      }
      double averageRating =
          totalReviews > 0 ? totalRating / totalReviews : 0.0;

      await _firestore
          .collection('service_providers')
          .doc(widget.providerId)
          .update({
        'rating': averageRating,
        'review': totalReviews,
      });
    } catch (e) {
      print('Error updating provider rating and reviews: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to update provider data: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Ratings & Reviews'),
        elevation: 0,
        backgroundColor: theme.colorScheme.surface,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _updateProviderRatingAndReviews,
            tooltip: 'Refresh Reviews',
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _updateProviderRatingAndReviews,
        child: Column(
          children: [
            _buildSummarySection(theme, isDark),
            const Divider(height: 1, thickness: 1),
            Expanded(
              child: _buildReviewsList(theme, isDark),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummarySection(ThemeData theme, bool isDark) {
    return StreamBuilder<DocumentSnapshot>(
      stream: _firestore
          .collection('service_providers')
          .doc(widget.providerId)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return _buildSummaryShimmer(isDark);
        }
        if (!snapshot.hasData || !snapshot.data!.exists) {
          return const Padding(
            padding: EdgeInsets.all(16.0),
            child: Center(child: Text('Provider data not found.')),
          );
        }

        final providerData = snapshot.data!.data() as Map<String, dynamic>;
        final averageRating = (providerData['averageRating'] ?? 0.0).toDouble();
        final totalReviews = (providerData['totalReviews'] ?? 0).toInt();

        return AnimatedOpacity(
          opacity: snapshot.hasData ? 1.0 : 0.0,
          duration: const Duration(milliseconds: 500),
          child: Container(
            margin: const EdgeInsets.all(16.0),
            padding: const EdgeInsets.all(20.0),
            decoration: BoxDecoration(
              color: isDark ? Colors.grey[800] : Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(isDark ? 0.2 : 0.1),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                Column(
                  children: [
                    Text(
                      averageRating.toStringAsFixed(1),
                      style: TextStyle(
                        fontSize: 40,
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: List.generate(5, (index) {
                        return Icon(
                          index < averageRating.round()
                              ? Icons.star
                              : Icons.star_border,
                          color: Colors.amber,
                          size: 24,
                        );
                      }),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Average Rating',
                      style: TextStyle(
                        fontSize: 14,
                        color: isDark ? Colors.grey[400] : Colors.grey[600],
                      ),
                    ),
                  ],
                ),
                Column(
                  children: [
                    Text(
                      totalReviews.toString(),
                      style: TextStyle(
                        fontSize: 40,
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.secondary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Total Reviews',
                      style: TextStyle(
                        fontSize: 14,
                        color: isDark ? Colors.grey[400] : Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildSummaryShimmer(bool isDark) {
    return Shimmer.fromColors(
      baseColor: isDark ? Colors.grey[700]! : Colors.grey[300]!,
      highlightColor: isDark ? Colors.grey[600]! : Colors.grey[100]!,
      child: Container(
        margin: const EdgeInsets.all(16.0),
        padding: const EdgeInsets.all(20.0),
        decoration: BoxDecoration(
          color: Colors.grey[300],
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            Column(
              children: [
                Container(
                  width: 60,
                  height: 40,
                  color: Colors.white,
                ),
                const SizedBox(height: 8),
                Row(
                  children: List.generate(
                      5,
                      (_) => Container(
                            width: 24,
                            height: 24,
                            color: Colors.white,
                            margin: const EdgeInsets.symmetric(horizontal: 2),
                          )),
                ),
                const SizedBox(height: 8),
                Container(
                  width: 80,
                  height: 14,
                  color: Colors.white,
                ),
              ],
            ),
            Column(
              children: [
                Container(
                  width: 60,
                  height: 40,
                  color: Colors.white,
                ),
                const SizedBox(height: 8),
                Container(
                  width: 80,
                  height: 14,
                  color: Colors.white,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReviewsList(ThemeData theme, bool isDark) {
    return StreamBuilder<QuerySnapshot>(
      stream: _firestore
          .collection('ratings_reviews')
          .where('providerId', isEqualTo: widget.providerId)
          .orderBy('timestamp', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return _buildReviewsShimmer(isDark);
        }
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Center(
            child: Text(
              'No reviews yet.',
              style: TextStyle(
                fontSize: 16,
                color: isDark ? Colors.grey[400] : Colors.grey[600],
              ),
            ),
          );
        }

        final reviews = snapshot.data!.docs;

        return ListView.separated(
          padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
          itemCount: reviews.length,
          separatorBuilder: (context, index) => const SizedBox(height: 8),
          itemBuilder: (context, index) {
            final reviewData = reviews[index].data() as Map<String, dynamic>;
            return AnimatedSlide(
              offset: Offset(0, index % 2 == 0 ? 0.1 : -0.1),
              duration: Duration(milliseconds: 300 + index * 100),
              child: _buildReviewItem(reviewData, theme, isDark),
            );
          },
        );
      },
    );
  }

  Widget _buildReviewsShimmer(bool isDark) {
    return Shimmer.fromColors(
      baseColor: isDark ? Colors.grey[700]! : Colors.grey[300]!,
      highlightColor: isDark ? Colors.grey[600]! : Colors.grey[100]!,
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
        itemCount: 3,
        itemBuilder: (context, index) {
          return Container(
            margin: const EdgeInsets.symmetric(vertical: 8.0),
            padding: const EdgeInsets.all(16.0),
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: 100,
                            height: 15,
                            color: Colors.white,
                          ),
                          const SizedBox(height: 4),
                          Container(
                            width: 60,
                            height: 12,
                            color: Colors.white,
                          ),
                        ],
                      ),
                    ),
                    Row(
                      children: List.generate(
                          5,
                          (_) => Container(
                                width: 18,
                                height: 18,
                                color: Colors.white,
                                margin:
                                    const EdgeInsets.symmetric(horizontal: 2),
                              )),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Container(
                  width: double.infinity,
                  height: 40,
                  color: Colors.white,
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildReviewItem(
      Map<String, dynamic> reviewData, ThemeData theme, bool isDark) {
    final seekerName = reviewData['seekerName'] ?? 'Anonymous';
    final seekerImageUrl = reviewData['seekerProfileImageUrl'];
    final rating = (reviewData['rating'] ?? 0.0).toDouble();
    final reviewText = reviewData['reviewText'] ?? '';
    final timestamp = reviewData['timestamp'] as Timestamp?;
    final formattedDate = timestamp != null
        ? DateFormat('MMM d, yyyy').format(timestamp.toDate())
        : '';

    // Generate initials for placeholder avatar
    String initials = seekerName.isNotEmpty
        ? seekerName.split(' ').map((e) => e[0]).take(2).join().toUpperCase()
        : 'AN';

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () {}, // Optional: Add interaction if needed
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 24,
                    backgroundColor:
                        isDark ? Colors.grey[700] : Colors.grey[200],
                    backgroundImage: seekerImageUrl != null
                        ? NetworkImage(seekerImageUrl)
                        : null,
                    child: seekerImageUrl == null
                        ? Text(
                            initials,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color:
                                  isDark ? Colors.grey[300] : Colors.grey[700],
                            ),
                          )
                        : null,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          seekerName,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: isDark ? Colors.grey[200] : Colors.black87,
                          ),
                          semanticsLabel: 'Reviewer: $seekerName',
                        ),
                        const SizedBox(height: 4),
                        Text(
                          formattedDate,
                          style: TextStyle(
                            fontSize: 12,
                            color: isDark ? Colors.grey[400] : Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                  Row(
                    children: List.generate(5, (i) {
                      return Icon(
                        i < rating ? Icons.star : Icons.star_border,
                        color: Colors.amber,
                        size: 20,
                      );
                    }),
                  ),
                ],
              ),
              if (reviewText.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 12.0, left: 60.0),
                  child: Text(
                    reviewText,
                    style: TextStyle(
                      fontSize: 14,
                      color: isDark ? Colors.grey[300] : Colors.black87,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
