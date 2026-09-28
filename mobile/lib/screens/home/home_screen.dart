import 'dart:ui';
import 'dart:async';
import 'package:flutter/material.dart';
import 'dart:io';
import 'package:in_app_update/in_app_update.dart';
import 'package:go_router/go_router.dart';
import 'package:shimmer/shimmer.dart';
import 'package:intl/intl.dart';
import 'package:upgrader/upgrader.dart';
import '../../core/constants.dart';
import '../../core/theme.dart';
import '../../models/meal_plan.dart';
import '../../models/profile.dart';
import '../../models/progress_log.dart';
import '../../models/workout_plan.dart';
import '../../services/subscription_service.dart';
import '../../services/supabase_service.dart';
import '../../services/notification_service.dart';

import '../../widgets/app_card.dart';
import '../../widgets/progress_ring.dart';
import '../../widgets/streak_fire.dart';
import '../../widgets/animated_mesh_background.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';

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
  bool _isOffline = false;
  Timer? _adTimer;

  @override
  void initState() {
    super.initState();
    _load();
    _startAdTimer();
    _checkForUpdate();
  }

  Future<void> _checkForUpdate() async {
    if (!Platform.isAndroid) return;
    try {
      final info = await InAppUpdate.checkForUpdate();
      if (info.updateAvailability == UpdateAvailability.updateAvailable) {
        await InAppUpdate.startFlexibleUpdate();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Update your FitForge app', style: TextStyle(color: Colors.black)),
              backgroundColor: Colors.white,
              duration: const Duration(days: 1), 
              action: SnackBarAction(
                label: 'Restart',
                textColor: AppColors.primary,
                onPressed: () {
                  InAppUpdate.completeFlexibleUpdate();
                },
              ),
            ),
          );
        }
      }
    } catch (e) {
      debugPrint('Failed to check for update: $e');
    }
  }

  void _startAdTimer() {
    _adTimer = Timer.periodic(const Duration(seconds: 150), (timer) {
      if (!SubscriptionService.isPremium) {

      } else {
        timer.cancel();
      }
    });
  }

  @override
  void dispose() {
    _adTimer?.cancel();
    super.dispose();
  }

  Future<void> _load() async {
    if (!mounted) return;
    
    try {
      final results = await Future.wait([
        _supabase.getProfile(),
        _supabase.getActiveWorkoutPlan(),
        _supabase.getActiveMealPlan(),
        _supabase.getProgressLogs(limit: 30),
      ]);
      
      final notifs = NotificationService();
      await notifs.requestPermissions();
      await notifs.scheduleSmartCycling(_profile?.country);
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
      debugPrint('Error loading home data (offline): $e');
      if (mounted) {
        setState(() {
          _isOffline = true;
          _loading = false;
        });
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
        backgroundColor: AppColors.background,
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Shimmer.fromColors(
              baseColor: AppColors.surface,
              highlightColor: AppColors.border,
              child: Column(
                children: [
                  Container(height: 60, decoration: BoxDecoration(color: AppColors.textHeader, borderRadius: BorderRadius.circular(16))),
                  const SizedBox(height: 16),
                  Container(height: 200, decoration: BoxDecoration(color: AppColors.textHeader, borderRadius: BorderRadius.circular(16))),
                  const SizedBox(height: 16),
                  Container(height: 100, decoration: BoxDecoration(color: AppColors.textHeader, borderRadius: BorderRadius.circular(16))),
                ],
              ),
            ),
          ),
        ),
      );
    }

    final name = _profile?.fullName?.split(' ').first ?? 'Athlete';
    final todayStr = DateFormat('yyyy-MM-dd').format(DateTime.now());
    final todayLogMatches = _logs.where((l) => l.logDate == todayStr);
    final todayLog = todayLogMatches.isEmpty ? null : todayLogMatches.first;

    return UpgradeAlert(
      upgrader: Upgrader(),
      showIgnore: false,
      showLater: false,
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          title: Row(
            children: [
              const Icon(Icons.fitness_center, color: AppColors.primary),
              const SizedBox(width: 8),
              const Text('FITFORGE AI', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.textHeader)),
            ],
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.notifications_none, color: AppColors.textHeader),
              onPressed: () {},
            ),
          ],
        ),
        body: RefreshIndicator(
          onRefresh: _load,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 120),
            children: [
              if (_isOffline)
                Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                  decoration: BoxDecoration(color: Colors.orangeAccent.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(12)),
                  child: Row(
                    children: [
                      const Icon(Icons.wifi_off, color: Colors.orangeAccent, size: 20),
                      const SizedBox(width: 12),
                      const Text('Offline Mode (Showing cached data)', style: TextStyle(color: Colors.orangeAccent, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ).animate().fadeIn(),
              
              Stack(
                clipBehavior: Clip.none,
                children: [
                  Positioned(
                    right: -30,
                    top: -20,
                    child: Container(
                      width: 220,
                      height: 220,
                      decoration: BoxDecoration(
                        color: AppColors.primaryLight.withOpacity(0.5),
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Hello $name 👋', style: const TextStyle(color: AppColors.textSecondary, fontSize: 16)),
                      const SizedBox(height: 4),
                      RichText(
                        text: const TextSpan(
                          style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: AppColors.textHeader, height: 1.2),
                          children: [
                            TextSpan(text: "Let's Build a\n"),
                            TextSpan(text: "Healthier", style: TextStyle(color: AppColors.primary)),
                            TextSpan(text: " You"),
                          ],
                        ),
                      ),
                      const SizedBox(height: 48),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [AppColors.gradientStart, AppColors.primary],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Row(
                          children: [
                            const Text('🔥', style: TextStyle(fontSize: 32)),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('${_streak()} Day Streak!', style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                                  const Text('Keep it up! You are crushing it.', style: TextStyle(color: Colors.white70, fontSize: 13)),
                                ],
                              ),
                            ),
                            const Icon(Icons.chevron_right, color: Colors.white),
                          ],
                        ),
                      ).animate().scale(delay: 200.ms, duration: 400.ms, curve: Curves.easeOutBack),
                    ],
                  ),
                  Positioned(
                    right: -10,
                    top: -10,
                    bottom: 20,
                    child: Image.asset(
                      'assets/images/hero.png',
                      width: 160,
                      fit: BoxFit.contain,
                      alignment: Alignment.bottomRight,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: AppCard(
                      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
                      child: Column(
                        children: [
                          SizedBox(
                            height: 60,
                            width: 60,
                            child: Stack(
                              fit: StackFit.expand,
                              children: [
                                CircularProgressIndicator(
                                  value: _weeklyProgress() / 100,
                                  backgroundColor: AppColors.border,
                                  valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary),
                                  strokeWidth: 6,
                                ),
                                Center(
                                  child: Text('${_weeklyProgress().toInt()}%', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.textHeader)),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 12),
                          const Text('This week', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _StatCard(
                      icon: Icons.fitness_center,
                      title: 'Workouts',
                      value: '${_logs.where((l) => l.workoutCompleted).take(7).length}/7',
                      subtitle: 'this week',
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _StatCard(
                      icon: Icons.water_drop,
                      title: 'Water Today',
                      value: '${todayLog?.waterMl ?? 0} ml',
                      subtitle: 'Stay hydrated',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              const Text('Quick Actions', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textHeader)),
              const SizedBox(height: 12),

              _QuickActionCard(
                icon: Icons.fitness_center,
                title: "Today's Workout",
                subtitle: _workout?.title ?? "No plan yet",
                onTap: () => context.go('/workout'),
              ),
              const SizedBox(height: 12),
              _QuickActionCard(
                icon: Icons.restaurant,
                title: "Meal Plan",
                subtitle: _meal?.title ?? "No plan yet",
                onTap: () => context.go('/meals'),
              ),
              const SizedBox(height: 12),
              _QuickActionCard(
                icon: Icons.trending_up,
                title: "Log Progress",
                subtitle: "Track your journey",
                onTap: () => context.go('/progress'),
              ),
              const SizedBox(height: 12),
              _QuickActionCard(
                icon: Icons.chat_bubble_outline,
                title: "AI Coach",
                subtitle: "Ask anything",
                onTap: () => context.go('/coach'),
              ),
              
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;
  final String subtitle;

  const _StatCard({required this.icon, required this.title, required this.value, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
      child: Column(
        children: [
          Icon(icon, color: AppColors.primary, size: 28),
          const SizedBox(height: 8),
          Text(title, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary), textAlign: TextAlign.center, maxLines: 1, overflow: TextOverflow.ellipsis),
          const SizedBox(height: 4),
          Text(value, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textHeader)),
          const SizedBox(height: 2),
          Text(subtitle, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary), textAlign: TextAlign.center, maxLines: 1, overflow: TextOverflow.ellipsis),
        ],
      ),
    );
  }
}

class _QuickActionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _QuickActionCard({required this.icon, required this.title, required this.subtitle, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border, width: 1),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: const BoxDecoration(
                color: AppColors.primaryLight,
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: AppColors.primary),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textHeader)),
                  const SizedBox(height: 4),
                  Text(subtitle, style: const TextStyle(fontSize: 14, color: AppColors.textSecondary)),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: AppColors.textSecondary),
          ],
        ),
      ),
    );
  }
}

