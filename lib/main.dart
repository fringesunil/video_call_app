import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:vcapp/screens/incomming_call_screen.dart';
import 'package:vcapp/services/notification_services.dart';
import 'package:vcapp/screens/auth_screen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';


Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  debugPrint('Background message received: ${message.data}');
  await NotificationService.showCallNotification(message.data);
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await Firebase.initializeApp();
    debugPrint('Firebase initialized successfully');
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
    await NotificationService.initialize();

    // Check for initial message (e.g., app opened from notification tap)
    final initialMessage = await FirebaseMessaging.instance.getInitialMessage();
    Widget initialScreen = const AuthScreen();

    if (initialMessage != null && initialMessage.data['type'] == 'call') {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();
        final userId = userDoc.data()?['userId'] as int?;
        if (userId != null) {
          initialScreen = IncomingCallScreen(
            channelName: initialMessage.data['channelName'],
            callerId: initialMessage.data['callerId'],
            userId: userId,
          );
        }
      }
    }

    runApp(VideoCallApp(initialScreen: initialScreen));
  } catch (e, stackTrace) {
    debugPrint('Firebase initialization failed: $e\n$stackTrace');
  }
}

class VideoCallApp extends StatelessWidget {
  final Widget initialScreen;

  const VideoCallApp({Key? key, required this.initialScreen}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Video Call App',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: initialScreen,
      debugShowCheckedModeBanner: false,
      navigatorKey: NotificationService.navigatorKey,
    );
  }
}