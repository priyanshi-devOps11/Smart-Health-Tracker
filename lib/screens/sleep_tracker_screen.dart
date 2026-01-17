import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz_data;
import 'package:fl_chart/fl_chart.dart';

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
  TimeOfDay? _bedTime;
  TimeOfDay? _wakeTime;

  final _prefsFuture = SharedPreferences.getInstance();
  late FlutterLocalNotificationsPlugin _notif;

  @override
  void initState() {
    super.initState();
    _initPrefs();
    _initNotifications();
  }

  Future<void> _initPrefs() async {
    final prefs = await _prefsFuture;
    if (prefs.containsKey('bedTime')) {
      final t = prefs.getString('bedTime')!.split(':');
      _bedTime = TimeOfDay(hour: int.parse(t[0]), minute: int.parse(t[1]));
    }
    if (prefs.containsKey('wakeTime')) {
      final t = prefs.getString('wakeTime')!.split(':');
      _wakeTime = TimeOfDay(hour: int.parse(t[0]), minute: int.parse(t[1]));
    }
    if (prefs.containsKey('ongoingStart')) {
      _sleepStart = DateTime.parse(prefs.getString('ongoingStart')!);
    }
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
    var scheduled = tz.TZDateTime(
      location,
      now.year,
      now.month,
      now.day,
      _bedTime!.hour,
      _bedTime!.minute,
    );
    if (scheduled.isBefore(now)) {
      scheduled = scheduled.add(const Duration(days: 1));
    }
    await _notif.zonedSchedule(
      0,
      'Time to sleep 🛌',
      'Follow your bedtime schedule for better rest.',
      scheduled,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'sleep_channel',
          'Sleep',
          importance: Importance.max,
          priority: Priority.high,
        ),
      ),
      androidAllowWhileIdle: true,
      uiLocalNotificationDateInterpretation:
      UILocalNotificationDateInterpretation.absoluteTime,
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
    await prefs.setString(
        'sleepHistory', jsonEncode(_history.map((e) => e.toJson()).toList()));

    _sleepStart = null;
    setState(() {});
  }

  Future<void> _pickBedWakeTimes() async {
    final bed = await showTimePicker(
      context: context,
      initialTime: _bedTime ?? const TimeOfDay(hour: 22, minute: 0),
    );
    if (bed == null) return;
    final wake = await showTimePicker(
      context: context,
      initialTime: _wakeTime ?? const TimeOfDay(hour: 7, minute: 0),
    );
    if (wake == null) return;
    _bedTime = bed;
    _wakeTime = wake;
    final prefs = await _prefsFuture;
    await prefs.setString('bedTime', '${bed.hour}:${bed.minute}');
    await prefs.setString('wakeTime', '${wake.hour}:${wake.minute}');
    _scheduleDailyBedtimeNotification();
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final ongoing = _sleepStart != null;
    final avgSleep = _history.isEmpty
        ? 0.0
        : _history.take(7).fold<int>(0, (sum, s) => sum + s.duration.inMinutes) /
        _history.take(7).length /
        60;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              const Color(0xFF667EEA).withOpacity(0.1),
              const Color(0xFFF8F9FA),
              const Color(0xFF764BA2).withOpacity(0.1),
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              _buildAppBar(context, size),
              Expanded(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  child: Padding(
                    padding: EdgeInsets.all(size.width * 0.05),
                    child: Column(
                      children: [
                        SizedBox(height: size.height * 0.01),
                        _buildSleepStatusCard(size, ongoing),
                        SizedBox(height: size.height * 0.03),
                        _buildStatsRow(size, avgSleep),
                        SizedBox(height: size.height * 0.03),
                        _buildScheduleCard(size),
                        SizedBox(height: size.height * 0.03),
                        _buildWeeklyChart(size),
                        SizedBox(height: size.height * 0.02),
                        _buildHistoryList(size),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAppBar(BuildContext context, Size size) {
    return Padding(
      padding: EdgeInsets.all(size.width * 0.05),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(15),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 10,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: const Icon(Icons.arrow_back_ios_new, size: 20),
            ),
          ),
          const Spacer(),
          const Text(
            'Sleep Tracker',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Color(0xFF2D3436),
            ),
          ),
          const Spacer(),
          const SizedBox(width: 44),
        ],
      ),
    );
  }

  Widget _buildSleepStatusCard(Size size, bool ongoing) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(size.width * 0.06),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF667EEA), Color(0xFF764BA2)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(25),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF667EEA).withOpacity(0.4),
            blurRadius: 25,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(
            ongoing ? Icons.bedtime : Icons.nightlight_round,
            size: 80,
            color: Colors.white,
          ),
          const SizedBox(height: 20),
          Text(
            ongoing ? 'Sleep in Progress' : 'Ready to Sleep',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          if (ongoing)
            Text(
              'Started at ${_sleepStart!.hour.toString().padLeft(2, '0')}:${_sleepStart!.minute.toString().padLeft(2, '0')}',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
              ),
            )
          else
            const Text(
              'Tap below to start tracking',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
              ),
            ),
          const SizedBox(height: 25),
          GestureDetector(
            onTap: ongoing ? _endSleep : _startSleep,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(30),
              ),
              child: Text(
                ongoing ? 'End Sleep' : 'Start Sleep',
                style: const TextStyle(
                  color: Color(0xFF667EEA),
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsRow(Size size, double avgSleep) {
    return Row(
      children: [
        Expanded(
          child: _buildStatCard(
            size,
            Icons.access_time,
            avgSleep.toStringAsFixed(1),
            'Avg Hours',
            const [Color(0xFF667EEA), Color(0xFF764BA2)],
          ),
        ),
        SizedBox(width: size.width * 0.04),
        Expanded(
          child: _buildStatCard(
            size,
            Icons.calendar_today,
            _history.length.toString(),
            'Tracked Days',
            const [Color(0xFFFF6B6B), Color(0xFFFF8E8E)],
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard(
      Size size,
      IconData icon,
      String value,
      String label,
      List<Color> gradient,
      ) {
    return Container(
      padding: EdgeInsets.all(size.width * 0.04),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: gradient[0].withOpacity(0.2),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: gradient),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: Colors.white, size: 24),
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Color(0xFF2D3436),
            ),
          ),
          Text(
            label,
            style: TextStyle(
              fontSize: 13,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScheduleCard(Size size) {
    return GestureDetector(
      onTap: _pickBedWakeTimes,
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.all(size.width * 0.05),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFF667EEA).withOpacity(0.3)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF667EEA).withOpacity(0.1),
                borderRadius: BorderRadius.circular(15),
              ),
              child: const Icon(
                Icons.schedule,
                color: Color(0xFF667EEA),
                size: 28,
              ),
            ),
            const SizedBox(width: 15),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Sleep Schedule',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF2D3436),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _bedTime == null
                        ? 'Not set - Tap to configure'
                        : 'Bed: ${_bedTime!.format(context)} • Wake: ${_wakeTime!.format(context)}',
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.edit, color: Color(0xFF667EEA)),
          ],
        ),
      ),
    );
  }

  Widget _buildWeeklyChart(Size size) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(size.width * 0.05),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Last 7 Nights',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF2D3436),
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 200,
            child: _history.isEmpty
                ? const Center(
              child: Text(
                'No sleep data yet',
                style: TextStyle(color: Colors.grey),
              ),
            )
                : BarChart(
              BarChartData(
                alignment: BarChartAlignment.spaceAround,
                maxY: 12,
                barTouchData: BarTouchData(enabled: false),
                titlesData: FlTitlesData(
                  show: true,
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        final sessions = _history.take(7).toList().reversed.toList();
                        if (value.toInt() >= sessions.length) {
                          return const SizedBox();
                        }
                        final date = sessions[value.toInt()].start;
                        return Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Text(
                            '${date.day}/${date.month}',
                            style: const TextStyle(
                              fontSize: 10,
                              color: Colors.grey,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  leftTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                ),
                gridData: const FlGridData(show: false),
                borderData: FlBorderData(show: false),
                barGroups: _history
                    .take(7)
                    .toList()
                    .reversed
                    .toList()
                    .asMap()
                    .entries
                    .map((entry) {
                  return BarChartGroupData(
                    x: entry.key,
                    barRods: [
                      BarChartRodData(
                        toY: entry.value.duration.inHours.toDouble() +
                            (entry.value.duration.inMinutes % 60) / 60,
                        gradient: const LinearGradient(
                          colors: [Color(0xFF667EEA), Color(0xFF764BA2)],
                        ),
                        width: 20,
                        borderRadius: BorderRadius.circular(6),
                      ),
                    ],
                  );
                }).toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHistoryList(Size size) {
    if (_history.isEmpty) return const SizedBox();

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(size.width * 0.05),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Recent Sleep Sessions',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF2D3436),
            ),
          ),
          const SizedBox(height: 15),
          ..._history.take(5).map((session) {
            final hours = session.duration.inHours;
            final minutes = session.duration.inMinutes.remainder(60);
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xFF667EEA).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.nightlight_round,
                      color: Color(0xFF667EEA),
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${hours}h ${minutes}m',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF2D3436),
                          ),
                        ),
                        Text(
                          '${session.start.day}/${session.start.month}/${session.start.year}',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    hours >= 7 ? '😴' : '😪',
                    style: const TextStyle(fontSize: 24),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
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