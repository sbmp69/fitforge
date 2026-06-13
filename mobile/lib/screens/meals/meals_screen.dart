import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/constants.dart';
import '../../core/theme.dart';
import '../../models/meal_plan.dart';
import '../../services/api_service.dart';
import '../../services/supabase_service.dart';
import '../../widgets/app_card.dart';
import '../../widgets/loading_overlay.dart';
import '../../models/profile.dart';
import '../paywall/paywall_screen.dart';

class MealsScreen extends StatefulWidget {
  const MealsScreen({super.key});

  @override
  State<MealsScreen> createState() => _MealsScreenState();
}

class _MealsScreenState extends State<MealsScreen> {
  final _supabase = SupabaseService();
  final _api = ApiService();
  MealPlan? _plan;
  Profile? _profile;
  int _dayIndex = 0;
  bool _loading = false;
  bool _showForm = false;
  String? _error;

  double _calories = 2000;
  String _diet = 'non_veg';
  final _allergies = TextEditingController();

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final results = await Future.wait([
      _supabase.getActiveMealPlan(),
      _supabase.getProfile(),
    ]);
    if (mounted) {
      setState(() {
        _plan = results[0] as MealPlan?;
        _profile = results[1] as Profile?;
      });
    }
  }

  Future<void> _generate() async {
    int aiUsed = _profile?.aiPlansUsedThisMonth ?? 0;
    final session = Supabase.instance.client.auth.currentSession;
    if (session != null) {
      try {
        final res = await Supabase.instance.client.from('profiles').select('ai_plans_used_this_month').eq('id', session.user.id).single();
        aiUsed = res['ai_plans_used_this_month'] as int? ?? 0;
      } catch (_) {}
    }

    final aiLimit = AppConstants.aiPlanLimits[_profile?.subscriptionTier] ?? 3;
    if (aiUsed >= aiLimit) {
      if (mounted) Navigator.of(context).push(MaterialPageRoute(builder: (_) => const PaywallScreen()));
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final data = await _api.generateMeals(
        calorieTarget: _calories.round(),
        dietaryPreference: _diet,
        allergies: _allergies.text.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList(),
      );
      if (mounted) {
        setState(() {
          _plan = MealPlan.fromJson(data['plan']);
          _showForm = false;
        });
      }
    } catch (e) {
      if (e.toString().toLowerCase().contains('limit')) {
        if (mounted) Navigator.of(context).push(MaterialPageRoute(builder: (_) => const PaywallScreen()));
      } else {
        if (mounted) setState(() => _error = e.toString());
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final day = _plan != null && _plan!.days.isNotEmpty ? _plan!.days[_dayIndex] : null;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Meal Plan'),
        actions: [
          TextButton(onPressed: () => setState(() => _showForm = !_showForm), child: const Text('New Plan')),
        ],
      ),
      body: Stack(
        children: [
          ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (_error != null)
            Container(
              padding: const EdgeInsets.all(12),
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(color: Colors.red.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)),
              child: Text(_error!, style: const TextStyle(color: Colors.redAccent)),
            ),
          if (_showForm)
            AppCard(
              child: Column(
                children: [
                  Text('Calories: ${_calories.round()}'),
                  Slider(value: _calories, min: 1200, max: 4000, divisions: 28, onChanged: (v) => setState(() => _calories = v)),
                  DropdownButtonFormField<String>(
                    value: _diet,
                    decoration: const InputDecoration(labelText: 'Diet'),
                    items: AppConstants.dietLabels.entries
                        .map((e) => DropdownMenuItem(value: e.key, child: Text(e.value)))
                        .toList(),
                    onChanged: (v) => setState(() => _diet = v!),
                  ),
                  const SizedBox(height: 12),
                  TextField(controller: _allergies, decoration: const InputDecoration(labelText: 'Allergies (comma-separated)')),
                  const SizedBox(height: 24),
                  InkWell(
                    onTap: _loading ? null : _generate,
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(colors: [AppColors.amber, Colors.orangeAccent]),
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(color: AppColors.amber.withValues(alpha: 0.3), blurRadius: 12, offset: const Offset(0, 4)),
                        ],
                      ),
                      alignment: Alignment.center,
                      child: const Text('Generate Meal Plan ⚡', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
            ),
          if (_plan != null && _plan!.days.isNotEmpty) ...[
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: List.generate(_plan!.days.length, (i) {
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: Text(_plan!.days[i].day),
                      selected: _dayIndex == i,
                      onSelected: (_) => setState(() => _dayIndex = i),
                    ),
                  );
                }),
              ),
            ),
            const SizedBox(height: 16),
            if (day != null) ...[
              _MealCard(title: 'Breakfast', meal: day.breakfast),
              _MealCard(title: 'Lunch', meal: day.lunch),
              _MealCard(title: 'Dinner', meal: day.dinner),
              ...day.snacks.asMap().entries.map((e) => _MealCard(title: 'Snack ${e.key + 1}', meal: e.value)),
            ],
          ] else if (!_showForm)
            const AppCard(child: Center(child: Padding(padding: EdgeInsets.all(24), child: Text('No meal plan yet', style: TextStyle(color: AppColors.slate400))))),
        ],
      ),
          if (_loading) const LoadingOverlay(text: 'Forging your meal plan... ⚡'),
        ],
      ),
    );
  }
}

class _MealCard extends StatelessWidget {
  final String title;
  final MealItem meal;

  const _MealCard({required this.title, required this.meal});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: AppCard(
        child: Container(
          decoration: const BoxDecoration(
            border: Border(left: BorderSide(color: AppColors.amber, width: 4)),
          ),
          padding: const EdgeInsets.only(left: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(fontSize: 12, color: AppColors.slate400)),
              const SizedBox(height: 4),
              Text(meal.name, style: const TextStyle(fontWeight: FontWeight.w600, color: Colors.white)),
              Text('${meal.calories} kcal', style: const TextStyle(color: AppColors.amber)),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _Macro('P', meal.protein, Colors.redAccent),
                  _Macro('C', meal.carbs, Colors.blueAccent),
                  _Macro('F', meal.fat, Colors.yellow),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Macro extends StatelessWidget {
  final String label;
  final int value;
  final Color color;

  const _Macro(this.label, this.value, this.color);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text('${value}g', style: TextStyle(fontWeight: FontWeight.bold, color: color)),
        Text(label, style: const TextStyle(fontSize: 11, color: AppColors.slate400)),
      ],
    );
  }
}
