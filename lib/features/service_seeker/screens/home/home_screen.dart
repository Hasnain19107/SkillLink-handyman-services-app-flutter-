import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';

import '../../../../core/theme/theme_provider.dart';
// Updated import to use fcm_service.dart
import '../../../notification/notification_fcm.dart';
import 'widgets/home_content.dart';
import '../bookings/bookings_seeker.dart';
import '../messages/messages_screen.dart';
import '../profile/profile_seeker.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;
  bool _notificationsInitialized = false;

  @override
  void initState() {
    super.initState();

    // Initialize FCM notifications after user login
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        try {
          // Set user type
          Provider.of<ThemeProvider>(context, listen: false)
              .setUserType(UserType.seeker);

          // Initialize FCM if not already initialized
          if (!_notificationsInitialized &&
              FirebaseAuth.instance.currentUser != null) {
            NotificationService().initializeNotifications();
            _notificationsInitialized = true;
          }
        } catch (e) {
          print('Error during initialization: $e');
        }
      }
    });

    // Listen for auth state changes to handle token updates
    FirebaseAuth.instance.authStateChanges().listen((User? user) {
      if (user != null && mounted && !_notificationsInitialized) {
        NotificationService().initializeNotifications();
        setState(() {
          _notificationsInitialized = true;
        });
      }
    });
  }

  final GlobalKey<HomeContentState> _homeContentKey =
      GlobalKey<HomeContentState>();

  late final List<Widget> _screens = [
    HomeContent(key: _homeContentKey),
    const BookingsScreen(),
    const MessagesScreen(),
    const ProfileScreen(),
  ];

  void _onItemTapped(int index) {
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

  void navigateToTab(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
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
          selectedItemColor: Colors.blue,
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
