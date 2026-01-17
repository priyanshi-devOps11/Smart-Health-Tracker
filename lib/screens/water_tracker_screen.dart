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

class _WaterTrackerScreenState extends State<WaterTrackerScreen>
    with SingleTickerProviderStateMixin {
  int _waterCount = 0;
  List<Map<String, dynamic>> _history = [];
  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
  FlutterLocalNotificationsPlugin();
  final int _dailyGoal = 8;
  late AnimationController _waveController;

  @override
  void initState() {
    super.initState();
    _waveController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();
    _initializeNotifications();
    _loadWaterData();
    tz.initializeTimeZones();
  }

  @override
  void dispose() {
    _waveController.dispose();
    super.dispose();
  }

  Future<void> _initializeNotifications() async {
    const AndroidInitializationSettings initializationSettingsAndroid =
    AndroidInitializationSettings('@mipmap/ic_launcher');

    const InitializationSettings initializationSettings =
    InitializationSettings(
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
      final todayStr = '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';

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

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final progress = (_waterCount / _dailyGoal).clamp(0.0, 1.0);

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              const Color(0xFF4ECDC4).withOpacity(0.1),
              const Color(0xFFF8F9FA),
              const Color(0xFF44A08D).withOpacity(0.1),
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
                        SizedBox(height: size.height * 0.02),
                        _buildWaterBottle(size, progress),
                        SizedBox(height: size.height * 0.04),
                        _buildActionButtons(size),
                        SizedBox(height: size.height * 0.03),
                        _buildStatsCard(size),
                        SizedBox(height: size.height * 0.03),
                        _buildWeeklyChart(size),
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
            'Water Tracker',
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

  Widget _buildWaterBottle(Size size, double progress) {
    return Container(
      width: size.width * 0.5,
      height: size.width * 0.85,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF4ECDC4).withOpacity(0.3),
            blurRadius: 30,
            offset: const Offset(0, 15),
          ),
        ],
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(30),
            child: AnimatedBuilder(
              animation: _waveController,
              builder: (context, child) {
                return CustomPaint(
                  size: Size(size.width * 0.5, size.width * 0.85),
                  painter: WaterWavePainter(
                    progress: progress,
                    wavePhase: _waveController.value,
                  ),
                );
              },
            ),
          ),
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.water_drop,
                size: 60,
                color: Colors.white,
              ),
              const SizedBox(height: 10),
              Text(
                '$_waterCount',
                style: const TextStyle(
                  fontSize: 56,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              Text(
                'of $_dailyGoal glasses',
                style: const TextStyle(
                  fontSize: 16,
                  color: Colors.white,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(Size size) {
    return Row(
      children: [
        Expanded(
          flex: 2,
          child: GestureDetector(
            onTap: _logWater,
            child: Container(
              padding: EdgeInsets.symmetric(vertical: size.height * 0.025),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF4ECDC4), Color(0xFF44A08D)],
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF4ECDC4).withOpacity(0.4),
                    blurRadius: 15,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.add_circle_outline, color: Colors.white, size: 28),
                  SizedBox(width: 10),
                  Text(
                    'Log Water',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        SizedBox(width: size.width * 0.03),
        GestureDetector(
          onTap: _resetWaterData,
          child: Container(
            padding: EdgeInsets.all(size.height * 0.022),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: const Icon(
              Icons.refresh,
              color: Color(0xFF4ECDC4),
              size: 28,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStatsCard(Size size) {
    final percentage = ((_waterCount / _dailyGoal) * 100).toStringAsFixed(0);
    final remaining = _dailyGoal - _waterCount;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(size.width * 0.05),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF4ECDC4), Color(0xFF44A08D)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF4ECDC4).withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildStatItem(size, percentage, '% Goal', Icons.track_changes),
          Container(width: 1, height: 50, color: Colors.white.withOpacity(0.3)),
          _buildStatItem(
            size,
            remaining > 0 ? '$remaining' : '0',
            'Remaining',
            Icons.schedule,
          ),
          Container(width: 1, height: 50, color: Colors.white.withOpacity(0.3)),
          _buildStatItem(size, '2L', 'Target', Icons.local_drink),
        ],
      ),
    );
  }

  Widget _buildStatItem(Size size, String value, String label, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: Colors.white, size: 24),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 12,
          ),
        ),
      ],
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
            'Past Week',
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
                'No data yet',
                style: TextStyle(color: Colors.grey),
              ),
            )
                : BarChart(
              BarChartData(
                alignment: BarChartAlignment.spaceAround,
                maxY: _dailyGoal.toDouble() + 2,
                barTouchData: BarTouchData(enabled: false),
                titlesData: FlTitlesData(
                  show: true,
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        if (value.toInt() >= _history.length) {
                          return const SizedBox();
                        }
                        try {
                          final dateStr = _history[value.toInt()]['date'] as String;
                          final date = DateTime.parse(dateStr);
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
                        } catch (e) {
                          return const SizedBox();
                        }
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
                barGroups: _history.asMap().entries.map((entry) {
                  final index = entry.key;
                  final data = entry.value;
                  return BarChartGroupData(
                    x: index,
                    barRods: [
                      BarChartRodData(
                        toY: data['count'].toDouble(),
                        gradient: const LinearGradient(
                          colors: [Color(0xFF4ECDC4), Color(0xFF44A08D)],
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
}

class WaterWavePainter extends CustomPainter {
  final double progress;
  final double wavePhase;

  WaterWavePainter({required this.progress, required this.wavePhase});

  @override
  void paint(Canvas canvas, Size size) {
    final waterHeight = size.height * (1 - progress);

    final paint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          const Color(0xFF4ECDC4).withOpacity(0.8),
          const Color(0xFF44A08D),
        ],
      ).createShader(Rect.fromLTWH(0, waterHeight, size.width, size.height));

    final path = Path();
    path.moveTo(0, size.height);
    path.lineTo(0, waterHeight);

    // Create wave effect
    for (double i = 0; i <= size.width; i++) {
      final waveY = waterHeight +
          10 * (i / size.width) * (1 - i / size.width) *
              (1 + 0.5 * (1 - progress)) *
              (1 + 0.5 * (i / size.width - wavePhase).abs());
      path.lineTo(i, waveY);
    }

    path.lineTo(size.width, size.height);
    path.close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}