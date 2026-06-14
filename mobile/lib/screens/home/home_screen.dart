import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shimmer/shimmer.dart';
import 'package:intl/intl.dart';
import '../../core/constants.dart';
import '../../core/theme.dart';
import '../../models/meal_plan.dart';
import '../../models/profile.dart';
import '../../models/progress_log.dart';
import '../../models/workout_plan.dart';
import '../../services/supabase_service.dart';
import '../../services/notification_service.dart';
import '../../widgets/app_card.dart';
import '../../widgets/progress_ring.dart';
import '../../widgets/streak_fire.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _supabase = SupabaseService();
  Profile? _profile;
  WorkoutPlan? _workout;
  MealPlan? _meal;
  List<ProgressLog> _logs = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final results = await Future.wait([
        _supabase.getProfile(),
        _supabase.getActiveWorkoutPlan(),
        _supabase.getActiveMealPlan(),
        _supabase.getProgressLogs(limit: 30),
      ]);
      
      final notifs = NotificationService();
      await notifs.requestPermissions();
      await notifs.scheduleDailyReminder(
        id: 1, 
        title: 'Time to crush it! 💪', 
        body: 'Don\'t forget to complete your workout today and log your progress!', 
        hour: 17, // 5 PM
        minute: 0,
      );
        if (mounted) {
          final profile = results[0] as Profile?;
          if (profile != null && profile.heightCm == null) {
            context.go('/physique-onboarding');
            return;
          }
          setState(() {
            _profile = profile;
            _workout = results[1] as WorkoutPlan?;
            _meal = results[2] as MealPlan?;
            _logs = results[3] as List<ProgressLog>;
            _loading = false;
          });
        }
    } catch (e) {
      debugPrint('Error loading home data: $e');
      if (mounted) {
        setState(() {
          _loading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load data: $e')),
        );
      }
    }
  }

  int _streak() {
    var streak = 0;
    final today = DateTime.now();
    for (var i = 0; i < 365; i++) {
      final date = DateFormat('yyyy-MM-dd').format(today.subtract(Duration(days: i)));
      final matches = _logs.where((l) => l.logDate == date);
      final log = matches.isEmpty ? null : matches.first;
      if (log?.workoutCompleted == true) {
        streak++;
      } else if (i > 0) {
        break;
      }
    }
    return streak;
  }

  double _weeklyProgress() {
    final weekAgo = DateTime.now().subtract(const Duration(days: 7));
    final count = _logs.where((l) {
      final d = DateTime.parse(l.logDate);
      return d.isAfter(weekAgo) && l.workoutCompleted;
    }).length;
    return (count / 7 * 100).clamp(0, 100);
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return Scaffold(
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Shimmer.fromColors(
              baseColor: AppColors.navy800,
              highlightColor: AppColors.navy700,
              child: Column(
                children: [
                  Container(height: 60, decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16))),
                  const SizedBox(height: 16),
                  Container(height: 200, decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16))),
                  const SizedBox(height: 16),
                  Container(height: 100, decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16))),
                ],
              ),
            ),
          ),
        ),
      );
    }

    final name = _profile?.fullName?.split(' ').first ?? 'Athlete';
    final tier = AppConstants.tierLabels[_profile?.subscriptionTier] ?? 'Free';
    final aiLimit = AppConstants.aiPlanLimits[_profile?.subscriptionTier] ?? 3;
    final aiUsed = _profile?.aiPlansUsedThisMonth ?? 0;
    final aiLeft = aiLimit > 1000 ? '∞' : '${(aiLimit - aiUsed).clamp(0, aiLimit)}';

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Hey, $name ⚡', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppColors.slate50)),
            Text(DateFormat('EEEE, MMM d').format(DateTime.now()), style: const TextStyle(fontSize: 14, color: AppColors.slate400)),
          ],
        ),
        actions: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [AppColors.primary, AppColors.accent]),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(tier.toUpperCase(), style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white)),
          ),
          const SizedBox(width: 16),
        ],
      ),
      body: Stack(
        children: [
          // Ambient Glow 1
          Positioned(
            top: -100,
            left: -100,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.primary.withValues(alpha: 0.15),
              ),
            ),
          ),
          // Ambient Glow 2
          Positioned(
            bottom: 100,
            right: -150,
            child: Container(
              width: 400,
              height: 400,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.accent.withValues(alpha: 0.1),
              ),
            ),
          ),
          // Blur Filter
          Positioned.fill(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 80, sigmaY: 80),
              child: const SizedBox(),
            ),
          ),
          // Content
          RefreshIndicator(
            onRefresh: _load,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Row(
              children: [
                Expanded(child: AppCard(child: StreakFire(streak: _streak()))),
                const SizedBox(width: 12),
                Expanded(child: AppCard(child: Center(child: ProgressRing(progress: _weeklyProgress(), label: 'This week')))),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(child: _StatCard(title: 'AI Plans Left', value: aiLeft, subtitle: 'this month')),
                const SizedBox(width: 12),
                Expanded(child: _StatCard(title: 'Workouts', value: '${_logs.where((l) => l.workoutCompleted).take(7).length}/7', subtitle: 'this week')),
              ],
            ),
            const SizedBox(height: 24),
            const Text('Quick Actions', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: Colors.white)),
            const SizedBox(height: 12),
            _QuickAction(icon: Icons.fitness_center, label: "Today's Workout", color: AppColors.primary, onTap: () => context.go('/workout')),
            _QuickAction(icon: Icons.restaurant, label: 'Meal Plan', color: AppColors.amber, onTap: () => context.go('/meals')),
            _QuickAction(icon: Icons.trending_up, label: 'Log Progress', color: Colors.blueAccent, onTap: () => context.go('/progress')),
            _QuickAction(icon: Icons.chat_bubble_outline, label: 'AI Coach', color: Colors.purpleAccent, onTap: () => context.push('/coach')),
            const SizedBox(height: 24),
            AppCard(
              onTap: () => context.go('/workout'),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Active Workout', style: TextStyle(fontWeight: FontWeight.w600, color: Colors.white)),
                  const SizedBox(height: 8),
                  Text(
                    _workout?.title ?? 'No plan yet — generate one',
                    style: TextStyle(color: _workout != null ? AppColors.primary : AppColors.slate400),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            AppCard(
              onTap: () => context.go('/meals'),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Active Meal Plan', style: TextStyle(fontWeight: FontWeight.w600, color: Colors.white)),
                  const SizedBox(height: 8),
                  Text(
                    _meal?.title ?? 'No plan yet — generate one',
                    style: TextStyle(color: _meal != null ? AppColors.amber : AppColors.slate400),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final String subtitle;

  const _StatCard({required this.title, required this.value, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontSize: 12, color: AppColors.slate400)),
          const SizedBox(height: 4),
          Text(value, style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white)),
          Text(subtitle, style: const TextStyle(fontSize: 11, color: AppColors.slate400)),
        ],
      ),
    );
  }
}

class _QuickAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _QuickAction({required this.icon, required this.label, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.navy800,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withValues(alpha: 0.3)),
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.1),
              blurRadius: 10,
              spreadRadius: 1,
            ),
          ]
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(16),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(icon, color: color, size: 24),
                  ),
                  const SizedBox(width: 16),
                  Text(label, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.slate50)),
                  const Spacer(),
                  const Icon(Icons.chevron_right, color: AppColors.slate400),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
