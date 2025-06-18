import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../core/widgets/full_screen.dart';
import '../../../../services/location_selector.dart';

class BookingDetailPage extends StatefulWidget {
  final String document;

  const BookingDetailPage({
    Key? key,
    required this.document,
    required String bookingId,
    required Map<String, dynamic> bookingData,
    required Map<String, dynamic> data,
  }) : super(key: key);

  @override
  _BookingDetailPageState createState() => _BookingDetailPageState();
}

class _BookingDetailPageState extends State<BookingDetailPage> {
  Map<String, dynamic>? _serviceDetails;
  bool _loadingServiceDetails = false;

  // Function to fetch booking data from Firestore
  Future<DocumentSnapshot<Map<String, dynamic>>> _fetchBookingDetails() {
    return FirebaseFirestore.instance
        .collection('booking_service')
        .doc(widget.document)
        .get();
  }

  // Fetch service details from Firestore with timeout and error handling
  Future<void> _fetchServiceDetails(String serviceId) async {
    setState(() {
      _loadingServiceDetails = true;
    });

    try {
      print('Fetching service details for serviceId: $serviceId');
      final serviceDoc = await FirebaseFirestore.instance
          .collection('provider_services')
          .doc(serviceId)
          .get()
          .timeout(Duration(seconds: 10), onTimeout: () {
        throw Exception('Timed out fetching service details');
      });

      print(
          'Service document exists: ${serviceDoc.exists}, data: ${serviceDoc.data()}');
      if (serviceDoc.exists) {
        setState(() {
          _serviceDetails = serviceDoc.data();
        });
      } else {
        print('No service found for serviceId: $serviceId');
      }
    } catch (e) {
      print('Error fetching service details: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load service details: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() {
        _loadingServiceDetails = false;
      });
    }
  }

  void _launchPhoneCall(String phoneNumber) async {
    try {
      final Uri phoneUri = Uri(scheme: 'tel', path: phoneNumber);
      if (await canLaunchUrl(phoneUri)) {
        await launchUrl(phoneUri);
      } else {
        print('Could not launch $phoneNumber');
      }
    } catch (e) {
      print('Error launching phone call: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Booking Details',
          style: TextStyle(
            color: isDark ? Colors.white : Colors.black87,
          ),
        ),
        backgroundColor: isDark ? Colors.grey[900] : Colors.white,
        elevation: 0,
        iconTheme: IconThemeData(
          color: isDark ? Colors.white : Colors.black87,
        ),
      ),
      body: FutureBuilder<DocumentSnapshot<Map<String, dynamic>>>(
        future: _fetchBookingDetails(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            print('Error fetching booking details: ${snapshot.error}');
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          if (snapshot.connectionState == ConnectionState.done &&
              snapshot.hasData) {
            final bookingData = snapshot.data!.data() ?? {};
            print('Booking data fetched: $bookingData');

            // Safely handle all data with proper type checking
            final String customerName = bookingData['seekerName'] ?? 'N/A';
            final String jobDescription =
                bookingData['jobDescription'] ?? 'N/A';
            final String address = bookingData['address'] ?? 'N/A';
            final String? status = bookingData['status'] ?? 'pending';
            final double budget =
                (bookingData['budget'] as num?)?.toDouble() ?? 0.0;
            final String serviceName = bookingData['serviceName'] ?? 'N/A';
            final String? serviceId =
                bookingData['serviceId']?.toString(); // Convert to String
            final double? servicePrice =
                bookingData['servicePrice']?.toDouble();

            // FIX: Handle serviceDuration properly - it's stored as int but used as String
            final dynamic serviceDurationRaw = bookingData['serviceDuration'];
            final String? serviceDuration = serviceDurationRaw != null
                ? serviceDurationRaw.toString()
                : null;

            // Fetch service details if serviceId is available and not already fetched
            if (serviceId != null &&
                _serviceDetails == null &&
                !_loadingServiceDetails) {
              _fetchServiceDetails(serviceId);
            }

            // Handle date and time
            String formattedDate = 'N/A';
            String formattedTime = 'N/A';
            String createdAt = 'N/A';

            try {
              if (bookingData['date'] is Timestamp) {
                final DateTime dateTime =
                    (bookingData['date'] as Timestamp).toDate();
                formattedDate = DateFormat('MMM dd, yyyy').format(dateTime);
              }

              if (bookingData['time'] != null) {
                formattedTime = bookingData['time'];
                try {
                  final timeComponents = formattedTime.split(':');
                  if (timeComponents.length == 2) {
                    final hour = int.parse(timeComponents[0]);
                    final minute = int.parse(timeComponents[1]);
                    final dt = DateTime(2022, 1, 1, hour, minute);
                    formattedTime = DateFormat('hh:mm a').format(dt);
                  }
                } catch (e) {
                  print('Error formatting time: $e');
                }
              }

              if (bookingData['createdAt'] is Timestamp) {
                final DateTime createdDateTime =
                    (bookingData['createdAt'] as Timestamp).toDate();
                createdAt =
                    DateFormat('MMM dd, yyyy hh:mm a').format(createdDateTime);
              }
            } catch (e) {
              print('Error formatting dates: $e');
            }

            // Handle image URLs
            final List<String> imageUrls =
                (bookingData['imageUrls'] as List<dynamic>?)
                        ?.map((e) => e.toString())
                        .toList() ??
                    [];

            return ListView(
              padding: const EdgeInsets.all(16.0),
              children: [
                _buildDetailCard('Customer Information', [
                  _buildDetailRow('Name', customerName),
                  _buildPhoneRow('Phone', bookingData['seekerPhone'] ?? 'N/A'),
                  _buildLocationRow('Location', address),
                ]),
                const SizedBox(height: 16),
                // Selected Service Card (only if serviceId is non-null)
                if (serviceId != null) ...[
                  _buildSelectedServiceCard(
                      serviceName, servicePrice, serviceDuration),
                  const SizedBox(height: 16),
                ],
                _buildDetailCard('Booking Information', [
                  _buildDetailRow('Service',
                      serviceId != null ? jobDescription : serviceName),
                  if (serviceId == null && servicePrice != null)
                    _buildDetailRow(
                        'Price', '\Rs${servicePrice.toStringAsFixed(2)}'),
                  if (serviceId == null && serviceDuration != null)
                    _buildDetailRow('Duration', '$serviceDuration min'),
                  _buildDetailRow('Job Description', jobDescription),
                  _buildDetailRow('Date', formattedDate),
                  _buildDetailRow('Time', formattedTime),
                  _buildDetailRow('Budget', '\Rs${budget.toStringAsFixed(2)}'),
                  _buildDetailRow('Status', status?.toUpperCase() ?? 'N/A'),
                  _buildDetailRow('Created', createdAt),
                ]),
                if (imageUrls.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  _buildImageGallery(imageUrls),
                ],
              ],
            );
          }

          return const Center(child: CircularProgressIndicator());
        },
      ),
    );
  }

  // Selected Service Card (matches BookingSummaryScreen)
  Widget _buildSelectedServiceCard(
      String serviceName, double? servicePrice, String? serviceDuration) {
    return Card(
      color: const Color(0xFF2A9D8F).withOpacity(0.1),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(
          color: Color(0xFF2A9D8F),
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
                  color: const Color(0xFF2A9D8F),
                  size: 20,
                ),
                const SizedBox(width: 8),
                const Text(
                  'Selected Service',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF2A9D8F),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              _serviceDetails?['name'] ?? serviceName,
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
                if (servicePrice != null)
                  _buildServiceDetailChip(
                    Icons.attach_money,
                    '\Rs${servicePrice.toStringAsFixed(2)}',
                    Colors.green,
                  ),
                if (servicePrice != null && serviceDuration != null)
                  const SizedBox(width: 12),
                if (serviceDuration != null)
                  _buildServiceDetailChip(
                    Icons.timer,
                    '$serviceDuration min', // serviceDuration is already a String
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
                            color: const Color(0xFF2A9D8F).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(
                              color: const Color(0xFF2A9D8F).withOpacity(0.3),
                            ),
                          ),
                          child: Text(
                            tag.toString(),
                            style: const TextStyle(
                              fontSize: 10,
                              color: Color(0xFF2A9D8F),
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

  // Helper method for service detail chips (matches BookingSummaryScreen)
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

  Widget _buildDetailCard(String title, List<Widget> children) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Card(
      elevation: 2,
      color: isDark ? Colors.grey[850] : Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : Colors.black87,
              ),
            ),
            const SizedBox(height: 16),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
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
              style: TextStyle(
                color: isDark ? Colors.white : Colors.black87,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPhoneRow(String label, String value) {
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
            child: Row(
              children: [
                Text(
                  value,
                  style: TextStyle(
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                ),
                if (value != 'N/A') ...[
                  const SizedBox(width: 8),
                  InkWell(
                    onTap: () => _launchPhoneCall(value),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.blue.withOpacity(isDark ? 0.2 : 0.1),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Text(
                        'Call',
                        style: TextStyle(
                          color: Colors.blue,
                          fontWeight: FontWeight.bold,
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

  Widget _buildLocationRow(String label, String address) {
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
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  address,
                  style: TextStyle(
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                ),
                const SizedBox(height: 8),
                TextButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => LocationSelector(
                          initialAddress: address,
                          readOnly: true,
                        ),
                      ),
                    );
                  },
                  icon: Icon(
                    Icons.location_on,
                    size: 18,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  label: Text(
                    'See on Map',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                  style: TextButton.styleFrom(
                    backgroundColor:
                        Theme.of(context).colorScheme.primary.withOpacity(0.1),
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImageGallery(List<String> imageUrls) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Card(
      elevation: 2,
      color: isDark ? Colors.grey[850] : Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Images',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : Colors.black87,
              ),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8.0,
              runSpacing: 8.0,
              children:
                  imageUrls.map((url) => _buildImageThumbnail(url)).toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImageThumbnail(String url) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => FullScreenImage(imageUrl: url),
          ),
        );
      },
      child: Hero(
        tag: url,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Image.network(
            url,
            height: 100,
            width: 100,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) {
              return Container(
                height: 100,
                width: 100,
                color: isDark ? Colors.grey[700] : Colors.grey[200],
                child: Icon(
                  Icons.error_outline,
                  color: isDark ? Colors.grey[500] : Colors.grey[400],
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
