import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:vcapp/screens/auth_screen.dart';
import 'package:vcapp/screens/home_screen.dart';
import 'package:vcapp/screens/incomming_call_screen.dart';
import 'package:vcapp/services/notification_services.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await Firebase.initializeApp();
    debugPrint('Firebase initialized successfully');
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
    await NotificationService.initialize();

    runApp(const VideoCallApp());
  } catch (e, stackTrace) {
    debugPrint('Firebase initialization failed: $e\n$stackTrace');
  }
}

Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  debugPrint('Background message received: ${message.data}');
  await NotificationService.showCallNotification(message.data);
}

class VideoCallApp extends StatelessWidget {
  const VideoCallApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Video Call App',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: FutureBuilder<Widget>(
        future: _getInitialScreen(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          }
          if (snapshot.hasError) {
            debugPrint('Error determining initial screen: ${snapshot.error}');
            return const AuthScreen();
          }
          return snapshot.data ?? const AuthScreen();
        },
      ),
      debugShowCheckedModeBanner: false,
      navigatorKey: NotificationService.navigatorKey,
    );
  }

  Future<Widget> _getInitialScreen() async {
    final user = FirebaseAuth.instance.currentUser;
    final initialMessage = await FirebaseMessaging.instance.getInitialMessage();

    if (initialMessage != null && initialMessage.data['type'] == 'call') {
      if (user != null) {
        final userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();
        final userId = userDoc.data()?['userId'] as int?;
        if (userId != null) {
          return IncomingCallScreen(
            channelName: initialMessage.data['channelName'],
            callerId: initialMessage.data['callerId'],
            userId: userId,
          );
        }
      }
    }

    // If user is authenticated, go to HomeScreen, else AuthScreen
    return user != null ? const HomeScreen() : const AuthScreen();
  }
}