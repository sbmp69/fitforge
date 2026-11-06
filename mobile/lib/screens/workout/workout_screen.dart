import 'package:flutter/material.dart';
import 'dart:async';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/constants.dart';
import '../../core/theme.dart';
import '../../models/profile.dart';
import '../../models/workout_plan.dart';
import '../../services/api_service.dart';
import '../../services/supabase_service.dart';
import '../../widgets/app_card.dart';
import '../../widgets/loading_overlay.dart';

import '../../services/subscription_service.dart';
import '../../services/ad_service.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../widgets/workout_timer.dart';
import '../paywall/paywall_screen.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../widgets/ai_outage_dialog.dart';

class WorkoutScreen extends StatefulWidget {
  const WorkoutScreen({super.key});

  @override
  State<WorkoutScreen> createState() => _WorkoutScreenState();
}

class _WorkoutScreenState extends State<WorkoutScreen> {
  final _supabase = SupabaseService();
  final _api = ApiService();
  WorkoutPlan? _plan;
  Profile? _profile;
  bool _loading = false;
  bool _showForm = false;
  int? _activeRest;
  final TextEditingController _customEquipmentController = TextEditingController();

  String _goal = 'build_muscle';
  String _level = 'intermediate';
  double _days = 4;
  final _equipment = <String>{'Dumbbells', 'No Equipment'};

