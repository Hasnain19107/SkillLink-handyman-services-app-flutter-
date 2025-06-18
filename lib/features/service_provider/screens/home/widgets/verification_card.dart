import 'package:flutter/material.dart';

class VerificationCard extends StatelessWidget {
  final String verificationStatus;
  final VoidCallback onVerifyPressed;

  const VerificationCard({
    Key? key,
    required this.verificationStatus,
    required this.onVerifyPressed,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    Color backgroundColor;
    Color textColor;
    Color borderColor;
    String title;
    String message;
    String buttonText;
    IconData icon;

    switch (verificationStatus) {
      case 'pending':
        backgroundColor = isDark
            ? Colors.orange.shade900.withOpacity(0.2)
            : Colors.orange.shade50;
        borderColor = isDark ? Colors.orange.shade800 : Colors.orange.shade200;
        textColor = isDark ? Colors.orange.shade300 : Colors.orange.shade800;
        title = 'Verification in Progress';
        message =
            'Your documents are being reviewed. This usually takes 1-2 business days.';
        buttonText = 'Check Status';
        icon = Icons.pending;
        break;
      case 'rejected':
        backgroundColor =
            isDark ? Colors.red.shade900.withOpacity(0.2) : Colors.red.shade50;
        borderColor = isDark ? Colors.red.shade800 : Colors.red.shade200;
        textColor = isDark ? Colors.red.shade300 : Colors.red.shade800;
        title = 'Verification Rejected';
        message =
            'Your verification was rejected. Please check the details and resubmit.';
        buttonText = 'Resubmit';
        icon = Icons.error_outline;
        break;
      default:
        backgroundColor = isDark
            ? Colors.blue.shade900.withOpacity(0.2)
            : Colors.blue.shade50;
        borderColor = isDark ? Colors.blue.shade800 : Colors.blue.shade200;
        textColor = isDark ? Colors.blue.shade300 : Colors.blue.shade800;
        title = 'Verification Required';
        message =
            'Please verify your account to access all features and build trust with clients.';
        buttonText = 'Verify Now';
        icon = Icons.verified_user_outlined;
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor),
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
              color: isDark ? Colors.grey[300] : Colors.grey[700],
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: onVerifyPressed,
              style: ElevatedButton.styleFrom(
                backgroundColor: verificationStatus == 'pending'
                    ? Colors.orange
                    : verificationStatus == 'rejected'
                        ? Colors.red
                        : const Color(0xFF2A9D8F),
                foregroundColor: Colors.white,
              ),
              child: Text(buttonText),
            ),
          ),
        ],
      ),
    );
  }
}
