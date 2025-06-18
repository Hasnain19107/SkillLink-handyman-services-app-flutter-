import 'package:flutter/material.dart';

class VerificationStatusBanner extends StatelessWidget {
  final String status;
  final String? rejectionReason;

  const VerificationStatusBanner({
    Key? key,
    required this.status,
    this.rejectionReason,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    Color backgroundColor;
    Color textColor;
    IconData icon;
    String message;

    switch (status) {
      case 'verified':
        backgroundColor =
            isDark ? Colors.green.shade900 : Colors.green.shade100;
        textColor = isDark ? Colors.green.shade100 : Colors.green.shade900;
        icon = Icons.verified;
        message = 'Your account is verified';
        break;
      case 'pending':
        backgroundColor =
            isDark ? Colors.orange.shade900 : Colors.orange.shade100;
        textColor = isDark ? Colors.orange.shade100 : Colors.orange.shade900;
        icon = Icons.pending;
        message = 'Your verification is under review';
        break;
      case 'rejected':
        backgroundColor = isDark ? Colors.red.shade900 : Colors.red.shade100;
        textColor = isDark ? Colors.red.shade100 : Colors.red.shade900;
        icon = Icons.cancel;
        message = 'Your verification was rejected';
        break;
      default:
        backgroundColor = isDark ? Colors.blue.shade900 : Colors.blue.shade100;
        textColor = isDark ? Colors.blue.shade100 : Colors.blue.shade900;
        icon = Icons.info;
        message = 'Please verify your account to access all features';
    }

    return Container(
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.all(16),
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
        children: [
          Row(
            children: [
              Icon(icon, color: textColor),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  message,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: textColor,
                  ),
                ),
              ),
            ],
          ),
          if (rejectionReason != null && status == 'rejected')
            Container(
              margin: const EdgeInsets.only(top: 12),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isDark
                    ? Colors.red.shade800.withOpacity(0.3)
                    : Colors.red.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: isDark ? Colors.red.shade700 : Colors.red.shade200,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Reason for rejection:',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.red.shade100 : Colors.red.shade900,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    rejectionReason!,
                    style: TextStyle(
                      color: isDark ? Colors.red.shade100 : Colors.red.shade900,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
