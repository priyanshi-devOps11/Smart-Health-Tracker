import 'package:flutter/material.dart';
import 'dart:math' as math;

class BmiScreen extends StatefulWidget {
  const BmiScreen({super.key});

  @override
  State<BmiScreen> createState() => _BmiScreenState();
}

class _BmiScreenState extends State<BmiScreen> with TickerProviderStateMixin {
  final TextEditingController _heightController = TextEditingController();
  final TextEditingController _weightController = TextEditingController();

  double? _bmi;
  String _bmiCategory = '';
  Color _categoryColor = const Color(0xFF6C63FF);
  late AnimationController _scaleController;
  late AnimationController _fadeController;

  @override
  void initState() {
    super.initState();
    _scaleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
  }

  @override
  void dispose() {
    _heightController.dispose();
    _weightController.dispose();
    _scaleController.dispose();
    _fadeController.dispose();
    super.dispose();
  }

  void _calculateBMI() {
    final double? height = double.tryParse(_heightController.text);
    final double? weight = double.tryParse(_weightController.text);

    if (height == null || weight == null || height <= 0 || weight <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter valid numbers'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final double heightInMeters = height / 100;
    final double bmi = weight / (heightInMeters * heightInMeters);

    String category;
    Color color;

    if (bmi < 18.5) {
      category = 'Underweight';
      color = const Color(0xFF42A5F5);
    } else if (bmi < 24.9) {
      category = 'Normal';
      color = const Color(0xFF66BB6A);
    } else if (bmi < 29.9) {
      category = 'Overweight';
      color = const Color(0xFFFFA726);
    } else {
      category = 'Obese';
      color = const Color(0xFFEF5350);
    }

    setState(() {
      _bmi = bmi;
      _bmiCategory = category;
      _categoryColor = color;
    });

    _scaleController.forward(from: 0);
    _fadeController.forward(from: 0);
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
              const Color(0xFFF093FB).withOpacity(0.1),
              const Color(0xFFF8F9FA),
              const Color(0xFFF5576C).withOpacity(0.1),
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
                        _buildInputCard(size),
                        SizedBox(height: size.height * 0.03),
                        _buildCalculateButton(size),
                        if (_bmi != null) ...[
                          SizedBox(height: size.height * 0.04),
                          _buildResultCard(size),
                          SizedBox(height: size.height * 0.03),
                          _buildBMIScale(size),
                          SizedBox(height: size.height * 0.03),
                          _buildHealthTips(size),
                        ],
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
            'BMI Calculator',
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

  Widget _buildInputCard(Size size) {
    return Container(
      padding: EdgeInsets.all(size.width * 0.05),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(25),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Enter Your Details',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Color(0xFF2D3436),
            ),
          ),
          const SizedBox(height: 25),
          _buildInputField(
            controller: _heightController,
            label: 'Height',
            unit: 'cm',
            icon: Icons.height,
            gradient: const [Color(0xFFF093FB), Color(0xFFF5576C)],
          ),
          const SizedBox(height: 20),
          _buildInputField(
            controller: _weightController,
            label: 'Weight',
            unit: 'kg',
            icon: Icons.monitor_weight,
            gradient: const [Color(0xFF667EEA), Color(0xFF764BA2)],
          ),
        ],
      ),
    );
  }

  Widget _buildInputField({
    required TextEditingController controller,
    required String label,
    required String unit,
    required IconData icon,
    required List<Color> gradient,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: gradient),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: Colors.white, size: 20),
            ),
            const SizedBox(width: 10),
            Text(
              label,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Color(0xFF2D3436),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Container(
          decoration: BoxDecoration(
            color: Colors.grey.shade50,
            borderRadius: BorderRadius.circular(15),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: TextField(
            controller: controller,
            keyboardType: TextInputType.number,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF2D3436),
            ),
            decoration: InputDecoration(
              hintText: 'Enter $label',
              suffixText: unit,
              suffixStyle: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 20,
                vertical: 16,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCalculateButton(Size size) {
    return GestureDetector(
      onTap: _calculateBMI,
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.symmetric(vertical: size.height * 0.025),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFFF093FB), Color(0xFFF5576C)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFFF093FB).withOpacity(0.4),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.calculate, color: Colors.white, size: 28),
            SizedBox(width: 12),
            Text(
              'Calculate BMI',
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResultCard(Size size) {
    return ScaleTransition(
      scale: CurvedAnimation(
        parent: _scaleController,
        curve: Curves.elasticOut,
      ),
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.all(size.width * 0.06),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [_categoryColor, _categoryColor.withOpacity(0.7)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(25),
          boxShadow: [
            BoxShadow(
              color: _categoryColor.withOpacity(0.4),
              blurRadius: 25,
              offset: const Offset(0, 12),
            ),
          ],
        ),
        child: Column(
          children: [
            const Text(
              'Your BMI',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              _bmi!.toStringAsFixed(1),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 64,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.3),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                _bmiCategory,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBMIScale(Size size) {
    return FadeTransition(
      opacity: _fadeController,
      child: Container(
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
              'BMI Scale',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF2D3436),
              ),
            ),
            const SizedBox(height: 20),
            _buildScaleItem('< 18.5', 'Underweight', const Color(0xFF42A5F5)),
            _buildScaleItem('18.5 - 24.9', 'Normal', const Color(0xFF66BB6A)),
            _buildScaleItem('25.0 - 29.9', 'Overweight', const Color(0xFFFFA726)),
            _buildScaleItem('≥ 30.0', 'Obese', const Color(0xFFEF5350)),
          ],
        ),
      ),
    );
  }

  Widget _buildScaleItem(String range, String label, Color color) {
    final isActive = label == _bmiCategory;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isActive ? color.withOpacity(0.1) : Colors.transparent,
          borderRadius: BorderRadius.circular(15),
          border: Border.all(
            color: isActive ? color : Colors.grey.shade200,
            width: isActive ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: isActive ? FontWeight.bold : FontWeight.w500,
                  color: isActive ? color : const Color(0xFF2D3436),
                ),
              ),
            ),
            Text(
              range,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHealthTips(Size size) {
    final tips = _getHealthTips();

    return FadeTransition(
      opacity: _fadeController,
      child: Container(
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
            Row(
              children: [
                Icon(Icons.lightbulb_outline, color: _categoryColor),
                const SizedBox(width: 10),
                const Text(
                  'Health Tips',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF2D3436),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 15),
            ...tips.map((tip) => _buildTipItem(tip)),
          ],
        ),
      ),
    );
  }

  Widget _buildTipItem(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            margin: const EdgeInsets.only(top: 6),
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: _categoryColor,
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
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }

  List<String> _getHealthTips() {
    if (_bmi == null) return [];

    if (_bmi! < 18.5) {
      return [
        'Increase calorie intake with nutrient-rich foods',
        'Add healthy fats like nuts and avocados',
        'Eat smaller, frequent meals throughout the day',
        'Consult a nutritionist for personalized advice',
      ];
    } else if (_bmi! < 24.9) {
      return [
        'Maintain a balanced diet with variety',
        'Stay active with regular exercise',
        'Aim for 7-9 hours of quality sleep',
        'Keep up the great work!',
      ];
    } else if (_bmi! < 29.9) {
      return [
        'Focus on portion control',
        'Increase physical activity gradually',
        'Choose whole grains over refined carbs',
        'Stay hydrated throughout the day',
      ];
    } else {
      return [
        'Consult a healthcare professional',
        'Start with light exercises like walking',
        'Reduce processed and sugary foods',
        'Track your food intake and progress',
      ];
    }
  }
}