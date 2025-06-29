import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_callkit_incoming/entities/android_params.dart';
import 'package:flutter_callkit_incoming/entities/call_event.dart';
import 'package:flutter_callkit_incoming/entities/call_kit_params.dart';
import 'package:flutter_callkit_incoming/entities/ios_params.dart';
import 'package:flutter_callkit_incoming/entities/notification_params.dart';
import 'package:flutter_callkit_incoming/flutter_callkit_incoming.dart';
import 'package:uuid/uuid.dart';
import 'package:vcapp/screens/auth_screen.dart';
import 'package:vcapp/screens/video_call_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  String? errorMessage;
  try {
    debugPrint('Initializing Firebase...');
    await Firebase.initializeApp();
    debugPrint('Firebase initialized successfully');
  } catch (e) {
    errorMessage = 'Firebase initialization failed: $e';
    debugPrint('Error during Firebase initialization: $e');
  }

  runApp(MyApp(errorMessage: errorMessage));
}

Future<void> showCallkitIncoming(String uuid, String callerId, String channelName, int userId) async {
  try {
    debugPrint('Showing CallKit incoming: uuid=$uuid, callerId=$callerId, channelName=$channelName, userId=$userId');
    if (channelName.isEmpty) {
      debugPrint('Error: channelName is empty');
      return;
    }
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
      callingNotification: const NotificationParams(
        showNotification: true,
        isShowCallback: true,
        subtitle: 'Calling...',
        callbackText: 'Hang Up',
      ),
      missedCallNotification: const NotificationParams(
        showNotification: true,
        isShowCallback: true,
        subtitle: 'Missed call',
        callbackText: 'Call back',
      ),
      android: const AndroidParams(
        isCustomNotification: true,
        isShowLogo: false,
        ringtonePath: 'system_ringtone_default',
        backgroundColor: '#0955fa',
        actionColor: '#4CAF50',
        incomingCallNotificationChannelName: 'Incoming Call',
        missedCallNotificationChannelName: 'Missed Call',
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
  } catch (e) {
    debugPrint('Error showing callkit incoming: $e');
  }
}

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  try {
    debugPrint('Background message received: ${message.data}');
    await Firebase.initializeApp();
    if (message.data['type'] == 'call') {
      final callerId = message.data['callerId'] ?? 'Unknown';
      final channelName = message.data['channelName'] ?? '';
      final userId = message.data['userId'] ?? '0';
      if (channelName.isEmpty || int.tryParse(userId) == null) {
        debugPrint('Error: Invalid channelName or userId in background handler');
        return;
      }
      final uuid = Uuid().v4();
      await showCallkitIncoming(uuid, callerId, channelName, int.parse(userId));
    }
  } catch (e) {
    debugPrint('Error in background handler: $e');
  }
}

class MyApp extends StatefulWidget {
  final String? errorMessage;

  final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

  MyApp({super.key, this.errorMessage});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  String? _currentCallUuid;

  @override
  Widget build(BuildContext context) {
    debugPrint('Building MyApp, errorMessage=${widget.errorMessage}');
    if (widget.errorMessage != null) {
      return MaterialApp(
        home: Scaffold(
          body: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error, color: Colors.red, size: 48),
                const SizedBox(height: 16),
                const Text(
                  'Initialization Error',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text(
                  widget.errorMessage!,
                  style: const TextStyle(fontSize: 16),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(builder: (context) => MyApp()),
                    );
                  },
                  child: const Text('Retry'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return MaterialApp(
      navigatorKey: widget.navigatorKey,
      title: 'CallSync',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: Builder(
        builder: (context) {
          debugPrint('Rendering AuthScreen');
          return const AuthScreen();
        },
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    _initializeAsyncTasks();
    _initCallKit();
    _handleForegroundMessages();
    debugPrint('MyApp initState completed, rendering AuthScreen');
  }

  void _handleForegroundMessages() {
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      debugPrint('Foreground message received: ${message.data}');
      if (message.data['type'] == 'call') {
        final callerId = message.data['callerId'] ?? 'Unknown';
        final channelName = message.data['channelName'] ?? '';
        final userId = message.data['userId'] ?? '0';
        if (channelName.isEmpty || int.tryParse(userId) == null) {
          debugPrint('Error: Invalid channelName or userId in foreground message');
          return;
        }
        final uuid = Uuid().v4();
        showCallkitIncoming(uuid, callerId, channelName, int.parse(userId));
      }
    });

    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      debugPrint('Message opened app: ${message.data}');
      if (message.data['type'] == 'call') {
        final channelName = message.data['channelName'] ?? '';
        final userId = message.data['userId'] ?? '0';
        if (channelName.isEmpty || int.tryParse(userId) == null) {
          debugPrint('Error: Invalid channelName or userId in message opened');
          return;
        }
        widget.navigatorKey.currentState?.push(
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

  void _initCallKit() {
    FlutterCallkitIncoming.onEvent.listen((CallEvent? event) {
      if (event == null) return;
      debugPrint('CallKit event: ${event.event}');
      switch (event.event) {
        case Event.actionCallAccept:
          final channelName = event.body['extra']['channelName'];
          final userId = int.parse(event.body['extra']['userId']);
          debugPrint('Call accepted: channelName=$channelName, userId=$userId');
          widget.navigatorKey.currentState?.push(
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
          debugPrint('Call ended/declined: uuid=$_currentCallUuid');
          FlutterCallkitIncoming.endCall(_currentCallUuid!);
          _currentCallUuid = null;
          break;
        case Event.actionCallTimeout:
          debugPrint('Call timed out: uuid=$_currentCallUuid');
          final params = CallKitParams(
            id: _currentCallUuid!,
            nameCaller: 'User ${event.body['nameCaller']?.replaceFirst('User ', '') ?? 'Unknown'}',
            handle: event.body['extra']['channelName'],
            type: 1,
            missedCallNotification: const NotificationParams(
              showNotification: true,
              isShowCallback: true,
              subtitle: 'Missed call',
              callbackText: 'Call back',
            ),
            android: const AndroidParams(
              isCustomNotification: true,
              isShowCallID: true,
            ),
            extra: event.body['extra'],
          );
          FlutterCallkitIncoming.showMissCallNotification(params);
          FlutterCallkitIncoming.endCall(_currentCallUuid!);
          _currentCallUuid = null;
          break;
        case Event.actionCallIncoming:
          debugPrint('Call incoming: uuid=${event.body['id']}');
          _currentCallUuid = event.body['id'];
          break;
        default:
          break;
      }
    });
  }

  Future<void> _initializeAsyncTasks() async {
    try {
      debugPrint('Requesting notification permissions...');
      await FirebaseMessaging.instance.requestPermission();
      debugPrint('Notification permissions requested');

      debugPrint('Requesting CallKit notification permissions...');
      await FlutterCallkitIncoming.requestNotificationPermission({
        'rationaleMessagePermission': 'Notification permission is required to show call notifications.',
        'postNotificationMessageRequired': 'Please allow notification permission from settings.'
      });
      debugPrint('CallKit notification permissions requested');

      debugPrint('Requesting full intent permission for Android 14+...');
      await FlutterCallkitIncoming.requestFullIntentPermission();
      debugPrint('Full intent permission requested');

      debugPrint('Setting up background message handler...');
      FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
      debugPrint('Background message handler set up');
    } catch (e) {
      debugPrint('Error in async initialization: $e');
    }
  }
}