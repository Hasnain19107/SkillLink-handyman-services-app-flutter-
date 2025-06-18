import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';

import '../../../../core/theme/theme_provider.dart';
import '../../../../core/widgets/dialogs/theme_selector_dialog.dart';
import '../../../../services/auth/auth_service.dart';
import '../../../help_support/screens/help_support_screen.dart';
import '../../widgets/profile/profile_header.dart';
import '../../widgets/profile/profile_menu.dart';
import '../notifications/notifications_screen.dart';
import '../payment/payment_methods_screen.dart';
import '../security/security_privacy_screen.dart';
import 'edit_profile.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({Key? key}) : super(key: key);

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final AuthService _authService = AuthService();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String _name = '';
  String _phone = '';
  String _email = '';
  String _address = '';
  String _imageUrl = '';
  final String _userType = 'Service Seeker';
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    try {
      final User? user = _auth.currentUser;
      if (user != null) {
        final userData =
            await _firestore.collection('service_seekers').doc(user.uid).get();

        if (userData.exists && mounted) {
          final data = userData.data();
          setState(() {
            _name = data?['fullName'] ?? 'User';
            _phone = data?['phone'] ?? '';
            _address = data?['address'] ?? '';
            _imageUrl = data?['profileImageUrl'] ?? data?['imageUrl'] ?? '';
            _isLoading = false;
          });

          print('Loaded user data - Image URL: $_imageUrl'); // Debug log
        }
      }
    } catch (e) {
      print('Error loading user data: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _navigateToEditProfile() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EditProfileScreen(
          name: _name,
          phone: _phone,
          address: _address,
          imageUrl: _imageUrl,
        ),
      ),
    );

    // Handle the returned data
    if (result != null && mounted) {
      setState(() {
        _name = result['name'] ?? _name;
        _phone = result['phone'] ?? _phone;
        _address = result['address'] ?? _address;
        _imageUrl = result['imageUrl'] ?? _imageUrl;
      });

      // Also reload user data from Firebase to ensure consistency
      await _loadUserData();
    }
  }

  void _showThemeSelector() {
    showDialog(
      context: context,
      builder: (context) => const ThemeSelectorDialog(),
    );
  }

  void _navigateToPaymentMethods() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const PaymentMethodsScreen(),
      ),
    );
  }

  void _navigateToSecurityPrivacy() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const SecurityPrivacyScreen(),
      ),
    );
  }

  // Update your profile image widget

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDarkMode = themeProvider.isDarkMode;

    if (_isLoading) {
      return Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Profile & Settings',
          style: TextStyle(
            color: isDarkMode ? Colors.white : Colors.black,
          ),
        ),
        backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(
              Icons.edit,
              color: isDarkMode ? Colors.white : Colors.black,
            ),
            onPressed: _navigateToEditProfile,
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ProfileHeader(
              imageUrl: _imageUrl,
              name: _name,
              phone: _phone,
              email: _email,
              address: _address,
              userType: _userType,
            ),
            const SizedBox(height: 24),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                'Account Information',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: isDarkMode ? Colors.white70 : Colors.grey,
                ),
              ),
            ),
            ProfileMenuItem(
              icon: Icons.person_outline,
              title: 'Personal Details',
              onTap: _navigateToEditProfile,
            ),
            const SizedBox(height: 24),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                'Settings',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: isDarkMode ? Colors.white70 : Colors.grey,
                ),
              ),
            ),
            ProfileMenuItem(
              icon: Icons.notifications_outlined,
              title: 'Notifications',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const NotificationsScreen(),
                  ),
                );
              },
            ),
            ProfileMenuItem(
              icon: Icons.payment_outlined,
              title: 'Payment Methods',
              onTap: _navigateToPaymentMethods,
            ),
            ProfileMenuItem(
              icon: Icons.security_outlined,
              title: 'Security & Privacy',
              onTap: _navigateToSecurityPrivacy,
            ),
            ProfileMenuItem(
              icon: Icons.color_lens_outlined,
              title: 'Theme',
              onTap: _showThemeSelector,
            ),
            ProfileMenuItem(
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
                onPressed: () =>
                    _authService.signOutAndNavigateToLogin(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: isDarkMode
                      ? Colors.redAccent.withOpacity(0.2)
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
    );
  }
}