  static const _equipmentOptions = [
    'Dumbbells', 'Barbell', 'Resistance Bands', 'Pull-up Bar',
    'Kettlebell', 'Cable Machine', 'Bench', 'Bodyweight Only', 'No Equipment',
  ];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final results = await Future.wait([
      _supabase.getActiveWorkoutPlan(),
      _supabase.getProfile(),
    ]);
    if (mounted) {
      setState(() {
        _plan = results[0] as WorkoutPlan?;
        _profile = results[1] as Profile?;
        if (_profile?.primaryGoal != null) _goal = _profile!.primaryGoal!;
        if (_profile?.fitnessLevel != null) _level = _profile!.fitnessLevel!;
        if (_profile?.workoutDays.isNotEmpty ?? false) {
          _days = _profile!.workoutDays.length.clamp(2, 6).toDouble();
        }
        if (_profile?.equipment.isNotEmpty ?? false) {
          _equipment.clear();
          for (final eq in _profile!.equipment) {
            final lower = eq.toLowerCase();
            if (lower.contains('bodyweight')) {
              _equipment.addAll(['Bodyweight Only', 'No Equipment']);
            } else if (lower.contains('portable')) {
              _equipment.addAll(['Dumbbells', 'Resistance Bands', 'Kettlebell']);
            } else if (lower.contains('gym')) {
              _equipment.addAll(['Barbell', 'Dumbbells', 'Cable Machine', 'Bench', 'Pull-up Bar']);
            } else if (_equipmentOptions.contains(eq)) {
              _equipment.add(eq);
            }
          }
          if (_equipment.isEmpty) {
            _equipment.addAll(['Dumbbells', 'No Equipment']);
          }
        }
      });
    }
  }

  Future<void> _generate() async {
    HapticFeedback.lightImpact();

    setState(() {
      _loading = true;
    });

    final completer = Completer<void>();
    AdService.showInterstitialAd(() {
      completer.complete();
    });
    await completer.future;

    if (!SubscriptionService.isPremium) {
      int aiUsed = 0;
      final session = Supabase.instance.client.auth.currentSession;
      if (session != null) {
        try {
          final res = await Supabase.instance.client.from('profiles').select('ai_plans_used_this_month').eq('id', session.user.id).single();
          aiUsed = res['ai_plans_used_this_month'] as int? ?? 0;
        } catch (_) {}
      }

      const int aiLimit = 10;
      if (aiUsed >= aiLimit) {
        if (mounted) {
          setState(() => _loading = false);
          Navigator.of(context).push(MaterialPageRoute(builder: (_) => const PaywallScreen()));
        }
        return;
      }
      
      AdService.showInterstitialAd(() {});
    }
    try {
      final custom = _customEquipmentController.text.trim();
      final allEquipment = _equipment.toList();
      if (custom.isNotEmpty) {
        allEquipment.add(custom);
      }
      final data = await _api.generateWorkout(
        goal: _goal,
        level: _level,
        daysPerWeek: _days.round(),
        equipment: allEquipment,
      );
      if (mounted) {
        setState(() {
          _plan = WorkoutPlan.fromJson(data['plan']);
          _showForm = false;
        });
      }
    } catch (e) {
      if (e.toString().toLowerCase().contains('limit')) {
        if (mounted) Navigator.of(context).push(MaterialPageRoute(builder: (_) => const PaywallScreen()));
      } else {
        if (mounted) {
          showDialog(
            context: context,
            builder: (context) => const AiOutageDialog(),
          );
        }
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Workout'),
        actions: [
          TextButton(
            onPressed: () => setState(() => _showForm = !_showForm),
            child: Text(
              _plan == null ? '' : 'Regenerate',
              style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
      body: Stack(
        children: [
          ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 140),
        children: [
          if (_plan == null) ...[
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: AppColors.border),
                boxShadow: [
                  BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 14, offset: const Offset(0, 4)),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.primaryLight,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.fitness_center, color: AppColors.primary, size: 28),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Your Personalized Plan is Ready',
                              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textHeader),
                            ),
                            const SizedBox(height: 4),
                            const Text(
                              'Tailored using your 17 onboarding answers',
                              style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppColors.primaryLight.withValues(alpha: 0.4),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.flag, size: 16, color: AppColors.primary),
                            const SizedBox(width: 8),
                            Text('Goal: ${AppConstants.goalLabels[_goal] ?? _goal}', style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.textHeader, fontSize: 13)),
                            const Spacer(),
                            const Icon(Icons.bolt, size: 16, color: AppColors.primary),
                            const SizedBox(width: 8),
                            Text('Level: ${AppConstants.levelLabels[_level] ?? _level}', style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.textHeader, fontSize: 13)),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            const Icon(Icons.calendar_today, size: 16, color: AppColors.primary),
                            const SizedBox(width: 8),
                            Text('Schedule: ${_days.round()} days / week', style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.textHeader, fontSize: 13)),
                            const Spacer(),
                            const Icon(Icons.shield, size: 16, color: AppColors.primary),
                            const SizedBox(width: 8),
                            Text(
                              _profile?.injuries.isNotEmpty == true && !_profile!.injuries.contains('No injuries')
                                  ? 'Injury Safe'
                                  : 'Full Mobility',
                              style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.textHeader, fontSize: 13),
                            ),
                          ],
                        ),
                        if (_profile?.targetFocusAreas.isNotEmpty == true) ...[
                          const SizedBox(height: 10),
                          Row(
                            children: [
                              const Icon(Icons.gps_fixed, size: 16, color: AppColors.primary),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'Focus: ${_profile!.targetFocusAreas.join(', ')}',
                                  style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.textHeader, fontSize: 13),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  InkWell(
                    onTap: _loading ? null : _generate,
                    borderRadius: BorderRadius.circular(30),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(colors: [AppColors.primary, AppColors.accent]),
                        borderRadius: BorderRadius.circular(30),
                        boxShadow: [
                          BoxShadow(color: AppColors.primary.withValues(alpha: 0.3), blurRadius: 12, offset: const Offset(0, 4)),
                        ],
                      ),
                      alignment: Alignment.center,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: const [
                          Icon(Icons.bolt, color: AppColors.textHeader, size: 22),
                          SizedBox(width: 8),
                          Text('Generate My Workout Plan', style: TextStyle(color: AppColors.textHeader, fontSize: 16, fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ),
                  ).animate(onPlay: (c) => c.repeat(reverse: true)).shimmer(duration: 2.seconds, color: Colors.black26),
                  const SizedBox(height: 12),
                  Center(
                    child: TextButton.icon(
                      onPressed: () => setState(() => _showForm = !_showForm),
                      icon: Icon(_showForm ? Icons.expand_less : Icons.tune, size: 16, color: AppColors.textSecondary),
                      label: Text(
                        _showForm ? 'Hide Preferences' : 'Adjust Equipment or Days',
                        style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],
          if (_showForm) ...[
            AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text('Customize Workout Parameters', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.textHeader)),
                  const SizedBox(height: 14),
                  Text('Days per week: ${_days.round()}', style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.textHeader)),
                  Slider(value: _days, min: 1, max: 7, divisions: 6, activeColor: AppColors.primary, onChanged: (v) => setState(() => _days = v)),
                  const SizedBox(height: 8),
                  const Text('Select Available Equipment', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.textHeader)),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _equipmentOptions.map((item) {
                      final selected = _equipment.contains(item);
                      return FilterChip(
                        label: Text(item),
                        selected: selected,
                        selectedColor: AppColors.primary,
                        checkmarkColor: Colors.white,
                        labelStyle: TextStyle(color: selected ? Colors.white : AppColors.textHeader, fontWeight: FontWeight.bold),
                        onSelected: (_) => setState(() {
                          selected ? _equipment.remove(item) : _equipment.add(item);
                        }),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 14),
                  TextField(
                    controller: _customEquipmentController,
                    decoration: const InputDecoration(
                      labelText: 'Custom Equipment (e.g. Ab Roller, Dip Station)',
                      hintText: 'Type any specific equipment you have',
                    ),
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: _loading ? null : () {
                      _generate();
                      setState(() => _showForm = false);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: const Text('Regenerate Workout Plan', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],
          if (_activeRest != null)
            WorkoutTimer(restSeconds: _activeRest!, onComplete: () => setState(() => _activeRest = null)),
          if (_plan != null) ...[
            Hero(
              tag: 'workout_card',
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.primaryLight,
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: const BoxDecoration(
                        color: AppColors.primary,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.fitness_center, color: Colors.white),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Active Plan', style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.w600, fontSize: 12)),
                          const SizedBox(height: 4),
                          Text(
                            _plan!.title,
                            style: GoogleFonts.playfairDisplay(fontSize: 18, fontStyle: FontStyle.italic, fontWeight: FontWeight.bold, color: AppColors.textHeader),
                          ),
                        ],
                      ),
                    ),
                    const Icon(Icons.chevron_right, color: AppColors.primary),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            ..._plan!.days.map((day) => _DayCard(
                  day: day,
                  onRest: (s) => setState(() => _activeRest = s),
                ))
          ] else if (!_showForm)
            const AppCard(
              child: Center(
                child: Padding(
                  padding: EdgeInsets.all(24),
                  child: Text('No workout plan yet', style: TextStyle(color: AppColors.textSecondary)),
                ),
              ),
            ),
        ],
      ),
          if (_loading) const LoadingOverlay(text: 'Forging your workout...'),
        ],
      ),
    );
  }
}

