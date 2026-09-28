import 'package:flutter/material.dart';
import 'dart:async';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/constants.dart';
import '../../core/theme.dart';
import '../../models/meal_plan.dart';
import '../../services/api_service.dart';
import '../../services/supabase_service.dart';
import '../../widgets/app_card.dart';
import '../../widgets/loading_overlay.dart';

import '../../services/subscription_service.dart';
import '../../services/ad_service.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../models/profile.dart';
import '../paywall/paywall_screen.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../widgets/ai_outage_dialog.dart';

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
    HapticFeedback.lightImpact();

    setState(() => _loading = true);

    final completer = Completer<void>();
    AdService.showInterstitialAd(() {
      completer.complete();
    });
    await completer.future;
    
    if (!SubscriptionService.isPremium) {
      int aiUsed = _profile?.aiPlansUsedThisMonth ?? 0;
      final session = Supabase.instance.client.auth.currentSession;
      if (session != null) {
        try {
          final res = await Supabase.instance.client.from('profiles').select('ai_plans_used_this_month').eq('id', session.user.id).single();
          aiUsed = res['ai_plans_used_this_month'] as int? ?? 0;
        } catch (_) {}
      }

      final aiLimit = AppConstants.aiPlanLimits[_profile?.subscriptionTier] ?? 10;
      if (aiUsed >= aiLimit) {
        if (mounted) {
          setState(() => _loading = false);
          Navigator.of(context).push(MaterialPageRoute(builder: (_) => const PaywallScreen()));
        }
        return;
      }

      AdService.showInterstitialAd(() {});
    }

    setState(() {
      _loading = true;
    });
    try {
      final data = await _api.generateMeals(
        dietaryPreference: _diet,
        allergies: _allergies.text.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList(),
      );
      if (mounted) {
        setState(() {
          _plan = MealPlan.fromJson(data['plan']);
          _dayIndex = 0;
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
        title: const Text('Meals'),
        actions: [
          TextButton(
            onPressed: () => setState(() => _showForm = !_showForm),
            child: const Text('New Plan', style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
      body: Stack(
        children: [
          ListView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 140),
            children: [
              if (_showForm)
                AppCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
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
                      if (!SubscriptionService.isPremium)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Text('${(5 - (_profile?.aiPlansUsedThisMonth ?? 0)).clamp(0, 5)} AI plans left this month', textAlign: TextAlign.center, style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                        ),
                      ElevatedButton(
                        onPressed: _loading ? null : _generate,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                        child: const Text('Generate Meal Plan', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
                ),
              if (_plan != null && _plan!.days.isNotEmpty) ...[
                if (_showForm) const SizedBox(height: 24),
                Hero(
                  tag: 'meal_card',
                  child: Container(
                    decoration: BoxDecoration(
                      color: AppColors.primaryLight,
                      borderRadius: BorderRadius.circular(24),
                    ),
                    padding: const EdgeInsets.all(20),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: const BoxDecoration(
                            color: AppColors.primary,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.restaurant, color: Colors.white, size: 28),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Active Plan', style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.w600)),
                              const SizedBox(height: 4),
                              Text('My Meal Plan', style: GoogleFonts.playfairDisplay(fontSize: 22, fontStyle: FontStyle.italic, fontWeight: FontWeight.bold, color: AppColors.textHeader)),
                            ],
                          ),
                        ),
                        const Icon(Icons.chevron_right, color: AppColors.primary),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                ...List.generate(_plan!.days.length, (i) {
                  final day = _plan!.days[i];
                  final isExpanded = _dayIndex == i;
                  return Theme(
                    data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
                    child: ExpansionTile(
                      initiallyExpanded: isExpanded,
                      onExpansionChanged: (expanded) {
                        if (expanded) setState(() => _dayIndex = i);
                      },
                      tilePadding: EdgeInsets.zero,
                      title: Row(
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
                          Text(day.day, style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold, fontSize: 18)),
                        ],
                      ),
                      children: [
                        _MealCard(title: 'Breakfast', meal: day.breakfast),
                        _MealCard(title: 'Lunch', meal: day.lunch),
                        _MealCard(title: 'Dinner', meal: day.dinner),
                        ...day.snacks.asMap().entries.map((e) => _MealCard(title: 'Snack ${e.key + 1}', meal: e.value)),
                        const SizedBox(height: 16),
                      ],
                    ),
                  );
                }),
              ] else if (!_showForm)
                const AppCard(child: Center(child: Padding(padding: EdgeInsets.all(24), child: Text('No meal plan yet', style: TextStyle(color: AppColors.textSecondary))))),
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
    return Container(
      margin: const EdgeInsets.only(bottom: 12, left: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
      ),
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Builder(
              builder: (context) {
                final foodImgs = [
                  '1546069901-ba9599a7e63c', '1512621776951-a57141f2eefd', 
                  '1493770348161-369560ae357d', '1473093295043-cdd812d0e601',
                  '1467003909585-2f8a72700288'
                ];
                final imgId = foodImgs[meal.name.hashCode.abs() % foodImgs.length];
                return Image.network(
                  'https://images.unsplash.com/photo-$imgId?q=80&w=200',
                  width: 60,
                  height: 60,
                  fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) => Container(
                width: 60,
                height: 60,
                color: AppColors.primaryLight,
                child: const Icon(Icons.restaurant, color: AppColors.primary),
              ),
            );
              },
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary, fontWeight: FontWeight.w600)),
                const SizedBox(height: 2),
                Text(meal.name, style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.textHeader, fontSize: 15)),
                const SizedBox(height: 4),
                Text('${meal.calories} kcal • ${meal.protein}g P', style: const TextStyle(color: AppColors.textSecondary, fontSize: 13)),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: const BoxDecoration(
              color: AppColors.primaryLight,
              shape: BoxShape.circle,
            ),
            child: Text('${meal.calories}\nkcal', textAlign: TextAlign.center, style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold, fontSize: 10, height: 1.1)),
          ),
        ],
      ),
    );
  }
}
