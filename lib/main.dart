import 'package:bank_app/auth_services/auth_wrapper.dart';
import 'package:bank_app/auth_services/user_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

/// Handles background FCM messages
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  print("📩 Background message received: ${message.messageId}");
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // ✅ Ensure background handler is set before Firebase initializes
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  await Firebase.initializeApp();

  FirebaseMessaging messaging = FirebaseMessaging.instance;

  // 🔹 Request notification permission
  NotificationSettings settings = await messaging.requestPermission(
    alert: true,
    badge: true,
    sound: true,
  );

  print("🔔 Notification permission status: ${settings.authorizationStatus}");

  if (settings.authorizationStatus == AuthorizationStatus.denied) {
    print("❌ User denied notification permissions.");
  }

  // ✅ Get & log FCM token
  String? token = await messaging.getToken();
  print("🔥 FCM Token: $token");

  // 🔹 Handle foreground messages
  FirebaseMessaging.onMessage.listen((RemoteMessage message) {
    print("📩 Foreground message: ${message.notification?.title}");
  });

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => AuthProvider(),
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        home: AuthWrapper(),
      ),
    );
  }
}
