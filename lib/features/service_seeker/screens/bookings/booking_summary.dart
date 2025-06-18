import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:intl/intl.dart';
import 'dart:io';

import '../../../../data/models/booking_model.dart';
import '../../../notification/notification_fcm.dart';
import 'payment_method_screen.dart';

class BookingSummaryScreen extends StatefulWidget {
  final BookingModel booking;
  final List<File> images;

  const BookingSummaryScreen({
    Key? key,
    required this.booking,
    this.images = const [],
    required Map bookingData,
  }) : super(key: key);

  @override
  State<BookingSummaryScreen> createState() => _BookingSummaryScreenState();
}

class _BookingSummaryScreenState extends State<BookingSummaryScreen> {
  bool _isSubmitting = false;
  Map<String, dynamic>? _serviceDetails;
  bool _loadingServiceDetails = false;
  String _selectedPaymentMethod = 'cod'; // Default to Cash on Delivery

  @override
  void initState() {
    super.initState();
    if (widget.booking.serviceId != null) {
      _fetchServiceDetails();
    }
  }

  // Fetch complete service details from Firestore
  Future<void> _fetchServiceDetails() async {
    if (widget.booking.serviceId == null) return;

    setState(() => _loadingServiceDetails = true);

    try {
      final serviceDoc = await FirebaseFirestore.instance
          .collection('provider_services')
          .doc(widget.booking.serviceId)
          .get();

      if (serviceDoc.exists) {
        setState(() {
          _serviceDetails = serviceDoc.data();
        });
      }
    } catch (e) {
      print('Error fetching service details: $e');
    } finally {
      setState(() => _loadingServiceDetails = false);
    }
  }

  Future<void> _navigateToPaymentMethod() async {
    final result = await Navigator.push<String>(
      context,
      MaterialPageRoute(
        builder: (context) => PaymentMethodScreen(
          selectedPaymentMethod: _selectedPaymentMethod,
        ),
      ),
    );

    if (result != null) {
      setState(() {
        _selectedPaymentMethod = result;
      });
    }
  }

  String _getPaymentMethodDisplayName(String method) {
    switch (method) {
      case 'cod':
        return 'Cash on Delivery';
      case 'card':
        return 'Credit/Debit Card';
      case 'wallet':
        return 'Digital Wallet';
      case 'bank':
        return 'Bank Transfer';
      default:
        return 'Cash on Delivery';
    }
  }

  IconData _getPaymentMethodIcon(String method) {
    switch (method) {
      case 'cod':
        return Icons.money;
      case 'card':
        return Icons.credit_card;
      case 'wallet':
        return Icons.account_balance_wallet;
      case 'bank':
        return Icons.account_balance;
      default:
        return Icons.money;
    }
  }

