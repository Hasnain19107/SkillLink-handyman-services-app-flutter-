import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../verification/provider_verification_screen.dart';
import 'widgets/verification_required_screen.dart';
import 'widgets/pending_verification_screen.dart';
import 'widgets/bookings_tab_view.dart';

class ProviderBookingsScreen extends StatefulWidget {
  final VoidCallback? onNavigateHome;
  final int initialTabIndex;

  const ProviderBookingsScreen({
    Key? key,
    this.onNavigateHome,
    this.initialTabIndex = 0,
  }) : super(key: key);

  @override
  State<ProviderBookingsScreen> createState() => _ProviderBookingsScreenState();
}

class _ProviderBookingsScreenState extends State<ProviderBookingsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  bool _isLoading = true;
  String _verificationStatus = 'unverified';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: 5,
      vsync: this,
      initialIndex: widget.initialTabIndex,
    );
    _checkVerificationStatus();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
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
            _isLoading = false;
          });
        } else {
          setState(() => _isLoading = false);
        }
      } else {
        setState(() => _isLoading = false);
      }
    } catch (e) {
      print('Error checking verification status: $e');
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(
          title: Text('My Bookings',
              style: TextStyle(color: isDark ? Colors.white : Colors.black)),
          backgroundColor: isDark ? Colors.grey[900] : Colors.white,
          elevation: 0,
        ),
        body: const Center(
          child: CircularProgressIndicator(
            color: Color(0xFF2A9D8F),
          ),
        ),
      );
    }

    if (_verificationStatus != 'verified' && _verificationStatus != 'pending') {
      return Scaffold(
        appBar: AppBar(
          title: Text('My Bookings',
              style: TextStyle(color: isDark ? Colors.white : Colors.black)),
          backgroundColor: isDark ? Colors.grey[900] : Colors.white,
          elevation: 0,
        ),
        body: VerificationRequiredScreen(
          onVerifyPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const ProviderVerificationScreen(),
              ),
            ).then((_) {
              _checkVerificationStatus();
            });
          },
        ),
      );
    }

    if (_verificationStatus == 'pending') {
      return Scaffold(
        appBar: AppBar(
          title: Text('My Bookings',
              style: TextStyle(color: isDark ? Colors.white : Colors.black)),
          backgroundColor: isDark ? Colors.grey[900] : Colors.white,
          elevation: 0,
        ),
        body: PendingVerificationScreen(
          onViewStatusPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const ProviderVerificationScreen(),
              ),
            ).then((_) {
              _checkVerificationStatus();
            });
          },
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Bookings'),
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        foregroundColor: isDark ? Colors.white : Colors.black,
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          labelColor: Color(0xFF2A9D8F),
          unselectedLabelColor: isDark ? Colors.grey[400] : Colors.grey,
          indicatorColor: Color(0xFF2A9D8F),
          isScrollable: true,
          tabs: const [
            Tab(text: 'Pending'),
            Tab(text: 'Confirmed'),
            Tab(text: 'Awaiting Confirmation'),
            Tab(text: 'Completed'),
            Tab(text: 'Cancelled'),
          ],
        ),
      ),
      body: BookingsTabView(tabController: _tabController),
    );
  }
}
