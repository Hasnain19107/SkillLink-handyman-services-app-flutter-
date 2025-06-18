import 'package:flutter/material.dart';

class VerificationBadge extends StatelessWidget {
  final String status;
  final double size;
  final bool showText;

  const VerificationBadge({
    Key? key,
    required this.status,
    this.size = 24.0,
    this.showText = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    IconData icon;
    Color color;
    String text;

    switch (status) {
      case 'verified':
        icon = Icons.verified;
        color = isDark ? Colors.green[300]! : Colors.green;
        text = 'Verified';
        break;
      case 'pending':
        icon = Icons.pending;
        color = isDark ? Colors.orange[300]! : Colors.orange;
        text = 'Pending Verification';
        break;
      case 'rejected':
        icon = Icons.cancel;
        color = isDark ? Colors.red[300]! : Colors.red;
        text = 'Verification Rejected';
        break;
      default:
        icon = Icons.error_outline;
        color = isDark ? Colors.grey[400]! : Colors.grey;
        text = 'Unverified';
    }

    if (!showText) {
      return Container(
        decoration: BoxDecoration(
          color: isDark ? Colors.black.withOpacity(0.5) : Colors.white.withOpacity(0.8),
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        padding: const EdgeInsets.all(2),
        child: Icon(
          icon,
          color: color,
          size: size,
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            color: color,
            size: size * 0.8,
          ),
          const SizedBox(width: 4),
          Text(
            text,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.bold,
              fontSize: size * 0.5,
            ),
          ),
        ],
      ),
    );
  }
}
