import 'dart:async';
import 'dart:math';
import 'dart:typed_data';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:tflite_flutter/tflite_flutter.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class HeartRateScreen extends StatefulWidget {
  const HeartRateScreen({super.key});

  @override
  State<HeartRateScreen> createState() => _HeartRateScreenState();
}

class _HeartRateScreenState extends State<HeartRateScreen> {
  CameraController? _controller;
  bool _isDetecting = false;
  List<int> _bpmHistory = [];
  int _currentBPM = 0;
  List<double> _redAvgBuffer = [];
  Interpreter? _interpreter;

  @override
  void initState() {
    super.initState();
    _initCamera();
    _loadModel();
    Firebase.initializeApp();
  }

  Future<void> _loadModel() async {
    try {
      _interpreter = await Interpreter.fromAsset('skin_classifier.tflite');
    } catch (e) {
      print('Model load failed: $e');
    }
  }

  Future<void> _initCamera() async {
    final cameras = await availableCameras();
    final backCamera = cameras.firstWhere((c) => c.lensDirection == CameraLensDirection.back);
    _controller = CameraController(backCamera, ResolutionPreset.low, enableAudio: false);
    await _controller!.initialize();
    _controller!.setFlashMode(FlashMode.torch);

    _controller!.startImageStream((CameraImage image) async {
      if (_isDetecting) return;
      _isDetecting = true;

      final redAvg = _calculateRedAverage(image.planes[0].bytes);
      if (_isSkin(redAvg)) {
        _redAvgBuffer.add(redAvg);
        if (_redAvgBuffer.length >= 60) {
          final bpm = _calculateBPM(_redAvgBuffer);
          setState(() {
            _currentBPM = bpm;
            _bpmHistory.add(bpm);
            if (_bpmHistory.length > 7) _bpmHistory.removeAt(0);
          });
          _uploadToFirebase(bpm);
          _redAvgBuffer.clear();
        }
      }

      _isDetecting = false;
    });
  }

  double _calculateRedAverage(Uint8List bytes) {
    double total = 0;
    for (int i = 0; i < bytes.length; i += 4) {
      total += bytes[i].toDouble(); // R channel
    }
    return total / (bytes.length / 4);
  }

  bool _isSkin(double redAvg) {
    // Simple rule or ML classifier check
    if (_interpreter != null) {
      final input = Float32List.fromList([redAvg]);
      final output = Float32List(1);
      _interpreter!.run(input, output);
      return output[0] > 0.7;
    } else {
      return redAvg > 100;
    }
  }

  int _calculateBPM(List<double> values) {
    // Simple peak detection
    int peaks = 0;
    for (int i = 1; i < values.length - 1; i++) {
      if (values[i] > values[i - 1] && values[i] > values[i + 1]) {
        peaks++;
      }
    }
    return peaks * 6; // 60 samples = 6 seconds
  }

  Future<void> _uploadToFirebase(int bpm) async {
    await FirebaseFirestore.instance.collection('heart_rate').add({
      'bpm': bpm,
      'timestamp': DateTime.now(),
    });
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Heart Rate Monitor")),
      body: _controller == null || !_controller!.value.isInitialized
          ? const Center(child: CircularProgressIndicator())
          : Column(
        children: [
          SizedBox(
            height: 200,
            width: double.infinity,
            child: CameraPreview(_controller!),
          ),
          const SizedBox(height: 20),
          Text("BPM: $_currentBPM", style: const TextStyle(fontSize: 32)),
          const SizedBox(height: 30),
          const Text("Weekly BPM Chart"),
          SizedBox(
            height: 200,
            child: LineChart(
              LineChartData(
                borderData: FlBorderData(show: false),
                titlesData: FlTitlesData(show: true),
                lineBarsData: [
                  LineChartBarData(
                    spots: _bpmHistory
                        .asMap()
                        .entries
                        .map((e) => FlSpot(e.key.toDouble(), e.value.toDouble()))
                        .toList(),
                    isCurved: true,
                    color: Colors.red,
                    barWidth: 3,
                    dotData: FlDotData(show: true),
                  )
                ],
              ),
            ),
          )
        ],
      ),
    );
  }
}
