import 'package:flutter/material.dart';
import 'step_tracker_screen.dart';
import 'water_tracker_screen.dart';
import 'heart_rate_screen.dart';
import 'sleep_tracker_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Smart Health Tracker')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          buildCard(context, "👣 Step Tracker", const StepTrackerScreen()),
          buildCard(context, "💧 Water Tracker", const WaterTrackerScreen()),
          buildCard(context, "❤️ Heart Rate", const HeartRateScreen()),
          buildCard(context, "😴 Sleep Tracker", const SleepTrackerScreen()),
        ],
      ),
    );
  }

  Widget buildCard(BuildContext context, String title, Widget screen) {
    return Card(
      elevation: 4,
      margin: const EdgeInsets.symmetric(vertical: 10),
      child: ListTile(
        title: Text(title, style: const TextStyle(fontSize: 18)),
        trailing: const Icon(Icons.arrow_forward_ios),
        onTap: () {
          Navigator.push(context, MaterialPageRoute(builder: (_) => screen));
        },
      ),
    );
  }
}
