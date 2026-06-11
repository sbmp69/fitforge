import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/constants.dart';
import '../../core/theme.dart';
import '../../models/profile.dart';
import '../../models/workout_plan.dart';
import '../../services/api_service.dart';
import '../../services/supabase_service.dart';
import '../../widgets/app_card.dart';
import '../../widgets/workout_timer.dart';

class WorkoutScreen extends StatefulWidget {
  const WorkoutScreen({super.key});

  @override
  State<WorkoutScreen> createState() => _WorkoutScreenState();
}

class _WorkoutScreenState extends State<WorkoutScreen> {
  final _supabase = SupabaseService();
  final _api = ApiService();
  WorkoutPlan? _plan;
  bool _loading = false;
  bool _showForm = false;
  String? _error;
  int? _activeRest;
  final TextEditingController _customEquipmentController = TextEditingController();

  String _goal = 'build_muscle';
  String _level = 'intermediate';
  double _days = 4;
  final _equipment = <String>{'Dumbbells', 'Bodyweight Only'};

  static const _equipmentOptions = [
    'Dumbbells', 'Barbell', 'Resistance Bands', 'Pull-up Bar',
    'Kettlebell', 'Cable Machine', 'Bench', 'Bodyweight Only',
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
        final profile = results[1] as Profile?;
        if (profile?.primaryGoal != null) _goal = profile!.primaryGoal!;
        if (profile?.fitnessLevel != null) _level = profile!.fitnessLevel!;
      });
    }
  }

  Future<void> _generate() async {
    setState(() {
      _loading = true;
      _error = null;
    });
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
      if (mounted) setState(() => _error = e.toString());
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
            child: Text(_plan == null ? 'Generate' : 'New Plan'),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (_error != null)
            Container(
              padding: const EdgeInsets.all(12),
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(color: Colors.red.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)),
              child: Text(_error!, style: const TextStyle(color: Colors.redAccent)),
            ),
          if (_showForm) ...[
            AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  DropdownButtonFormField<String>(
                    value: _goal,
                    decoration: const InputDecoration(labelText: 'Goal'),
                    items: AppConstants.goalLabels.entries
                        .map((e) => DropdownMenuItem(value: e.key, child: Text(e.value)))
                        .toList(),
                    onChanged: (v) => setState(() => _goal = v!),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    value: _level,
                    decoration: const InputDecoration(labelText: 'Level'),
                    items: AppConstants.levelLabels.entries
                        .map((e) => DropdownMenuItem(value: e.key, child: Text(e.value)))
                        .toList(),
                    onChanged: (v) => setState(() => _level = v!),
                  ),
                  const SizedBox(height: 12),
                  Text('Days per week: ${_days.round()}'),
                  Slider(value: _days, min: 1, max: 7, divisions: 6, onChanged: (v) => setState(() => _days = v)),
                  const Text('Equipment', style: TextStyle(color: AppColors.slate400)),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _equipmentOptions.map((item) {
                      final selected = _equipment.contains(item);
                      return FilterChip(
                        label: Text(item),
                        selected: selected,
                        onSelected: (_) => setState(() {
                          selected ? _equipment.remove(item) : _equipment.add(item);
                        }),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _customEquipmentController,
                    decoration: const InputDecoration(
                      labelText: 'Custom Equipment (e.g. Ab Roller)',
                      hintText: 'Type any specific equipment you have',
                    ),
                  ),
                  const SizedBox(height: 24),
                  InkWell(
                    onTap: _loading ? null : _generate,
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(colors: [AppColors.primary, AppColors.accent]),
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(color: AppColors.primary.withValues(alpha: 0.3), blurRadius: 12, offset: const Offset(0, 4)),
                        ],
                      ),
                      alignment: Alignment.center,
                      child: _loading 
                          ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                          : const Text('Generate AI Plan ⚡', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],
          if (_activeRest != null)
            WorkoutTimer(restSeconds: _activeRest!, onComplete: () => setState(() => _activeRest = null)),
          if (_plan != null)
            ..._plan!.days.map((day) => _DayCard(
                  day: day,
                  onRest: (s) => setState(() => _activeRest = s),
                ))
          else if (!_showForm)
            const AppCard(
              child: Center(
                child: Padding(
                  padding: EdgeInsets.all(24),
                  child: Text('No workout plan yet', style: TextStyle(color: AppColors.slate400)),
                ),
              ),
            ),
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
      padding: const EdgeInsets.only(bottom: 12),
      child: AppCard(
        child: Container(
          decoration: const BoxDecoration(
            border: Border(left: BorderSide(color: AppColors.accent, width: 4)),
          ),
          padding: const EdgeInsets.only(left: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              InkWell(
                onTap: () => setState(() => _expanded = !_expanded),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(widget.day.day, style: const TextStyle(fontWeight: FontWeight.w600, color: Colors.white)),
                          Text(widget.day.focus, style: const TextStyle(color: AppColors.primary)),
                        ],
                      ),
                    ),
                    Icon(_expanded ? Icons.expand_less : Icons.expand_more, color: AppColors.slate400),
                  ],
                ),
              ),
            if (_expanded) ...[
              const Divider(height: 24),
              ...widget.day.exercises.map((ex) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(ex.name, style: const TextStyle(color: Colors.white)),
                              Text('${ex.sets} sets × ${ex.reps}', style: const TextStyle(fontSize: 12, color: AppColors.slate400)),
                              const SizedBox(height: 8),
                              OutlinedButton.icon(
                                onPressed: () async {
                                  final url = Uri.parse('https://www.youtube.com/results?search_query=how+to+do+${Uri.encodeComponent(ex.name)}+exercise+tutorial');
                                  launchUrl(url, mode: LaunchMode.externalApplication).catchError((_) => false);
                                },
                                icon: const Icon(Icons.play_circle_outline, size: 16),
                                label: const Text('Watch Tutorial 🎥', style: TextStyle(fontSize: 12)),
                                style: OutlinedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
                                  minimumSize: const Size(0, 32),
                                ),
                              ),
                            ],
                          ),
                        ),
                        TextButton(
                          onPressed: () => widget.onRest(ex.restSeconds),
                          child: Text('${ex.restSeconds}s'),
                        ),
                      ],
                    ),
                  )),
            ],
          ],
        ),
        ),
      ),
    );
  }
}
