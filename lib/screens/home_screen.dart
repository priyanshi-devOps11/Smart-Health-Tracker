import 'package:flutter/material.dart';
import 'step_tracker_screen.dart';
import 'water_tracker_screen.dart';
import 'heart_rate_screen.dart';
import 'sleep_tracker_screen.dart';
import 'bmi_screen.dart'; // ✅ Add this import

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Smart Health Tracker')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: GridView.count(
          crossAxisCount: 2,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          children: [
            buildCard(context, "👣\nStep Tracker", const StepTrackerScreen()),
            buildCard(context, "💧\nWater Tracker", const WaterTrackerScreen()),
            buildCard(context, "❤️\nHeart Rate", const HeartRateScreen()),
            buildCard(context, "😴\nSleep Tracker", const SleepTrackerScreen()),
            buildCard(context, "📊\nBMI Calculator", const BmiScreen()), // ✅ New!
          ],
        ),
      ),
    );
  }

  Widget buildCard(BuildContext context, String title, Widget screen) {
    return GestureDetector(
      onTap: () {
        Navigator.push(context, MaterialPageRoute(builder: (_) => screen));
      },
      child: Card(
        elevation: 6,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
          ),
        ),
      ),
    );
  }
}

