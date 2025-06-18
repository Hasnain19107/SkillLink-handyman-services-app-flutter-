import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:permission_handler/permission_handler.dart';

import '../bookings/booking_service.dart';
import '../messages/chat_seeker.dart';

class ProviderDetailScreen extends StatefulWidget {
  final String providerId;
  final Map<String, dynamic>? initialData;

  const ProviderDetailScreen({
    Key? key,
    required this.providerId,
    this.initialData,
    required Map<String, Object> providerData,
  }) : super(key: key);

  @override
  State<ProviderDetailScreen> createState() => _ProviderDetailScreenState();
}

class _ProviderDetailScreenState extends State<ProviderDetailScreen> {
  bool _isLoading = true;
  Map<String, dynamic> _providerData = {};
  String _imageUrl = '';
  bool _isProviderAvailable = false;
  String _verificationStatus = 'unverified';

  // Keep these for service selection
  List<Map<String, dynamic>> _providerServices = [];
  String? _selectedServiceId;
  Map<String, dynamic>? _selectedService;
  bool _servicesLoading = true;

  @override
  void initState() {
    super.initState();
    _loadProviderData();
    _fetchProviderServices(); // Add this line
  }

  Future<void> _loadProviderData() async {
    try {
      // If we have initial data, use it while loading full data
      if (widget.initialData != null) {
        setState(() {
          _providerData = widget.initialData!;
          _imageUrl = widget.initialData!['imageUrl'] ?? '';
          _isLoading = false;
        });
      }

      // Get full provider data from Firestore
      final providerDoc = await FirebaseFirestore.instance
          .collection('service_providers')
          .doc(widget.providerId)
          .get();

      if (providerDoc.exists) {
        final data = providerDoc.data() as Map<String, dynamic>;

        // Get profile image URL if not already available
        String imageUrl = data['profileImageUrl'] ?? '';
        if (imageUrl.isEmpty) {
          try {
            final ref = FirebaseStorage.instance
                .ref()
                .child('profile_images')
                .child('${widget.providerId}.jpg');
            imageUrl = await ref.getDownloadURL();
          } catch (e) {
            imageUrl = 'https://randomuser.me/api/portraits/lego/1.jpg';
          }
        }

        setState(() {
          _providerData = data;
          _imageUrl = imageUrl;
          _isProviderAvailable = data['isAvailable'] ?? false;
          _verificationStatus = data['verificationStatus'] ?? 'unverified';
          _isLoading = false;
        });
      } else {
        // If document doesn't exist but we have initial data, keep using that
        if (widget.initialData == null) {
          setState(() {
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  // Add this new method to fetch services from provider_services collection
  Future<void> _fetchProviderServices() async {
    try {
      final servicesQuery = await FirebaseFirestore.instance
          .collection('provider_services')
          .where('providerId', isEqualTo: widget.providerId)
          .where('isActive', isEqualTo: true)
          .get();

      setState(() {
        _providerServices = servicesQuery.docs.map((doc) {
          final data = doc.data();
          data['id'] = doc.id; // Add document ID
          return data;
        }).toList();
        _servicesLoading = false;
      });
    } catch (e) {
      print('Error fetching services: $e');
      setState(() => _servicesLoading = false);
    }
  }

  Future<void> _launchPhoneCall(String phoneNumber) async {
    if (phoneNumber == 'Not available') {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Phone number not available')),
      );
      return;
    }

    // Clean the phone number
    final cleanPhone = phoneNumber.replaceAll(RegExp(r'[^\d+]'), '');

    try {
      // Check phone call permission
      final status = await Permission.phone.request();
      if (status.isGranted) {
        // Create the phone URL
        final Uri phoneUri = Uri(
          scheme: 'tel',
          path: cleanPhone,
        );

        // Check if we can launch the URL
        if (await canLaunchUrl(phoneUri)) {
          await launchUrl(phoneUri);
        } else {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Could not launch phone app')),
            );
          }
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Phone permission denied')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error making phone call: $e')),
        );
      }
    }
  }

  void _navigateToChat() {
    // Navigate to chat screen with this provider
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ChatScreen(
          providerId: widget.providerId,
          providerName: _providerData['fullName'] ?? 'Service Provider',
          providerImage: _imageUrl,
          seekerId: FirebaseAuth.instance.currentUser!.uid,
        ),
      ),
    );
  }

  // Add these new methods for service selection
  void _selectService(String serviceId, Map<String, dynamic> service) {
    setState(() {
      _selectedServiceId = serviceId;
      _selectedService = service;
    });
  }

  // Update the _navigateToBooking method
  void _navigateToBooking() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => BookingServiceScreen(
          providerId: widget.providerId,
          providerData: {
            'fullName': _providerData['fullName'] ?? 'Name not available',
            'category': _providerData['category'] ?? 'Category not set',
            'rating': (_providerData['rating'] ?? 0.0).toDouble(),
            'review': _providerData['review'] ?? 0,
            'imageUrl': _imageUrl,
          },
          selectedService:
              _selectedService, // Pass selected service (can be null)
        ),
      ),
    );
  }

  Widget _buildVerificationBadge() {
    final isVerified = _verificationStatus == 'verified';
    Theme.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: isVerified
            ? Colors.blue.withOpacity(0.1)
            : (isDark ? Colors.grey[800] : Colors.grey[100]),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isVerified ? Colors.blue : Colors.grey,
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isVerified ? Icons.verified_user : Icons.error_outline,
            size: 16,
            color: isVerified ? Colors.blue : Colors.grey,
          ),
          const SizedBox(width: 8),
          Text(
            isVerified ? 'Verified Provider' : 'Unverified',
            style: TextStyle(
              color: isVerified ? Colors.blue : Colors.grey,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;

    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Provider Details'),
          backgroundColor: theme.appBarTheme.backgroundColor,
          foregroundColor: theme.appBarTheme.foregroundColor,
          elevation: 0,
        ),
        body: Center(
          child: CircularProgressIndicator(
            color: theme.colorScheme.primary,
          ),
        ),
      );
    }

    final name = _providerData['fullName'] ?? 'Name not available';
    final profession = _providerData['category'] ?? 'Category not set';
    final rating = (_providerData['rating'] ?? 0.0).toDouble();
    final reviews = _providerData['review'] ?? 0;
    final address = _providerData['address'] ?? 'Address not available';
    final about = _providerData['about'] ??
        'No information available about this provider.';
    final hourlyRate = _providerData['hourlyRate'] ?? 0.0;
    final phoneNumber = _providerData['phone'] ?? 'Not available';

    Widget availabilityIndicator = Container(
      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: _isProviderAvailable
            ? Colors.green.withOpacity(0.1)
            : Colors.red.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: _isProviderAvailable ? Colors.green : Colors.red,
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: _isProviderAvailable ? Colors.green : Colors.red,
            ),
          ),
          SizedBox(width: 8),
          Text(
            _isProviderAvailable ? 'Available' : 'Unavailable',
            style: TextStyle(
              color: _isProviderAvailable ? Colors.green : Colors.red,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Provider Details'),
        backgroundColor: theme.appBarTheme.backgroundColor,
        foregroundColor: theme.appBarTheme.foregroundColor,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Provider image and basic info
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: isDarkMode ? theme.cardColor : Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: isDarkMode
                        ? Colors.black12
                        : Colors.grey.withOpacity(0.1),
                    spreadRadius: 1,
                    blurRadius: 5,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 60,
                    backgroundColor: isDarkMode
                        ? theme.colorScheme.surface
                        : Colors.grey[200],
                    backgroundImage:
                        _imageUrl.isNotEmpty ? NetworkImage(_imageUrl) : null,
                    onBackgroundImageError: (exception, stackTrace) {},
                    child: _imageUrl.isEmpty
                        ? Icon(Icons.person,
                            size: 60,
                            color: isDarkMode
                                ? theme.colorScheme.onSurface
                                : Colors.grey[600])
                        : null,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    name,
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: theme.textTheme.headlineMedium?.color,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    profession,
                    style: TextStyle(
                      fontSize: 18,
                      color: theme.textTheme.bodyLarge?.color,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.star, color: Colors.amber, size: 20),
                      const SizedBox(width: 4),
                      Text(
                        '${rating.toStringAsFixed(1)} ($reviews review)',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          color: theme.textTheme.bodyMedium?.color,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  availabilityIndicator,
                  const SizedBox(height: 8),
                  _buildVerificationBadge(),
                ],
              ),
            ),

            const SizedBox(height: 12),

            // Provider details
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isDarkMode ? theme.cardColor : Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: isDarkMode
                        ? Colors.black12
                        : Colors.grey.withOpacity(0.1),
                    spreadRadius: 1,
                    blurRadius: 5,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Address
                  _buildDetailItem(
                    context: context,
                    icon: Icons.location_on,
                    title: 'Address',
                    content: address,
                  ),

                  const SizedBox(height: 16),
                  Divider(
                    color: isDarkMode ? Colors.grey[700] : Colors.grey[300],
                  ),
                  const SizedBox(height: 16),

                  // Hourly Rate
                  _buildDetailItem(
                    context: context,
                    icon: Icons.attach_money,
                    title: 'Hourly Rate',
                    content: '\$${hourlyRate.toStringAsFixed(2)}',
                  ),

                  const SizedBox(height: 16),
                  Divider(
                    color: isDarkMode ? Colors.grey[700] : Colors.grey[300],
                  ),
                  const SizedBox(height: 16),

                  // Phone Number
                  _buildDetailItem(
                    context: context,
                    icon: Icons.phone,
                    title: 'Phone Number',
                    content: phoneNumber,
                    onTap: () => _launchPhoneCall(phoneNumber),
                    isPhone: true,
                  ),
                ],
              ),
            ),

            // About section
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isDarkMode ? theme.cardColor : Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: isDarkMode
                        ? Colors.black12
                        : Colors.grey.withOpacity(0.1),
                    spreadRadius: 1,
                    blurRadius: 5,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'About',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: theme.textTheme.titleLarge?.color,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    about,
                    style: TextStyle(
                      fontSize: 16,
                      color: theme.textTheme.bodyMedium?.color,
                      height: 1.5,
                    ),
                  ),
                ],
              ),
            ),

            // Available Services for Booking (keep this but make it optional)
            if (_providerServices.isNotEmpty) ...[
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isDarkMode ? theme.cardColor : Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: isDarkMode
                          ? Colors.black12
                          : Colors.grey.withOpacity(0.1),
                      spreadRadius: 1,
                      blurRadius: 5,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          'Available Services',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: theme.textTheme.titleLarge?.color,
                          ),
                        ),
                        Spacer(),
                        Container(
                          padding:
                              EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.primary.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            'Optional',
                            style: TextStyle(
                              fontSize: 12,
                              color: theme.colorScheme.primary,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Select a specific service or book directly with general requirements',
                      style: TextStyle(
                        fontSize: 14,
                        color: theme.textTheme.bodySmall?.color,
                      ),
                    ),
                    const SizedBox(height: 16),
                    if (_servicesLoading)
                      const Center(
                        child: Padding(
                          padding: EdgeInsets.all(32),
                          child: CircularProgressIndicator(),
                        ),
                      )
                    else
                      ...List.generate(_providerServices.length, (index) {
                        final service = _providerServices[index];
                        final serviceId = service['id'];
                        final isSelected = _selectedServiceId == serviceId;

                        return Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          decoration: BoxDecoration(
                            border: Border.all(
                              color: isSelected
                                  ? theme.colorScheme.primary
                                  : (isDarkMode
                                      ? Colors.grey[700]!
                                      : Colors.grey.withOpacity(0.2)),
                              width: isSelected ? 2 : 1,
                            ),
                            borderRadius: BorderRadius.circular(8),
                            color: isSelected
                                ? theme.colorScheme.primary.withOpacity(0.1)
                                : null,
                          ),
                          child: InkWell(
                            onTap: () => _selectService(serviceId, service),
                            borderRadius: BorderRadius.circular(8),
                            child: Padding(
                              padding: const EdgeInsets.all(12),
                              child: Row(
                                children: [
                                  Radio<String>(
                                    value: serviceId,
                                    groupValue: _selectedServiceId,
                                    onChanged: (value) =>
                                        _selectService(serviceId, service),
                                    activeColor: theme.colorScheme.primary,
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          service['name'] ?? 'Unnamed Service',
                                          style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                            color: isSelected
                                                ? theme.colorScheme.primary
                                                : theme.textTheme.titleMedium
                                                    ?.color,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          service['description'] ??
                                              'No description',
                                          style: TextStyle(
                                            fontSize: 14,
                                            color: theme
                                                .textTheme.bodySmall?.color,
                                          ),
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        const SizedBox(height: 8),
                                        Row(
                                          children: [
                                            Icon(
                                              Icons.attach_money,
                                              size: 16,
                                              color: Colors.green,
                                            ),
                                            Text(
                                              '\$${service['price']?.toStringAsFixed(2) ?? '0.00'}',
                                              style: TextStyle(
                                                fontSize: 14,
                                                fontWeight: FontWeight.w500,
                                                color: Colors.green,
                                              ),
                                            ),
                                            const SizedBox(width: 16),
                                            Icon(
                                              Icons.timer,
                                              size: 16,
                                              color: Colors.blue,
                                            ),
                                            Text(
                                              '${service['durationMinutes'] ?? 60} min',
                                              style: TextStyle(
                                                fontSize: 14,
                                                fontWeight: FontWeight.w500,
                                                color: Colors.blue,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      }),
                  ],
                ),
              ),
            ],

            // Bottom padding
            const SizedBox(height: 80),
          ],
        ),
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isDarkMode ? theme.cardColor : Colors.white,
          boxShadow: [
            BoxShadow(
              color: isDarkMode ? Colors.black26 : Colors.grey.withOpacity(0.2),
              spreadRadius: 1,
              blurRadius: 5,
              offset: const Offset(0, -3),
            ),
          ],
        ),
        child: Row(
          children: [
            // Chat Button
            Expanded(
              child: ElevatedButton(
                onPressed: _navigateToChat,
                style: ElevatedButton.styleFrom(
                  backgroundColor:
                      isDarkMode ? theme.colorScheme.surface : Colors.white,
                  foregroundColor: theme.colorScheme.primary,
                  side: BorderSide(color: theme.colorScheme.primary),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  elevation: 0,
                ),
                child: const Text(
                  'Chat',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 16),
            // Book Now Button
            Expanded(
              child: ElevatedButton(
                onPressed: _isProviderAvailable ? _navigateToBooking : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _isProviderAvailable
                      ? theme.colorScheme.primary
                      : theme.colorScheme.surface,
                  foregroundColor: _isProviderAvailable
                      ? theme.colorScheme.onPrimary
                      : theme.colorScheme.onSurface,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: Text(
                  _isProviderAvailable
                      ? (_selectedService != null
                          ? 'Book ${_selectedService!['name']}'
                          : 'Book Now')
                      : 'Provider Unavailable',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailItem({
    required BuildContext context,
    required IconData icon,
    required String title,
    required String content,
    VoidCallback? onTap,
    bool isPhone = false,
  }) {
    final theme = Theme.of(context);

    return InkWell(
      onTap: onTap,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            color: theme.colorScheme.primary,
            size: 24,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: theme.textTheme.titleMedium?.color,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  content,
                  style: TextStyle(
                    fontSize: 16,
                    color: onTap != null
                        ? theme.colorScheme.primary
                        : theme.textTheme.bodyMedium?.color,
                  ),
                ),
              ],
            ),
          ),
          if (isPhone && onTap != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Text(
                'Call',
                style: TextStyle(
                  color: theme.colorScheme.primary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
