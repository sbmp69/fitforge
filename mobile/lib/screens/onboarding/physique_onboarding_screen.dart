import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants.dart';
import '../../core/theme.dart';
import '../../services/supabase_service.dart';
import '../../widgets/app_card.dart';

class PhysiqueOnboardingScreen extends StatefulWidget {
  const PhysiqueOnboardingScreen({super.key});

  @override
  State<PhysiqueOnboardingScreen> createState() => _PhysiqueOnboardingScreenState();
}

class _PhysiqueOnboardingScreenState extends State<PhysiqueOnboardingScreen> {
  final _supabase = SupabaseService();
  bool _loading = false;
  String? _error;

  double _heightCm = 175;
  double _weightKg = 70;
  String _primaryGoal = 'build_muscle';
  String _fitnessLevel = 'intermediate';
  String _country = 'India';
  String _mealPreference = 'Indian';

  Future<void> _submit() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      await _supabase.updatePhysiqueProfile(
        heightCm: _heightCm.round(),
        weightKg: _weightKg,
        goal: _primaryGoal,
        level: _fitnessLevel,
        country: _country,
        mealPreference: _mealPreference,
      );
      if (mounted) context.go('/home');
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Complete Your Profile')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Help us customize your AI workouts by providing your starting stats.',
                style: TextStyle(color: AppColors.slate400),
              ),
              const SizedBox(height: 24),
              if (_error != null)
                Container(
                  padding: const EdgeInsets.all(12),
                  margin: const EdgeInsets.only(bottom: 24),
                  decoration: BoxDecoration(color: Colors.red.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)),
                  child: Text(_error!, style: const TextStyle(color: Colors.redAccent)),
                ),
              Text('Height: ${_heightCm.round()} cm', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
              Slider(
                value: _heightCm,
                min: 140,
                max: 220,
                divisions: 80,
                onChanged: (v) => setState(() => _heightCm = v),
              ),
              const SizedBox(height: 16),
              Text('Weight: ${_weightKg.toStringAsFixed(1)} kg', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
              Slider(
                value: _weightKg,
                min: 40,
                max: 150,
                divisions: 220,
                onChanged: (v) => setState(() => _weightKg = v),
              ),
              const SizedBox(height: 24),
              DropdownButtonFormField<String>(
                value: _primaryGoal,
                decoration: const InputDecoration(labelText: 'Primary Goal'),
                items: AppConstants.goalLabels.entries
                    .map((e) => DropdownMenuItem(value: e.key, child: Text(e.value)))
                    .toList(),
                onChanged: (v) => setState(() => _primaryGoal = v!),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _fitnessLevel,
                decoration: const InputDecoration(labelText: 'Fitness Level'),
                items: AppConstants.levelLabels.entries
                    .map((e) => DropdownMenuItem(value: e.key, child: Text(e.value)))
                    .toList(),
                onChanged: (v) => setState(() => _fitnessLevel = v!),
              ),
              const SizedBox(height: 16),
              Autocomplete<String>(
                initialValue: TextEditingValue(text: _country),
                optionsBuilder: (TextEditingValue val) {
                  if (val.text.isEmpty) return AppConstants.allCountries;
                  return AppConstants.allCountries.where((option) => option.toLowerCase().contains(val.text.toLowerCase()));
                },
                onSelected: (selection) => setState(() => _country = selection),
                fieldViewBuilder: (context, controller, focusNode, onFieldSubmitted) {
                  return TextFormField(
                    controller: controller,
                    focusNode: focusNode,
                    decoration: const InputDecoration(
                      labelText: 'Country',
                      hintText: 'Search your country...',
                      suffixIcon: Icon(Icons.search, color: AppColors.slate400),
                    ),
                    onChanged: (v) => setState(() => _country = v),
                  );
                },
              ),
              const SizedBox(height: 16),
              Autocomplete<String>(
                initialValue: TextEditingValue(text: _mealPreference),
                optionsBuilder: (TextEditingValue val) {
                  if (val.text.isEmpty) return AppConstants.popularCuisines;
                  return AppConstants.popularCuisines.where((option) => option.toLowerCase().contains(val.text.toLowerCase()));
                },
                onSelected: (selection) => setState(() => _mealPreference = selection),
                fieldViewBuilder: (context, controller, focusNode, onFieldSubmitted) {
                  return TextFormField(
                    controller: controller,
                    focusNode: focusNode,
                    decoration: const InputDecoration(
                      labelText: 'Meal Preference / Cuisine',
                      hintText: 'Type any cuisine (e.g. Vegan Keto, Indian)',
                      suffixIcon: Icon(Icons.edit, color: AppColors.slate400),
                    ),
                    onChanged: (v) => setState(() => _mealPreference = v),
                  );
                },
              ),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: _loading ? null : _submit,
                child: _loading ? const CircularProgressIndicator() : const Text('Continue to App'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
