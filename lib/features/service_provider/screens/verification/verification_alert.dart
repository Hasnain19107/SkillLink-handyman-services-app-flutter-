import 'package:flutter/material.dart';
import 'provider_verification_screen.dart';

class VerificationAlert extends StatelessWidget {
  final String status;

  const VerificationAlert({
    Key? key,
    required this.status,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Don't show alert for verified providers
    if (status == 'verified') {
      return const SizedBox.shrink();
    }

    Color backgroundColor;
    Color textColor;
    IconData icon;
    String title;
    String message;
    String buttonText;

    switch (status) {
      case 'pending':
        backgroundColor = isDark
            ? Colors.orange.shade900.withOpacity(0.3)
            : Colors.orange.shade50;
        textColor = isDark ? Colors.orange.shade100 : Colors.orange.shade900;
        icon = Icons.pending;
        title = 'Verification in Progress';
        message =
            'Your account verification is being reviewed. Some features are limited until verification is complete.';
        buttonText = 'View Status';
        break;
      case 'rejected':
        backgroundColor =
            isDark ? Colors.red.shade900.withOpacity(0.3) : Colors.red.shade50;
        textColor = isDark ? Colors.red.shade100 : Colors.red.shade900;
        icon = Icons.cancel;
        title = 'Verification Rejected';
        message =
            'Your verification was rejected. Please check the details and resubmit.';
        buttonText = 'Resubmit';
        break;
      default: // unverified
        backgroundColor = isDark
            ? Colors.blue.shade900.withOpacity(0.3)
            : Colors.blue.shade50;
        textColor = isDark ? Colors.blue.shade100 : Colors.blue.shade900;
        icon = Icons.verified_user_outlined;
        title = 'Verify Your Account';
        message =
            'Complete verification to unlock all features and build trust with clients.';
        buttonText = 'Verify Now';
    }

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: isDark ? Colors.black26 : Colors.black12,
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: textColor),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: textColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            message,
            style: TextStyle(
              color: textColor,
            ),
          ),
          const SizedBox(height: 16),
          Align(
            alignment: Alignment.centerRight,
            child: ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const ProviderVerificationScreen(),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: textColor,
                foregroundColor: backgroundColor,
                elevation: 0,
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: Text(buttonText),
            ),
          ),
        ],
      ),
    );
  }
}
