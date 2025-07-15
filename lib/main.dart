import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tz;

import 'screens/home_screen.dart';

final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
FlutterLocalNotificationsPlugin();

void main() async {
  // ✅ Ensure bindings before any plugin calls
  WidgetsFlutterBinding.ensureInitialized();

  // ✅ Initialize timezone
  tz.initializeTimeZones();

  // ✅ Initialize notifications
  const AndroidInitializationSettings androidSettings =
  AndroidInitializationSettings('@mipmap/ic_launcher');

  const InitializationSettings initSettings = InitializationSettings(
    android: androidSettings,
  );

  await flutterLocalNotificationsPlugin.initialize(initSettings);

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Smart Health Tracker',
      theme: ThemeData(primarySwatch: Colors.teal),
      home: const HomeScreen(),
      // Set to the screen you're testing
      debugShowCheckedModeBanner: false,
    );
  }
}
