import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'firebase_options.dart';

@pragma('vm:entry-point')
Future<void> _messageHandler(RemoteMessage message) async {
  print('background message ${message.notification?.body}');
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    if (Firebase.apps.isEmpty) {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
    }
  } catch (e) {
    if (e.toString().contains('duplicate-app')) {
      print('Firebase already initialized');
    } else {
      rethrow;
    }
  }
  FirebaseMessaging.onBackgroundMessage(_messageHandler);
  runApp(const MessagingTutorial());
}

class MessagingTutorial extends StatelessWidget {
  const MessagingTutorial({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Firebase Messaging',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const MyHomePage(title: 'Firebase Messaging'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, this.title});

  final String? title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  late FirebaseMessaging messaging;
  String? notificationText;
  String? fcmToken;
  String? errorMessage;

  @override
  void initState() {
    super.initState();
    messaging = FirebaseMessaging.instance;
    messaging.subscribeToTopic("messaging");
    
    messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    messaging.getToken().then((value) {
      print('FCM Token: $value');
      setState(() {
        fcmToken = value;
        errorMessage = null;
      });
    }).catchError((error) {
      print('Error getting FCM token: $error');
      setState(() {
        errorMessage = 'Failed to get FCM token. Google Play Services is required. Please use an emulator with Google Play or a physical device.';
        fcmToken = null;
      });
    });

    FirebaseMessaging.onMessage.listen((RemoteMessage event) {
      print("message received");
      print(event.notification?.body);
      print(event.data.values);
      
      if (mounted) {
        setState(() {
          notificationText = event.notification?.body;
        });

        _showNotificationDialog(
          context,
          event.notification?.title ?? 'Notification',
          event.notification?.body ?? '',
          event.data,
        );
      }
    });

    FirebaseMessaging.onMessageOpenedApp.listen((message) {
      print('Message clicked!');
      if (mounted) {
        _showNotificationDialog(
          context,
          message.notification?.title ?? 'Notification',
          message.notification?.body ?? '',
          message.data,
        );
      }
    });

    messaging.getInitialMessage().then((message) {
      if (message != null && mounted) {
        _showNotificationDialog(
          context,
          message.notification?.title ?? 'Notification',
          message.notification?.body ?? '',
          message.data,
        );
      }
    });
  }

  void _showNotificationDialog(
    BuildContext context,
    String title,
    String body,
    Map<String, dynamic> data,
  ) {
    final String notificationType = data['type']?.toString().toLowerCase() ?? 'regular';

    Color backgroundColor;
    Color textColor;
    IconData iconData;
    String typeLabel;

    switch (notificationType) {
      case 'important':
        backgroundColor = Colors.red.shade700;
        textColor = Colors.white;
        iconData = Icons.warning;
        typeLabel = 'Important';
        break;
      case 'wisdom':
        backgroundColor = Colors.purple.shade700;
        textColor = Colors.white;
        iconData = Icons.lightbulb;
        typeLabel = 'Wisdom';
        break;
      case 'inspiration':
      case 'motivation':
        backgroundColor = Colors.blue.shade700;
        textColor = Colors.white;
        iconData = Icons.emoji_events;
        typeLabel = 'Inspiration';
        break;
      default:
        backgroundColor = Colors.grey.shade700;
        textColor = Colors.white;
        iconData = Icons.message;
        typeLabel = 'Regular';
    }

    if (!context.mounted) return;

    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          backgroundColor: backgroundColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Row(
            children: [
              Icon(iconData, color: textColor, size: 28),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        color: textColor,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      typeLabel,
                      style: TextStyle(
                        color: textColor.withValues(alpha: 0.9),
                        fontSize: 12,
                        fontWeight: FontWeight.normal,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          content: Text(
            body,
            style: TextStyle(
              color: textColor,
              fontSize: 16,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop();
              },
              child: Text(
                'Ok',
                style: TextStyle(
                  color: textColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title ?? 'Firebase Messaging'),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.notifications_active,
                size: 64,
                color: Colors.blue,
              ),
              const SizedBox(height: 24),
              const Text(
                'Firebase Cloud Messaging',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Your FCM Token:',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 8),
              if (fcmToken != null)
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade200,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: SelectableText(
                    fcmToken!,
                    style: const TextStyle(
                      fontSize: 12,
                      fontFamily: 'monospace',
                    ),
                    textAlign: TextAlign.center,
                  ),
                )
              else if (errorMessage != null)
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.red.shade200),
                  ),
                  child: Column(
                    children: [
                      const Icon(
                        Icons.error_outline,
                        color: Colors.red,
                        size: 32,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        errorMessage!,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Colors.red,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                )
              else
                const CircularProgressIndicator(),
              const SizedBox(height: 24),
              if (notificationText != null)
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.blue.shade200),
                  ),
                  child: Column(
                    children: [
                      const Text(
                        'Last Notification:',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        notificationText!,
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontSize: 14),
                      ),
                    ],
                  ),
                ),
              const SizedBox(height: 24),
              const Text(
                'Send test notifications from Firebase Console',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
