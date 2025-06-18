import 'package:flutter/material.dart';

class BookingActions extends StatelessWidget {
  final String status;
  final Function(String) onStatusChange;

  const BookingActions({
    Key? key,
    required this.status,
    required this.onStatusChange,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    switch (status) {
      case 'pending':
        return _buildPendingActions(context);
      case 'confirmed':
        return _buildConfirmedActions(context);
      case 'pending_confirmation':
        return _buildPendingConfirmationMessage(context);
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildPendingActions(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Row(
      children: [
        Expanded(
          child: OutlinedButton(
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  backgroundColor: isDark ? Colors.grey[850] : Colors.white,
                  title: Text(
                    'Decline Booking',
                    style: TextStyle(
                      color: isDark ? Colors.white : Colors.black87,
                    ),
                  ),
                  content: Text(
                    'Are you sure you want to decline this booking? This action cannot be undone.',
                    style: TextStyle(
                      color: isDark ? Colors.grey[300] : Colors.grey[800],
                    ),
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Cancel'),
                    ),
                    TextButton(
                      onPressed: () {
                        onStatusChange('cancelled');
                        Navigator.pop(context);
                      },
                      style: TextButton.styleFrom(
                        foregroundColor: Colors.red,
                      ),
                      child: const Text('Decline'),
                    ),
                  ],
                ),
              );
            },
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.red,
              side: const BorderSide(color: Colors.red),
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: const [
                Icon(Icons.cancel_outlined, size: 18),
                SizedBox(width: 8),
                Text('Decline', style: TextStyle(fontSize: 14)),
              ],
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: ElevatedButton(
            onPressed: () => onStatusChange('confirmed'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF2A9D8F),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              elevation: 0,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: const [
                Icon(Icons.check_circle_outline, size: 18),
                SizedBox(width: 8),
                Text('Accept', style: TextStyle(fontSize: 14)),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildConfirmedActions(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton(
            onPressed: () => onStatusChange('cancelled'),
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.red,
              side: const BorderSide(color: Colors.red),
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: const [
                Icon(Icons.cancel_outlined, size: 18),
                SizedBox(width: 8),
                Text('Cancel', style: TextStyle(fontSize: 14)),
              ],
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: ElevatedButton(
            onPressed: () => onStatusChange('pending_confirmation'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF2A9D8F),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              elevation: 0,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: const [
                Icon(Icons.check_circle_outline, size: 18),
                SizedBox(width: 8),
                Text('Mark Complete', style: TextStyle(fontSize: 14)),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPendingConfirmationMessage(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.amber.withOpacity(0.2)
            : Colors.amber.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
            color: isDark
                ? Colors.amber.withOpacity(0.6)
                : Colors.amber.withOpacity(0.5)),
      ),
      child: Row(
        children: [
          Icon(Icons.info_outline,
              color: isDark ? Colors.amber[300] : Colors.amber),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Waiting for client to confirm completion',
              style: TextStyle(
                color: isDark ? Colors.amber[300] : Colors.amber[800],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
