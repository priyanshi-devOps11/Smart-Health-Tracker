import 'package:flutter/material.dart';
import 'package:pedometer/pedometer.dart';
import 'package:permission_handler/permission_handler.dart';

class StepTrackerScreen extends StatefulWidget {
  const StepTrackerScreen({super.key});

  @override
  State<StepTrackerScreen> createState() => _StepTrackerScreenState();
}

class _StepTrackerScreenState extends State<StepTrackerScreen> {
  int _steps = 0;
  Stream<StepCount>? _stepCountStream;

  @override
  void initState() {
    super.initState();
    requestPermissionAndStartTracking();
  }

  Future<void> requestPermissionAndStartTracking() async {
    var status = await Permission.activityRecognition.request();
    if (status.isGranted) {
      startStepCountStream();
    } else {
      // You can show dialog or snackbar
      print("Permission denied.");
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
        print("Step Count Error: $error");
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Step Tracker')),
      body: Center(
        child: Text(
          'Steps Taken Today: $_steps',
          style: const TextStyle(fontSize: 24),
        ),
      ),
    );
  }
}