class _DayCard extends StatefulWidget {
  final WorkoutDay day;
  final ValueChanged<int> onRest;

  const _DayCard({required this.day, required this.onRest});

  @override
  State<_DayCard> createState() => _DayCardState();
}

class _DayCardState extends State<_DayCard> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InkWell(
            onTap: () => setState(() => _expanded = !_expanded),
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Row(
                children: [
                  Container(
                    width: 12,
                    height: 12,
                    decoration: const BoxDecoration(
                      color: AppColors.primary,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      '${widget.day.day} ${widget.day.focus}',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.primary),
                    ),
                  ),
                  Icon(_expanded ? Icons.expand_less : Icons.expand_more, color: AppColors.primary),
                ],
              ),
            ),
          ),
          if (_expanded) ...[
            const SizedBox(height: 16),
            ...widget.day.exercises.map((ex) => Padding(
                  padding: const EdgeInsets.only(left: 5, bottom: 12),
                  child: Container(
                    decoration: const BoxDecoration(
                      border: Border(left: BorderSide(color: AppColors.border, width: 2)),
                    ),
                    padding: const EdgeInsets.only(left: 19),
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppColors.border),
                      ),
                      padding: const EdgeInsets.all(12),
                      child: Row(
                        children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: Builder(
                                builder: (context) {
                                  final fitnessImgs = [
                                    '1581009146145-b5ef050c2e1e', '1534438327276-14e5300c3a48', 
                                    '1517836357463-d25dfeac3438', '1571019614242-c5c5dee9f50b', 
                                    '1599058917212-d750089bc07e', '1571019613454-1cb2f99b2d8b',
                                    '1518611012118-696072aa579a'
                                  ];
                                  final imgId = fitnessImgs[ex.name.hashCode.abs() % fitnessImgs.length];
                                  return Image.network(
                                    'https://images.unsplash.com/photo-$imgId?q=80&w=200',
                                    width: 60,
                                    height: 60,
                                    fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) => Container(
                                  width: 60,
                                  height: 60,
                                  color: AppColors.border,
                                  child: const Icon(Icons.fitness_center, color: AppColors.textSecondary, size: 24),
                                ),
                              );
                                },
                              ),
                            ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(ex.name, style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.textHeader, fontSize: 14)),
                                const SizedBox(height: 4),
                                Text('${ex.sets} sets x ${ex.reps}', style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                                const SizedBox(height: 8),
                                InkWell(
                                  onTap: () async {
                                    final url = Uri.parse('https://www.youtube.com/results?search_query=how+to+do+${Uri.encodeComponent(ex.name)}+exercise+tutorial');
                                    launchUrl(url, mode: LaunchMode.externalApplication).catchError((_) => false);
                                  },
                                  child: const Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(Icons.play_circle_fill, size: 16, color: AppColors.primary),
                                      SizedBox(width: 4),
                                      Text('Watch Tutorial', style: TextStyle(fontSize: 12, color: AppColors.primary, fontWeight: FontWeight.w600)),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          InkWell(
                            onTap: () => widget.onRest(ex.restSeconds),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: AppColors.primaryLight,
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Text('${ex.restSeconds}s', style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold, fontSize: 12)),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                )),
          ],
        ],
      ),
    );
  }
}

