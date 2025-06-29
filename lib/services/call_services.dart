import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:uuid/uuid.dart';

class CallService {
  static const String serverUrl = 'https://cloud-message.onrender.com/initiate-call';

  static Future<void> initiateCall({
    required String callerId,
    required String targetUserId,
    required String channelName,
    required String targetFcmToken,
  }) async {
    final uuid = Uuid().v4();
    final payload = {
      'callerId': callerId,
      'targetUserId': targetUserId,
      'channelName': channelName,
      'targetFcmToken': targetFcmToken,
      'type': 'call',
      'uuid': uuid,
    };

    debugPrint('Sending call notification with payload: $payload');

    try {
      final response = await http.post(
        Uri.parse(serverUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(payload),
      );

      if (response.statusCode == 200) {
        debugPrint('Notification sent successfully: ${response.body}');
      } else {
        debugPrint('Failed to send notification: ${response.statusCode}, ${response.body}');
      }
    } catch (e) {
      debugPrint('Error sending notification: $e');
    }
  }
}