import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz_data;
import 'package:fl_chart/fl_chart.dart';
// Uncomment the following line and add usage_stats in pubspec.yaml (Android only)
// import 'package:usage_stats/usage_stats.dart';

/// **************************************
/// SleepTrackerScreen
/// Features:
/// 1. Start / End sleep session
/// 2. Persistent history (last 30 entries)
/// 3. Bedtime scheduler with notification
/// 4. Screen‑time before bed (Android UsageStats) – fallback to N/A on iOS
/// 5. Weekly bar‑chart analytics
/// **************************************

class SleepTrackerScreen extends StatefulWidget {
  const SleepTrackerScreen({super.key});
  @override
  State<SleepTrackerScreen> createState() => _SleepTrackerScreenState();
}

class _SleepTrackerScreenState extends State<SleepTrackerScreen> {
  DateTime? _sleepStart;
  DateTime? _sleepEnd;
  Duration? _sleepDuration;
  List<SleepSession> _history = [];

  // Bedtime schedule
  TimeOfDay? _bedTime;
  TimeOfDay? _wakeTime;

  // Screen‑time (minutes) for last night
  int? _bedScreenMinutes;

  final _prefsFuture = SharedPreferences.getInstance();
  late FlutterLocalNotificationsPlugin _notif;

  @override
  void initState() {
    super.initState();
    _initPrefs();
    _initNotifications();
    _loadUsageStats();
  }

  Future<void> _initPrefs() async {
    final prefs = await _prefsFuture;
    // Load schedule
    if (prefs.containsKey('bedTime')) {
      final t = prefs.getString('bedTime')!.split(':');
      _bedTime = TimeOfDay(hour: int.parse(t[0]), minute: int.parse(t[1]));
    }
    if (prefs.containsKey('wakeTime')) {
      final t = prefs.getString('wakeTime')!.split(':');
      _wakeTime = TimeOfDay(hour: int.parse(t[0]), minute: int.parse(t[1]));
    }
    // Load ongoing sleep
    if (prefs.containsKey('ongoingStart')) {
      _sleepStart = DateTime.parse(prefs.getString('ongoingStart')!);
    }
    // Load history
    if (prefs.containsKey('sleepHistory')) {
      final list = jsonDecode(prefs.getString('sleepHistory')!) as List;
      _history = list.map((e) => SleepSession.fromJson(e)).toList();
    }
    setState(() {});
  }

  Future<void> _initNotifications() async {
    tz_data.initializeTimeZones();
    _notif = FlutterLocalNotificationsPlugin();
    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    await _notif.initialize(const InitializationSettings(android: androidInit));
    _scheduleDailyBedtimeNotification();
  }

  Future<void> _scheduleDailyBedtimeNotification() async {
    if (_bedTime == null) return;
    final location = tz.local;
    final now = tz.TZDateTime.now(location);
    var scheduled = tz.TZDateTime(location, now.year, now.month, now.day, _bedTime!.hour, _bedTime!.minute);
    if (scheduled.isBefore(now)) {
      scheduled = scheduled.add(const Duration(days: 1));
    }
    await _notif.zonedSchedule(
      0,
      'Time to sleep 🛌',
      'Follow your bedtime schedule for better rest.',
      scheduled,
      const NotificationDetails(
        android: AndroidNotificationDetails('sleep_channel', 'Sleep', importance: Importance.max, priority: Priority.high),
      ),
      androidAllowWhileIdle: true,
      uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.time,
      payload: 'bedtime',
    );
  }

  Future<void> _startSleep() async {
    _sleepStart = DateTime.now();
    final prefs = await _prefsFuture;
    await prefs.setString('ongoingStart', _sleepStart!.toIso8601String());
    setState(() {});
  }

  Future<void> _endSleep() async {
    _sleepEnd = DateTime.now();
    if (_sleepStart == null) return;
    _sleepDuration = _sleepEnd!.difference(_sleepStart!);
    final session = SleepSession(start: _sleepStart!, end: _sleepEnd!);
    _history.insert(0, session);
    if (_history.length > 30) _history.removeLast();

    final prefs = await _prefsFuture;
    await prefs.remove('ongoingStart');
    await prefs.setString('sleepHistory', jsonEncode(_history.map((e) => e.toJson()).toList()));

    _sleepStart = null;
    setState(() {});
  }

