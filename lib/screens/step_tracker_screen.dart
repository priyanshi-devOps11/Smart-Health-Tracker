import 'package:flutter/material.dart';
import 'package:pedometer/pedometer.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:math' as math;

class StepTrackerScreen extends StatefulWidget {
  const StepTrackerScreen({super.key});

  @override
  State<StepTrackerScreen> createState() => _StepTrackerScreenState();
}

class _StepTrackerScreenState extends State<StepTrackerScreen>
    with SingleTickerProviderStateMixin {
  int _steps = 0;
  Stream<StepCount>? _stepCountStream;
  late AnimationController _controller;
  final int _dailyGoal = 10000;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat();
    requestPermissionAndStartTracking();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> requestPermissionAndStartTracking() async {
    var status = await Permission.activityRecognition.request();
    if (status.isGranted) {
      startStepCountStream();
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Permission denied. Please enable in settings.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void startStepCountStream() {
    _stepCountStream = Pedometer.stepCountStream;
    _stepCountStream?.listen(
          (StepCount event) {
        setState(() {
          _steps = event.steps;
        });
      },
      onError: (error) {
        debugPrint("Step Count Error: $error");
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final progress = (_steps / _dailyGoal).clamp(0.0, 1.0);
    final calories = (_steps * 0.04).toStringAsFixed(0);
    final distance = (_steps * 0.0008).toStringAsFixed(2);

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              const Color(0xFFFF6B6B).withOpacity(0.1),
              const Color(0xFFF8F9FA),
              const Color(0xFFFF8E8E).withOpacity(0.1),
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
                        _buildCircularProgress(size, progress),
                        SizedBox(height: size.height * 0.04),
                        _buildStatsCards(size, calories, distance),
                        SizedBox(height: size.height * 0.03),
                        _buildGoalCard(size),
                        SizedBox(height: size.height * 0.03),
                        _buildTipsCard(size),
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
            'Step Tracker',
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

  Widget _buildCircularProgress(Size size, double progress) {
    return Container(
      width: size.width * 0.7,
      height: size.width * 0.7,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFFF6B6B).withOpacity(0.3),
            blurRadius: 30,
            offset: const Offset(0, 15),
          ),
        ],
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          AnimatedBuilder(
            animation: _controller,
            builder: (context, child) {
              return CustomPaint(
                size: Size(size.width * 0.65, size.width * 0.65),
                painter: CircularProgressPainter(
                  progress: progress,
                  animationValue: _controller.value,
                ),
              );
            },
          ),
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.directions_walk,
                size: 50,
                color: Color(0xFFFF6B6B),
              ),
              const SizedBox(height: 10),
              Text(
                '$_steps',
                style: const TextStyle(
                  fontSize: 48,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF2D3436),
                ),
              ),
              Text(
                'of $_dailyGoal steps',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(height: 10),
              Text(
                '${(progress * 100).toStringAsFixed(0)}% Complete',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFFFF6B6B),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatsCards(Size size, String calories, String distance) {
    return Row(
      children: [
        Expanded(
          child: _buildStatCard(
            size,
            Icons.local_fire_department,
            calories,
            'Calories',
            const [Color(0xFFFFA726), Color(0xFFFF7043)],
          ),
        ),
        SizedBox(width: size.width * 0.04),
        Expanded(
          child: _buildStatCard(
            size,
            Icons.route,
            distance,
            'Km',
            const [Color(0xFF42A5F5), Color(0xFF1E88E5)],
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
            padding: const EdgeInsets.all(10),
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

  Widget _buildGoalCard(Size size) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(size.width * 0.05),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFFF6B6B), Color(0xFFFF8E8E)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFFF6B6B).withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        children: [
          const Icon(Icons.emoji_events, color: Colors.white, size: 40),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Daily Goal',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _steps >= _dailyGoal
                      ? '🎉 Goal Achieved!'
                      : '${_dailyGoal - _steps} steps to go',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTipsCard(Size size) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(size.width * 0.05),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.lightbulb_outline, color: Color(0xFFFF6B6B)),
              SizedBox(width: 10),
              Text(
                'Daily Tips',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF2D3436),
                ),
              ),
            ],
          ),
          const SizedBox(height: 15),
          _buildTipItem('Take stairs instead of elevator'),
          _buildTipItem('Walk during phone calls'),
          _buildTipItem('Park farther from your destination'),
        ],
      ),
    );
  }

  Widget _buildTipItem(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: const BoxDecoration(
              color: Color(0xFFFF6B6B),
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[700],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class CircularProgressPainter extends CustomPainter {
  final double progress;
  final double animationValue;

  CircularProgressPainter({
    required this.progress,
    required this.animationValue,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    // Background circle
    final bgPaint = Paint()
      ..color = Colors.grey.shade200
      ..strokeWidth = 12
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    canvas.drawCircle(center, radius, bgPaint);

    // Progress circle
    final progressPaint = Paint()
      ..shader = const LinearGradient(
        colors: [Color(0xFFFF6B6B), Color(0xFFFF8E8E)],
      ).createShader(Rect.fromCircle(center: center, radius: radius))
      ..strokeWidth = 12
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2,
      2 * math.pi * progress,
      false,
      progressPaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}