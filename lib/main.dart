import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_callkit_incoming/entities/android_params.dart';
import 'package:flutter_callkit_incoming/entities/call_event.dart';
import 'package:flutter_callkit_incoming/entities/call_kit_params.dart';
import 'package:flutter_callkit_incoming/entities/ios_params.dart';
import 'package:flutter_callkit_incoming/flutter_callkit_incoming.dart';
import 'package:uuid/uuid.dart';
import 'package:vcapp/screens/auth_screen.dart';
import 'package:vcapp/screens/video_call_screen.dart';

Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  if (message.data['type'] == 'call') {
    final callerId = message.data['callerId'] ?? 'Unknown';
    final channelName = message.data['channelName'] ?? '';
    final userId = message.data['userId'] ?? '0';
    final uuid = Uuid().v4();
    
    await showCallkitIncoming(uuid, callerId, channelName, int.parse(userId));
  }
}

Future<void> showCallkitIncoming(String uuid, String callerId, String channelName, int userId) async {
  final params = CallKitParams(
    id: uuid,
    nameCaller: 'User $callerId',
    appName: 'CallSync',
    handle: channelName,
    type: 1, // Video call
    textAccept: 'Accept',
    textDecline: 'Decline',
    duration: 30000, // 30 seconds timeout
    extra: <String, dynamic>{'userId': userId.toString(), 'channelName': channelName},
    android: const AndroidParams(
      isCustomNotification: true,
      isShowLogo: false,
      ringtonePath: 'system_ringtone_default',
      backgroundColor: '#0955fa',
      actionColor: '#4CAF50',
      incomingCallNotificationChannelName: 'Incoming Call',
      isShowCallID: true,
    ),
    ios: const IOSParams(
      iconName: 'CallKitLogo',
      handleType: 'generic',
      supportsVideo: true,
      maximumCallGroups: 2,
      maximumCallsPerCallGroup: 1,
      audioSessionMode: 'default',
      audioSessionActive: true,
      audioSessionPreferredSampleRate: 44100.0,
      audioSessionPreferredIOBufferDuration: 0.005,
      supportsDTMF: true,
      supportsHolding: true,
      supportsGrouping: false,
      supportsUngrouping: false,
      ringtonePath: 'system_ringtone_default',
    ),
  );
  await FlutterCallkitIncoming.showCallkitIncoming(params);
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  
  // Request notification permissions
  await FirebaseMessaging.instance.requestPermission();
  await FlutterCallkitIncoming.requestNotificationPermission({
    'rationaleMessagePermission': 'Notification permission is required to show call notifications.',
    'postNotificationMessageRequired': 'Please allow notification permission from settings.'
  });

  // Set up background message handler
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  String? _currentCallUuid;

  @override
  void initState() {
    super.initState();
    _initCallKit();
    _handleForegroundMessages();
  }

  void _initCallKit() {
    FlutterCallkitIncoming.onEvent.listen((CallEvent? event) {
      if (event == null) return;
      switch (event.event) {
        case Event.actionCallAccept:
          final channelName = event.body['extra']['channelName'];
          final userId = int.parse(event.body['extra']['userId']);
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => VideoCallScreen(
                channelName: channelName,
                userId: userId,
                isIncomingCall: true,
              ),
            ),
          );
          FlutterCallkitIncoming.setCallConnected(_currentCallUuid!);
          break;
        case Event.actionCallDecline:
        case Event.actionCallEnded:
        case Event.actionCallTimeout:
          FlutterCallkitIncoming.endCall(_currentCallUuid!);
          _currentCallUuid = null;
          break;
        case Event.actionCallIncoming:
          _currentCallUuid = event.body['id'];
          break;
        default:
          break;
      }
    });
  }

  void _handleForegroundMessages() {
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      if (message.data['type'] == 'call') {
        final callerId = message.data['callerId'] ?? 'Unknown';
        final channelName = message.data['channelName'] ?? '';
        final userId = message.data['userId'] ?? '0';
        final uuid = Uuid().v4();
        showCallkitIncoming(uuid, callerId, channelName, int.parse(userId));
      }
    });

    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      if (message.data['type'] == 'call') {
        final channelName = message.data['channelName'] ?? '';
        final userId = message.data['userId'] ?? '0';
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => VideoCallScreen(
              channelName: channelName,
              userId: int.parse(userId),
              isIncomingCall: true,
            ),
          ),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'CallSync',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const AuthScreen(),
    );
  }
}