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
import '../../widgets/ai_cached_image.dart';

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

  String _diet = 'traditional_indian';
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
        if (_profile?.mealPreference != null) {
          final pref = _profile!.mealPreference!.toLowerCase();
          if (pref.contains('traditional') || pref.contains('indian')) _diet = 'traditional_indian';
          else if (pref.contains('high protein') || pref.contains('protein')) _diet = 'high_protein';
          else if (pref.contains('veg') && !pref.contains('non')) _diet = 'veg';
          else if (pref.contains('vegan')) _diet = 'vegan';
          else if (pref.contains('keto')) _diet = 'keto';
          else if (pref.contains('mediterranean')) _diet = 'mediterranean';
          else _diet = 'non_veg';
        }
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
                            child: const Icon(Icons.restaurant_menu, color: AppColors.primary, size: 28),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Your Personalized Diet is Ready',
                                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textHeader),
                                ),
                                const SizedBox(height: 4),
                                const Text(
                                  'Tailored to your metabolism and cuisine',
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
                                const Icon(Icons.dining, size: 16, color: AppColors.primary),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    'Cuisine: ${_profile?.mealPreference ?? "Traditional Indian"}',
                                    style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.textHeader, fontSize: 13),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            Row(
                              children: [
                                const Icon(Icons.public, size: 16, color: AppColors.primary),
                                const SizedBox(width: 8),
                                Text('Country: ${_profile?.country ?? "India"}', style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.textHeader, fontSize: 13)),
                                const Spacer(),
                                const Icon(Icons.speed, size: 16, color: AppColors.primary),
                                const SizedBox(width: 8),
                                Text('Pace: ${_profile?.targetPace ?? "Normal"}', style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.textHeader, fontSize: 13)),
                              ],
                            ),
                            if (_profile?.weightKg != null && _profile?.targetWeightKg != null) ...[
                              const SizedBox(height: 10),
                              Row(
                                children: [
                                  const Icon(Icons.monitor_weight_outlined, size: 16, color: AppColors.primary),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Target: ${_profile!.weightKg!.toStringAsFixed(1)} kg -> ${_profile!.targetWeightKg!.toStringAsFixed(1)} kg',
                                    style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.textHeader, fontSize: 13),
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
                              Icon(Icons.restaurant, color: AppColors.textHeader, size: 22),
                              SizedBox(width: 8),
                              Text('Generate My Meal Plan', style: TextStyle(color: AppColors.textHeader, fontSize: 16, fontWeight: FontWeight.bold)),
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
                            _showForm ? 'Hide Preferences' : 'Add Allergies or Adjust Diet',
                            style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],
              if (_showForm)
                AppCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Text('Customize Meal Parameters', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.textHeader)),
                      const SizedBox(height: 14),
                      DropdownButtonFormField<String>(
                        value: _diet,
                        decoration: const InputDecoration(labelText: 'Dietary Preference'),
                        items: AppConstants.dietLabels.entries
                            .map((e) => DropdownMenuItem(value: e.key, child: Text(e.value)))
                            .toList(),
                        onChanged: (v) => setState(() => _diet = v!),
                      ),
                      const SizedBox(height: 12),
                      TextField(controller: _allergies, decoration: const InputDecoration(labelText: 'Allergies to Exclude (comma-separated)', hintText: 'e.g. peanuts, dairy, gluten')),
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
                        child: const Text('Regenerate Meal Plan', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
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
          AiCachedImage(
            name: meal.name,
            category: 'meal',
            fallbackUrl: (meal.imageUrl != null && meal.imageUrl!.isNotEmpty) ? meal.imageUrl! : _getMealImageUrl(meal.name),
            width: 60,
            height: 60,
            borderRadius: BorderRadius.circular(16),
            fallbackIcon: Icons.restaurant,
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


String _getMealImageUrl(String name) {
  final n = name.toLowerCase();
  if (n.contains('baingan') || n.contains('bharta') || n.contains('eggplant') || n.contains('sabzi')) {
    return 'https://images.unsplash.com/photo-1546833999-b9f581a1996d?q=80&w=240';
  } else if (n.contains('poha') || n.contains('upma') || n.contains('idli') || n.contains('dosa') || n.contains('uttapam') || n.contains('khichdi')) {
    return 'https://images.unsplash.com/photo-1589301760014-d929f3979dbc?q=80&w=240';
  } else if (n.contains('oat') || n.contains('porridge') || n.contains('cereal') || n.contains('muesli')) {
    return 'https://images.unsplash.com/photo-1509358271058-acd22cc93898?q=80&w=240';
  } else if (n.contains('paneer') || n.contains('palak') || n.contains('tofu')) {
    return 'https://images.unsplash.com/photo-1631452180519-c014fe946bc7?q=80&w=240';
  } else if (n.contains('roti') || n.contains('chapati') || n.contains('paratha') || n.contains('naan') || n.contains('bajra') || n.contains('bread')) {
    return 'https://images.unsplash.com/photo-1565557623262-b51c2513a641?q=80&w=240';
  } else if (n.contains('dal') || n.contains('lentil') || n.contains('sambar') || n.contains('soup') || n.contains('tadka') || n.contains('curry')) {
    return 'https://images.unsplash.com/photo-1546833999-b9f581a1996d?q=80&w=240';
  } else if (n.contains('chana') || n.contains('chickpea') || n.contains('rajma') || n.contains('bean') || n.contains('sprout')) {
    return 'https://images.unsplash.com/photo-1546833999-b9f581a1996d?q=80&w=240';
  } else if (n.contains('rice') || n.contains('biryani') || n.contains('pulao')) {
    return 'https://images.unsplash.com/photo-1563379091339-03b21ab4a4f8?q=80&w=240';
  } else if (n.contains('nut') || n.contains('almond') || n.contains('walnut') || n.contains('seed')) {
    return 'https://images.unsplash.com/photo-1546833999-b9f581a1996d?q=80&w=240';
  } else if (n.contains('salad') || n.contains('cucumber') || n.contains('green')) {
    return 'https://images.unsplash.com/photo-1512621776951-a57141f2eefd?q=80&w=240';
  } else if (n.contains('yogurt') || n.contains('curd') || n.contains('smoothie') || n.contains('shake') || n.contains('lassi')) {
    return 'https://images.unsplash.com/photo-1488477181946-6428a0291777?q=80&w=240';
  } else if (n.contains('egg') || n.contains('omelette') || n.contains('scramble') || n.contains('bhurji')) {
    return 'https://images.unsplash.com/photo-1525351484163-7529414344d8?q=80&w=240';
  } else if (n.contains('chicken') || n.contains('turkey') || n.contains('meat') || n.contains('kebab')) {
    return 'https://images.unsplash.com/photo-1598515214211-89d3c73ae83b?q=80&w=240';
  } else if (n.contains('fish') || n.contains('salmon') || n.contains('tuna')) {
    return 'https://images.unsplash.com/photo-1467003909585-2f8a72700288?q=80&w=240';
  } else if (n.contains('fruit') || n.contains('apple') || n.contains('banana') || n.contains('berry')) {
    return 'https://images.unsplash.com/photo-1490818387583-1baba5e638af?q=80&w=240';
  }
  return 'https://images.unsplash.com/photo-1546069901-ba9599a7e63c?q=80&w=240';
}
