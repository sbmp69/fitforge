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
  DateTime? _dateOfBirth;
  String _gender = 'Male';

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
        dateOfBirth: _dateOfBirth ?? DateTime(2000, 1, 1),
        gender: _gender,
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
              DropdownButtonFormField<String>(
                value: AppConstants.allCountries.contains(_country) ? _country : AppConstants.allCountries.first,
                isExpanded: true,
                decoration: const InputDecoration(labelText: 'Country'),
                items: AppConstants.allCountries.map((e) => DropdownMenuItem(value: e, child: Text(e, overflow: TextOverflow.ellipsis))).toList(),
                onChanged: (v) => setState(() => _country = v!),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: AppConstants.popularCuisines.contains(_mealPreference) ? _mealPreference : AppConstants.popularCuisines.first,
                isExpanded: true,
                decoration: const InputDecoration(labelText: 'Meal Preference / Cuisine'),
                items: AppConstants.popularCuisines.map((e) => DropdownMenuItem(value: e, child: Text(e, overflow: TextOverflow.ellipsis))).toList(),
                onChanged: (v) => setState(() => _mealPreference = v!),
              ),
              const SizedBox(height: 16),
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Date of Birth', style: TextStyle(color: Colors.white, fontSize: 16)),
                subtitle: Text(
                  _dateOfBirth == null ? 'Select your birthday' : '${_dateOfBirth!.year}-${_dateOfBirth!.month.toString().padLeft(2, '0')}-${_dateOfBirth!.day.toString().padLeft(2, '0')}',
                  style: TextStyle(color: _dateOfBirth == null ? AppColors.slate400 : AppColors.primary),
                ),
                trailing: const Icon(Icons.calendar_today, color: AppColors.slate400),
                onTap: () async {
                  final date = await showDatePicker(
                    context: context,
                    initialDate: _dateOfBirth ?? DateTime(2000, 1, 1),
                    firstDate: DateTime(1920),
                    lastDate: DateTime.now(),
                  );
                  if (date != null) setState(() => _dateOfBirth = date);
                },
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _gender,
                isExpanded: true,
                decoration: const InputDecoration(labelText: 'Gender'),
                items: ['Male', 'Female', 'Other'].map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
                onChanged: (v) => setState(() => _gender = v!),
              ),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: _loading || _dateOfBirth == null ? null : _submit,
                child: _loading ? const CircularProgressIndicator() : const Text('Continue to App'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
