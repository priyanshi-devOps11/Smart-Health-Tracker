import 'package:flutter/material.dart';
import 'step_tracker_screen.dart';
import 'water_tracker_screen.dart' as water;
import 'sleep_tracker_screen.dart' as sleep;
import 'bmi_screen.dart';
import 'heart_rate_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final padding = MediaQuery.of(context).padding;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              const Color(0xFF6C63FF).withOpacity(0.1),
              const Color(0xFFF8F9FA),
              const Color(0xFF00D2FF).withOpacity(0.1),
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              _buildHeader(context, size),
              Expanded(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  child: Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: size.width * 0.05,
                      vertical: size.height * 0.02,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildWelcomeCard(context, size),
                        SizedBox(height: size.height * 0.03),
                        _buildTrackerGrid(context, size),
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

  Widget _buildHeader(BuildContext context, Size size) {
    return Container(
      padding: EdgeInsets.all(size.width * 0.05),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Smart Health',
                style: TextStyle(
                  fontSize: size.width * 0.07,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF2D3436),
                ),
              ),
              Text(
                'Track your wellness journey',
                style: TextStyle(
                  fontSize: size.width * 0.035,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(15),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF6C63FF).withOpacity(0.2),
                  blurRadius: 15,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: const Icon(
              Icons.notifications_outlined,
              color: Color(0xFF6C63FF),
              size: 28,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWelcomeCard(BuildContext context, Size size) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(size.width * 0.05),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF6C63FF), Color(0xFF8B7FFF)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(25),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF6C63FF).withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.wb_sunny, color: Colors.white, size: 28),
              SizedBox(width: size.width * 0.03),
              Text(
                'Good ${_getGreeting()}!',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          SizedBox(height: size.height * 0.015),
          Text(
            'Let\'s make today healthier than yesterday',
            style: TextStyle(
              color: Colors.white.withOpacity(0.9),
              fontSize: 15,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTrackerGrid(BuildContext context, Size size) {
    final trackers = [
      TrackerItem(
        title: 'Steps',
        subtitle: 'Track daily steps',
        icon: Icons.directions_walk,
        gradient: const [Color(0xFFFF6B6B), Color(0xFFFF8E8E)],
        screen: const StepTrackerScreen(),
      ),
      TrackerItem(
        title: 'Water',
        subtitle: 'Stay hydrated',
        icon: Icons.water_drop,
        gradient: const [Color(0xFF4ECDC4), Color(0xFF44A08D)],
        screen: const water.WaterTrackerScreen(),
      ),
      TrackerItem(
        title: 'Sleep',
        subtitle: 'Rest well',
        icon: Icons.bedtime,
        gradient: const [Color(0xFF667EEA), Color(0xFF764BA2)],
        screen: const sleep.SleepTrackerScreen(),
      ),
      TrackerItem(
        title: 'Heart',
        subtitle: 'Monitor BPM',
        icon: Icons.favorite,
        gradient: const [Color(0xFFEF5350), Color(0xFFE53935)],
        screen: const HeartRateScreen(),
      ),
      TrackerItem(
        title: 'BMI',
        subtitle: 'Body metrics',
        icon: Icons.monitor_weight,
        gradient: const [Color(0xFFF093FB), Color(0xFFF5576C)],
        screen: const BmiScreen(),
      ),
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: size.width * 0.04,
        mainAxisSpacing: size.width * 0.04,
        childAspectRatio: 0.85,
      ),
      itemCount: trackers.length,
      itemBuilder: (context, index) {
        return _buildTrackerCard(context, trackers[index], size);
      },
    );
  }

  Widget _buildTrackerCard(BuildContext context, TrackerItem item, Size size) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => item.screen),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(25),
          boxShadow: [
            BoxShadow(
              color: item.gradient[0].withOpacity(0.2),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(25),
          child: Stack(
            children: [
              Positioned(
                right: -20,
                top: -20,
                child: Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      colors: item.gradient.map((c) => c.withOpacity(0.1)).toList(),
                    ),
                  ),
                ),
              ),
              Padding(
                padding: EdgeInsets.all(size.width * 0.05),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(colors: item.gradient),
                        borderRadius: BorderRadius.circular(15),
                      ),
                      child: Icon(
                        item.icon,
                        color: Colors.white,
                        size: 28,
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.title,
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF2D3436),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          item.subtitle,
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Morning';
    if (hour < 17) return 'Afternoon';
    return 'Evening';
  }
}

class TrackerItem {
  final String title;
  final String subtitle;
  final IconData icon;
  final List<Color> gradient;
  final Widget screen;

  TrackerItem({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.gradient,
    required this.screen,
  });
}