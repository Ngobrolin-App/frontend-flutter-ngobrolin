import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:ngobrolin_app/firebase_options.dart';
import 'package:provider/provider.dart';

import 'core/localization/app_localizations.dart';
import 'core/providers/auth_provider.dart';
import 'core/providers/settings_provider.dart';
import 'core/providers/socket_provider.dart';
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
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => SettingsProvider()),
        ChangeNotifierProvider(create: (_) => SocketProvider()..init()),
      ],
      child: const MyApp(),
    ),
  );
}

// class MyApp
class MyApp extends StatelessWidget {
  const MyApp({super.key});

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
