import 'dart:convert';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:kantinku/screens/staff_order_inbox_view.dart';
import 'package:kantinku/screens/order_history_screen.dart';
import 'package:kantinku/models/user_model.dart';

// ✅ BACKGROUND HANDLER - HARUS TOP-LEVEL
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  print("🔔 Background message: ${message.messageId}");
  print("📦 Data: ${message.data}");
}

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();
  
  GlobalKey<NavigatorState>? _navigatorKey;
  User? _currentUser;

  Future<void> init(GlobalKey<NavigatorState> navigatorKey) async {
    _navigatorKey = navigatorKey;
    print("🚀 Initializing Notification Service...");

    // 1. Request Permission
    NotificationSettings settings = await _firebaseMessaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      print('✅ Notification permission granted');
    } else {
      print('❌ Notification permission denied');
      return;
    }

    // 2. Create Notification Channel (Android)
    const AndroidNotificationChannel channel = AndroidNotificationChannel(
      'order_updates',
      'Order Updates',
      description: 'Notifikasi untuk update pesanan',
      importance: Importance.high,
      playSound: true,
      enableVibration: true,
    );

    await _flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);

    // 3. Initialize Local Notifications
    const AndroidInitializationSettings androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    
    const DarwinInitializationSettings iosSettings =
        DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );
    
    const InitializationSettings initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );
    
    await _flutterLocalNotificationsPlugin.initialize(
      initSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        print("🔔 Local notification clicked");
        if (response.payload != null && response.payload!.isNotEmpty) {
          try {
            final data = jsonDecode(response.payload!);
            _handleNotificationClick(data);
          } catch (e) {
            print("❌ Error parsing payload: $e");
          }
        }
      },
    );

    // 4. Handle Foreground Messages
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      print('📬 Foreground notification received');
      print('Title: ${message.notification?.title}');
      print('Body: ${message.notification?.body}');
      print('Data: ${message.data}');
      
      if (message.notification != null) {
        _showLocalNotification(message);
      }
    });

    // 5. Handle Background Message Click
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      print('🔔 Notification clicked (background)');
      _handleNotificationClick(message.data);
    });

    // 6. Handle Terminated State
    RemoteMessage? initialMessage = await _firebaseMessaging.getInitialMessage();
    if (initialMessage != null) {
      print('🔔 Notification clicked (terminated)');
      Future.delayed(const Duration(milliseconds: 1500), () {
        _handleNotificationClick(initialMessage.data);
      });
    }

    print("✅ Notification Service initialized");
  }

  // Update user (panggil setelah login atau di checkLoginStatus)
  void setCurrentUser(User? user) {
    _currentUser = user;
    print("👤 Current user updated: ${user?.namaPengguna ?? 'null'} (${user?.role ?? 'no role'})");
  }

  // Show Local Notification
  void _showLocalNotification(RemoteMessage message) async {
    const AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
      'order_updates',
      'Order Updates',
      channelDescription: 'Notifikasi status pesanan',
      importance: Importance.high,
      priority: Priority.high,
      showWhen: true,
      icon: '@mipmap/ic_launcher',
      playSound: true,
      enableVibration: true,
    );
    
    const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );
    
    const NotificationDetails details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );
    
    await _flutterLocalNotificationsPlugin.show(
      message.hashCode,
      message.notification?.title,
      message.notification?.body,
      details,
      payload: jsonEncode(message.data),
    );
  }

  // ✅ MAIN HANDLER FOR NOTIFICATION CLICK
  void _handleNotificationClick(Map<String, dynamic> data) {
    final BuildContext? context = _navigatorKey?.currentContext;
    
    if (context == null) {
      print("❌ Context is null, cannot navigate");
      return;
    }

    final String? type = data['type'];
    final String? screen = data['screen'];
    final String? orderIdStr = data['order_id'];

    print('=== HANDLING NOTIFICATION CLICK ===');
    print('Type: $type');
    print('Screen: $screen');
    print('Order ID: $orderIdStr');
    print('User Role: ${_currentUser?.role}');

    // ✅ ROUTING BASED ON NOTIFICATION TYPE
    if (type == 'new_order' && screen == 'staff_inbox') {
      // Staff: New Order
      print("➡️ Navigating to Staff Inbox");
      _navigateToStaffInbox(context);
      
    } else if ((type == 'order_ready' || 
                type == 'item_status_update' || 
                type == 'order_status_update') && 
               orderIdStr != null) {
      // Customer: Order updates
      print("➡️ Navigating to Order History");
      _navigateToOrderHistory(context);
      
    } else {
      // Default
      print("➡️ Navigating to default screen");
      if (_currentUser?.role.toLowerCase() == 'staff') {
        _navigateToStaffInbox(context);
      } else {
        _navigateToOrderHistory(context);
      }
    }
  }

  // ✅ NAVIGATION METHODS
  void _navigateToStaffInbox(BuildContext context) {
    if (_currentUser == null || _currentUser!.role.toLowerCase() != 'staff') {
      print("❌ Not a staff user");
      return;
    }

    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => StaffOrderInboxView(staffId: _currentUser!.id),
      ),
    );
  }

  void _navigateToOrderHistory(BuildContext context) {
    if (_currentUser == null) {
      print("❌ User is null");
      return;
    }

    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => OrderHistoryScreen(user: _currentUser!),
      ),
    );
  }

  // Get FCM Token
  Future<String?> getFCMToken() async {
    try {
      String? token = await _firebaseMessaging.getToken();
      print("📱 FCM Token: ${token?.substring(0, 20)}...");
      return token;
    } catch (e) {
      print("❌ Error getting FCM token: $e");
      return null;
    }
  }

  // Listen to token refresh
  void listenToTokenRefresh(Function(String) onTokenRefresh) {
    _firebaseMessaging.onTokenRefresh.listen((newToken) {
      print("🔄 Token refreshed: ${newToken.substring(0, 20)}...");
      onTokenRefresh(newToken);
    });
  }
}