import 'package:flutter/material.dart';

class ProviderProfileHeader extends StatelessWidget {
  final String imageUrl;
  final String fullName;
  final String phone;
  final String email;
  final String address;
  final String userType;
  final String category;
  final double hourlyRate;
  final String verificationStatus;

  const ProviderProfileHeader({
    Key? key,
    required this.imageUrl,
    required this.fullName,
    required this.phone,
    required this.email,
    required this.address,
    required this.userType,
    required this.category,
    required this.hourlyRate,
    this.verificationStatus = 'unverified',
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? Colors.grey[850] : Colors.white,
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
          Stack(
            children: [
              CircleAvatar(
                radius: 50,
                backgroundColor: isDark ? Colors.grey[700] : Colors.grey[300],
                backgroundImage:
                    imageUrl.isNotEmpty ? NetworkImage(imageUrl) : null,
                child: imageUrl.isEmpty
                    ? Icon(Icons.person,
                        size: 50,
                        color: isDark ? Colors.grey[500] : Colors.grey[600])
                    : null,
              ),
              if (verificationStatus == 'verified')
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(
                      color: Colors.green,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.verified,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            fullName,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : Colors.black87,
            ),
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                userType,
                style: TextStyle(
                  color: isDark ? Colors.grey[400] : Colors.grey[600],
                ),
              ),
              if (category.isNotEmpty) ...[
                Text(
                  ' • ',
                  style: TextStyle(
                    color: isDark ? Colors.grey[400] : Colors.grey[600],
                  ),
                ),
                Text(
                  category,
                  style: TextStyle(
                    color: isDark ? Colors.grey[400] : Colors.grey[600],
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 8),
          _buildVerificationBadge(context),
          const SizedBox(height: 16),
          if (hourlyRate > 0)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFF2A9D8F).withOpacity(0.1),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Text(
                '\Rs${hourlyRate.toStringAsFixed(2)}/hr',
                style: const TextStyle(
                  color: Color(0xFF2A9D8F),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          const SizedBox(height: 16),
          const Divider(),
          const SizedBox(height: 8),
          _buildInfoRow(Icons.phone, phone),
          const SizedBox(height: 8),
          _buildInfoRow(Icons.email, email),
          if (address.isNotEmpty) ...[
            const SizedBox(height: 8),
            _buildInfoRow(Icons.location_on, address),
          ],
        ],
      ),
    );
  }

  Widget _buildVerificationBadge(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    Color badgeColor;
    String badgeText;
    IconData badgeIcon;

    switch (verificationStatus) {
      case 'verified':
        badgeColor = Colors.green;
        badgeText = 'Verified';
        badgeIcon = Icons.verified;
        break;
      case 'pending':
        badgeColor = Colors.orange;
        badgeText = 'Verification Pending';
        badgeIcon = Icons.pending;
        break;
      case 'rejected':
        badgeColor = Colors.red;
        badgeText = 'Verification Rejected';
        badgeIcon = Icons.cancel;
        break;
      default:
        badgeColor = isDark ? Colors.grey[400]! : Colors.grey;
        badgeText = 'Unverified';
        badgeIcon = Icons.error_outline;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: badgeColor.withOpacity(isDark ? 0.2 : 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: badgeColor.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            badgeIcon,
            size: 16,
            color: badgeColor,
          ),
          const SizedBox(width: 4),
          Text(
            badgeText,
            style: TextStyle(
              color: badgeColor,
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String text) {
    return Row(
      children: [
        Icon(
          icon,
          size: 20,
          color: const Color(0xFF2A9D8F),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(
              fontSize: 14,
            ),
          ),
        ),
      ],
    );
  }
}
