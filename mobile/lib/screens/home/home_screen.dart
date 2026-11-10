import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
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
import '../../services/api_service.dart';

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
  final _api = ApiService();
  bool _autoGenerating = false;
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

    // Absolute fallback: NEVER stay on shimmer for more than 3 seconds
    Timer(const Duration(seconds: 3), () {
      if (mounted && _loading) {
        setState(() => _loading = false);
      }
    });
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

    // 1. Instant Cache-First Loading (0ms UI render)
    try {
      final prefs = await SharedPreferences.getInstance();
      final cachedProfStr = prefs.getString('cached_profile');
      final cachedWorkStr = prefs.getString('cached_workout_plan');
      final cachedMealStr = prefs.getString('cached_meal_plan');
      final cachedLogsStr = prefs.getString('cached_logs');

      Profile? p;
      WorkoutPlan? w;
      MealPlan? m;
      List<ProgressLog> l = [];

      if (cachedProfStr != null) {
        try { p = Profile.fromJson(jsonDecode(cachedProfStr)); } catch (_) {}
      }
      if (cachedWorkStr != null) {
        try { w = WorkoutPlan.fromJson(jsonDecode(cachedWorkStr)); } catch (_) {}
      }
      if (cachedMealStr != null) {
        try { m = MealPlan.fromJson(jsonDecode(cachedMealStr)); } catch (_) {}
      }
      if (cachedLogsStr != null) {
        try {
          final list = jsonDecode(cachedLogsStr) as List<dynamic>;
          l = list.map((e) => ProgressLog.fromJson(e)).toList();
        } catch (_) {}
      }

      if (mounted && (p != null || w != null || m != null)) {
        setState(() {
          if (p != null) _profile = p;
          if (w != null) _workout = w;
          if (m != null) _meal = m;
          if (l.isNotEmpty) _logs = l;
          _loading = false; // Render immediately!
        });
      }
    } catch (_) {}
    
    // 2. Fresh Network Fetch with a strict 4-second timeout
    try {
      final results = await Future.wait([
        _supabase.getProfile(),
        _supabase.getActiveWorkoutPlan(),
        _supabase.getActiveMealPlan(),
        _supabase.getProgressLogs(limit: 30),
      ]).timeout(const Duration(seconds: 4));
      
      if (mounted) {
        final profile = results[0] as Profile?;
        setState(() {
          _profile = profile ?? _profile;
          _workout = results[1] as WorkoutPlan? ?? _workout;
          _meal = results[2] as MealPlan? ?? _meal;
          _logs = (results[3] as List<ProgressLog>).isNotEmpty ? (results[3] as List<ProgressLog>) : _logs;
          _loading = false;
        });

        if ((_workout == null || _meal == null) && profile?.primaryGoal != null) {
          _autoGenerateStarterPlans(profile!);
        }

        // Initialize smart notifications in background without blocking Home UI
        unawaited(() async {
          try {
            final notifs = NotificationService();
            await notifs.requestPermissions();
            await notifs.scheduleSmartCycling(profile?.country ?? _profile?.country);
          } catch (e) {
            debugPrint('Notification scheduling error: $e');
          }
        }());
      }
    } catch (e) {
      debugPrint('Error or timeout loading home data: $e');
      if (mounted) {
        setState(() {
          _isOffline = true;
          _loading = false;
        });
      }
    } finally {
      if (mounted && _loading) {
        setState(() => _loading = false);
      }
    }
  }

  Future<void> _autoGenerateStarterPlans(Profile prof) async {
    if (_autoGenerating) return;
    _autoGenerating = true;

    final equip = <String>[];
    for (final eq in prof.equipment) {
      final lower = eq.toLowerCase();
      if (lower.contains('bodyweight')) {
        equip.addAll(['Bodyweight Only', 'No Equipment']);
      } else if (lower.contains('portable')) {
        equip.addAll(['Dumbbells', 'Resistance Bands', 'Kettlebell']);
      } else if (lower.contains('gym')) {
        equip.addAll(['Barbell', 'Dumbbells', 'Cable Machine', 'Bench']);
      }
    }
    if (equip.isEmpty) equip.addAll(['Dumbbells', 'No Equipment']);

    String diet = 'traditional_indian';
    final pref = prof.mealPreference?.toLowerCase() ?? '';
    if (pref.contains('veg') && !pref.contains('non')) {
      diet = 'veg';
    } else if (pref.contains('vegan')) {
      diet = 'vegan';
    } else if (pref.contains('keto')) {
      diet = 'keto';
    } else if (pref.contains('mediterranean')) {
      diet = 'mediterranean';
    } else if (pref.contains('high protein')) {
      diet = 'high_protein';
    }

    try {
      if (_workout == null) {
        final wData = await _api.generateWorkout(
          goal: prof.primaryGoal ?? 'build_muscle',
          level: prof.fitnessLevel ?? 'beginner',
          daysPerWeek: prof.workoutDays.isNotEmpty ? prof.workoutDays.length.clamp(2, 6) : 3,
          equipment: equip,
        );
        if (mounted && wData['plan'] != null) {
          setState(() => _workout = WorkoutPlan.fromJson(wData['plan']));
        }
      }
      if (_meal == null) {
        final mData = await _api.generateMeals(
          dietaryPreference: diet,
          allergies: [],
        );
        if (mounted && mData['plan'] != null) {
          setState(() => _meal = MealPlan.fromJson(mData['plan']));
        }
      }
    } catch (e) {
      debugPrint('Background starter plan auto-generation error: $e');
    } finally {
      _autoGenerating = false;
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

    return Scaffold(
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
                      Row(
                        children: [
                          Text('Hello $name', style: const TextStyle(color: AppColors.textSecondary, fontSize: 16)),
                          const SizedBox(width: 6),
                          const Icon(Icons.waving_hand, color: Color(0xFFFFCC80), size: 16),
                        ],
                      ),
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
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.15),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.local_fire_department,
                                color: Color(0xFFFF9800),
                                size: 28,
                              ),
                            ),
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

                              if (_profile != null && (_profile?.targetWeightKg != null || _profile?.targetFocusAreas.isNotEmpty == true)) ...[
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFFEAF1EB), Color(0xFFD8E5DA)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: AppColors.accent.withValues(alpha: 0.3)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: const BoxDecoration(
                                color: AppColors.primary,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.track_changes, color: Colors.white, size: 20),
                            ),
                            const SizedBox(width: 12),
                            const Text(
                              'Your Target Roadmap 🎯',
                              style: TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.w900,
                                color: AppColors.textHeader,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),
                        Row(
                          children: [
                            if (_profile?.weightKg != null && _profile?.targetWeightKg != null)
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text('Goal Target', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                                    const SizedBox(height: 2),
                                    Text(
                                      '${_profile?.weightKg?.toStringAsFixed(1) ?? "--"} kg ➔ ${_profile?.targetWeightKg?.toStringAsFixed(1) ?? "--"} kg',
                                      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.textHeader),
                                    ),
                                  ],
                                ),
                              ),
                            if (_profile?.targetPace != null)
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text('Pace', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                                    const SizedBox(height: 2),
                                    Text(
                                      _profile!.targetPace!.toUpperCase(),
                                      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.primary),
                                    ),
                                  ],
                                ),
                              ),
                          ],
                        ),
                        if (_profile?.targetFocusAreas.isNotEmpty ?? false) ...[
                          const SizedBox(height: 12),
                          Wrap(
                            spacing: 6,
                            runSpacing: 6,
                            children: _profile!.targetFocusAreas.map((area) => Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: AppColors.border),
                              ),
                              child: Text(
                                area,
                                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.textHeader),
                              ),
                            )).toList(),
                          ),
                        ],
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.85),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: AppColors.primary.withOpacity(0.2)),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: [
                              Column(
                                children: [
                                  const Text('METABOLIC DEFICIT', style: TextStyle(fontSize: 8, fontWeight: FontWeight.w800, color: AppColors.textSecondary)),
                                  const SizedBox(height: 2),
                                  Text(
                                    _profile?.targetPace == 'fast' ? '-750 kcal/day' : _profile?.targetPace == 'steady' ? '-350 kcal/day' : '-500 kcal/day',
                                    style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.primary),
                                  ),
                                ],
                              ),
                              Container(width: 1, height: 22, color: AppColors.border),
                              Column(
                                children: [
                                  const Text('PROTEIN FLOOR', style: TextStyle(fontSize: 8, fontWeight: FontWeight.w800, color: AppColors.textSecondary)),
                                  const SizedBox(height: 2),
                                  Text(
                                    '${((_profile?.weightKg ?? 75) * 1.8).round()}g / day',
                                    style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.textHeader),
                                  ),
                                ],
                              ),
                              Container(width: 1, height: 22, color: AppColors.border),
                              Column(
                                children: [
                                  const Text('RATE OF LOSS', style: TextStyle(fontSize: 8, fontWeight: FontWeight.w800, color: AppColors.textSecondary)),
                                  const SizedBox(height: 2),
                                  Text(
                                    _profile?.targetPace == 'fast' ? '~0.8 kg/wk' : _profile?.targetPace == 'steady' ? '~0.3 kg/wk' : '~0.5 kg/wk',
                                    style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.textHeader),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
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
                icon: Icons.fastfood_rounded,
                title: "AI Food & Calorie Scanner",
                subtitle: "Snap dish photo or type • Health Meter",
                onTap: () => context.push('/food-scanner'),
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


