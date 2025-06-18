import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';

import '../bookings/provider_bookings_screen.dart';
import '../messages/provider_messages_screen.dart';
import '../profile/notification_screen.dart';
import '../profile/provider_profile_screen.dart';
import '../services/provider_services.dart';
import '../verification/provider_verification_screen.dart';
import '../ratings/rating_review_provider.dart';
import 'widgets/provider_header.dart';
import 'widgets/provider_stats_card.dart';
import 'widgets/verification_card.dart';
import 'widgets/availability_toggle.dart';
import 'widgets/booking_requests_section.dart';
import 'widgets/services_section.dart';

class ProviderHomeScreen extends StatefulWidget {
  const ProviderHomeScreen({Key? key}) : super(key: key);

  @override
  State<ProviderHomeScreen> createState() => _ProviderHomeScreenState();
}

class _ProviderHomeScreenState extends State<ProviderHomeScreen> {
  int _selectedIndex = 0;
  late final List<Widget> _screens;

  @override
  void initState() {
    super.initState();
    // Pass navigation callbacks to each screen
    _screens = [
      const ProviderHomeContent(),
      ProviderBookingsScreen(onNavigateHome: () => navigateToTab(0)),
      ProviderMessagesScreen(onNavigateHome: () => navigateToTab(0)),
      ProviderProfileScreen(onNavigateHome: () => navigateToTab(0)),
    ];
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  void navigateToTab(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  // Handle back button press

  Future<bool?> _showExitConfirmationDialog() async {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Exit App'),
        content: const Text('Are you sure you want to exit the app?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Exit'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      // ignore: deprecated_member_use
      onPopInvoked: (didPop) async {
        if (didPop) return;

        // If user is not on home tab, navigate back to home
        if (_selectedIndex != 0) {
          setState(() {
            _selectedIndex = 0;
          });
          return;
        }

        // If on home tab, show exit confirmation dialog
        final shouldPop = await _showExitConfirmationDialog() ?? false;
        if (shouldPop && context.mounted) {
          Navigator.of(context).pop();
        }
      },
      child: Scaffold(
        body: IndexedStack(
          index: _selectedIndex,
          children: _screens,
        ),
        bottomNavigationBar: BottomNavigationBar(
          type: BottomNavigationBarType.fixed,
          currentIndex: _selectedIndex,
          onTap: _onItemTapped,
          selectedItemColor: Color(0xFF2A9D8F),
          unselectedItemColor: Colors.grey,
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.home),
              label: 'Home',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.calendar_today),
              label: 'Bookings',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.message),
              label: 'Messages',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.person),
              label: 'Profile',
            ),
          ],
        ),
      ),
    );
  }
}

class ProviderHomeContent extends StatefulWidget {
  const ProviderHomeContent({Key? key}) : super(key: key);

  @override
  State<ProviderHomeContent> createState() => _ProviderHomeContentState();
}

