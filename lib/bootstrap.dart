import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:ngobrolin_app/core/services/deeplink/deeplink_service.dart';
import 'package:provider/provider.dart';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import 'firebase_options_dev.dart' as dev_firebase;
import 'firebase_options_prod.dart' as prod_firebase;
import 'routes/app_routes.dart';
import 'theme/app_theme.dart';

// DI
import 'core/di/service_locator.dart';

// Localization
import 'core/localization/app_localizations.dart';

// Providers
import 'core/providers/socket_provider.dart';

// ViewModels
import 'core/viewmodels/auth/auth_view_model.dart';
import 'core/viewmodels/chat/chat_view_model.dart';
import 'core/viewmodels/settings/settings_view_model.dart';
import 'core/viewmodels/settings/blocked_users_view_model.dart';

// Repository
import 'core/repositories/user_repository.dart';

import 'flavors/flavor_config.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

const String kNotificationChannelId = 'ngobrolin_default_channel';
const String kNotificationChannelName = 'Ngobrolin Notifications';

/// =======================
///  FCM Background Handler
/// =======================
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  final firebaseOptions = FlavorConfig.isProd
      ? prod_firebase.DefaultFirebaseOptions.currentPlatform
      : dev_firebase.DefaultFirebaseOptions.currentPlatform;

  await Firebase.initializeApp(options: firebaseOptions);
}

Future<void> bootstrap() async {
  WidgetsFlutterBinding.ensureInitialized();

  // =======================
  // ENV
  // =======================
  try {
    await dotenv.load(fileName: FlavorConfig.isProd ? '.env.prod' : '.env.dev');
  } catch (_) {}

  // =======================
  // FIREBASE
  // =======================

  final firebaseOptions = FlavorConfig.isProd
      ? prod_firebase.DefaultFirebaseOptions.currentPlatform
      : dev_firebase.DefaultFirebaseOptions.currentPlatform;

  await Firebase.initializeApp(options: firebaseOptions);

  // iOS only
  if (Platform.isIOS) {
    await FirebaseMessaging.instance.requestPermission();
  }

  // =======================
  // DI
  // =======================
  setupServiceLocator();

  await serviceLocator<DeeplinkService>().init();

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

      if (payload == null || payload.isEmpty) {
        return;
      }

      serviceLocator<DeeplinkService>().handleDeepLink(payload);
    },
  );

  if (Platform.isAndroid) {
    const androidChannel = AndroidNotificationChannel(
      kNotificationChannelId,
      kNotificationChannelName,
      importance: Importance.max,
    );

    await flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
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
      payload: message.data['deeplink'] ?? '',
    );
  });

  // Notification tap
  FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
    // developer.log('Bootstrap - onMessageOpenedApp - message: ${message.data}');
    serviceLocator<DeeplinkService>().handleNotification(message.data);
  });

  // =======================
  // RUN APP (NO SIDE EFFECT)
  // =======================
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => SocketProvider()),
        ChangeNotifierProvider(create: (_) => serviceLocator<AuthViewModel>()),
        ChangeNotifierProvider(
          create: (_) => serviceLocator<SettingsViewModel>(),
        ),
        ChangeNotifierProvider(
          create: (_) => serviceLocator<BlockedUsersViewModel>(),
        ),
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
      if (mounted) {
        final authViewModel = Provider.of<AuthViewModel>(
          context,
          listen: false,
        );
        if (authViewModel.authenticated) {
          await serviceLocator<UserRepository>().registerFcmToken(token);
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: navigatorKey,
      title: FlavorConfig.instance.appName,
      debugShowCheckedModeBanner: false,
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      locale: context.watch<SettingsViewModel>().locale,
      theme: AppTheme.lightTheme,
      initialRoute: AppRoutes.splash,
      onGenerateRoute: AppRoutes.generateRoute,
    );
  }
}
