import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:fl_chart/fl_chart.dart';
import 'dart:convert';

class WaterTrackerScreen extends StatefulWidget {
  const WaterTrackerScreen({super.key});

  @override
  State<WaterTrackerScreen> createState() => _WaterTrackerScreenState();
}

class _WaterTrackerScreenState extends State<WaterTrackerScreen> {
  int _waterCount = 0;
  List<Map<String, dynamic>> _history = [];
  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();

  @override
  void initState() {
    super.initState();
    _initializeNotifications();
    _loadWaterData();
    tz.initializeTimeZones();
  }

  Future<void> _initializeNotifications() async {
    const AndroidInitializationSettings initializationSettingsAndroid =
    AndroidInitializationSettings('@mipmap/ic_launcher');

    const InitializationSettings initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
    );

    await flutterLocalNotificationsPlugin.initialize(initializationSettings);
  }

  Future<void> _scheduleReminder() async {
    final now = tz.TZDateTime.now(tz.local);
    final reminderTime = now.add(const Duration(hours: 2));

    await flutterLocalNotificationsPlugin.zonedSchedule(
      0,
      'Hydration Reminder',
      'Time to drink water! 💧',
      reminderTime,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'water_reminder_channel',
          'Water Reminders',
          importance: Importance.max,
          priority: Priority.high,
        ),
      ),
      androidAllowWhileIdle: true,
      uiLocalNotificationDateInterpretation:
      UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }

  Future<void> _loadWaterData() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _waterCount = prefs.getInt('waterCount') ?? 0;
      final historyJson = prefs.getString('waterHistory') ?? '[]';
      _history = List<Map<String, dynamic>>.from(json.decode(historyJson));
    });
  }

  Future<void> _saveWaterData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('waterCount', _waterCount);
    await prefs.setString('waterHistory', json.encode(_history));
  }

  void _logWater() {
    setState(() {
      _waterCount++;
      final today = DateTime.now();
      final todayStr = '${today.year}-${today.month}-${today.day}';

      final existing = _history.indexWhere((e) => e['date'] == todayStr);
      if (existing != -1) {
        _history[existing]['count'] += 1;
      } else {
        _history.add({'date': todayStr, 'count': 1});
      }

      if (_history.length > 7) {
        _history.removeAt(0);
      }
    });
    _saveWaterData();
    _scheduleReminder();
  }

  void _resetWaterData() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _waterCount = 0;
    });
    await prefs.setInt('waterCount', 0);
  }

  List<BarChartGroupData> _buildBarChart() {
    return _history.asMap().entries.map((entry) {
      final index = entry.key;
      final data = entry.value;
      return BarChartGroupData(x: index, barRods: [
        BarChartRodData(toY: data['count'].toDouble(), color: Colors.blueAccent)
      ]);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Water Tracker")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text("Glasses Drunk Today: $_waterCount", style: const TextStyle(fontSize: 24)),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _logWater,
              child: const Text("Log a Glass of Water 💧"),
            ),
            const SizedBox(height: 10),
            ElevatedButton(
              onPressed: _resetWaterData,
              style: ElevatedButton.styleFrom(backgroundColor: Colors.white10),
              child: const Text("Reset Today's Count"),
            ),
            const SizedBox(height: 20),
            const Text("Past Week Water Intake", style: TextStyle(fontSize: 18)),
            const SizedBox(height: 12),
            SizedBox(
              height: 200,
              child: BarChart(
                BarChartData(
                  borderData: FlBorderData(show: false),
                  barGroups: _buildBarChart(),
                  titlesData: FlTitlesData(
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(showTitles: true),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (double value, _) {
                          final date = DateTime.now().subtract(Duration(days: _history.length - 1 - value.toInt()));
                          return Text("${date.day}/${date.month}", style: const TextStyle(fontSize: 10));
                        },
                      ),
                    ),
                  ),
                ),
              ),
            )
          ],
        ),
      ),
    );
  }
}
