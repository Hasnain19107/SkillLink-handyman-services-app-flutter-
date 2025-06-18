import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../earnings/provider_earnings_screen.dart';

class ProviderStatsCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  const ProviderStatsCard({
    Key? key,
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? Colors.grey[800] : Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
        border: Border.all(
          color: isDark ? Colors.grey[700]! : Colors.grey[200]!,
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Icon(
                icon,
                color: color,
                size: 24,
              ),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  icon,
                  color: color,
                  size: 16,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            title,
            style: TextStyle(
              fontSize: 14,
              color: isDark ? Colors.grey[400] : Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          Flexible(
            child: Text(
              value,
              style: TextStyle(
                fontSize: title == 'Rating'
                    ? 14
                    : 20, // Smaller font for rating to fit
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : Colors.black87,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

class StatsSection extends StatelessWidget {
  final int pendingBookings;
  final int completedJobs;
  final double totalEarnings;
  final VoidCallback onPendingTap;
  final VoidCallback onCompletedTap;
  final VoidCallback onRatingTap;

  const StatsSection({
    Key? key,
    required this.pendingBookings,
    required this.completedJobs,
    required this.totalEarnings,
    required this.onPendingTap,
    required this.onCompletedTap,
    required this.onRatingTap,
  }) : super(key: key);

  // Helper function to format earnings with 'k' for thousands
  String _formatEarnings(double amount) {
    if (amount >= 1000) {
      return '\Rs${(amount / 1000).toStringAsFixed(1)}k';
    } else {
      return '\Rs${amount.toStringAsFixed(0)}';
    }
  }

  @override
  Widget build(BuildContext context) {
    final FirebaseAuth _auth = FirebaseAuth.instance;
    final FirebaseFirestore _firestore = FirebaseFirestore.instance;

    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: GestureDetector(
                onTap: onPendingTap,
                child: ProviderStatsCard(
                  title: 'Pending',
                  value: pendingBookings.toString(),
                  icon: Icons.pending_actions,
                  color: Color(0xFFE9C46A),
                ),
              ),
            ),
            SizedBox(width: 12),
            Expanded(
              child: GestureDetector(
                onTap: onCompletedTap,
                child: ProviderStatsCard(
                  title: 'Completed',
                  value: completedJobs.toString(),
                  icon: Icons.check_circle_outline,
                  color: Color(0xFF2A9D8F),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const ProviderEarningsScreen(),
                    ),
                  );
                },
                child: ProviderStatsCard(
                  title:
                      'Earnings', // Changed from 'Total Earnings' to just 'Earnings'
                  value:
                      _formatEarnings(totalEarnings), // Use formatted earnings
                  icon: Icons.attach_money,
                  color: Colors.green,
                ),
              ),
            ),
            SizedBox(width: 12),
            Expanded(
              child: GestureDetector(
                onTap: onRatingTap,
                child: StreamBuilder<QuerySnapshot>(
                  stream: _firestore
                      .collection('ratings_reviews')
                      .where('providerId', isEqualTo: _auth.currentUser?.uid)
                      .snapshots(),
                  builder: (context, snapshot) {
                    double currentRating = 0.0;
                    int currentReviews = 0;

                    if (snapshot.hasData && snapshot.data!.docs.isNotEmpty) {
                      currentReviews = snapshot.data!.docs.length;
                      double totalRating = 0.0;

                      for (var doc in snapshot.data!.docs) {
                        final reviewData = doc.data() as Map<String, dynamic>;
                        totalRating += (reviewData['rating'] ?? 0.0).toDouble();
                      }

                      currentRating = currentReviews > 0
                          ? totalRating / currentReviews
                          : 0.0;
                    }

                    return ProviderStatsCard(
                      title: 'Rating',
                      value: currentReviews > 0
                          ? '${currentRating.toStringAsFixed(1)} (${currentReviews})'
                          : 'No reviews',
                      icon: Icons.star,
                      color: Colors.amber,
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class ProviderAvailabilityCard extends StatelessWidget {
  final bool isAvailable;
  final VoidCallback onToggleAvailability;
  final double rating;
  final int completedJobs;

  const ProviderAvailabilityCard({
    Key? key,
    required this.isAvailable,
    required this.onToggleAvailability,
    required this.rating,
    required this.completedJobs,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? Colors.grey[850] : Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: [
          // Availability toggle
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: isAvailable
                  ? (isDark ? const Color(0xFF1E3A38) : const Color(0xFFE6F7F5))
                  : (isDark ? Colors.grey[800] : Colors.grey[200]),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        color:
                            isAvailable ? const Color(0xFF2A9D8F) : Colors.grey,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      isAvailable
                          ? 'You are available for work'
                          : 'You are unavailable',
                      style: TextStyle(
                        fontWeight: FontWeight.w500,
                        color: isAvailable
                            ? const Color(0xFF2A9D8F)
                            : isDark
                                ? Colors.white70
                                : Colors.grey[700],
                      ),
                    ),
                  ],
                ),
                Switch(
                  value: isAvailable,
                  onChanged: (_) => onToggleAvailability(),
                  activeColor: const Color(0xFF2A9D8F),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Stats
          Row(
            children: [
              Expanded(
                child: _buildStat(
                  context,
                  Icons.star,
                  rating.toStringAsFixed(1),
                  'Rating',
                  Colors.amber,
                ),
              ),
              Container(
                height: 40,
                width: 1,
                color: isDark ? Colors.grey[700] : Colors.grey[300],
              ),
              Expanded(
                child: _buildStat(
                  context,
                  Icons.check_circle,
                  completedJobs.toString(),
                  'Completed',
                  isDark ? Colors.green[300]! : Colors.green,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStat(
    BuildContext context,
    IconData icon,
    String value,
    String label,
    Color iconColor,
  ) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: iconColor,
              size: 18,
            ),
            const SizedBox(width: 4),
            Text(
              value,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : Colors.black87,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            color: isDark ? Colors.grey[400] : Colors.grey[600],
          ),
        ),
      ],
    );
  }
}
