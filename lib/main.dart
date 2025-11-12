import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:ngobrolin_app/firebase_options.dart';
import 'package:provider/provider.dart';

import 'core/di/service_locator.dart';
import 'core/localization/app_localizations.dart';
// Legacy providers
import 'core/providers/auth_provider.dart';
import 'core/providers/settings_provider.dart';
import 'core/providers/socket_provider.dart';
// ViewModels
import 'core/viewmodels/auth/auth_view_model.dart';
import 'core/viewmodels/profile/profile_view_model.dart';
import 'core/viewmodels/profile/user_profile_view_model.dart';
import 'core/viewmodels/chat/chat_view_model.dart';
import 'core/viewmodels/chat/chat_list_view_model.dart';
import 'core/viewmodels/search/search_user_view_model.dart';
import 'core/viewmodels/settings/settings_view_model.dart';
import 'core/viewmodels/settings/blocked_users_view_model.dart';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'routes/app_routes.dart';
import 'theme/app_theme.dart';

// main() function in main.dart
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: '.env');
  await Firebase.initializeApp();

  // Setup service locator
  setupServiceLocator();

  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  final flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();
  const initSettings = InitializationSettings(
    android: AndroidInitializationSettings('@mipmap/ic_launcher'),
  );
  await flutterLocalNotificationsPlugin.initialize(initSettings);

  FirebaseMessaging.onMessage.listen((RemoteMessage message) async {
    final notification = message.notification;
    if (notification != null) {
      const androidDetails = AndroidNotificationDetails(
        'ngobrolin_default_channel',
        'Ngobrolin Notifications',
        importance: Importance.max,
        priority: Priority.high,
      );
      const details = NotificationDetails(android: androidDetails);
      await flutterLocalNotificationsPlugin.show(
        notification.hashCode,
        notification.title,
        notification.body,
        details,
      );
    }
  });

  runApp(
    MultiProvider(
      providers: [
        // Legacy providers (will be replaced gradually)
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => SettingsProvider()),
        ChangeNotifierProvider(create: (_) => SocketProvider()..init()),

        // ViewModels with dependency injection
        ChangeNotifierProvider(create: (_) => serviceLocator<AuthViewModel>()),
        ChangeNotifierProvider(create: (_) => serviceLocator<ProfileViewModel>()),
        ChangeNotifierProvider(create: (_) => serviceLocator<UserProfileViewModel>()),
        ChangeNotifierProvider(create: (_) => serviceLocator<ChatViewModel>()),
        ChangeNotifierProvider(create: (_) => serviceLocator<ChatListViewModel>()),
        ChangeNotifierProvider(create: (_) => serviceLocator<SearchUserViewModel>()),
        ChangeNotifierProvider(create: (_) => serviceLocator<SettingsViewModel>()),
        ChangeNotifierProvider(create: (_) => serviceLocator<BlockedUsersViewModel>()),
      ],
      child: const MyApp(),
    ),
  );
}

// class MyApp
class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final socketProvider = Provider.of<SocketProvider>(context, listen: false);
      final chatListViewModel = Provider.of<ChatListViewModel>(context, listen: false);
      final authViewModel = Provider.of<AuthViewModel>(context, listen: false);

      // Join semua room percakapan milik user agar listener new_message di main aktif
      final fetched = await chatListViewModel.fetchChatList();
      if (fetched) {
        for (final chat in chatListViewModel.chatList) {
          final convId = chat['id'] as String?;
          if (convId != null) {
            socketProvider.joinConversation(convId);
          }
        }
      }

      // Listener conversation_updated sudah benar (user room)
      socketProvider.on('conversation_updated', (data) {
        print('-------- conversation_updated: $data');
        try {
          final convId = data['conversationId'] as String?;
          final last = data['lastMessage'] as Map<String, dynamic>?;
          final senderId = last?['sender_id'] as String?;
          final myId = authViewModel.user?.id;

          if (convId != null && last != null) {
            final content = last['content'] as String? ?? '';
            final createdAt = last['created_at'] as String? ?? DateTime.now().toIso8601String();
            chatListViewModel.updateWithNewMessage(
              convId,
              content,
              createdAt,
              senderId: senderId,
              currentUserId: myId,
            );
          }
        } catch (_) {}
      });

      // Tambahkan listener global untuk new_message agar chat list ikut update
      socketProvider.on('new_message', (data) async {
        print('-------- main new_message: $data');
        try {
          final msg = data['message'] as Map<String, dynamic>?;
          if (msg == null) return;
          final convId = msg['conversation_id'] as String?;
          final content = msg['content'] as String? ?? '';
          final createdAt = msg['created_at'] as String? ?? DateTime.now().toIso8601String();
          final senderId = msg['sender_id'] as String?;
          final myId = authViewModel.user?.id;

          if (convId != null) {
            // Upsert: update jika ada, reload jika belum ada (chat baru / pagination)
            await chatListViewModel.updateWithNewMessage(
              convId,
              content,
              createdAt,
              senderId: senderId,
              currentUserId: myId,
            );
          }
        } catch (_) {}
      });
    });
  }

  @override
  void dispose() {
    final socketProvider = Provider.of<SocketProvider>(context, listen: false);
    socketProvider.off('conversation_updated');
    // Lepas listener new_message agar tidak terjadi duplikasi
    socketProvider.off('new_message');
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Ngobrolin',
      debugShowCheckedModeBanner: false,
      supportedLocales: const [Locale('en'), Locale('id')],
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      locale: context.watch<SettingsProvider>().locale,
      theme: AppTheme.lightTheme,
      initialRoute: AppRoutes.splash,
      onGenerateRoute: AppRoutes.generateRoute,
    );
  }
}
