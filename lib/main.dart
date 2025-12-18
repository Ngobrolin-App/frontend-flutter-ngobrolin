import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:provider/provider.dart';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import 'firebase_options.dart';
import 'routes/app_routes.dart';
import 'theme/app_theme.dart';

// DI
import 'core/di/service_locator.dart';

// Localization
import 'core/localization/app_localizations.dart';

// Providers
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

// Repository
import 'core/repositories/user_repository.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

const String kNotificationChannelId = 'ngobrolin_default_channel';
const String kNotificationChannelName = 'Ngobrolin Notifications';

/// =======================
///  FCM Background Handler
/// =======================
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // =======================
  // ENV (ANTI CRASH)
  // =======================
  try {
    await dotenv.load(fileName: '.env');
  } catch (_) {}

  // =======================
  // FIREBASE
  // =======================
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // iOS only
  if (Platform.isIOS) {
    await FirebaseMessaging.instance.requestPermission();
  }

  // =======================
  // DI (HARUS SYNC ONLY)
  // =======================
  setupServiceLocator();

  // =======================
  // FCM Background
  // =======================
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  // =======================
  // Local Notifications
  // =======================
  final flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();

  const initSettings = InitializationSettings(
    android: AndroidInitializationSettings('@mipmap/launcher_icon'),
  );

  await flutterLocalNotificationsPlugin.initialize(
    initSettings,
    onDidReceiveNotificationResponse: (NotificationResponse response) {
      final payload = response.payload;
      if (payload != null && payload.isNotEmpty) {
        navigatorKey.currentState?.pushNamed(AppRoutes.chat, arguments: {'userId': payload});
      }
    },
  );

  if (Platform.isAndroid) {
    const androidChannel = AndroidNotificationChannel(
      kNotificationChannelId,
      kNotificationChannelName,
      importance: Importance.max,
    );

    await flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(androidChannel);
  }

  // Foreground message
  FirebaseMessaging.onMessage.listen((RemoteMessage message) async {
    final notification = message.notification;
    if (notification == null) return;

    const androidDetails = AndroidNotificationDetails(
      kNotificationChannelId,
      kNotificationChannelName,
      importance: Importance.max,
      priority: Priority.high,
    );

    const details = NotificationDetails(android: androidDetails);

    await flutterLocalNotificationsPlugin.show(
      notification.hashCode,
      notification.title,
      notification.body,
      details,
      payload: message.data['userId'] ?? '',
    );
  });

  // Notification tap
  FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
    final data = message.data;
    final userId = data['userId'];

    if (userId != null && userId.isNotEmpty) {
      navigatorKey.currentState?.pushNamed(
        AppRoutes.chat,
        arguments: {'userId': userId, 'name': data['name'], 'avatarUrl': data['avatarUrl']},
      );
    }
  });

  // =======================
  // RUN APP (NO SIDE EFFECT)
  // =======================
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => SettingsProvider()),

        // ❌ JANGAN INIT SOCKET DI SINI
        ChangeNotifierProvider(create: (_) => SocketProvider()),

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

/// =======================
///        MyApp
/// =======================
class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  void initState() {
    super.initState();

    // FCM token refresh
    FirebaseMessaging.instance.onTokenRefresh.listen((token) async {
      final authViewModel = Provider.of<AuthViewModel>(context, listen: false);
      if (authViewModel.authenticated) {
        await serviceLocator<UserRepository>().registerFcmToken(token);
      }
    });

    // =======================
    // POST FRAME INIT (AMAN)
    // =======================
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final socketProvider = Provider.of<SocketProvider>(context, listen: false);
      final chatListViewModel = Provider.of<ChatListViewModel>(context, listen: false);

      // 🔥 SOCKET INIT DI SINI (ANTI BLACKSCREEN)
      try {
        await socketProvider.init();
      } catch (_) {
        return;
      }

      try {
        final fetched = await chatListViewModel.fetchChatList();
        if (fetched) {
          for (final chat in chatListViewModel.chatList) {
            final convId = chat.id as String?;
            if (convId != null) {
              socketProvider.joinConversation(convId);
            }
          }
        }
      } catch (_) {}
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: navigatorKey,
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