  Future<void> _submitBooking() async {
    setState(() => _isSubmitting = true);

    try {
      // Upload images if any
      List<String> imageUrls = [];
      if (widget.images.isNotEmpty) {
        imageUrls = await _uploadImages(widget.images);
      }

      // Update booking with image URLs, payment method and generate ID
      final bookingWithImages = widget.booking.copyWith(
        imageUrls: imageUrls,
        createdAt: DateTime.now(),
        paymentMethod: _selectedPaymentMethod,
        paymentStatus: 'pending', // Will be updated when payment is completed
      );

      // Create booking in Firestore
      final bookingRef = await FirebaseFirestore.instance
          .collection('booking_service')
          .add(bookingWithImages.toMap());

      // Send notification to provider
      await NotificationService().notifyBookingCreated(
        providerId: widget.booking.providerId,
        bookingId: bookingRef.id,
        seekerName: widget.booking.seekerName,
        serviceName: widget.booking.serviceName,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Booking request sent successfully!'),
            backgroundColor: Colors.green,
          ),
        );

        // Navigate back to home
        Navigator.popUntil(context, (route) => route.isFirst);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error submitting booking: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  Future<List<String>> _uploadImages(List<File> images) async {
    List<String> imageUrls = [];
    try {
      for (File image in images) {
        final fileName =
            '${DateTime.now().millisecondsSinceEpoch}_${image.path.split('/').last}';
        final storageRef = FirebaseStorage.instance
            .ref()
            .child('booking_images')
            .child(fileName);

        final uploadTask = storageRef.putFile(image);
        final taskSnapshot = await uploadTask;
        final downloadUrl = await taskSnapshot.ref.getDownloadURL();
        imageUrls.add(downloadUrl);
      }
    } catch (e) {
      print('Error uploading images: $e');
    }
    return imageUrls;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Booking Summary'),
        elevation: 0,
      ),
      body: _isSubmitting
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Submitting your booking request...'),
                ],
              ),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Provider Info
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 30,
                            backgroundImage: NetworkImage(
                              widget.booking.providerImage ??
                                  'https://randomuser.me/api/portraits/lego/1.jpg',
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  widget.booking.providerName,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 18,
                                  ),
                                ),
                                Text(
                                  widget.booking.providerProfession ??
                                      'Service Provider',
                                  style: TextStyle(
                                    color: Colors.grey[600],
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Selected Service Card
                  if (widget.booking.serviceId != null) ...[
                    _buildSelectedServiceCard(),
                    const SizedBox(height: 24),
                  ],

                  // Customer Information
                  _buildSection('Customer Information', [
                    _buildSummaryItem('Name', widget.booking.seekerName),
                    _buildSummaryItem(
                        'Phone', widget.booking.seekerPhone ?? 'Not provided'),
                  ]),

                  // Booking Details
                  _buildSection('Booking Details', [
                    _buildSummaryItem(
                        'Job Description', widget.booking.jobDescription),
                    _buildSummaryItem(
                        'Service Address', widget.booking.address),
                    _buildSummaryItem(
                      'Date & Time',
                      '${DateFormat('MMMM dd, yyyy').format(widget.booking.bookingDate ?? DateTime.now())} at ${widget.booking.time ?? 'Not specified'}',
                    ),
                    _buildSummaryItem('Budget',
                        '\$${widget.booking.budget.toStringAsFixed(2)}'),
                  ]),

                  // Payment Method Section (Updated)
                  _buildPaymentMethodSection(),

                  // Images
                  if (widget.images.isNotEmpty) ...[
                    const SizedBox(height: 24),
                    const Text(
                      'Attached Images',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      height: 100,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: widget.images.length,
                        itemBuilder: (context, index) {
                          return Container(
                            margin: const EdgeInsets.only(right: 8),
                            width: 100,
                            height: 100,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(8),
                              image: DecorationImage(
                                image: FileImage(widget.images[index]),
                                fit: BoxFit.cover,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],

                  const SizedBox(height: 32),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: _submitBooking,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Text(
                        'Submit Job Request',
                        style: TextStyle(
                          fontSize: 16,
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

  // Updated Payment Method Section
  Widget _buildPaymentMethodSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 24),
        const Text(
          'Payment Method',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),

        // Selected Payment Method Card
        Card(
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: const BorderSide(
              color: Colors.blue,
              width: 2,
            ),
          ),
          child: ListTile(
            onTap: _navigateToPaymentMethod,
            contentPadding: const EdgeInsets.all(16),
            leading: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.blue.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                _getPaymentMethodIcon(_selectedPaymentMethod),
                color: Colors.blue,
                size: 24,
              ),
            ),
            title: Text(
              _getPaymentMethodDisplayName(_selectedPaymentMethod),
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 16,
              ),
            ),
            subtitle: const Text(
              'Tap to change payment method',
              style: TextStyle(fontSize: 14),
            ),
            trailing: const Icon(
              Icons.arrow_forward_ios,
              color: Colors.blue,
              size: 16,
            ),
          ),
        ),

        const SizedBox(height: 16),

        // Payment Info Card
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.blue.shade50,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: Colors.blue.withOpacity(0.3),
            ),
          ),
          child: Row(
            children: [
              Icon(
                Icons.info_outline,
                color: Colors.blue.shade600,
                size: 20,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Payment will be processed after the service provider accepts your booking request.',
                  style: TextStyle(
                    color: Colors.blue.shade700,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // Selected Service Card (matches BookingsScreen)
  Widget _buildSelectedServiceCard() {
    if (_loadingServiceDetails) {
      return Card(
        color: Colors.blue.withOpacity(0.1),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(
            color: Colors.blue,
            width: 2,
          ),
        ),
        child: const Padding(
          padding: EdgeInsets.all(16.0),
          child: Center(
            child: CircularProgressIndicator(
              color: Colors.blue,
            ),
          ),
        ),
      );
    }

    return Card(
      color: Colors.blue.withOpacity(0.1),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(
          color: Colors.blue,
          width: 2,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.work,
                  color: Colors.blue,
                  size: 20,
                ),
                const SizedBox(width: 8),
                const Text(
                  'Selected Service',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              _serviceDetails?['name'] ?? widget.booking.serviceName,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            if (_serviceDetails?['description'] != null) ...[
              const SizedBox(height: 4),
              Text(
                _serviceDetails!['description'],
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
              ),
            ],
            const SizedBox(height: 12),
            Row(
              children: [
                if (widget.booking.servicePrice != null)
                  _buildServiceDetailChip(
                    Icons.attach_money,
                    '\$${widget.booking.servicePrice!.toStringAsFixed(2)}',
                    Colors.green,
                  ),
                if (widget.booking.servicePrice != null &&
                    widget.booking.serviceDuration != null)
                  const SizedBox(width: 12),
                if (widget.booking.serviceDuration != null)
                  _buildServiceDetailChip(
                    Icons.timer,
                    '${widget.booking.serviceDuration} min',
                    Colors.blue,
                  ),
              ],
            ),
            if (_serviceDetails?['tags'] != null &&
                (_serviceDetails!['tags'] as List).isNotEmpty) ...[
              const SizedBox(height: 12),
              Wrap(
                spacing: 4,
                runSpacing: 4,
                children: (_serviceDetails!['tags'] as List<dynamic>)
                    .take(5)
                    .map((tag) => Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.blue.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(
                              color: Colors.blue.withOpacity(0.3),
                            ),
                          ),
                          child: Text(
                            tag.toString(),
                            style: const TextStyle(
                              fontSize: 10,
                              color: Colors.blue,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ))
                    .toList(),
              ),
            ],
          ],
        ),
      ),
    );
  }

  // Helper method for service detail chips (matches BookingsScreen)
  Widget _buildServiceDetailChip(IconData icon, String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Text(
            text,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSection(String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 24),
        Text(
          title,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        ...children,
      ],
    );
  }

  Widget _buildSummaryItem(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(fontSize: 16),
          ),
        ],
      ),
    );
  }
}
