import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'dart:io' show Platform;

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  // Track app state
  static bool _isAppInForeground = true;

  // Set app state
  static void setAppState(bool isInForeground) {
    _isAppInForeground = isInForeground;
    print(
        'NotificationService: App state changed to: ${isInForeground ? "Foreground" : "Background"}');
  }

  // Initialize local notifications only
  Future<void> initializeNotifications() async {
    try {
      print('NotificationService: Starting local notification initialization');

      // Initialize local notifications
      await _initializeLocalNotifications();

      // Request POST_NOTIFICATIONS for Android 13+
      if (Platform.isAndroid) {
        print('NotificationService: Requesting POST_NOTIFICATIONS permission');
        await Permission.notification.request();
      }

      print('NotificationService: Local notification initialization completed');
    } catch (e, stackTrace) {
      print('NotificationService: Error initializing notifications: $e');
      print('NotificationService: Stack trace: $stackTrace');
    }
  }

  // Initialize local notifications
  Future<void> _initializeLocalNotifications() async {
    try {
      const AndroidInitializationSettings initializationSettingsAndroid =
          AndroidInitializationSettings('@mipmap/ic_launcher');

      const InitializationSettings initializationSettings =
          InitializationSettings(
        android: initializationSettingsAndroid,
      );

      await _localNotifications.initialize(
        initializationSettings,
        onDidReceiveNotificationResponse: (NotificationResponse response) {
          print('Local notification tapped: ${response.payload}');
          // Handle local notification tap
        },
      );
      print(
          'NotificationService: Local notifications initialized successfully');
    } catch (e) {
      print('NotificationService: Error initializing local notifications: $e');
    }
  }

  // Show local notification
  Future<void> showLocalNotification({
    required String title,
    required String body,
    String? payload,
  }) async {
    try {
      // Create notification channel for Android
      const AndroidNotificationDetails androidDetails =
          AndroidNotificationDetails(
        'hunarmand_notifications',
        'Hunarmand Notifications',
        channelDescription: 'Notifications for Hunarmand app',
        importance: Importance.max,
        priority: Priority.high,
        showWhen: false,
        enableVibration: true,
        playSound: true,
        icon: '@mipmap/ic_launcher',
      );

      const NotificationDetails platformChannelSpecifics = NotificationDetails(
        android: androidDetails,
      );

      // Generate unique ID
      int notificationId =
          DateTime.now().millisecondsSinceEpoch.remainder(100000);

      await _localNotifications.show(
        notificationId,
        title,
        body,
        platformChannelSpecifics,
        payload: payload,
      );

      print(
          'NotificationService: Local notification shown with ID: $notificationId');
    } catch (e) {
      print('NotificationService: Error showing local notification: $e');
    }
  }

  // Update app state in Firestore
  Future<void> updateAppState(bool isActive) async {
    try {
      _isAppInForeground = isActive;
      if (FirebaseAuth.instance.currentUser != null) {
        String userId = FirebaseAuth.instance.currentUser!.uid;
        await _firestore.collection('app_states').doc(userId).set({
          'isAppActive': isActive,
          'lastUpdated': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
        print('NotificationService: App state updated to: $isActive');
      }
    } catch (e) {
      print('NotificationService: Error updating app state: $e');
    }
  }

  // Notify when a booking is created - Show to PROVIDER
  Future<void> notifyBookingCreated({
    required String providerId,
    required String bookingId,
    required String seekerName,
    required String serviceName,
  }) async {
    try {
      print(
          'NotificationService: Processing booking created notification for provider: $providerId');

      String? currentUserId = FirebaseAuth.instance.currentUser?.uid;
      print('NotificationService: Current user ID: $currentUserId');

      // Check if PROVIDER's app is active
      DocumentSnapshot stateDoc =
          await _firestore.collection('app_states').doc(providerId).get();
      bool isProviderAppActive = false;

      if (stateDoc.exists) {
        Map<String, dynamic> data = stateDoc.data() as Map<String, dynamic>;
        isProviderAppActive = data['isAppActive'] ?? false;
        print(
            'NotificationService: Provider app active status: $isProviderAppActive');
      } else {
        print('NotificationService: No app state document found for provider');
      }

      // Always show local notification if this is the provider's device
      if (currentUserId == providerId) {
        await showLocalNotification(
          title: 'New Booking Request',
          body: '$seekerName has requested $serviceName',
          payload: 'booking_created_$bookingId',
        );
        print(
            'NotificationService: Local notification shown on provider device');
      } else {
        // Store for when provider opens their app
        await _storeNotificationForLater(
          userId: providerId,
          title: 'New Booking Request',
          body: '$seekerName has requested $serviceName',
          type: 'booking_created',
          bookingId: bookingId,
        );
        print(
            'NotificationService: Notification stored for provider (different device)');
      }
    } catch (e, stackTrace) {
      print(
          'NotificationService: Error processing booking created notification: $e');
      print('NotificationService: Stack trace: $stackTrace');
    }
  }

  // Notify when a booking is confirmed - Show to PROVIDER
  Future<void> notifyBookingConfirmed({
    required String providerId,
    required String bookingId,
    required String seekerName,
    required String serviceName,
  }) async {
    try {
      print(
          'NotificationService: Processing booking confirmed notification for provider: $providerId');

      // Check if PROVIDER's app is active
      DocumentSnapshot stateDoc =
          await _firestore.collection('app_states').doc(providerId).get();
      bool isProviderAppActive = false;

      if (stateDoc.exists) {
        Map<String, dynamic> data = stateDoc.data() as Map<String, dynamic>;
        isProviderAppActive = data['isAppActive'] ?? false;
      }

      String? currentUserId = FirebaseAuth.instance.currentUser?.uid;

      if (currentUserId == providerId && isProviderAppActive) {
        // Show to provider when booking is confirmed
        await showLocalNotification(
          title: 'Booking Confirmed',
          body: '$seekerName has confirmed the $serviceName booking',
          payload: 'booking_confirmed_$bookingId',
        );
        print(
            'NotificationService: Local notification shown on provider device');
      } else {
        await _storeNotificationForLater(
          userId: providerId,
          title: 'Booking Confirmed',
          body: '$seekerName has confirmed the $serviceName booking',
          type: 'booking_confirmed',
          bookingId: bookingId,
        );
        print('NotificationService: Notification stored for provider');
      }
    } catch (e, stackTrace) {
      print(
          'NotificationService: Error processing booking confirmed notification: $e');
    }
  }

  // Notify when a booking is accepted - Show to SEEKER
  Future<void> notifyBookingAccepted({
    required String seekerId,
    required String bookingId,
    required String providerName,
    required String serviceName,
  }) async {
    try {
      print(
          'NotificationService: Processing booking accepted notification for seeker: $seekerId');

      String? currentUserId = FirebaseAuth.instance.currentUser?.uid;
      print('NotificationService: Current user ID: $currentUserId');

      // Check if SEEKER's app is active
      DocumentSnapshot stateDoc =
          await _firestore.collection('app_states').doc(seekerId).get();
      bool isSeekerAppActive = false;

      if (stateDoc.exists) {
        Map<String, dynamic> data = stateDoc.data() as Map<String, dynamic>;
        isSeekerAppActive = data['isAppActive'] ?? false;
        print(
            'NotificationService: Seeker app active status: $isSeekerAppActive');
      } else {
        print('NotificationService: No app state document found for seeker');
      }

      // Always show local notification if this is the seeker's device
      if (currentUserId == seekerId) {
        await showLocalNotification(
          title: 'Booking Accepted',
          body: '$providerName has accepted your $serviceName booking',
          payload: 'booking_accepted_$bookingId',
        );
        print('NotificationService: Local notification shown on seeker device');
      } else {
        // Store for when seeker opens their app
        await _storeNotificationForLater(
          userId: seekerId,
          title: 'Booking Accepted',
          body: '$providerName has accepted your $serviceName booking',
          type: 'booking_accepted',
          bookingId: bookingId,
        );
        print(
            'NotificationService: Notification stored for seeker (different device)');
      }
    } catch (e, stackTrace) {
      print(
          'NotificationService: Error processing booking accepted notification: $e');
      print('NotificationService: Stack trace: $stackTrace');
    }
  }

  // Notify when a booking is completed - Show to SEEKER
  Future<void> notifyBookingCompleted({
    required String seekerId,
    required String bookingId,
    required String providerName,
    required String serviceName,
  }) async {
    try {
      print(
          'NotificationService: Processing booking completed notification for seeker: $seekerId');

      String? currentUserId = FirebaseAuth.instance.currentUser?.uid;
      print('NotificationService: Current user ID: $currentUserId');

      // Always show local notification if this is the seeker's device
      if (currentUserId == seekerId) {
        await showLocalNotification(
          title: 'Service Completed',
          body: '$providerName has completed your $serviceName service',
          payload: 'booking_completed_$bookingId',
        );
        print('NotificationService: Local notification shown on seeker device');
      } else {
        // Store for when seeker opens their app
        await _storeNotificationForLater(
          userId: seekerId,
          title: 'Service Completed',
          body: '$providerName has completed your $serviceName service',
          type: 'booking_completed',
          bookingId: bookingId,
        );
        print(
            'NotificationService: Notification stored for seeker (different device)');
      }
    } catch (e, stackTrace) {
      print(
          'NotificationService: Error processing booking completed notification: $e');
      print('NotificationService: Stack trace: $stackTrace');
    }
  }

  // Notify when a booking is cancelled - Show to OPPOSITE PERSON
  Future<void> notifyBookingCancelled({
    required String
        recipientId, // The person who should receive the notification
    required String bookingId,
    required String cancellerId,
    required String cancellerName,
    required String serviceName,
    required bool isCancelledByProvider,
  }) async {
    try {
      print(
          'NotificationService: Processing booking cancelled notification for recipient: $recipientId');

      // Check if RECIPIENT's app is active
      DocumentSnapshot stateDoc =
          await _firestore.collection('app_states').doc(recipientId).get();
      bool isRecipientAppActive = false;

      if (stateDoc.exists) {
        Map<String, dynamic> data = stateDoc.data() as Map<String, dynamic>;
        isRecipientAppActive = data['isAppActive'] ?? false;
      }

      String title = 'Booking Cancelled';
      String body = '$cancellerName has cancelled the $serviceName booking';

      String? currentUserId = FirebaseAuth.instance.currentUser?.uid;

      if (currentUserId == recipientId && isRecipientAppActive) {
        // Show to the opposite person who didn't cancel
        await showLocalNotification(
          title: title,
          body: body,
          payload: 'booking_cancelled_$bookingId',
        );
        print(
            'NotificationService: Local notification shown on recipient device');
      } else {
        await _storeNotificationForLater(
          userId: recipientId,
          title: title,
          body: body,
          type: 'booking_cancelled',
          bookingId: bookingId,
        );
        print('NotificationService: Notification stored for recipient');
      }
    } catch (e, stackTrace) {
      print(
          'NotificationService: Error processing booking cancelled notification: $e');
    }
  }

  // Add a new method for when booking is rejected - Show to SEEKER
  Future<void> notifyBookingRejected({
    required String seekerId,
    required String bookingId,
    required String providerName,
    required String serviceName,
  }) async {
    try {
      print(
          'NotificationService: Processing booking rejected notification for seeker: $seekerId');

      // Check if SEEKER's app is active
      DocumentSnapshot stateDoc =
          await _firestore.collection('app_states').doc(seekerId).get();
      bool isSeekerAppActive = false;

      if (stateDoc.exists) {
        Map<String, dynamic> data = stateDoc.data() as Map<String, dynamic>;
        isSeekerAppActive = data['isAppActive'] ?? false;
      }

      String? currentUserId = FirebaseAuth.instance.currentUser?.uid;

      if (currentUserId == seekerId && isSeekerAppActive) {
        // Show to seeker when booking is rejected
        await showLocalNotification(
          title: 'Booking Rejected',
          body: '$providerName has rejected your $serviceName booking',
          payload: 'booking_rejected_$bookingId',
        );
        print('NotificationService: Local notification shown on seeker device');
      } else {
        await _storeNotificationForLater(
          userId: seekerId,
          title: 'Booking Rejected',
          body: '$providerName has rejected your $serviceName booking',
          type: 'booking_rejected',
          bookingId: bookingId,
        );
        print('NotificationService: Notification stored for seeker');
      }
    } catch (e, stackTrace) {
      print(
          'NotificationService: Error processing booking rejected notification: $e');
    }
  }

  // Store notification for later when app becomes active
  Future<void> _storeNotificationForLater({
    required String userId,
    required String title,
    required String body,
    required String type,
    required String bookingId,
  }) async {
    try {
      await _firestore.collection('pending_notifications').add({
        'userId': userId,
        'title': title,
        'body': body,
        'type': type,
        'bookingId': bookingId,
        'createdAt': FieldValue.serverTimestamp(),
        'isShown': false,
      });
      print('NotificationService: Notification stored for later delivery');
    } catch (e) {
      print('NotificationService: Error storing notification: $e');
    }
  }

  // Check and show pending notifications when app becomes active
  Future<void> checkPendingNotifications() async {
    try {
      if (FirebaseAuth.instance.currentUser == null) return;

      String userId = FirebaseAuth.instance.currentUser!.uid;
      QuerySnapshot pendingDocs = await _firestore
          .collection('pending_notifications')
          .where('userId', isEqualTo: userId)
          .where('isShown', isEqualTo: false)
          .orderBy('createdAt', descending: true)
          .limit(5) // Show only last 5 notifications
          .get();

      for (DocumentSnapshot doc in pendingDocs.docs) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;

        await showLocalNotification(
          title: data['title'],
          body: data['body'],
          payload: '${data['type']}_${data['bookingId']}',
        );

        // Mark as shown
        await doc.reference.update({'isShown': true});

        // Add delay between notifications
        await Future.delayed(Duration(milliseconds: 500));
      }

      if (pendingDocs.docs.isNotEmpty) {
        print(
            'NotificationService: Showed ${pendingDocs.docs.length} pending notifications');
      }
    } catch (e) {
      print('NotificationService: Error checking pending notifications: $e');
    }
  }

  // Clean up old notifications
  Future<void> cleanupOldNotifications() async {
    try {
      DateTime oneWeekAgo = DateTime.now().subtract(Duration(days: 7));

      QuerySnapshot oldDocs = await _firestore
          .collection('pending_notifications')
          .where('createdAt', isLessThan: Timestamp.fromDate(oneWeekAgo))
          .get();

      for (DocumentSnapshot doc in oldDocs.docs) {
        await doc.reference.delete();
      }

      if (oldDocs.docs.isNotEmpty) {
        print(
            'NotificationService: Cleaned up ${oldDocs.docs.length} old notifications');
      }
    } catch (e) {
      print('NotificationService: Error cleaning up notifications: $e');
    }
  }

  // Test method to show notification immediately (for debugging)
  Future<void> testNotification() async {
    try {
      await showLocalNotification(
        title: 'Test Notification',
        body:
            'This is a test notification to check if local notifications work',
        payload: 'test_notification',
      );
      print('NotificationService: Test notification sent');
    } catch (e) {
      print('NotificationService: Error sending test notification: $e');
    }
  }
}
