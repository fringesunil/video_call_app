// import 'package:flutter/material.dart';
// import 'package:flutter_callkit_incoming/entities/call_kit_params.dart';
// import 'package:flutter_callkit_incoming/flutter_callkit_incoming.dart';
// import 'package:uuid/uuid.dart';
// import 'package:vcapp/screens/video_call_screen.dart';
// import 'package:vcapp/services/notification_services.dart';
// import 'package:vcapp/services/ringtone_service.dart';

// class CallkitService {
//   static const String _channelName = 'video_call_channel';
//   static const String _channelDescription = 'Video Call Notifications';
//   static const String _ringtonePath = 'assets/ringtone.mp3';
  
//   static final Uuid _uuid = Uuid();

//   /// End all calls
//   static Future<void> endAllCalls() async {
//     try {
//       await FlutterCallkitIncoming.endAllCalls();
//       await RingtoneService.stopRingtone();
//       debugPrint('All calls ended');
//     } catch (e) {
//       debugPrint('Error ending all calls: $e');
//     }
//   }

//   /// Check if there are active calls
//   static Future<bool> hasActiveCalls() async {
//     try {
//       final activeCalls = await FlutterCallkitIncoming.activeCalls();
//       return activeCalls.isNotEmpty;
//     } catch (e) {
//       debugPrint('Error checking active calls: $e');
//       return false;
//     }
//   }

//   /// Initialize the call service
//   static Future<void> initialize() async {
//     try {
//       // Listen for incoming call events
//       FlutterCallkitIncoming.onEvent.listen((event) async {
//         debugPrint('Callkit event: ${event!.event}');
        
//         switch (event.event) {
//           case 'ACTION_CALL_ACCEPT':
//             await _handleCallAccepted(event.body);
//             break;
//           case 'ACTION_CALL_DECLINE':
//             await _handleCallDeclined(event.body);
//             break;
//           case 'ACTION_CALL_INCOMING':
//             await _handleIncomingCall(event.body);
//             break;
//           case 'ACTION_CALL_ENDED':
//             await _handleCallEnded(event.body);
//             break;
//           default:
//             debugPrint('Unhandled callkit event: ${event.event}');
//             break;
//         }
//       });

//       // Request permissions
//       await FlutterCallkitIncoming.requestNotificationPermission(true);
      
//       debugPrint('Callkit service initialized successfully');
//     } catch (e) {
//       debugPrint('Error initializing callkit service: $e');
//     }
//   }

//   /// Show incoming call UI
//   static Future<void> showIncomingCall({
//     required String callerId,
//     required String callerName,
//     required String channelName,
//     required int userId,
//   }) async {
//     try {
//       final callData = {
//         'id': _uuid.v4(),
//         'nameCaller': callerName,
//         'appName': 'CallSync',
//         'avatar': 'https://i.pravatar.cc/100?img=$callerId',
//         'handle': callerId,
//         'type': 1, // Video call
//         'duration': 30000, // 30 seconds
//         'textAccept': 'Accept',
//         'textDecline': 'Decline',
//         'extra': {
//           'channelName': channelName,
//           'userId': userId,
//           'callerId': callerId,
//         },
//         'headers': {
//           'apiKey': 'Abc@123!',
//           'platform': 'flutter',
//         },
//         'android': {
//           'isCustomNotification': true,
//           'isShowLogo': false,
//           'ringtonePath': _ringtonePath,
//           'backgroundColor': '#0955fa',
//           'backgroundUrl': 'assets/test.png',
//           'actionColor': '#4CAF50',
//           'incomingCallNotificationChannelName': _channelName,
//           'missedCallNotificationChannelName': 'Missed call',
//         },
//         'ios': {
//           'iconName': 'CallKitLogo',
//           'handleType': 'generic',
//           'supportsVideo': true,
//           'maximumCallGroups': 2,
//           'maximumCallsPerCallGroup': 1,
//           'audioSessionMode': 'default',
//           'audioSessionActive': true,
//           'audioSessionPreferredSampleRate': 44100.0,
//           'audioSessionPreferredIOBufferDuration': 0.005,
//           'supportsDTMF': true,
//           'supportsHolding': true,
//           'supportsGrouping': false,
//           'supportsUngrouping': false,
//           'ringtonePath': _ringtonePath,
//         },
//       };

//       await FlutterCallkitIncoming.showCallkitIncoming(callData as CallKitParams);
//       debugPrint('Incoming call UI shown for: $callerName');
//     } catch (e) {
//       debugPrint('Error showing incoming call: $e');
//     }
//   }

//   /// Handle call accepted
//   static Future<void> _handleCallAccepted(dynamic body) async {
//     try {
//       debugPrint('Call accepted: $body');
      
//       // Stop ringtone
//       await RingtoneService.stopRingtone();
      
//       // Extract call data
//       final extra = body['extra'] as Map<String, dynamic>?;
//       if (extra != null) {
//         final channelName = extra['channelName'] as String?;
//         final userId = extra['userId'] as int?;
        
//         if (channelName != null && userId != null) {
//           // Navigate to video call screen
//           final navigator = NotificationService.navigatorKey.currentState;
//           if (navigator != null) {
//             navigator.pushReplacement(
//               MaterialPageRoute(
//                 builder: (context) => VideoCallScreen(
//                   channelName: channelName,
//                   userId: userId,
//                   isIncomingCall: true,
//                 ),
//               ),
//             );
//           }
//         }
//       }
      
//       // End the callkit call
//       await FlutterCallkitIncoming.endCall(body['id']);
//     } catch (e) {
//       debugPrint('Error handling call accepted: $e');
//     }
//   }

//   /// Handle call declined
//   static Future<void> _handleCallDeclined(dynamic body) async {
//     try {
//       debugPrint('Call declined: $body');
      
//       // Stop ringtone
//       await RingtoneService.stopRingtone();
      
//       // End the callkit call
//       await FlutterCallkitIncoming.endCall(body['id']);
//     } catch (e) {
//       debugPrint('Error handling call declined: $e');
//     }
//   }

//   /// Handle call ended
//   static Future<void> _handleCallEnded(dynamic body) async {
//     try {
//       debugPrint('Call ended: $body');
      
//       // Stop ringtone
//       await RingtoneService.stopRingtone();
//     } catch (e) {
//       debugPrint('Error handling call ended: $e');
//     }
//   }

//   /// Handle incoming call
//   static Future<void> _handleIncomingCall(dynamic body) async {
//     try {
//       debugPrint('Incoming call received: $body');
      
//       // Start ringtone
//       await RingtoneService.playRingtone();
//     } catch (e) {
//       debugPrint('Error handling incoming call: $e');
//     }
//   }
// } 