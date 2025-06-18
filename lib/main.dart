import 'package:SkillLink/core/theme/theme_provider.dart';
import 'package:SkillLink/features/authentication/screens/forgot_password_screen.dart';
import 'package:SkillLink/features/authentication/screens/login_screen.dart';
import 'package:SkillLink/features/authentication/screens/onboarding_screen.dart';
import 'package:SkillLink/features/authentication/screens/register_screen.dart';
import 'package:SkillLink/features/service_provider/screens/bookings/booking_detail.dart';
import 'package:SkillLink/services/firebase/firebase_options.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:provider/provider.dart';
import 'features/notification/notification_fcm.dart';
import 'features/service_provider/screens/bookings/provider_bookings_screen.dart';
import 'features/service_seeker/screens/bookings/bookings_seeker.dart';
import 'features/service_seeker/screens/home/home_screen.dart';

import 'features/authentication/screens/splash_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  FlutterError.onError = FirebaseCrashlytics.instance.recordFlutterFatalError;
  // Initialize App Check for development/debug mode
  await FirebaseAppCheck.instance.activate(
    // For Android debug builds
    androidProvider: AndroidProvider.debug,
    // For iOS debug builds
    appleProvider: AppleProvider.debug,
    // For web debug builds
    webProvider: ReCaptchaV3Provider('recaptcha-v3-site-key'),
  );

  // Initialize notifications

  // Initialize local database

  runApp(
    ChangeNotifierProvider(
      create: (context) => ThemeProvider(),
      child: MyApp(),
    ),
  );
}

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    NotificationService().initializeNotifications();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);

    switch (state) {
      case AppLifecycleState.resumed:
        NotificationService().updateAppState(true);
        NotificationService()
            .checkPendingNotifications(); // Show pending notifications
        break;
      case AppLifecycleState.paused:
      case AppLifecycleState.inactive:
      case AppLifecycleState.detached:
        NotificationService().updateAppState(false);
        break;
      case AppLifecycleState.hidden:
        // TODO: Handle this case.
        throw UnimplementedError();
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);

    return MaterialApp(
      title: 'SkillLink',
      theme: themeProvider.lightTheme,
      darkTheme: themeProvider.darkTheme,
      themeMode: themeProvider.themeMode,
      debugShowCheckedModeBanner: false,
      home: SplashScreen(),
      routes: {
        '/splash': (context) => SplashScreen(),
        '/login': (context) => LoginScreen(),
        '/register': (context) => RegisterScreen(),
        '/onboarding': (context) => OnboardingScreen(),
        '/forgot-password': (context) => ForgotPasswordScreen(),
        '/home': (context) => const HomeScreen(),
        '/seeker-bookings': (context) => const BookingsScreen(),
        '/provider-bookings': (context) => const ProviderBookingsScreen(),
        '/booking-details': (context) {
          final args = ModalRoute.of(context)!.settings.arguments
              as Map<String, dynamic>;
          return BookingDetailPage(
            document: args['bookingId'],
            bookingId: args['bookingId'],
            bookingData: args['bookingData'] ?? {},
            data: {},
          );
        },
      },
    );
  }
}
