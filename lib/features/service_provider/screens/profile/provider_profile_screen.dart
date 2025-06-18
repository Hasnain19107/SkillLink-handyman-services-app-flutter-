import 'package:SkillLink/features/service_provider/screens/profile/notification_screen.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import '../../../../core/widgets/dialogs/theme_selector_dialog.dart';
import '../../../help_support/screens/help_support_screen.dart';
import '../../../service_seeker/screens/security/security_privacy_screen.dart'
    as seeker;
import 'widgets/provider_profile_header.dart';
import '../ratings/rating_review_provider.dart';
import '../services/provider_services.dart';
import '../verification/provider_verification_screen.dart';
import 'widgets/provider_edit_profile.dart';
import '../payment/payment_methods_screen.dart';
import '../security/security_privacy_screen.dart';

class ProviderProfileScreen extends StatefulWidget {
  final VoidCallback? onNavigateHome;

  const ProviderProfileScreen({Key? key, this.onNavigateHome})
      : super(key: key);

  @override
  State<ProviderProfileScreen> createState() => _ProviderProfileScreenState();
}

class _ProviderProfileScreenState extends State<ProviderProfileScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  String _fullName = '';
  String _phone = '';
  String _email = '';
  String _address = '';
  String _imageUrl = '';
  String _category = '';
  String _description = '';
  double _hourlyRate = 0.0;
  final String _userType = 'Service Provider';
  String _verificationStatus = 'unverified';
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadProviderData();
  }

  Future<void> _loadProviderData() async {
    try {
      final User? user = _auth.currentUser;
      if (user != null) {
        final userData =
            await _firestore.collection('users').doc(user.uid).get();

        if (userData.exists) {
          String imageUrl = '';
          try {
            final profileImageUrl = userData.data()?['profileImageUrl'];
            if (profileImageUrl != null &&
                profileImageUrl.toString().isNotEmpty) {
              imageUrl = profileImageUrl.toString();
            } else {
              final ref = FirebaseStorage.instance
                  .ref()
                  .child('profile_images')
                  .child('${user.uid}.jpg');

              imageUrl = await ref.getDownloadURL().timeout(
                const Duration(seconds: 5),
                onTimeout: () {
                  print('Image load timeout');
                  return '';
                },
              );
            }
          } catch (e) {
            print('Error loading profile image: $e');
            imageUrl = '';
          }

          final providerData = await _firestore
              .collection('service_providers')
              .doc(user.uid)
              .get();

          if (mounted) {
            setState(() {
              _fullName = userData.data()?['fullName'] ?? '';
              _phone = userData.data()?['phone'] ?? '';
              _email = user.email ?? '';
              _address = userData.data()?['address'] ?? '';
              _imageUrl = imageUrl;

              if (providerData.exists) {
                _category = providerData.data()?['category'] ?? '';
                _description = providerData.data()?['description'] ?? '';
                _hourlyRate =
                    (providerData.data()?['hourlyRate'] ?? 0.0).toDouble();
                _verificationStatus =
                    providerData.data()?['verificationStatus'] ?? 'unverified';
              }

              _isLoading = false;
            });
          }
        }
      }
    } catch (e) {
      print('Error loading provider data: $e');
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _navigateToEditProfile() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ProviderEditProfileScreen(
          fullName: _fullName,
          phone: _phone,
          address: _address,
          imageUrl: _imageUrl,
          category: _category,
          description: _description,
          hourlyRate: _hourlyRate,
        ),
      ),
    );

    if (result != null && result is Map<String, dynamic>) {
      setState(() {
        _fullName = result['fullName'];
        _phone = result['phone'];
        _address = result['address'];
        _category = result['category'];
        _description = result['description'];
        _hourlyRate = result['hourlyRate'];
        if (result['imageUrl'] != null) {
          _imageUrl = result['imageUrl'];
        }
      });
    }
  }

  Future<void> _navigateToVerification() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const ProviderVerificationScreen(),
      ),
    );

    // Refresh data when returning from verification screen
    _loadProviderData();
  }

  Future<void> _signOut() async {
    try {
      await _auth.signOut();
      if (mounted) {
        Navigator.of(context).pushReplacementNamed('/login');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error signing out: $e')),
      );
    }
  }

  Widget _buildVerificationBanner() {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (_verificationStatus == 'verified') {
      return Container();
    }

    Color backgroundColor;
    Color borderColor;
    Color textColor;

    switch (_verificationStatus) {
      case 'pending':
        backgroundColor = isDark
            ? Colors.orange.shade900.withOpacity(0.2)
            : Colors.orange.shade50;
        borderColor = isDark ? Colors.orange.shade800 : Colors.orange.shade200;
        textColor = isDark ? Colors.orange.shade300 : Colors.orange.shade800;
        break;
      case 'rejected':
        backgroundColor =
            isDark ? Colors.red.shade900.withOpacity(0.2) : Colors.red.shade50;
        borderColor = isDark ? Colors.red.shade800 : Colors.red.shade200;
        textColor = isDark ? Colors.red.shade300 : Colors.red.shade800;
        break;
      default:
        backgroundColor = isDark
            ? Colors.blue.shade900.withOpacity(0.2)
            : Colors.blue.shade50;
        borderColor = isDark ? Colors.blue.shade800 : Colors.blue.shade200;
        textColor = isDark ? Colors.blue.shade300 : Colors.blue.shade800;
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Icon(
                _verificationStatus == 'pending'
                    ? Icons.pending
                    : _verificationStatus == 'rejected'
                        ? Icons.cancel
                        : Icons.verified_user_outlined,
                color: textColor,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  _verificationStatus == 'pending'
                      ? 'Your verification is under review'
                      : _verificationStatus == 'rejected'
                          ? 'Your verification was rejected'
                          : 'Please verify your account',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: textColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            _verificationStatus == 'pending'
                ? 'We are reviewing your documents. This usually takes 1-2 business days.'
                : _verificationStatus == 'rejected'
                    ? 'Please check your verification status for details and resubmit.'
                    : 'Verify your identity to unlock all features and build trust with clients.',
            style: TextStyle(
              fontSize: 12,
              color: isDark ? Colors.grey[300] : Colors.grey[700],
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _navigateToVerification,
              style: ElevatedButton.styleFrom(
                backgroundColor: _verificationStatus == 'pending'
                    ? Colors.orange
                    : _verificationStatus == 'rejected'
                        ? Colors.red
                        : const Color(0xFF2A9D8F),
                elevation: 0,
              ),
              child: Text(
                _verificationStatus == 'pending'
                    ? 'Check Status'
                    : _verificationStatus == 'rejected'
                        ? 'Resubmit Verification'
                        : 'Verify Now',
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final User? currentUser = _auth.currentUser;
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Profile & Settings',
          style: TextStyle(
            color: isDark ? Colors.white : Colors.black,
          ),
        ),
        backgroundColor: isDark ? Colors.grey[900] : Colors.white,
        elevation: 0,
      ),
      body: RefreshIndicator(
        onRefresh: _loadProviderData,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ProviderProfileHeader(
                imageUrl: _imageUrl,
                fullName: _fullName,
                phone: _phone,
                email: _email,
                address: _address,
                userType: _userType,
                category: _category,
                hourlyRate: _hourlyRate,
                verificationStatus: _verificationStatus,
              ),
              _buildVerificationBanner(),
              const SizedBox(height: 16),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  'Account Information',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: isDark ? Colors.grey[400] : Colors.grey,
                  ),
                ),
              ),
              ProviderProfileMenuItem(
                icon: Icons.person_outline,
                title: 'Personal Details',
                onTap: _navigateToEditProfile,
              ),
              ProviderProfileMenuItem(
                icon: Icons.verified_user_outlined,
                title: 'Verification',
                onTap: _navigateToVerification,
                trailing: _verificationStatus == 'verified'
                    ? const Icon(
                        Icons.verified,
                        color: Colors.green,
                        size: 20,
                      )
                    : _verificationStatus == 'pending'
                        ? const Icon(
                            Icons.pending,
                            color: Colors.orange,
                            size: 20,
                          )
                        : _verificationStatus == 'rejected'
                            ? const Icon(
                                Icons.cancel,
                                color: Colors.red,
                                size: 20,
                              )
                            : const Icon(
                                Icons.arrow_forward_ios,
                                size: 16,
                              ),
              ),
              ProviderProfileMenuItem(
                icon: Icons.work_outline,
                title: 'Services',
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ProviderServicesscreen(),
                    ),
                  );
                },
              ),
              ProviderProfileMenuItem(
                icon: Icons.star_outline,
                title: 'Reviews & Ratings',
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ProviderReviewsScreen(
                        providerId: currentUser!.uid,
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: 24),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  'Settings',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: isDark ? Colors.grey[400] : Colors.grey,
                  ),
                ),
              ),
              ProviderProfileMenuItem(
                icon: Icons.notifications_outlined,
                title: 'Notifications',
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const NotificationScreen(),
                    ),
                  );
                },
              ),
              ProviderProfileMenuItem(
                icon: Icons.payment_outlined,
                title: 'Payment Methods',
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const PaymentMethodsScreen(),
                    ),
                  );
                },
              ),
              ProviderProfileMenuItem(
                icon: Icons.security_outlined,
                title: 'Security & Privacy',
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const SecurityPrivacyScreen(),
                    ),
                  );
                },
              ),
              ProviderProfileMenuItem(
                icon: Icons.color_lens_outlined,
                title: 'Theme',
                onTap: () {
                  showDialog(
                    context: context,
                    builder: (context) => const ThemeSelectorDialog(),
                  );
                },
              ),
              ProviderProfileMenuItem(
                icon: Icons.help_outline,
                title: 'Help & Support',
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const HelpSupportScreen(),
                    ),
                  );
                },
              ),
              const SizedBox(height: 24),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: ElevatedButton(
                  onPressed: _signOut,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isDark
                        ? Colors.red.shade900.withOpacity(0.3)
                        : Colors.red.shade50,
                    foregroundColor: Colors.red,
                    elevation: 0,
                    minimumSize: const Size(double.infinity, 48),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text('Log Out'),
                ),
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}

// Placeholder for ProviderServicesScreen
class ProviderServicesScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('My Services'),
      ),
      body: Center(
        child: Text('Services Management Screen - To be implemented'),
      ),
    );
  }
}

class ProviderProfileMenuItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final VoidCallback onTap;
  final Widget? trailing;

  const ProviderProfileMenuItem({
    Key? key,
    required this.icon,
    required this.title,
    required this.onTap,
    this.trailing,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return ListTile(
      leading: Icon(
        icon,
        color: const Color(0xFF2A9D8F),
      ),
      title: Text(
        title,
        style: TextStyle(
          color: isDark ? Colors.white : Colors.black87,
        ),
      ),
      trailing: trailing ??
          Icon(
            Icons.arrow_forward_ios,
            size: 16,
            color: isDark ? Colors.grey[400] : Colors.grey[600],
          ),
      onTap: onTap,
    );
  }
}