  Future<void> _pickBedWakeTimes() async {
    final bed = await showTimePicker(context: context, initialTime: _bedTime ?? const TimeOfDay(hour: 22, minute: 0));
    if (bed == null) return;
    final wake = await showTimePicker(context: context, initialTime: _wakeTime ?? const TimeOfDay(hour: 7, minute: 0));
    if (wake == null) return;
    _bedTime = bed;
    _wakeTime = wake;
    final prefs = await _prefsFuture;
    await prefs.setString('bedTime', '${bed.hour}:${bed.minute}');
    await prefs.setString('wakeTime', '${wake.hour}:${wake.minute}');
    _scheduleDailyBedtimeNotification();
    setState(() {});
  }

  Future<void> _loadUsageStats() async {
    // Android only: requires permission PACKAGE_USAGE_STATS
    /*
    try {
      final end = DateTime.now();
      final start = end.subtract(const Duration(hours: 3));
      final events = await UsageStats.queryUsageStats(start, end);
      int minutes = 0;
      for (final e in events) {
        minutes += e.totalTimeInForeground.inMinutes;
      }
      setState(() => _bedScreenMinutes = minutes);
    } catch (_) {
      setState(() => _bedScreenMinutes = null);
    }
    */
    // Placeholder: disable feature on unsupported platforms
    setState(() => _bedScreenMinutes = null);
  }

  @override
  Widget build(BuildContext context) {
    final ongoing = _sleepStart != null;
    return Scaffold(
      appBar: AppBar(title: const Text('Sleep Tracker')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _sectionTitle('Sleep Logger'),
          Card(
            child: ListTile(
              title: Text(ongoing ? 'Sleep in progress…' : 'No active sleep session'),
              subtitle: ongoing ? Text('Started at: ${_sleepStart!.hour.toString().padLeft(2, '0')}:${_sleepStart!.minute.toString().padLeft(2, '0')}') : null,
              trailing: ElevatedButton(
                onPressed: ongoing ? _endSleep : _startSleep,
                child: Text(ongoing ? 'End Sleep' : 'Start Sleep'),
              ),
            ),
          ),
          const SizedBox(height: 16),
          _sectionTitle('Bedtime Schedule'),
          Card(
            child: ListTile(
              title: Text(_bedTime == null ? 'Not set' : 'Bed: ${_bedTime!.format(context)}  ·  Wake: ${_wakeTime!.format(context)}'),
              subtitle: const Text('Daily notification will be sent at bedtime'),
              trailing: const Icon(Icons.edit),
              onTap: _pickBedWakeTimes,
            ),
          ),
          const SizedBox(height: 16),
          _sectionTitle('Screen‑time Before Bed'),
          Card(
            child: ListTile(
              title: Text(_bedScreenMinutes == null ? 'Unavailable on this device' : '$_bedScreenMinutes minutes'),
              subtitle: const Text('In last 3 hours before sleep'),
            ),
          ),
          const SizedBox(height: 16),
          _sectionTitle('Last 7 sleeps'),
          SizedBox(
            height: 220,
            child: _history.isEmpty
                ? const Center(child: Text('No data'))
                : BarChart(
              BarChartData(
                alignment: BarChartAlignment.spaceAround,
                titlesData: FlTitlesData(show: false),
                barGroups: _history.take(7).toList().reversed
                    .map((e) => BarChartGroupData(x: e.start.day, barRods: [BarChartRodData(toY: e.duration.inHours.toDouble())]))
                    .toList(),
              ),
            ),
          ),
          const SizedBox(height: 16),
          _sectionTitle('History'),
          ..._history.map((e) => ListTile(
            leading: const Icon(Icons.nightlight_round),
            title: Text('${e.duration.inHours}h ${e.duration.inMinutes.remainder(60)}m'),
            subtitle: Text('${e.start.toLocal()} → ${e.end.toLocal()}'),
          )),
        ],
      ),
    );
  }

  Widget _sectionTitle(String text) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 4.0),
    child: Text(text, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
  );
}

class SleepSession {
  final DateTime start;
  final DateTime end;
  SleepSession({required this.start, required this.end});
  Duration get duration => end.difference(start);
  Map<String, dynamic> toJson() => {
    'start': start.toIso8601String(),
    'end': end.toIso8601String(),
  };
  factory SleepSession.fromJson(Map<String, dynamic> json) => SleepSession(
    start: DateTime.parse(json['start']),
    end: DateTime.parse(json['end']),
  );
}
