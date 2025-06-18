import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart'; // Import FirebaseAuth

class RatingReviewScreen extends StatefulWidget {
  final String bookingId;
  final String providerId;

  const RatingReviewScreen({
    Key? key,
    required this.bookingId,
    required this.providerId,
  }) : super(key: key);

  @override
  _RatingReviewScreenState createState() => _RatingReviewScreenState();
}

class _RatingReviewScreenState extends State<RatingReviewScreen> {
  double _rating = 0;
  final TextEditingController _reviewController = TextEditingController();
  bool _isSubmitting = false;

  // Get Firestore and Auth instances
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  @override
  void dispose() {
    _reviewController.dispose();
    super.dispose();
  }

  Future<void> _submitRatingAndReview() async {
    if (_rating == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a rating')),
      );
      return;
    }

    final currentUser = _auth.currentUser;
    if (currentUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('You must be logged in to submit a review.')),
      );
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      final seekerId = currentUser.uid;
      // Fetch seeker details (name and profile image URL)
      final seekerDoc =
          await _firestore.collection('users').doc(seekerId).get();
      final seekerData = seekerDoc.data();
      final seekerName =
          seekerData?['firstName'] != null && seekerData?['lastName'] != null
              ? '${seekerData!['firstName']} ${seekerData['lastName']}'
              : seekerData?['displayName'] ?? 'Anonymous User'; // Fallback name
      final seekerProfileImageUrl = seekerData?[
          'profileImageUrl']; // Assuming field name is 'profileImageUrl'

      // 1. Create the review document in the new 'ratings_reviews' collection
      await _firestore.collection('ratings_reviews').add({
        'bookingId': widget.bookingId,
        'providerId': widget.providerId,
        'seekerId': seekerId,
        'seekerName': seekerName,
        'seekerProfileImageUrl': seekerProfileImageUrl,
        'rating': _rating,
        'reviewText': _reviewController.text.trim(),
        'timestamp': FieldValue.serverTimestamp(),
      });

      // 2. Update the provider's average rating and total reviews
      final providerRef =
          _firestore.collection('service_providers').doc(widget.providerId);

      // Use a transaction to ensure atomic read and update
      await _firestore.runTransaction((transaction) async {
        final providerSnapshot = await transaction.get(providerRef);

        if (!providerSnapshot.exists) {
          throw Exception("Provider not found!");
        }

        // Use 'averageRating' and 'totalReviews' as per the design doc
        final currentAverageRating =
            (providerSnapshot.data()?['averageRating'] ?? 0.0) as num;
        final currentTotalReviews =
            (providerSnapshot.data()?['totalReviews'] ?? 0) as num;

        // Calculate new average rating
        final newTotalReviews = currentTotalReviews + 1;
        final newAverageRating =
            ((currentAverageRating * currentTotalReviews) + _rating) /
                newTotalReviews;

        // Update provider document within the transaction
        transaction.update(providerRef, {
          'averageRating': newAverageRating,
          'totalReviews': newTotalReviews,
        });
      });

      // Optional: Update the booking to mark it as reviewed (prevents re-reviewing)
      // Consider adding a 'isReviewed' field to the 'booking_service' collection
      // await _firestore.collection('booking_service').doc(widget.bookingId).update({'isReviewed': true});

      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Thank you for your feedback!')),
      );

      // Navigate back
      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error submitting review: $e')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Rate & Review'),
        elevation: 0,
      ),
      body: _isSubmitting
          ? const Center(
              child: CircularProgressIndicator(),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header
                  Text(
                    'How was your experience?',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Your feedback helps improve service quality',
                    style: TextStyle(
                      fontSize: 16,
                      color: isDark ? Colors.grey[300] : Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Rating stars
                  Center(
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: List.generate(5, (index) {
                            return IconButton(
                              icon: Icon(
                                index < _rating
                                    ? Icons.star
                                    : Icons.star_border,
                                size: 40,
                                color: index < _rating
                                    ? Colors.amber
                                    : isDark
                                        ? Colors.grey[400]
                                        : Colors.grey[600],
                              ),
                              onPressed: () {
                                setState(() {
                                  _rating =
                                      index + 1.0; // Ensure rating is double
                                });
                              },
                            );
                          }),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _getRatingText(),
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: _rating > 0
                                ? Colors.amber
                                : isDark
                                    ? Colors.grey[400]
                                    : Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Review text field
                  Text(
                    'Write a review (optional)',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _reviewController,
                    maxLines: 5,
                    decoration: InputDecoration(
                      hintText: 'Share your experience with this service...',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      filled: true,
                      fillColor: isDark ? Colors.grey[800] : Colors.grey[100],
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Submit button
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: _isSubmitting
                          ? null
                          : _submitRatingAndReview, // Disable button while submitting
                      style: ElevatedButton.styleFrom(
                        backgroundColor: theme.colorScheme.primary,
                        foregroundColor: theme.colorScheme.onPrimary,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        'Submit',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  String _getRatingText() {
    switch (_rating.toInt()) {
      case 0:
        return 'Tap to rate';
      case 1:
        return 'Poor';
      case 2:
        return 'Fair';
      case 3:
        return 'Good';
      case 4:
        return 'Very Good';
      case 5:
        return 'Excellent';
      default:
        return '';
    }
  }
}
