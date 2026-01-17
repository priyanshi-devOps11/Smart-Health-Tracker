import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:async';
import 'dart:convert';

class HeartRateScreen extends StatefulWidget {
  const HeartRateScreen({super.key});

  @override
  State<HeartRateScreen> createState() => _HeartRateScreenState();
}

class _HeartRateScreenState extends State<HeartRateScreen>
    with SingleTickerProviderStateMixin {
  CameraController? _controller;
  bool _isDetecting = false;
  bool _isMeasuring = false;
  List<int> _bpmHistory = [];
  int _currentBPM = 0;
  List<double> _redValues = [];
  Timer? _measurementTimer;
  int _secondsRemaining = 0;
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..repeat(reverse: true);
    _loadHistory();
  }

  @override
  void dispose() {
    _controller?.dispose();
    _measurementTimer?.cancel();
    _pulseController.dispose();
    super.dispose();
  }

  Future<void> _loadHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final historyJson = prefs.getString('bpmHistory') ?? '[]';
    setState(() {
      _bpmHistory = List<int>.from(json.decode(historyJson));
    });
  }

  Future<void> _saveHistory() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('bpmHistory', json.encode(_bpmHistory));
  }

  Future<void> _initCamera() async {
    try {
      final cameras = await availableCameras();
      final camera = cameras.firstWhere(
            (c) => c.lensDirection == CameraLensDirection.back,
        orElse: () => cameras.first,
      );

      _controller = CameraController(
        camera,
        ResolutionPreset.low,
        enableAudio: false,
        imageFormatGroup: ImageFormatGroup.yuv420,
      );

      await _controller!.initialize();
      await _controller!.setFlashMode(FlashMode.torch);

      _controller!.startImageStream((image) {
        if (!_isDetecting && _isMeasuring) {
          _isDetecting = true;
          _processImage(image);
          _isDetecting = false;
        }
      });

      setState(() {});
    } catch (e) {
      debugPrint('Camera error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Camera error: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _processImage(CameraImage image) {
    if (_redValues.length < 300) {
      // Capture for 10 seconds at 30fps
      double sum = 0;
      final plane = image.planes[0];
      for (int i = 0; i < plane.bytes.length; i++) {
        sum += plane.bytes[i];
      }
      final avg = sum / plane.bytes.length;
      _redValues.add(avg);
    }
  }

  void _startMeasurement() async {
    setState(() {
      _isMeasuring = true;
      _redValues.clear();
      _currentBPM = 0;
      _secondsRemaining = 10;
    });

    await _initCamera();

    _measurementTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        _secondsRemaining--;
      });

      if (_secondsRemaining <= 0) {
        _stopMeasurement();
      }
    });
  }

  void _stopMeasurement() {
    _measurementTimer?.cancel();
    _controller?.stopImageStream();
    _controller?.setFlashMode(FlashMode.off);
    _controller?.dispose();
    _controller = null;

    if (_redValues.length > 60) {
      final bpm = _calculateBPM(_redValues);
      setState(() {
        _currentBPM = bpm;
        _bpmHistory.insert(0, bpm);
        if (_bpmHistory.length > 10) {
          _bpmHistory.removeLast();
        }
      });
      _saveHistory();
    }

    setState(() {
      _isMeasuring = false;
      _redValues.clear();
    });
  }

  int _calculateBPM(List<double> values) {
    if (values.isEmpty) return 0;

    // Find average
    final avg = values.reduce((a, b) => a + b) / values.length;

    // Count peaks above average
    int peaks = 0;
    for (int i = 1; i < values.length - 1; i++) {
      if (values[i] > avg &&
          values[i] > values[i - 1] &&
          values[i] > values[i + 1]) {
        peaks++;
      }
    }

    // Convert to BPM (assuming 30 fps, 10 seconds)
    final bpm = (peaks * 60 / (values.length / 30)).round();
    return bpm.clamp(40, 200); // Reasonable heart rate range
  }

  String _getHeartRateStatus(int bpm) {
    if (bpm == 0) return 'Not measured';
    if (bpm < 60) return 'Low';
    if (bpm > 100) return 'High';
    return 'Normal';
  }

  Color _getStatusColor(int bpm) {
    if (bpm == 0) return Colors.grey;
    if (bpm < 60) return const Color(0xFF42A5F5);
    if (bpm > 100) return const Color(0xFFEF5350);
    return const Color(0xFF66BB6A);
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              const Color(0xFFEF5350).withOpacity(0.1),
              const Color(0xFFF8F9FA),
              const Color(0xFFE53935).withOpacity(0.1),
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
                        if (_isMeasuring)
                          _buildMeasurementCard(size)
                        else
                          _buildHeartCard(size),
                        SizedBox(height: size.height * 0.03),
                        _buildActionButton(size),
                        SizedBox(height: size.height * 0.03),
                        if (_currentBPM > 0) _buildStatsCards(size),
                        if (_currentBPM > 0)
                          SizedBox(height: size.height * 0.03),
                        if (_bpmHistory.isNotEmpty) _buildHistoryChart(size),
                        if (_bpmHistory.isNotEmpty)
                          SizedBox(height: size.height * 0.03),
                        _buildInstructionsCard(size),
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
            'Heart Rate',
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

  Widget _buildHeartCard(Size size) {
    return AnimatedBuilder(
      animation: _pulseController,
      builder: (context, child) {
        return Transform.scale(
          scale: _currentBPM > 0 ? 1.0 + (_pulseController.value * 0.05) : 1.0,
          child: Container(
            width: size.width * 0.7,
            height: size.width * 0.7,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: _getStatusColor(_currentBPM).withOpacity(0.3),
                  blurRadius: 30,
                  offset: const Offset(0, 15),
                ),
              ],
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.favorite,
                  size: 80,
                  color: _getStatusColor(_currentBPM),
                ),
                const SizedBox(height: 20),
                Text(
                  _currentBPM > 0 ? '$_currentBPM' : '--',
                  style: TextStyle(
                    fontSize: 64,
                    fontWeight: FontWeight.bold,
                    color: _getStatusColor(_currentBPM),
                  ),
                ),
                Text(
                  'BPM',
                  style: TextStyle(
                    fontSize: 18,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 12),
                Container(
                  padding:
                  const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                  decoration: BoxDecoration(
                    color: _getStatusColor(_currentBPM).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    _getHeartRateStatus(_currentBPM),
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: _getStatusColor(_currentBPM),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildMeasurementCard(Size size) {
    return Container(
      width: size.width * 0.85,
      padding: EdgeInsets.all(size.width * 0.06),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFEF5350), Color(0xFFE53935)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(25),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFEF5350).withOpacity(0.4),
            blurRadius: 25,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        children: [
          if (_controller != null && _controller!.value.isInitialized)
            ClipRRect(
              borderRadius: BorderRadius.circular(15),
              child: SizedBox(
                height: size.width * 0.4,
                width: double.infinity,
                child: CameraPreview(_controller!),
              ),
            )
          else
            Container(
              height: size.width * 0.4,
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(15),
              ),
              child: const Center(
                child: CircularProgressIndicator(color: Colors.white),
              ),
            ),
          const SizedBox(height: 20),
          const Text(
            'Place finger on camera',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Measuring... $_secondsRemaining seconds',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 15),
          LinearProgressIndicator(
            value: 1 - (_secondsRemaining / 10),
            backgroundColor: Colors.white.withOpacity(0.3),
            valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
            borderRadius: BorderRadius.circular(10),
            minHeight: 8,
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton(Size size) {
    return GestureDetector(
      onTap: _isMeasuring ? _stopMeasurement : _startMeasurement,
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.symmetric(vertical: size.height * 0.025),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: _isMeasuring
                ? [Colors.grey, Colors.grey.shade600]
                : [const Color(0xFFEF5350), const Color(0xFFE53935)],
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: (_isMeasuring ? Colors.grey : const Color(0xFFEF5350))
                  .withOpacity(0.4),
              blurRadius: 15,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              _isMeasuring ? Icons.stop : Icons.play_arrow,
              color: Colors.white,
              size: 28,
            ),
            const SizedBox(width: 12),
            Text(
              _isMeasuring ? 'Stop Measurement' : 'Start Measurement',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsCards(Size size) {
    final avg = _bpmHistory.isEmpty
        ? _currentBPM
        : (_bpmHistory.reduce((a, b) => a + b) / _bpmHistory.length).round();

    return Row(
      children: [
        Expanded(
          child: _buildStatCard(
            size,
            Icons.show_chart,
            '$avg',
            'Average',
            const [Color(0xFF42A5F5), Color(0xFF1E88E5)],
          ),
        ),
        SizedBox(width: size.width * 0.04),
        Expanded(
          child: _buildStatCard(
            size,
            Icons.history,
            '${_bpmHistory.length}',
            'Records',
            const [Color(0xFF66BB6A), Color(0xFF43A047)],
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

  Widget _buildHistoryChart(Size size) {
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
            'Recent Measurements',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF2D3436),
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 200,
            child: LineChart(
              LineChartData(
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: 20,
                  getDrawingHorizontalLine: (value) {
                    return FlLine(
                      color: Colors.grey.shade200,
                      strokeWidth: 1,
                    );
                  },
                ),
                titlesData: FlTitlesData(
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 40,
                      getTitlesWidget: (value, meta) {
                        return Text(
                          value.toInt().toString(),
                          style: const TextStyle(
                            fontSize: 10,
                            color: Colors.grey,
                          ),
                        );
                      },
                    ),
                  ),
                  bottomTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                ),
                borderData: FlBorderData(show: false),
                minY: 40,
                maxY: 120,
                lineBarsData: [
                  LineChartBarData(
                    spots: _bpmHistory
                        .take(10)
                        .toList()
                        .reversed
                        .toList()
                        .asMap()
                        .entries
                        .map((e) =>
                        FlSpot(e.key.toDouble(), e.value.toDouble()))
                        .toList(),
                    isCurved: true,
                    gradient: const LinearGradient(
                      colors: [Color(0xFFEF5350), Color(0xFFE53935)],
                    ),
                    barWidth: 3,
                    dotData: const FlDotData(show: true),
                    belowBarData: BarAreaData(
                      show: true,
                      gradient: LinearGradient(
                        colors: [
                          const Color(0xFFEF5350).withOpacity(0.3),
                          const Color(0xFFEF5350).withOpacity(0.0),
                        ],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInstructionsCard(Size size) {
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
              Icon(Icons.info_outline, color: Color(0xFFEF5350)),
              SizedBox(width: 10),
              Text(
                'How to Measure',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF2D3436),
                ),
              ),
            ],
          ),
          const SizedBox(height: 15),
          _buildInstructionItem('Place fingertip over rear camera'),
          _buildInstructionItem('Cover the camera completely'),
          _buildInstructionItem('Stay still during measurement'),
          _buildInstructionItem('Keep finger relaxed, not pressed hard'),
        ],
      ),
    );
  }

  Widget _buildInstructionItem(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: const BoxDecoration(
              color: Color(0xFFEF5350),
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