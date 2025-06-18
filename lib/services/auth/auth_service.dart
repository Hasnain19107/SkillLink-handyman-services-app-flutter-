import 'package:SkillLink/features/service_provider/screens/home/provider_home_screen.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/utils/shared_preferences_helper.dart';
import '../../features/authentication/screens/login_screen.dart';

import '../../features/service_seeker/screens/home/home_screen.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Get current user
  User? get currentUser => _auth.currentUser;

  // Auth state changes stream
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // Sign in with email and password
  Future<UserCredential> signInWithEmailAndPassword(
      String email, String password) async {
    return await _auth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
  }

  // Register with email and password
  Future<UserCredential> registerWithEmailAndPassword(
    String email,
    String password,
    String fullName,
    String phone,
    String userRole,
  ) async {
    // Create user with email and password
    final userCredential = await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );

    // Add user details to Firestore
    await _firestore.collection('users').doc(userCredential.user!.uid).set({
      'fullName': fullName,
      'email': email,
      'phone': phone,
      'userType':
          userRole == 'provider' ? 'Service Provider' : 'Service Seeker',
      'createdAt': FieldValue.serverTimestamp(),
    });

    // If user is a provider, create provider document
    if (userRole == 'provider') {
      await _firestore
          .collection('service_providers')
          .doc(userCredential.user!.uid)
          .set({
        'fullName'
            'email': email,
        'phone': phone,
        'userType': 'Service Provider',
        'isAvailable': true,
        'rating': 0.0,
        'completedJobs': 0,
        'createdAt': FieldValue.serverTimestamp(),
      });
    }

    // Update display name
    await userCredential.user!.updateDisplayName(fullName);

    return userCredential;
  }

  // Basic sign out (without navigation)
  Future<void> signOut() async {
    print("Starting signOut process");
    try {
      // Clear shared preferences first
      await SharedPreferencesHelper.clearLoginState();
      print("SharedPreferences cleared");

      // Clear notification token before signing out

      // Then sign out from Firebase
      await _auth.signOut();
      print("Firebase signOut completed");
    } catch (e) {
      print("Error during signOut: $e");
      throw e; // Re-throw to handle in the UI
    }
  }

  // Sign out and navigate to login screen
  void signOutAndNavigateToLogin(BuildContext context) async {
    print("Starting signOutAndNavigateToLogin");
    try {
      // Show loading indicator
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return Center(
            child: CircularProgressIndicator(),
          );
        },
      );

      // Perform sign out
      await signOut();

      // Close loading dialog
      Navigator.pop(context);

      // Navigate to login screen with a slight delay to ensure dialog is closed
      Future.delayed(Duration(milliseconds: 100), () {
        print("Navigating to login screen");
        // Use a direct MaterialPageRoute to LoginScreen
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => LoginScreen()),
          (route) => false, // Remove all previous routes
        );
      });
    } catch (e) {
      print("Error in signOutAndNavigateToLogin: $e");
      // Close loading dialog if it's open
      if (Navigator.canPop(context)) {
        Navigator.pop(context);
      }

      // Show error message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error logging out. Please try again.')),
      );
    }
  }

  // Get user role
  Future<String> getUserRole() async {
    final user = _auth.currentUser;
    if (user != null) {
      final userData = await _firestore.collection('users').doc(user.uid).get();
      if (userData.exists) {
        return userData.data()?['userType'] ?? 'Service Seeker';
      }
    }
    return 'Service Seeker'; // Default role
  }

  // Get appropriate home screen based on user role
  Future<Widget> getHomeScreen() async {
    final userRole = await getUserRole();
    if (userRole == 'Service Provider') {
      return ProviderHomeScreen();
    } else {
      return HomeScreen();
    }
  }
}
