import 'package:flutter/material.dart';
import '../../core/constants.dart';
import '../../core/theme.dart';
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
    final plan = await _supabase.getActiveWorkoutPlan();
    if (mounted) setState(() => _plan = plan);
  }

  Future<void> _generate() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final data = await _api.generateWorkout(
        goal: _goal,
        level: _level,
        daysPerWeek: _days.round(),
        equipment: _equipment.toList(),
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
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _loading ? null : _generate,
                    child: _loading ? const CircularProgressIndicator() : const Text('Generate Plan'),
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
    );
  }
}
