import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class BookingDetailsSection extends StatelessWidget {
  final Map<String, dynamic> data;

  const BookingDetailsSection({
    Key? key,
    required this.data,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final String customerName = data['seekerName'] ?? 'Customer';
    final String location = data['address'] ?? 'Not specified';
    final String notes = data['notes'] ?? '';
    final double price =
        (data['budget'] is num) ? (data['budget'] as num).toDouble() : 0.0;
    final DateTime bookingDate = (data['bookingDate'] is Timestamp)
        ? (data['bookingDate'] as Timestamp).toDate()
        : DateTime.now();
    final double? rating =
        data['rating'] != null ? (data['rating'] as num).toDouble() : null;
    final String? review = data['review'];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildDetailRow(
            context, Icons.person_outline, 'Customer', customerName),
        _buildDetailRow(
          context,
          Icons.calendar_today,
          'Date',
          DateFormat('MMM dd, yyyy').format(bookingDate),
        ),
        _buildDetailRow(
          context,
          Icons.access_time,
          'Time',
          DateFormat('hh:mm a').format(bookingDate),
        ),
        _buildDetailRow(
            context, Icons.location_on_outlined, 'Location', location),
        _buildDetailRow(
          context,
          Icons.attach_money,
          'Budget',
          '\Rs${price.toStringAsFixed(2)}',
        ),
        if (notes.isNotEmpty)
          _buildDetailRow(context, Icons.note_outlined, 'Notes', notes),
        if (rating != null)
          _buildDetailRow(context, Icons.star, 'Rating',
              '${rating.toStringAsFixed(1)} / 5.0'),
        if (review != null && review.isNotEmpty)
          _buildDetailRow(context, Icons.rate_review, 'Review', review),
      ],
    );
  }

  Widget _buildDetailRow(
    BuildContext context,
    IconData icon,
    String label,
    String value, {
    TextStyle? valueStyle,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: TextStyle(
                color: isDark ? Colors.grey[400] : Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: valueStyle ??
                  TextStyle(
                    color: isDark ? Colors.white : Colors.black87,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}
