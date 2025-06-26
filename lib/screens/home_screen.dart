import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:vcapp/services/call_services.dart';
import 'package:vcapp/services/notification_services.dart';
import 'video_call_screen.dart';
import 'auth_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  User? _currentUser;
  int? _currentUserId;
  String? _currentUserFcmToken;

  @override
  void initState() {
    super.initState();
    _currentUser = FirebaseAuth.instance.currentUser;
    _setupUserData();
    _setupFirebaseMessaging();
  }

  Future<void> _setupUserData() async {
    if (_currentUser != null) {
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(_currentUser!.uid)
          .get();
      if (mounted) {
        setState(() {
          _currentUserId = userDoc.data()?['userId'];
          _currentUserFcmToken = userDoc.data()?['fcmToken'];
        });
      }
    }
  }

  Future<void> _setupFirebaseMessaging() async {
    final fcmToken = await FirebaseMessaging.instance.getToken();
    if (_currentUser != null && fcmToken != null) {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(_currentUser!.uid)
          .update({'fcmToken': fcmToken});
      debugPrint('FCM Token updated for user ${_currentUser!.uid}: $fcmToken');
    }

    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      debugPrint('Foreground message received: ${message.data}');
      if (message.data['type'] == 'call' && mounted) {
        NotificationService.showCallNotification(
          message.data,
          context: context,
          currentUserId: _currentUserId,
        );
      }
    });

    FirebaseMessaging.instance.getInitialMessage().then((RemoteMessage? message) {
      if (message != null && message.data['type'] == 'call' && mounted) {
        debugPrint('Initial message received: ${message.data}');
        NotificationService.showCallNotification(
          message.data,
          context: context,
          currentUserId: _currentUserId,
        );
      }
    });

    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      if (message.data['type'] == 'call' && mounted) {
        debugPrint('App opened from notification: ${message.data}');
        NotificationService.showCallNotification(
          message.data,
          context: context,
          currentUserId: _currentUserId,
        );
      }
    });
  }

  void _startCall(String targetUserId, String targetFcmToken, String email) async {
    if (_currentUserId != null) {
      const channelName = 'fringe';
      await CallService.initiateCall(
        callerId: _currentUserId.toString(),
        targetUserId: targetUserId,
        channelName: channelName,
        targetFcmToken: targetFcmToken,
      );
      if (mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => VideoCallScreen(
              channelName: channelName,
              userId: _currentUserId!,
            ),
          ),
        );
      }
    }
  }

  void _logout() async {
    await FirebaseAuth.instance.signOut();
    if (mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const AuthScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1a1a2e),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          'Video Call App',
          style: TextStyle(color: Colors.white),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.white),
            onPressed: _logout,
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Your User ID: ${_currentUserId ?? 'Loading...'}',
                style: const TextStyle(fontSize: 16, color: Colors.grey),
              ),
              const SizedBox(height: 20),
              const Text(
                'Available Users',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 20),
              Expanded(
                child: StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance.collection('users').snapshots(),
                  builder: (context, snapshot) {
                    if (snapshot.hasError) {
                      return const Center(
                        child: Text(
                          'Error loading users',
                          style: TextStyle(color: Colors.red),
                        ),
                      );
                    }
                    if (!snapshot.hasData) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    final users = snapshot.data!.docs
                        .where((doc) => doc.id != _currentUser?.uid)
                        .toList();

                    if (users.isEmpty) {
                      return const Center(
                        child: Text(
                          'No other users found',
                          style: TextStyle(color: Colors.white),
                        ),
                      );
                    }

                    return ListView.builder(
                      itemCount: users.length,
                      itemBuilder: (context, index) {
                        final user = users[index];
                        final email = user['email'] as String;
                        final userId = user['userId'].toString();
                        final fcmToken = user['fcmToken'] as String;

                        return Card(
                          color: Colors.white.withOpacity(0.1),
                          margin: const EdgeInsets.symmetric(vertical: 8),
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundColor: Colors.blue.withOpacity(0.3),
                              child: const Icon(Icons.person, color: Colors.white),
                            ),
                            title: Text(
                              email,
                              style: const TextStyle(color: Colors.white),
                            ),
                            subtitle: Text(
                              'User ID: $userId',
                              style: const TextStyle(color: Colors.grey),
                            ),
                            trailing: ElevatedButton(
                              onPressed: () => _startCall(userId, fcmToken, email),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.blue,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                              child: const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.video_call, size: 20),
                                  SizedBox(width: 5),
                                  Text('Call'),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}