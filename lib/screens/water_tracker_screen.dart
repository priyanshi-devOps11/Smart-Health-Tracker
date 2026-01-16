import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:fl_chart/fl_chart.dart';

class WaterTrackerScreen extends StatefulWidget {
  const WaterTrackerScreen({super.key});

  @override
  State<WaterTrackerScreen> createState() => _WaterTrackerScreenState();
}

class _WaterTrackerScreenState extends State<WaterTrackerScreen> {
  int _waterCount = 0;
  final int _dailyGoal = 8;
  List<Map<String, dynamic>> _history = [];

  @override
  void initState() {
    super.initState();
    _loadWaterData();
  }

  Future<void> _loadWaterData() async {
    final prefs = await SharedPreferences.getInstance();
    final historyJson = prefs.getString('waterHistory') ?? '[]';

    setState(() {
      _waterCount = prefs.getInt('waterCount') ?? 0;
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
      final todayKey =
          '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';

      final index = _history.indexWhere((e) => e['date'] == todayKey);
      if (index != -1) {
        _history[index]['count'] += 1;
      } else {
        _history.add({'date': todayKey, 'count': 1});
      }

      if (_history.length > 7) {
        _history.removeAt(0);
      }
    });

    _saveWaterData();
  }

  void _resetWater() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() => _waterCount = 0);
    await prefs.setInt('waterCount', 0);
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final progress = (_waterCount / _dailyGoal).clamp(0.0, 1.0);

    return Scaffold(
      backgroundColor: const Color(0xFFF6F9F8),
      appBar: AppBar(
        title: const Text('Water Tracker'),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(size.width * 0.05),
        child: Column(
          children: [
            _buildBottle(progress),
            const SizedBox(height: 30),
            _buildButtons(),
            const SizedBox(height: 30),
            _buildWeeklyChart(),
          ],
        ),
      ),
    );
  }

  // 🧴 SIMPLE WATER BOTTLE (NO COLOR BEFORE FILL)
  Widget _buildBottle(double progress) {
    return Container(
      height: 300,
      width: 180,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 15,
          ),
        ],
      ),
      child: Stack(
        alignment: Alignment.bottomCenter,
        children: [
          // Water Fill
          FractionallySizedBox(
            heightFactor: progress,
            child: Container(
              decoration: const BoxDecoration(
                color: Color(0xFF4ECDC4),
                borderRadius: BorderRadius.vertical(
                  bottom: Radius.circular(30),
                ),
              ),
            ),
          ),

          // Text
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.water_drop, size: 48, color: Colors.teal),
              const SizedBox(height: 10),
              Text(
                '$_waterCount',
                style: const TextStyle(
                  fontSize: 48,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                'of $_dailyGoal glasses',
                style: const TextStyle(color: Colors.grey),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ➕ BUTTONS
  Widget _buildButtons() {
    return Row(
      children: [
        Expanded(
          child: ElevatedButton.icon(
            onPressed: _logWater,
            icon: const Icon(Icons.add),
            label: const Text('Log Water'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF4ECDC4),
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        IconButton(
          onPressed: _resetWater,
          icon: const Icon(Icons.refresh),
        ),
      ],
    );
  }

  // 📊 WEEKLY CHART (DATE SAFE)
  Widget _buildWeeklyChart() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Past Week',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 200,
            child: _history.isEmpty
                ? const Center(child: Text('No data'))
                : BarChart(
              BarChartData(
                maxY: _dailyGoal.toDouble(),
                barGroups: _history.asMap().entries.map((e) {
                  return BarChartGroupData(
                    x: e.key,
                    barRods: [
                      BarChartRodData(
                        toY: e.value['count'].toDouble(),
                        color: const Color(0xFF4ECDC4),
                        width: 18,
                        borderRadius: BorderRadius.circular(6),
                      ),
                    ],
                  );
                }).toList(),
                titlesData: FlTitlesData(
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        if (value.toInt() >= _history.length) {
                          return const SizedBox();
                        }
                        final date =
                        DateTime.tryParse(_history[value.toInt()]['date']);
                        return Text(
                          date == null
                              ? ''
                              : '${date.day}/${date.month}',
                          style: const TextStyle(fontSize: 10),
                        );
                      },
                    ),
                  ),
                  leftTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                ),
                gridData: const FlGridData(show: false),
                borderData: FlBorderData(show: false),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
