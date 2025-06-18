import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../../../../notification/notification_fcm.dart';
import '../../messages/chat_screen.dart';
import '../booking_detail.dart';
import '../provider_booking_report.dart';
import 'booking_actions.dart';
import 'booking_details_section.dart';
import 'seeker_avatar.dart';

class BookingCard extends StatelessWidget {
  final Map<String, dynamic> data;
  final DocumentSnapshot document;
  final String status;

  const BookingCard({
    Key? key,
    required this.data,
    required this.document,
    required this.status,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final String customerName = data['seekerName'] ?? 'Customer';
    final String serviceName = data['serviceName'] ?? 'Service';
    final String seekerId = data['seekerId'] ?? '';

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: isDark ? Colors.grey[850] : Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: isDark
                ? Colors.black.withOpacity(0.3)
                : Colors.grey.withOpacity(0.2),
            spreadRadius: 2,
            blurRadius: 5,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with service name and status
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: _getStatusColor(status).withOpacity(0.1),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    serviceName,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                      color: isDark ? Colors.white : Colors.black87,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Row(
                  children: [
                    // Report button
                    if (_shouldShowReportButton(status))
                      Container(
                        margin: const EdgeInsets.only(right: 8),
                        child: IconButton(
                          onPressed: () => _showReportDialog(context),
                          icon: const Icon(Icons.report_problem),
                          color: Colors.red[600],
                          iconSize: 20,
                          padding: const EdgeInsets.all(4),
                          constraints: const BoxConstraints(
                            minWidth: 32,
                            minHeight: 32,
                          ),
                          tooltip: 'Report Issue',
                        ),
                      ),
                    // Status badge
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: isDark ? Colors.grey[800] : Colors.white,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Text(
                        _getStatusText(status),
                        style: TextStyle(
                          color: _getStatusColor(status),
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Booking details - Use BookingDetailsSection instead
                BookingDetailsSection(data: data),

                const SizedBox(height: 16),
                Divider(
                  color: isDark ? Colors.grey[700] : Colors.grey[300],
                ),
                const SizedBox(height: 16),

                // Chat and View Details buttons
                Row(
                  children: [
                    Expanded(
                      flex: 1,
                      child: SeekerAvatar(
                        seekerId: seekerId,
                        customerName: customerName,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 2,
                      child: OutlinedButton.icon(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => BookingDetailPage(
                                document: document.id,
                                bookingId: document.id,
                                bookingData: data,
                                data: {},
                              ),
                            ),
                          );
                        },
                        icon: const Icon(Icons.visibility_outlined, size: 16),
                        label: const Text('View Details',
                            style: TextStyle(fontSize: 14)),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: const Color(0xFF2A9D8F),
                          side: const BorderSide(color: Color(0xFF2A9D8F)),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 10,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                // Status-dependent action buttons
                BookingActions(
                  status: status,
                  onStatusChange: (newStatus) =>
                      _handleStatusChange(context, newStatus),
                ),

                // Report button at the bottom for better visibility
                if (_shouldShowReportButton(status)) ...[
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () => _navigateToReportScreen(context),
                      icon: const Icon(Icons.report_problem, size: 16),
                      label: const Text('Report Issue'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.red[600],
                        side: BorderSide(color: Colors.red[600]!),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  bool _shouldShowReportButton(String status) {
    // Show report button for confirmed, completed, or cancelled bookings
    return ['confirmed', 'completed', 'cancelled', 'pending_confirmation']
        .contains(status);
  }

  void _showReportDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Report Issue'),
        content: const Text(
          'Do you want to report an issue with this booking or customer?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _navigateToReportScreen(context);
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Report'),
          ),
        ],
      ),
    );
  }

  void _navigateToReportScreen(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ProviderReportIssueScreen(
          bookingId: document.id,
          bookingData: data,
        ),
      ),
    );
  }

  Future<void> _handleStatusChange(
      BuildContext context, String newStatus) async {
    try {
      final FirebaseFirestore firestore = FirebaseFirestore.instance;

      if (newStatus == 'pending_confirmation') {
        final autoConfirmDeadline = DateTime.now().add(const Duration(days: 5));

        await firestore.collection('booking_service').doc(document.id).update({
          'status': newStatus,
          'isProviderCompleted': true,
          'providerCompletedAt': FieldValue.serverTimestamp(),
          'autoConfirmDeadline': Timestamp.fromDate(autoConfirmDeadline),
        });
      } else {
        await firestore
            .collection('booking_service')
            .doc(document.id)
            .update({'status': newStatus});
      }

      // Send notification to seeker
      await _sendStatusUpdateNotification(
        data['seekerId'] ?? '',
        newStatus,
        document.id,
      );

      // Show success message
      String message = '';
      switch (newStatus) {
        case 'confirmed':
          message = 'Booking accepted successfully';
          break;
        case 'pending_confirmation':
          message = 'Booking marked as completed';
          break;
        case 'cancelled':
          message = 'Booking cancelled successfully';
          break;
      }

      if (context.mounted && message.isNotEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(message)),
        );
      }
    } catch (e) {
      print('Error updating booking status: $e');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error updating booking: $e')),
        );
      }
    }
  }

  Future<void> _sendStatusUpdateNotification(
    String seekerId,
    String status,
    String bookingId,
  ) async {
    try {
      final serviceName = data['serviceName'] ?? 'Service';
      final providerName = data['providerName'] ?? 'Provider';

      switch (status) {
        case 'confirmed':
          await NotificationService().notifyBookingAccepted(
            seekerId: seekerId,
            bookingId: bookingId,
            providerName: providerName,
            serviceName: serviceName,
          );
          break;

        case 'pending_confirmation':
          await NotificationService().notifyBookingCompleted(
            seekerId: seekerId,
            bookingId: bookingId,
            providerName: providerName,
            serviceName: serviceName,
          );
          break;

        case 'cancelled':
          await NotificationService().notifyBookingCancelled(
            recipientId: seekerId,
            bookingId: bookingId,
            cancellerId: FirebaseAuth.instance.currentUser!.uid,
            cancellerName: providerName,
            serviceName: serviceName,
            isCancelledByProvider: true,
          );
          break;

        default:
          print('Unknown status: $status');
      }
    } catch (e) {
      print('Error sending notification: $e');
    }
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'pending':
        return Colors.orange;
      case 'confirmed':
        return const Color(0xFF2A9D8F);
      case 'pending_confirmation':
        return Colors.amber;
      case 'completed':
        return Colors.green;
      case 'cancelled':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  String _getStatusText(String status) {
    switch (status) {
      case 'pending':
        return 'Pending';
      case 'confirmed':
        return 'Confirmed';
      case 'pending_confirmation':
        return 'Awaiting Confirmation';
      case 'completed':
        return 'Completed';
      case 'cancelled':
        return 'Cancelled';
      default:
        return 'Unknown';
    }
  }
}