class _ProviderHomeContentState extends State<ProviderHomeContent> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  String _providerName = '';
  String _imageUrl = '';
  bool _isAvailable = true;
  bool _isLoading = true;
  String _verificationStatus = 'unverified';
  int _pendingBookings = 0;
  int _completedJobs = 0;
  double _totalEarnings = 0.0;

  @override
  void initState() {
    super.initState();
    _loadProviderData();
    _loadProviderStats();
    _checkVerificationStatus();
    _loadUnreadNotificationCount();
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
                profileImageUrl.toString().isNotEmpty &&
                profileImageUrl.toString().startsWith('http')) {
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

              if (imageUrl.isNotEmpty) {
                await _firestore
                    .collection('users')
                    .doc(user.uid)
                    .update({'profileImageUrl': imageUrl});
              }
            }
          } catch (e) {
            imageUrl = '';
          }

          if (mounted) {
            setState(() {
              _providerName =
                  userData.data()?['fullName']?.toString() ?? 'Provider';
              _imageUrl = imageUrl;
              _isAvailable = userData.data()?['isAvailable'] as bool? ?? true;
              _isLoading = false;
            });
          }
        } else {
          if (mounted) {
            setState(() => _isLoading = false);
          }
        }
      } else {
        if (mounted) {
          setState(() => _isLoading = false);
        }
      }
    } catch (e) {
      print('Error loading provider data: $e');
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _loadProviderStats() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return;

      // Get pending bookings count
      final pendingQuery = await _firestore
          .collection('booking_service')
          .where('providerId', isEqualTo: user.uid)
          .where('status', isEqualTo: 'pending')
          .get();

      // Get completed bookings
      final completedQuery = await _firestore
          .collection('booking_service')
          .where('providerId', isEqualTo: user.uid)
          .where('status', isEqualTo: 'completed')
          .get();

      // Calculate total earnings from completed bookings
      double totalEarnings = 0.0;
      for (var doc in completedQuery.docs) {
        final data = doc.data();
        // Use budget field from your booking model
        final earnings = (data['budget'] as num?)?.toDouble() ??
            (data['servicePrice'] as num?)?.toDouble() ??
            0.0;
        totalEarnings += earnings;
      }

      if (mounted) {
        setState(() {
          _pendingBookings = pendingQuery.docs.length;
          _completedJobs = completedQuery.docs.length;
          _totalEarnings = totalEarnings;
        });
      }
    } catch (e) {
      print('Error loading provider stats: $e');
      if (mounted) {
        setState(() {
          _pendingBookings = 0;
          _completedJobs = 0;
          _totalEarnings = 0.0;
        });
      }
    }
  }

  Future<void> _checkVerificationStatus() async {
    try {
      final user = _auth.currentUser;
      if (user != null) {
        final providerDoc = await _firestore
            .collection('service_providers')
            .doc(user.uid)
            .get();

        if (providerDoc.exists) {
          setState(() {
            _verificationStatus =
                providerDoc.data()?['verificationStatus'] ?? 'unverified';
          });
        }
      }
    } catch (e) {
      print('Error checking verification status: $e');
    }
  }

  Future<void> _loadUnreadNotificationCount() async {
    try {
      final user = _auth.currentUser;
      if (user != null) {
        if (mounted) {
          setState(() {});
        }
      }
    } catch (e) {
      print('Error loading unread notification count: $e');
    }
  }

  Stream<int> _getUnreadNotificationCountStream() {
    final user = _auth.currentUser;
    if (user == null) return Stream.value(0);

    return _firestore
        .collection('notifications')
        .where('recipientId', isEqualTo: user.uid)
        .where('isRead', isEqualTo: false)
        .snapshots()
        .map((snapshot) => snapshot.docs.length);
  }

  void _toggleAvailability() {
    if (!mounted) return;

    setState(() {
      _isAvailable = !_isAvailable;
    });

    try {
      final User? user = _auth.currentUser;
      if (user != null) {
        _firestore.collection('users').doc(user.uid).update({
          'isAvailable': _isAvailable,
        });

        _firestore.collection('providers').doc(user.uid).update({
          'isAvailable': _isAvailable,
        }).catchError((e) {
          print(
              'Note: Could not update availability in providers collection: $e');
        });
      }
    } catch (e) {
      print('Error updating availability: $e');
      if (mounted) {
        setState(() {
          _isAvailable = !_isAvailable;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to update availability')),
        );
      }
    }
  }

  Future<void> _refreshStats() async {
    await _loadProviderStats();
  }

  Future<void> _refreshData() async {
    try {
      // Run all refresh operations concurrently
      await Future.wait([
        _loadProviderData(),
        _loadProviderStats(),
        _checkVerificationStatus(),
        _loadUnreadNotificationCount(),
      ]);
    } catch (e) {
      print('Error refreshing data: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to refresh data'),
            duration: Duration(seconds: 2),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return SafeArea(
      child: RefreshIndicator(
        onRefresh: _refreshData,
        color: Color(0xFF2A9D8F),
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ProviderHeader(
                  providerName: _providerName,
                  imageUrl: _imageUrl,
                  unreadNotificationCountStream:
                      _getUnreadNotificationCountStream(),
                  onNotificationPressed: () async {
                    await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const NotificationScreen(),
                      ),
                    );
                    _loadUnreadNotificationCount();
                  },
                ),
                const SizedBox(height: 24),
                if (_verificationStatus != 'verified')
                  VerificationCard(
                    verificationStatus: _verificationStatus,
                    onVerifyPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              const ProviderVerificationScreen(),
                        ),
                      );
                    },
                  ),
                if (_verificationStatus != 'verified')
                  const SizedBox(height: 24),
                AvailabilityToggle(
                  isAvailable: _isAvailable,
                  onToggle: _toggleAvailability,
                ),
                const SizedBox(height: 24),
                StatsSection(
                  pendingBookings: _pendingBookings,
                  completedJobs: _completedJobs,
                  totalEarnings: _totalEarnings,
                  onPendingTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            ProviderBookingsScreen(initialTabIndex: 0),
                      ),
                    );
                  },
                  onCompletedTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            ProviderBookingsScreen(initialTabIndex: 2),
                      ),
                    );
                  },
                  onRatingTap: () async {
                    final User? user = _auth.currentUser;
                    if (user != null) {
                      await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ProviderReviewsScreen(
                            providerId: user.uid,
                          ),
                        ),
                      );
                      _refreshStats();
                    }
                  },
                ),
                const SizedBox(height: 24),
                BookingRequestsSection(
                  onViewAllPressed: () {
                    final homeScreenState = context
                        .findAncestorStateOfType<_ProviderHomeScreenState>();
                    homeScreenState?._onItemTapped(1);
                  },
                ),
                const SizedBox(height: 24),
                ServicesSection(
                  onManagePressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ProviderServicesscreen(),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
