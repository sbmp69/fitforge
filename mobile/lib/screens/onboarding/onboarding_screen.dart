import 'dart:async';
import 'dart:ui' as ui;
import 'package:intl/intl.dart' hide TextDirection;
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../services/supabase_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/constants.dart';
import '../../core/theme.dart';
import '../../models/onboarding_data.dart';
import 'dart:convert';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _pageController = PageController();
  int _currentStep = 0;

  @override
  void initState() {
    super.initState();
    _loadExistingProfile();
  }

  Future<void> _loadExistingProfile() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user != null) {
      try {
        final profile = await SupabaseService().getProfile();
        if (profile != null && mounted) {
          setState(() {
            if (profile.heightCm != null) _data.heightCm = profile.heightCm!;
            if (profile.weightKg != null) _data.currentWeightKg = profile.weightKg!;
            if (profile.targetWeightKg != null) _data.targetWeightKg = profile.targetWeightKg!;
            if (profile.gender != null) _data.gender = profile.gender!;
            if (profile.primaryGoal != null) _data.goal = profile.primaryGoal!;
            if (profile.fitnessLevel != null) _data.fitnessLevel = profile.fitnessLevel!;
            if (profile.country != null) _data.country = profile.country!;
            if (profile.mealPreference != null) _data.mealPreference = profile.mealPreference!;
            if (profile.targetFocusAreas.isNotEmpty) _data.targetFocusAreas = List.from(profile.targetFocusAreas);
            if (profile.injuries.isNotEmpty) _data.injuries = List.from(profile.injuries);
            if (profile.equipment.isNotEmpty) _data.equipment = List.from(profile.equipment);
            if (profile.workoutDays.isNotEmpty) _data.workoutDays = List.from(profile.workoutDays);
            if (profile.dateOfBirth != null) {
              final age = DateTime.now().year - profile.dateOfBirth!.year;
              if (age > 10 && age < 100) _data.age = age.toInt();
            }
          });
        }
      } catch (_) {}
    }
  }
  final int _totalSteps = 18;
  final OnboardingData _data = OnboardingData();

  bool _isAnalyzing = false;
  bool _showTeaser = false;
  double _analysisProgress = 0.0;
  String _analysisText = 'Calculating caloric surplus/deficit...';
  Timer? _analysisTimer;

  @override
  void dispose() {
    _analysisTimer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  void _startAnalyzing() {
    setState(() {
      _isAnalyzing = true;
      _showTeaser = false;
      _analysisProgress = 0.0;
      _analysisText = 'Calculating caloric surplus/deficit...';
    });

    _analysisTimer?.cancel();
    _analysisTimer = Timer.periodic(const Duration(milliseconds: 50), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      setState(() {
        _analysisProgress += 0.016; // Reaches 1.0 in ~3.1 seconds
        if (_analysisProgress < 0.35) {
          _analysisText = 'Calculating caloric surplus/deficit...';
        } else if (_analysisProgress < 0.70) {
          _analysisText = 'Designing optimal workout split...';
        } else if (_analysisProgress < 0.95) {
          _analysisText = 'Generating meal schedule...';
        } else {
          _analysisText = 'Personalizing your roadmap...';
        }

        if (_analysisProgress >= 1.0) {
          _analysisProgress = 1.0;
          timer.cancel();
          Future.delayed(const Duration(milliseconds: 300), () {
            if (mounted) {
              setState(() {
                _isAnalyzing = false;
                _showTeaser = true;
              });
            }
          });
        }
      });
    });
  }

  DateTime _calculateProjectedDate() {
    final current = _data.currentWeightKg;
    final target = _data.targetWeightKg;
    final diff = (current - target).abs();

    double weeklyRate = 0.5;
    final pace = _data.targetPace.toLowerCase();
    if (pace.contains('fast') || pace.contains('aggressive')) {
      weeklyRate = 0.75;
    } else if (pace.contains('steady') || pace.contains('slow')) {
      weeklyRate = 0.35;
    }

    int weeks = (diff / weeklyRate).ceil();
    if (weeks < 4) weeks = 4;
    if (weeks > 52) weeks = 52;
    return DateTime.now().add(Duration(days: weeks * 7));
  }

  int _calculateDailyCalories() {
    final w = _data.currentWeightKg > 0 ? _data.currentWeightKg : 70.0;
    final h = _data.heightCm > 0 ? _data.heightCm : 175;
    final a = _data.age > 0 ? _data.age : 25;
    final isMale = _data.gender.toLowerCase() == 'male';

    double bmr = 10 * w + 6.25 * h - 5 * a + (isMale ? 5 : -161);
    double tdee = bmr * 1.35;

    final goal = _data.goal.toLowerCase();
    if (goal.contains('lose') || goal.contains('loss')) {
      return (tdee - 450).round();
    } else if (goal.contains('gain') || goal.contains('muscle') || goal.contains('bulk')) {
      return (tdee + 350).round();
    }
    return tdee.round();
  }

  void _nextPage() {
    if (_currentStep < _totalSteps - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeInOut,
      );
    } else {
      _startAnalyzing();
    }
  }

  void _prevPage() {
    if (_currentStep > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeInOut,
      );
    }
  }

  Future<void> _finishOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(AppConstants.onboardingKey, true);
    await prefs.setString('pending_onboarding_data', jsonEncode(_data.toJson()));
    
    final loggedIn = Supabase.instance.client.auth.currentSession != null;
    if (loggedIn) {
      await SupabaseService().savePendingOnboardingProfile();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Fitness assessment updated successfully!')),
        );
        context.go('/profile');
      }
    } else {
      if (mounted) {
        context.go('/signup');
      }
    }
  }
  @override
  Widget build(BuildContext context) {
    if (_isAnalyzing) {
      return _buildAnalyzingScreen();
    }
    if (_showTeaser) {
      return _buildTeaserScreen();
    }

    final progress = (_currentStep + 1) / _totalSteps;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            // Top App Bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  if (_currentStep > 0)
                    IconButton(
                      icon: const Icon(Icons.arrow_back_ios_new, size: 20, color: AppColors.textHeader),
                      onPressed: _prevPage,
                    )
                  else if (Supabase.instance.client.auth.currentSession != null)
                    IconButton(
                      icon: const Icon(Icons.close, size: 22, color: AppColors.textHeader),
                      onPressed: () => context.go('/profile'),
                    )
                  else
                    const SizedBox(width: 48),
                  Expanded(
                    child: Center(
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: AppColors.primary,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: const Icon(Icons.bolt, color: Colors.white, size: 16),
                          ),
                          const SizedBox(width: 6),
                          const Text(
                            'FitForge',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w900,
                              color: AppColors.textHeader,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  if (Supabase.instance.client.auth.currentSession == null)
                    TextButton(
                      onPressed: () => context.go('/login'),
                      child: const Text('Log In', style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold)),
                    )
                  else
                    IconButton(
                      icon: const Icon(Icons.close, size: 22, color: AppColors.textHeader),
                      onPressed: () => context.go('/profile'),
                    ),
                ],
              ),
            ),
            // Progress Bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 4),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: progress,
                  minHeight: 4,
                  backgroundColor: AppColors.border,
                  valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary),
                ),
              ),
            ),
            Expanded(
              child: PageView(
                controller: _pageController,
                physics: const NeverScrollableScrollPhysics(),
                onPageChanged: (idx) => setState(() => _currentStep = idx),
                children: [
                  _buildGenderStep(),
                  _buildFitnessGoalStep(),
                  _buildWeightLossHistoryStep(),
                  _buildFocusAreasStep(),
                  _buildAgeStep(),
                  _buildHeightStep(),
                  _buildWeightStep(),
                  _buildPaceStep(),
                  _buildCurrentBodyFatStep(),
                  _buildWeightPredictionStep(),
                  _buildDesiredBodyFatStep(),
                  _buildLifestyleIssuesStep(),
                  _buildInjuriesStep(),
                  _buildFitnessLevelStep(),
                  _buildEquipmentStep(),
                  _buildMealPreferenceStep(),
                  _buildCountryStep(),
                  _buildScheduleStep(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- Step 1: Gender ---
  Widget _buildGenderStep() {
    return _StepContainer(
      title: "Let's Start with the Basics",
      subtitle: "We'll tailor your plan based on your gender for better results",
      child: Column(
        children: [
          _SelectableOptionCard(
            title: 'Male',
            icon: Icons.male,
            isSelected: _data.gender == 'Male',
            onTap: () {
              setState(() => _data.gender = 'Male');
              _nextPage();
            },
          ),
          const SizedBox(height: 14),
          _SelectableOptionCard(
            title: 'Female',
            icon: Icons.female,
            isSelected: _data.gender == 'Female',
            onTap: () {
              setState(() => _data.gender = 'Female');
              _nextPage();
            },
          ),
          const SizedBox(height: 14),
          _SelectableOptionCard(
            title: 'Prefer not to say',
            icon: Icons.transgender,
            isSelected: _data.gender == 'Other',
            onTap: () {
              setState(() => _data.gender = 'Other');
              _nextPage();
            },
          ),
        ],
      ),
    );
  }

  // --- Step 2: Fitness Goal ---
  Widget _buildFitnessGoalStep() {
    return _StepContainer(
      title: "What's your fitness goal?",
      subtitle: "Your goal is our roadmap, let's make it happen!",
      child: Row(
        children: [
          Expanded(
            child: _GoalVisualCard(
              title: 'Weight Loss',
              icon: Icons.monitor_weight_outlined,
              isSelected: _data.goal == 'weight_loss',
              onTap: () {
                setState(() => _data.goal = 'weight_loss');
                _nextPage();
              },
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: _GoalVisualCard(
              title: 'Muscle Build',
              icon: Icons.fitness_center,
              isSelected: _data.goal == 'build_muscle',
              onTap: () {
                setState(() => _data.goal = 'build_muscle');
                _nextPage();
              },
            ),
          ),
        ],
      ),
    );
  }

  // --- Step 3: Weight Loss History ---
  Widget _buildWeightLossHistoryStep() {
    final options = [
      {'key': 'succeeded_improve', 'title': 'Succeeded, Want to Improve', 'icon': Icons.trending_up},
      {'key': 'succeeded_rebound', 'title': 'Succeeded but Rebounded', 'icon': Icons.replay},
      {'key': 'tried_failed', 'title': 'Tried but Failed', 'icon': Icons.sentiment_dissatisfied},
      {'key': 'never_tried', 'title': 'Never Tried', 'icon': Icons.fiber_new},
    ];

    return _StepContainer(
      title: "Have you tried losing weight? Results?",
      subtitle: "Understanding your past helps us build habits that actually stick.",
      child: GridView.count(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 1.05,
        children: options.map((opt) {
          final isSelected = _data.weightLossHistory == opt['key'];
          return InkWell(
            onTap: () {
              setState(() => _data.weightLossHistory = opt['key'] as String);
              _nextPage();
            },
            borderRadius: BorderRadius.circular(16),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isSelected ? AppColors.primaryLight : AppColors.surface,
                border: Border.all(
                  color: isSelected ? AppColors.primary : AppColors.border,
                  width: isSelected ? 2 : 1,
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: isSelected ? AppColors.primary : AppColors.primaryLight,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(opt['icon'] as IconData, color: isSelected ? Colors.white : AppColors.primary, size: 28),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    opt['title'] as String,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: isSelected ? AppColors.primary : AppColors.textHeader,
                    ),
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  // --- Step 4: Focus Areas (Real Bodybuilder with Glowing Muscle Highlights) ---
  Widget _buildFocusAreasStep() {
    final muscleGroups = ['Back', 'Chest', 'Arms', 'Abs', 'Glutes', 'Leg', 'Full Body'];

    return _StepContainer(
      title: "Which areas do you want to focus on?",
      subtitle: "Select target zones on the physique to customize workout recommendations.",
      bottomAction: _PrimaryButton(title: 'CONTINUE', onPressed: _nextPage),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Real Bodybuilder Silhouette with Interactive Glowing Muscles
          Expanded(
            flex: 5,
            child: Container(
              height: 400,
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppColors.border),
              ),
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: FittedBox(
                  fit: BoxFit.contain,
                  child: SizedBox(
                    width: 896,
                    height: 1200,
                    child: Stack(
                      children: [
                        // Real Bodybuilder Image
                        Image.asset(
                          'assets/images/bodybuilder_physique.png',
                          width: 896,
                          height: 1200,
                          fit: BoxFit.fill,
                        ),
                        // Glowing Muscle Highlight Overlay
                        Positioned.fill(
                          child: CustomPaint(
                            painter: _RealBodybuilderGlowPainter(
                              selectedAreas: _data.targetFocusAreas,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          // Target Muscle Selection Buttons
          Expanded(
            flex: 5,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: muscleGroups.map((group) {
                final isSelected = _data.targetFocusAreas.contains(group);
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: InkWell(
                    onTap: () {
                      setState(() {
                        if (group == 'Full Body') {
                          _data.targetFocusAreas = ['Full Body'];
                        } else {
                          _data.targetFocusAreas.remove('Full Body');
                          if (isSelected) {
                            _data.targetFocusAreas.remove(group);
                          } else {
                            _data.targetFocusAreas.add(group);
                          }
                          if (_data.targetFocusAreas.isEmpty) {
                            _data.targetFocusAreas.add('Full Body');
                          }
                        }
                      });
                    },
                    borderRadius: BorderRadius.circular(14),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
                      decoration: BoxDecoration(
                        color: isSelected ? AppColors.primary : AppColors.surface,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: isSelected ? AppColors.primary : AppColors.border,
                          width: isSelected ? 2 : 1,
                        ),
                        boxShadow: isSelected
                            ? [
                                BoxShadow(
                                  color: AppColors.primary.withOpacity(0.35),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                )
                              ]
                            : null,
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              group,
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: isSelected ? Colors.white : AppColors.textHeader,
                              ),
                            ),
                          ),
                          if (isSelected)
                            const Icon(Icons.check_circle_rounded, color: Colors.white, size: 18),
                        ],
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  // --- Step 5: Age Wheel Picker ---
  Widget _buildAgeStep() {
    return _StepContainer(
      title: "Your age",
      subtitle: "Age information helps us more accurately assess your metabolic level",
      bottomAction: _PrimaryButton(title: 'CONTINUE', onPressed: _nextPage),
      child: Center(
        child: SizedBox(
          height: 250,
          child: CupertinoPicker(
            scrollController: FixedExtentScrollController(initialItem: _data.age - 14),
            itemExtent: 50,
            onSelectedItemChanged: (idx) {
              setState(() => _data.age = idx + 14);
            },
            selectionOverlay: Container(
              decoration: BoxDecoration(
                border: Border.symmetric(
                  horizontal: BorderSide(color: AppColors.primary.withValues(alpha: 0.5), width: 1.5),
                ),
              ),
            ),
            children: List.generate(70, (idx) {
              final ageVal = idx + 14;
              final isSelected = ageVal == _data.age;
              return Center(
                child: Text(
                  '$ageVal years old',
                  style: TextStyle(
                    fontSize: isSelected ? 24 : 18,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    color: isSelected ? AppColors.primary : AppColors.textSecondary,
                  ),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }

  // --- Step 6: Height (Real Bodybuilder Character Stadiometer) ---
  Widget _buildHeightStep() {
    final ft = (_data.heightCm / 30.48);
    final feet = ft.floor();
    final inches = ((ft - feet) * 12).round();

    return _StepContainer(
      title: "Your height",
      subtitle: "Height information helps us calculate your BMI and frame metrics accurately",
      bottomAction: _PrimaryButton(title: 'CONTINUE', onPressed: _nextPage),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                '${_data.heightCm}',
                style: const TextStyle(fontSize: 48, fontWeight: FontWeight.bold, color: AppColors.textHeader),
              ),
              const SizedBox(width: 6),
              const Text('cm', style: TextStyle(fontSize: 20, color: AppColors.textSecondary, fontWeight: FontWeight.bold)),
              const SizedBox(width: 14),
              Text('($feet\' $inches\")', style: const TextStyle(fontSize: 16, color: AppColors.textSecondary, fontWeight: FontWeight.w600)),
            ],
          ),
          const SizedBox(height: 8),
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              activeTrackColor: AppColors.primary,
              inactiveTrackColor: AppColors.border,
              thumbColor: AppColors.primary,
              trackHeight: 6,
            ),
            child: Slider(
              value: _data.heightCm.toDouble(),
              min: 130,
              max: 220,
              onChanged: (val) => setState(() => _data.heightCm = val.round()),
            ),
          ),
          const SizedBox(height: 12),
          // Dynamic Stadiometer Graphic with Real Bodybuilder Silhouette
          Expanded(
            child: _HeightStadiometer(heightCm: _data.heightCm),
          ),
        ],
      ),
    );
  }

  // --- Step 7: Weight & Accurate Functional BMI Gauge ---
  Widget _buildWeightStep() {
    final bmi = _data.bmi;
    final category = _data.bmiCategory;
    final normalizedPointer = ((bmi - 15.0) / 25.0).clamp(0.0, 1.0);

    Color categoryColor = AppColors.primary;
    if (category == 'Underweight') categoryColor = Colors.blueAccent;
    if (category == 'Overweight') categoryColor = Colors.orangeAccent;
    if (category == 'Obese') categoryColor = Colors.redAccent;

    return _StepContainer(
      title: "Your current weight",
      subtitle: "Weight helps us establish your baseline energy requirements.",
      bottomAction: _PrimaryButton(title: 'CONTINUE', onPressed: _nextPage),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                _data.currentWeightKg.toStringAsFixed(1),
                style: const TextStyle(fontSize: 48, fontWeight: FontWeight.bold, color: AppColors.textHeader),
              ),
              const SizedBox(width: 6),
              const Text('kg', style: TextStyle(fontSize: 20, color: AppColors.textSecondary, fontWeight: FontWeight.bold)),
            ],
          ),
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              activeTrackColor: AppColors.primary,
              inactiveTrackColor: AppColors.border,
              thumbColor: AppColors.primary,
              trackHeight: 6,
            ),
            child: Slider(
              value: _data.currentWeightKg,
              min: 40,
              max: 160,
              onChanged: (val) => setState(() => _data.currentWeightKg = double.parse(val.toStringAsFixed(1))),
            ),
          ),
          const SizedBox(height: 24),
          // Accurate Functional Dynamic BMI Card
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.border),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.03),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Calculated BMI', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textHeader)),
                        const SizedBox(height: 2),
                        Text(
                          'Category: $category',
                          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: categoryColor),
                        ),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                      decoration: BoxDecoration(
                        color: categoryColor,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        bmi.toStringAsFixed(1),
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                // Dynamic Sliding Pointer on Spectrum Bar
                LayoutBuilder(
                  builder: (context, constraints) {
                    final width = constraints.maxWidth;
                    final pointerX = (width * normalizedPointer).clamp(0.0, width - 12);
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          margin: EdgeInsets.only(left: pointerX),
                          child: Icon(Icons.arrow_drop_down, color: categoryColor, size: 24),
                        ),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(6),
                          child: Row(
                            children: [
                              Expanded(flex: 3, child: Container(height: 10, color: Colors.blueAccent)),
                              Expanded(flex: 5, child: Container(height: 10, color: AppColors.primary)),
                              Expanded(flex: 4, child: Container(height: 10, color: Colors.orangeAccent)),
                              Expanded(flex: 2, child: Container(height: 10, color: Colors.redAccent)),
                            ],
                          ),
                        ),
                      ],
                    );
                  },
                ),
                const SizedBox(height: 8),
                const Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('< 18.5', style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                    Text('18.5 - 24.9', style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                    Text('25 - 29.9', style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                    Text('30+', style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                  ],
                ),
                const SizedBox(height: 14),
                Text(
                  category == 'Normal'
                      ? 'You are currently in the healthy weight zone! FitForge will focus on muscle definition and metabolic conditioning.'
                      : category == 'Underweight'
                          ? 'Your BMI indicates you may benefit from calorie surplus nutrition and progressive hypertrophy resistance training.'
                          : 'FitForge will structure a progressive calorie deficit and high-efficiency metabolic training to safely lower fat mass.',
                  style: const TextStyle(fontSize: 13, color: AppColors.textSecondary, height: 1.4),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // --- Step 8: Desired Pace (High-Energy, Rich Visual Cards) ---
  Widget _buildPaceStep() {
    final options = [
      {
        'key': 'fast',
        'title': 'Fast & Intense',
        'tag': 'RAPID TRANSFORMATION',
        'rate': '0.8 - 1.0 kg / week',
        'desc': 'Targeted caloric deficit & progressive volume for quickest transformation.',
        'icon': Icons.bolt_rounded,
        'badgeColor': const Color(0xFFFF9800),
      },
      {
        'key': 'normal',
        'title': 'Normal Pace is OK',
        'tag': 'RECOMMENDED • SUSTAINABLE',
        'rate': '0.5 kg / week',
        'desc': 'Balanced progression with optimal muscle preservation and lowest rebound risk.',
        'icon': Icons.speed_rounded,
        'badgeColor': AppColors.primary,
      },
      {
        'key': 'steady',
        'title': 'Steady & Gradual',
        'tag': 'GENTLE & INJURY-FREE',
        'rate': '0.25 kg / week',
        'desc': 'Gentle habit building suited for busy schedules with zero burnout.',
        'icon': Icons.spa_rounded,
        'badgeColor': const Color(0xFF00B4D8),
      },
      {
        'key': 'ai_decide',
        'title': 'Let FitForge Decide',
        'tag': 'AI SMART ADAPTIVE',
        'rate': 'Dynamic auto-tuning',
        'desc': 'FitForge AI monitors weekly recovery, sleep, and weights to auto-calibrate pace.',
        'icon': Icons.auto_awesome_rounded,
        'badgeColor': const Color(0xFF8338EC),
      },
    ];

    return _StepContainer(
      title: "What Pace Would You Like To Achieve Your Goal?",
      subtitle: "Choose the intensity that best matches your daily schedule and stamina.",
      child: Column(
        children: options.map((opt) {
          final isSelected = _data.targetPace == opt['key'];
          final badgeColor = opt['badgeColor'] as Color;

          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: InkWell(
              onTap: () {
                setState(() => _data.targetPace = opt['key'] as String);
                _nextPage();
              },
              borderRadius: BorderRadius.circular(16),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: isSelected ? AppColors.primaryLight : AppColors.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isSelected ? AppColors.primary : AppColors.border,
                    width: isSelected ? 2 : 1,
                  ),
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                            color: AppColors.primary.withOpacity(0.15),
                            blurRadius: 10,
                            offset: const Offset(0, 3),
                          )
                        ]
                      : null,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: badgeColor.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(opt['icon'] as IconData, color: badgeColor, size: 22),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Text(
                                    opt['title'] as String,
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: isSelected ? AppColors.primary : AppColors.textHeader,
                                    ),
                                  ),
                                  const Spacer(),
                                  if (isSelected)
                                    const Icon(Icons.check_circle_rounded, color: AppColors.primary, size: 20),
                                ],
                              ),
                              const SizedBox(height: 3),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: badgeColor.withOpacity(0.12),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  opt['tag'] as String,
                                  style: TextStyle(
                                    fontSize: 9,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: 0.8,
                                    color: badgeColor,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Icon(Icons.trending_down, size: 14, color: AppColors.textSecondary),
                        const SizedBox(width: 4),
                        Text(
                          'Pace: ${opt['rate']}',
                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.textHeader),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      opt['desc'] as String,
                      style: const TextStyle(fontSize: 12, color: AppColors.textSecondary, height: 1.3),
                    ),
                  ],
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  String _getPhysiqueAssetForBodyFat(String bf) {
    switch (bf) {
      case '<15%':
      case '10%':
      case '15%':
        return 'assets/images/physique_lean.png';
      case '20%':
        return 'assets/images/physique_fit.png';
      case '25%':
        return 'assets/images/physique_average.png';
      case '30%':
      case '35%':
        return 'assets/images/physique_stocky.png';
      case '>40%':
      case '40%':
      default:
        return 'assets/images/physique_heavy.png';
    }
  }

  Widget _buildBodyFatSelectorRow({
    required List<String> tiers,
    required String selectedTier,
    required ValueChanged<String> onSelected,
  }) {
    return Row(
      children: tiers.map((t) {
        final isSel = selectedTier == t || (selectedTier == '15%' && t == '<15%');
        return Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 3),
            child: InkWell(
              onTap: () => onSelected(t),
              borderRadius: BorderRadius.circular(10),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                padding: const EdgeInsets.symmetric(vertical: 11),
                decoration: BoxDecoration(
                  color: isSel ? AppColors.primary : AppColors.surface,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: isSel ? AppColors.primary : AppColors.border,
                    width: isSel ? 1.5 : 1.0,
                  ),
                  boxShadow: isSel
                      ? [
                          BoxShadow(
                            color: AppColors.primary.withOpacity(0.3),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          ),
                        ]
                      : null,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (isSel) ...[
                      const Icon(Icons.check, size: 14, color: Colors.white),
                      const SizedBox(width: 3),
                    ],
                    Text(
                      t,
                      style: TextStyle(
                        color: isSel ? Colors.white : AppColors.textHeader,
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  // --- Step 9: Dynamic Current Body Shape Visualizer ---
  Widget _buildCurrentBodyFatStep() {
    final tiers = ['<15%', '20%', '25%', '30%', '>40%'];

    return _StepContainer(
      title: "Choose your current body shape",
      subtitle: "Estimating current body composition helps us dial in macronutrient splits.",
      bottomAction: _PrimaryButton(title: 'CONTINUE', onPressed: _nextPage),
      child: Column(
        children: [
          Expanded(
            child: Center(
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: AppColors.border),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Dynamic Real Character reflecting chosen body fat
                    Expanded(
                      child: Center(
                        child: AnimatedSwitcher(
                          duration: const Duration(milliseconds: 250),
                          transitionBuilder: (child, animation) => FadeTransition(
                            opacity: animation,
                            child: ScaleTransition(
                              scale: Tween<double>(begin: 0.94, end: 1.0).animate(animation),
                              child: child,
                            ),
                          ),
                          child: ClipRRect(
                            key: ValueKey(_data.currentBodyFat),
                            borderRadius: BorderRadius.circular(16),
                            child: Image.asset(
                              _getPhysiqueAssetForBodyFat(_data.currentBodyFat),
                              fit: BoxFit.contain,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    Text(
                      'Estimated Body Fat: ${_data.currentBodyFat}',
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textHeader),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      _getBodyFatDescription(_data.currentBodyFat),
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          _buildBodyFatSelectorRow(
            tiers: tiers,
            selectedTier: _data.currentBodyFat,
            onSelected: (t) => setState(() => _data.currentBodyFat = t),
          ),
        ],
      ),
    );
  }

  String _getBodyFatDescription(String bf) {
    switch (bf) {
      case '<15%':
        return 'Athletic / Lean: Visible abdominal definition and vascularity.';
      case '20%':
        return 'Fit / Healthy: Solid muscle tone with moderate subcutaneous layer.';
      case '25%':
        return 'Average: Everyday physique with room for metabolic improvement.';
      case '30%':
        return 'Soft: Excess fat accumulation around waist and abdomen.';
      case '>40%':
        return 'High: Higher adiposity requiring structured caloric management.';
      default:
        return 'Standard physique.';
    }
  }

  // --- Step 10: Target Date Prediction Graph (Interactive Realistic Timeline) ---
  Widget _buildWeightPredictionStep() {
    final date = _data.predictedTargetDate;
    final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    final dateStr = '${months[date.month - 1]} ${date.day}';

    return _StepContainer(
      title: "We predict that you'll be",
      subtitle: "Interactive predictive progression model tailored to your metabolism & pace.",
      bottomAction: _PrimaryButton(title: 'CONTINUE', onPressed: _nextPage),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                '${_data.targetWeightKg.round()}kg on ',
                style: const TextStyle(fontSize: 30, fontWeight: FontWeight.bold, color: AppColors.textHeader),
              ),
              Text(
                dateStr,
                style: const TextStyle(fontSize: 30, fontWeight: FontWeight.bold, color: AppColors.primary),
              ),
            ],
          ),
          const SizedBox(height: 20),
          // Interactive Realistic Fitness Curve Graph
          _InteractivePredictionGraph(
            startWeight: _data.currentWeightKg,
            targetWeight: _data.targetWeightKg,
            targetDateStr: dateStr,
          ),
          const SizedBox(height: 18),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: AppColors.primaryLight.withOpacity(0.5),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.primary.withOpacity(0.25)),
            ),
            child: const Row(
              children: [
                Icon(Icons.touch_app_rounded, color: AppColors.primary, size: 18),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Touch and drag along the curve to inspect weekly weight milestones!',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.primary),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            'Based on your metabolism and schedule, this realistic progression safeguards muscle while burning stubborn fat.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 13, color: AppColors.textSecondary, height: 1.4),
          ),
        ],
      ),
    );
  }

  // --- Step 11: Dynamic Desired Body Shape Visualizer ---
  Widget _buildDesiredBodyFatStep() {
    final tiers = ['<15%', '20%', '25%'];

    return _StepContainer(
      title: "Choose your desired body shape",
      subtitle: "Where do you want FitForge to take your physique?",
      bottomAction: _PrimaryButton(title: 'CONTINUE', onPressed: _nextPage),
      child: Column(
        children: [
          Expanded(
            child: Center(
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: AppColors.border),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Dynamic Real Character reflecting desired target body fat
                    Expanded(
                      child: Center(
                        child: AnimatedSwitcher(
                          duration: const Duration(milliseconds: 250),
                          transitionBuilder: (child, animation) => FadeTransition(
                            opacity: animation,
                            child: ScaleTransition(
                              scale: Tween<double>(begin: 0.94, end: 1.0).animate(animation),
                              child: child,
                            ),
                          ),
                          child: ClipRRect(
                            key: ValueKey(_data.desiredBodyFat),
                            borderRadius: BorderRadius.circular(16),
                            child: Image.asset(
                              _getPhysiqueAssetForBodyFat(_data.desiredBodyFat),
                              fit: BoxFit.contain,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    Text(
                      'Target Physique: ${_data.desiredBodyFat}',
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textHeader),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      _getBodyFatDescription(_data.desiredBodyFat),
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          _buildBodyFatSelectorRow(
            tiers: tiers,
            selectedTier: _data.desiredBodyFat,
            onSelected: (t) => setState(() => _data.desiredBodyFat = t),
          ),
        ],
      ),
    );
  }

  // --- Step 12: Lifestyle Issues ---
  Widget _buildLifestyleIssuesStep() {
    final issues = [
      {'title': 'Prolonged sitting', 'icon': Icons.chair},
      {'title': 'Poor sleep quality', 'icon': Icons.bedtime},
      {'title': 'Dietary issues', 'icon': Icons.restaurant_menu},
      {'title': "None, I'm healthy!", 'icon': Icons.sentiment_very_satisfied},
    ];

    return _StepContainer(
      title: "Do you experience any of the following issues?",
      subtitle: "We'll program mobility and corrective balance into your routines.",
      bottomAction: _PrimaryButton(title: 'CONTINUE', onPressed: _nextPage),
      child: Column(
        children: issues.map((item) {
          final title = item['title'] as String;
          final isSelected = _data.lifestyleIssues.contains(title);
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: InkWell(
              onTap: () {
                setState(() {
                  if (title.startsWith('None')) {
                    _data.lifestyleIssues = [title];
                  } else {
                    _data.lifestyleIssues.remove("None, I'm healthy!");
                    if (isSelected) {
                      _data.lifestyleIssues.remove(title);
                    } else {
                      _data.lifestyleIssues.add(title);
                    }
                  }
                });
              },
              borderRadius: BorderRadius.circular(16),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                decoration: BoxDecoration(
                  color: isSelected ? AppColors.primaryLight : AppColors.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isSelected ? AppColors.primary : AppColors.border,
                    width: isSelected ? 2 : 1,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(item['icon'] as IconData, color: isSelected ? AppColors.primary : AppColors.textSecondary),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Text(
                        title,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: isSelected ? AppColors.primary : AppColors.textHeader,
                        ),
                      ),
                    ),
                    if (isSelected) const Icon(Icons.check_circle, color: AppColors.primary, size: 20),
                  ],
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  // --- Step 13: Injuries (3D Anatomical Visual Cards - Zero Cognitive Load) ---
  Widget _buildInjuriesStep() {
    final injuryItems = [
      {
        'key': 'No injuries',
        'title': 'No injuries',
        'subtitle': '100% healthy & pain-free',
        'image': 'assets/images/injury_none.png',
      },
      {
        'key': 'Shoulders',
        'title': 'Shoulders',
        'subtitle': 'Rotator cuff & deltoids',
        'image': 'assets/images/injury_shoulder.png',
      },
      {
        'key': 'Back',
        'title': 'Back',
        'subtitle': 'Spine & lower lumbar',
        'image': 'assets/images/injury_back.png',
      },
      {
        'key': 'Waist',
        'title': 'Waist & Core',
        'subtitle': 'Lower torso & obliques',
        'image': 'assets/images/injury_waist.png',
      },
      {
        'key': 'Wrist',
        'title': 'Wrist & Hand',
        'subtitle': 'Carpal joints & tendons',
        'image': 'assets/images/injury_wrist.png',
      },
      {
        'key': 'Knee',
        'title': 'Knee',
        'subtitle': 'Patella & ligaments',
        'image': 'assets/images/injury_knee.png',
      },
    ];

    return _StepContainer(
      title: "Have you suffered any injuries recently?",
      subtitle: "Your safety is paramount. We will strictly filter hazardous exercises.",
      bottomAction: _PrimaryButton(title: 'CONTINUE', onPressed: _nextPage),
      child: GridView.count(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 1.15,
        children: injuryItems.map((item) {
          final key = item['key'] as String;
          final isSelected = _data.injuries.contains(key);

          return InkWell(
            onTap: () {
              setState(() {
                if (key == 'No injuries') {
                  _data.injuries = ['No injuries'];
                } else {
                  _data.injuries.remove('No injuries');
                  if (isSelected) {
                    _data.injuries.remove(key);
                  } else {
                    _data.injuries.add(key);
                  }
                  if (_data.injuries.isEmpty) _data.injuries.add('No injuries');
                }
              });
            },
            borderRadius: BorderRadius.circular(16),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: isSelected ? AppColors.primaryLight : AppColors.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isSelected ? AppColors.primary : AppColors.border,
                  width: isSelected ? 2 : 1,
                ),
                boxShadow: isSelected
                    ? [
                        BoxShadow(
                          color: AppColors.primary.withOpacity(0.18),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        )
                      ]
                    : null,
              ),
              child: Stack(
                children: [
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // 3D Anatomical Illustration
                      Image.asset(
                        item['image'] as String,
                        height: 52,
                        fit: BoxFit.contain,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        item['title'] as String,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: isSelected ? AppColors.primary : AppColors.textHeader,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        item['subtitle'] as String,
                        style: const TextStyle(
                          fontSize: 10,
                          color: AppColors.textSecondary,
                        ),
                        textAlign: TextAlign.center,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                  // Selection Checkmark Badge
                  Positioned(
                    top: 0,
                    right: 0,
                    child: Container(
                      width: 20,
                      height: 20,
                      decoration: BoxDecoration(
                        color: isSelected ? AppColors.primary : Colors.transparent,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: isSelected ? AppColors.primary : AppColors.border,
                          width: 1.5,
                        ),
                      ),
                      child: isSelected
                          ? const Icon(Icons.check, size: 14, color: Colors.white)
                          : null,
                    ),
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  // --- Step 14: Fitness Level ---
  Widget _buildFitnessLevelStep() {
    final levels = [
      {
        'level': 'Beginner',
        'badge': 'LEVEL 1 • FOUNDATION',
        'subtitle': 'New to working out or rebuilding routine after a long break',
        'frequency': '2 - 3 workouts / week',
        'focus': 'Mastering exercise form, core stability & endurance',
        'pips': 1,
        'icon': Icons.spa_rounded,
        'color': const Color(0xFF10B981),
      },
      {
        'level': 'Intermediate',
        'badge': 'LEVEL 2 • ACCELERATOR',
        'subtitle': 'Train consistently with solid knowledge of fundamental lifts',
        'frequency': '3 - 5 workouts / week',
        'focus': 'Progressive overload, muscle hypertrophy & strength',
        'pips': 2,
        'icon': Icons.fitness_center_rounded,
        'color': const Color(0xFF059669),
      },
      {
        'level': 'Advanced',
        'badge': 'LEVEL 3 • ELITE ATHLETE',
        'subtitle': 'Years of high-intensity training with solid lifting experience',
        'frequency': '5 - 6 workouts / week',
        'focus': 'Targeted periodization, peak power & maximum muscle density',
        'pips': 3,
        'icon': Icons.local_fire_department_rounded,
        'color': const Color(0xFFD97706),
      },
    ];

    return _StepContainer(
      title: "How would you rate your fitness level?",
      subtitle: "We'll tune the workout volume, sets, and rest intervals accordingly.",
      bottomAction: _PrimaryButton(title: 'CONTINUE', onPressed: _nextPage),
      child: Column(
        children: [
          ...levels.map((lvl) {
            final isSelected = _data.fitnessLevel == lvl['level'];
            final color = lvl['color'] as Color;
            final pips = lvl['pips'] as int;

            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: InkWell(
                onTap: () {
                  setState(() => _data.fitnessLevel = lvl['level'] as String);
                },
                borderRadius: BorderRadius.circular(16),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isSelected ? AppColors.primary : AppColors.border,
                      width: isSelected ? 2.0 : 1.0,
                    ),
                    boxShadow: isSelected
                        ? [
                            BoxShadow(
                              color: AppColors.primary.withOpacity(0.18),
                              blurRadius: 10,
                              offset: const Offset(0, 3),
                            ),
                          ]
                        : null,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              color: color.withOpacity(isSelected ? 0.2 : 0.1),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(lvl['icon'] as IconData, color: color, size: 22),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: color.withOpacity(0.12),
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Text(
                                        lvl['badge'] as String,
                                        style: TextStyle(
                                          color: color,
                                          fontSize: 9,
                                          fontWeight: FontWeight.w800,
                                          letterSpacing: 0.5,
                                        ),
                                      ),
                                    ),
                                    const Spacer(),
                                    // Intensity pips
                                    Row(
                                      children: List.generate(3, (idx) {
                                        final active = idx < pips;
                                        return Container(
                                          width: 8,
                                          height: 8,
                                          margin: const EdgeInsets.only(left: 3),
                                          decoration: BoxDecoration(
                                            color: active ? AppColors.primary : AppColors.border,
                                            shape: BoxShape.circle,
                                          ),
                                        );
                                      }),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  lvl['level'] as String,
                                  style: TextStyle(
                                    fontSize: 17,
                                    fontWeight: FontWeight.bold,
                                    color: isSelected ? AppColors.primary : AppColors.textHeader,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          Icon(
                            isSelected ? Icons.check_circle_rounded : Icons.radio_button_unchecked_rounded,
                            color: isSelected ? AppColors.primary : AppColors.border,
                            size: 22,
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Text(
                        lvl['subtitle'] as String,
                        style: const TextStyle(fontSize: 12, color: AppColors.textSecondary, height: 1.3),
                      ),
                      const SizedBox(height: 10),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: AppColors.background,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.calendar_today_rounded, size: 12, color: AppColors.textSecondary),
                            const SizedBox(width: 6),
                            Text(
                              lvl['frequency'] as String,
                              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.textHeader),
                            ),
                            const SizedBox(width: 12),
                            const Icon(Icons.bolt_rounded, size: 14, color: AppColors.primary),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                lvl['focus'] as String,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }),
          const SizedBox(height: 6),
          // AI Personalization Banner
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.08),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.primary.withOpacity(0.2)),
            ),
            child: Row(
              children: [
                const Icon(Icons.auto_awesome, color: AppColors.primary, size: 18),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    "FitForge AI automatically tunes starting weights, volume, and rest periods to match your tier.",
                    style: TextStyle(
                      fontSize: 11,
                      color: AppColors.textHeader.withOpacity(0.9),
                      height: 1.3,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // --- Step 15: Preferred Training Equipment ---
  Widget _buildEquipmentStep() {
    final equipCards = [
      {
        'key': 'Bodyweight',
        'title': 'Bodyweight',
        'subtitle': 'Bodyweight training.',
        'image': 'assets/images/equip_bodyweight.png',
      },
      {
        'key': 'Portable',
        'title': 'Portable',
        'subtitle': 'dumbbells, kettlebells,etc.',
        'image': 'assets/images/equip_portable.png',
      },
      {
        'key': 'Gym',
        'title': 'Gym',
        'subtitle': 'Smith machine, etc.',
        'image': 'assets/images/equip_gym.png',
      },
    ];

    return _StepContainer(
      title: "Choose your preferred training equipment",
      subtitle: "We provide over 800 exercises and 500 workouts for a wide range of equipment.",
      bottomAction: _PrimaryButton(
        title: 'CONTINUE',
        onPressed: _nextPage,
      ),
      child: Column(
        children: equipCards.map((item) {
          final key = item['key'] as String;
          final isSel = _data.equipment.contains(key);
          return Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: InkWell(
              onTap: () {
                setState(() {
                  if (isSel && _data.equipment.length > 1) {
                    _data.equipment.remove(key);
                  } else if (!isSel) {
                    _data.equipment.add(key);
                  }
                });
              },
              borderRadius: BorderRadius.circular(20),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                height: 110,
                decoration: BoxDecoration(
                  color: isSel ? AppColors.primaryLight : AppColors.surface,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isSel ? AppColors.primary : AppColors.border,
                    width: isSel ? 2 : 1,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.03),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Row(
                              children: [
                                Text(
                                  item['title'] as String,
                                  style: TextStyle(
                                    fontSize: 19,
                                    fontWeight: FontWeight.bold,
                                    color: isSel ? AppColors.primary : AppColors.textHeader,
                                  ),
                                ),
                                if (isSel) ...[
                                  const SizedBox(width: 8),
                                  const Icon(Icons.check_circle, size: 20, color: AppColors.primary),
                                ],
                              ],
                            ),
                            const SizedBox(height: 6),
                            Text(
                              item['subtitle'] as String,
                              style: const TextStyle(
                                fontSize: 13,
                                color: AppColors.textSecondary,
                                height: 1.2,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    ClipRRect(
                      borderRadius: const BorderRadius.horizontal(right: Radius.circular(19)),
                      child: SizedBox(
                        width: 125,
                        height: 110,
                        child: Image.asset(
                          item['image'] as String,
                          fit: BoxFit.cover,
                          errorBuilder: (ctx, err, stack) => Container(
                            color: AppColors.primaryLight,
                            child: const Icon(Icons.fitness_center, size: 36, color: AppColors.primary),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  // --- Step 16: Meal Preference / Cuisine ---
  Widget _buildMealPreferenceStep() {
    final options = [
      {'key': 'Traditional Indian', 'title': 'Traditional Indian', 'subtitle': 'Balanced regional curries, lentils & grains', 'icon': Icons.restaurant},
      {'key': 'High Protein', 'title': 'High Protein', 'subtitle': 'Lean meats, eggs, paneer, sprouts & fish', 'icon': Icons.fitness_center},
      {'key': 'Vegetarian', 'title': 'Vegetarian', 'subtitle': 'Pure plant & dairy based, rich in nutrition', 'icon': Icons.eco},
      {'key': 'Vegan', 'title': 'Vegan', 'subtitle': '100% plant-based, cruelty & dairy free', 'icon': Icons.spa},
      {'key': 'Keto', 'title': 'Keto / Low Carb', 'subtitle': 'Healthy fats, leafy greens & minimal carbs', 'icon': Icons.local_fire_department},
      {'key': 'Mediterranean', 'title': 'Mediterranean', 'subtitle': 'Olive oils, fresh greens, whole grains & seafood', 'icon': Icons.set_meal},
      {'key': 'No Preference', 'title': 'No Preference / Flexible', 'subtitle': 'Open to diverse and versatile wholesome meals', 'icon': Icons.all_inclusive},
    ];

    return _StepContainer(
      title: "Choose your meal preference",
      subtitle: "This preference is directly used to generate tailored AI meal plans and recipes for you.",
      bottomAction: _PrimaryButton(
        title: 'CONTINUE',
        onPressed: _nextPage,
      ),
      child: SingleChildScrollView(
        child: Column(
          children: options.map((opt) {
            final isSel = _data.mealPreference == opt['key'];
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: InkWell(
                onTap: () {
                  setState(() => _data.mealPreference = opt['key'] as String);
                  _nextPage();
                },
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: isSel ? AppColors.primaryLight : AppColors.surface,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isSel ? AppColors.primary : AppColors.border,
                      width: isSel ? 2 : 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: isSel ? AppColors.primary : AppColors.primaryLight,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(opt['icon'] as IconData, color: isSel ? Colors.white : AppColors.primary, size: 22),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              opt['title'] as String,
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: isSel ? AppColors.primary : AppColors.textHeader,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              opt['subtitle'] as String,
                              style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                            ),
                          ],
                        ),
                      ),
                      if (isSel)
                        const Icon(Icons.check_circle, color: AppColors.primary, size: 22),
                    ],
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  // --- Step 17: Country Selection ---
  Widget _buildCountryStep() {
    final countries = [
      'India',
      'United States',
      'United Kingdom',
      'Canada',
      'Australia',
      'United Arab Emirates',
      'Germany',
      'Other',
    ];

    return _StepContainer(
      title: "Where are you located?",
      subtitle: "Helps us optimize local ingredient availability and smart workout reminder timing.",
      bottomAction: _PrimaryButton(
        title: 'CONTINUE',
        onPressed: _nextPage,
      ),
      child: SingleChildScrollView(
        child: Column(
          children: countries.map((name) {
            final isSel = _data.country == name;
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: InkWell(
                onTap: () {
                  setState(() => _data.country = name);
                  _nextPage();
                },
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
                  decoration: BoxDecoration(
                    color: isSel ? AppColors.primaryLight : AppColors.surface,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isSel ? AppColors.primary : AppColors.border,
                      width: isSel ? 2 : 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: isSel ? AppColors.primary : AppColors.primaryLight,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(Icons.public, color: isSel ? Colors.white : AppColors.primary, size: 20),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Text(
                          name,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: isSel ? AppColors.primary : AppColors.textHeader,
                          ),
                        ),
                      ),
                      if (isSel)
                        const Icon(Icons.check_circle, color: AppColors.primary, size: 22),
                    ],
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  // --- Step 18: Training Schedule & Reminder ---
  Widget _buildScheduleStep() {
    final days = ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];

    return _StepContainer(
      title: "Which days will you train?",
      subtitle: "Choose your weekly workout rhythm and set training reminders.",
      bottomAction: _PrimaryButton(
        title: 'BUILD MY PERSONALIZED PLAN',
        onPressed: _startAnalyzing,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Weekly Workout Days',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.textHeader),
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: days.map((d) {
              final isSel = _data.workoutDays.contains(d);
              return FilterChip(
                label: Text(d),
                selected: isSel,
                selectedColor: AppColors.primary,
                checkmarkColor: Colors.white,
                labelStyle: TextStyle(
                  color: isSel ? Colors.white : AppColors.textHeader,
                  fontWeight: FontWeight.bold,
                ),
                onSelected: (val) {
                  setState(() {
                    if (val) {
                      _data.workoutDays.add(d);
                    } else if (_data.workoutDays.length > 1) {
                      _data.workoutDays.remove(d);
                    }
                  });
                },
              );
            }).toList(),
          ),
          const SizedBox(height: 32),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.border),
            ),
            child: SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Training Reminder', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.textHeader)),
              subtitle: const Text('Never miss your training day', style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
              value: _data.workoutReminder,
              activeColor: AppColors.primary,
              onChanged: (val) => setState(() => _data.workoutReminder = val),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAnalyzingScreen() {
    final int percent = (_analysisProgress * 100).toInt().clamp(0, 100);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const Spacer(),
              Stack(
                alignment: Alignment.center,
                children: [
                  SizedBox(
                    width: 150,
                    height: 150,
                    child: CircularProgressIndicator(
                      value: _analysisProgress,
                      strokeWidth: 8,
                      backgroundColor: AppColors.primaryLight,
                      valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary),
                    ),
                  ),
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.bolt, color: AppColors.primary, size: 36),
                      Text(
                        '$percent%',
                        style: const TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textHeader,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 36),
              const Text(
                'Personalizing Your Plan...',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textHeader,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                child: Text(
                  _analysisText,
                  key: ValueKey<String>(_analysisText),
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primary,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 40),
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.border),
                ),
                child: Column(
                  children: [
                    _buildAnalysisCheckItem(
                      'Calculating caloric surplus/deficit...',
                      _analysisProgress >= 0.33,
                    ),
                    const Divider(height: 24),
                    _buildAnalysisCheckItem(
                      'Designing optimal workout split...',
                      _analysisProgress >= 0.66,
                    ),
                    const Divider(height: 24),
                    _buildAnalysisCheckItem(
                      'Generating meal schedule...',
                      _analysisProgress >= 0.95,
                    ),
                  ],
                ),
              ),
              const Spacer(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAnalysisCheckItem(String label, bool isDone) {
    return Row(
      children: [
        AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          width: 24,
          height: 24,
          decoration: BoxDecoration(
            color: isDone ? AppColors.primary : Colors.transparent,
            shape: BoxShape.circle,
            border: Border.all(
              color: isDone ? AppColors.primary : AppColors.textSecondary.withOpacity(0.4),
              width: 2,
            ),
          ),
          child: isDone
              ? const Icon(Icons.check, size: 16, color: Colors.white)
              : const SizedBox.shrink(),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              fontSize: 14,
              fontWeight: isDone ? FontWeight.bold : FontWeight.w500,
              color: isDone ? AppColors.textHeader : AppColors.textSecondary,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTeaserScreen() {
    final projectedDate = _calculateProjectedDate();
    final dateStr = DateFormat('MMMM d, yyyy').format(projectedDate);
    final dailyCals = _calculateDailyCalories();
    final daysCount = _data.workoutDays.isNotEmpty ? _data.workoutDays.length : 3;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.primaryLight,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppColors.primary.withOpacity(0.3)),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.check_circle, color: AppColors.primary, size: 16),
                      SizedBox(width: 6),
                      Text(
                        'ANALYSIS COMPLETE',
                        style: TextStyle(
                          color: AppColors.primary,
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1.1,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Your Plan is Ready! 🎉',
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textHeader,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 6),
              const Text(
                'Personalized for your body metrics, goals & schedule.',
                style: TextStyle(fontSize: 14, color: AppColors.textSecondary),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),

              // Projected Goal Box
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFE8F3EB), Color(0xFFD4E8DA)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppColors.primary.withOpacity(0.3)),
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
                          child: const Icon(Icons.flag_rounded, color: Colors.white, size: 20),
                        ),
                        const SizedBox(width: 10),
                        const Text(
                          'PROJECTED TIMELINE',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.2,
                            color: AppColors.primary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    Text(
                      'Projected to reach ${_data.targetWeightKg.toStringAsFixed(1)} kg by $dateStr 🎯',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textHeader,
                        height: 1.3,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Based on your starting weight of ${_data.currentWeightKg.toStringAsFixed(1)} kg and ${_data.targetPace} pace.',
                      style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Key Highlights Grid
              Row(
                children: [
                  Expanded(
                    child: _buildTeaserMetricCard(
                      icon: Icons.local_fire_department,
                      title: 'Daily Target',
                      value: '$dailyCals kcal',
                      subtitle: 'Optimal metabolic burn',
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildTeaserMetricCard(
                      icon: Icons.fitness_center,
                      title: 'Workout Split',
                      value: '$daysCount Days/wk',
                      subtitle: _data.goal.replaceAll('_', ' ').toUpperCase(),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _buildTeaserMetricCard(
                      icon: Icons.restaurant,
                      title: 'Cuisine & Diet',
                      value: _data.mealPreference,
                      subtitle: 'Macro-matched recipes',
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildTeaserMetricCard(
                      icon: Icons.track_changes,
                      title: 'Target Focus',
                      value: _data.targetFocusAreas.isNotEmpty ? _data.targetFocusAreas.first : 'Full Body',
                      subtitle: '${_data.targetFocusAreas.length} target zones',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 28),

              // Primary Action Button
              _PrimaryButton(
                title: 'CONTINUE TO MY PLAN ➔',
                onPressed: _finishOnboarding,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTeaserMetricCard({
    required IconData icon,
    required String title,
    required String value,
    required String subtitle,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: AppColors.primary, size: 24),
          const SizedBox(height: 10),
          Text(title, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary, fontWeight: FontWeight.w600)),
          const SizedBox(height: 4),
          Text(value, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.textHeader), maxLines: 1, overflow: TextOverflow.ellipsis),
          const SizedBox(height: 2),
          Text(subtitle, style: const TextStyle(fontSize: 10, color: AppColors.textSecondary), maxLines: 1, overflow: TextOverflow.ellipsis),
        ],
      ),
    );
  }
}
// --- Helper UI & Custom Painters ---

class _StepContainer extends StatelessWidget {
  final String title;
  final String subtitle;
  final Widget child;
  final Widget? bottomAction;

  const _StepContainer({
    required this.title,
    required this.subtitle,
    required this.child,
    this.bottomAction,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w900,
              color: AppColors.textHeader,
              height: 1.25,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            style: const TextStyle(
              fontSize: 14,
              color: AppColors.textSecondary,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 24),
          Expanded(child: child),
          if (bottomAction != null) ...[
            const SizedBox(height: 16),
            bottomAction!,
          ],
        ],
      ),
    );
  }
}

class _SelectableOptionCard extends StatelessWidget {
  final String title;
  final String? subtitle;
  final IconData? icon;
  final bool isSelected;
  final VoidCallback onTap;

  const _SelectableOptionCard({
    required this.title,
    this.subtitle,
    this.icon,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primaryLight : AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.border,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            if (icon != null) ...[
              Icon(icon, color: isSelected ? AppColors.primary : AppColors.textSecondary, size: 28),
              const SizedBox(width: 16),
            ],
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: isSelected ? AppColors.primary : AppColors.textHeader,
                    ),
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      subtitle!,
                      style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                    ),
                  ],
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios,
              size: 16,
              color: isSelected ? AppColors.primary : AppColors.textSecondary,
            ),
          ],
        ),
      ),
    );
  }
}

class _GoalVisualCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  const _GoalVisualCard({
    required this.title,
    required this.icon,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        height: 220,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primaryLight : AppColors.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.border,
            width: isSelected ? 2 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isSelected ? AppColors.primary.withValues(alpha: 0.15) : AppColors.background,
              ),
              child: Icon(icon, size: 48, color: isSelected ? AppColors.primary : AppColors.textSecondary),
            ),
            const SizedBox(height: 20),
            Text(
              title,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w900,
                color: isSelected ? AppColors.primary : AppColors.textHeader,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PrimaryButton extends StatelessWidget {
  final String title;
  final VoidCallback onPressed;

  const _PrimaryButton({required this.title, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 54,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          elevation: 0,
        ),
        onPressed: onPressed,
        child: Text(
          title,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white, letterSpacing: 0.5),
        ),
      ),
    );
  }
}

// Professional Athletic Anatomy Silhouette Painter (Athletic curved muscular contours)
class _AnatomySilhouettePainter extends CustomPainter {
  final List<String> selectedAreas;

  _AnatomySilhouettePainter({required this.selectedAreas});

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;

    final basePaint = Paint()
      ..color = const Color(0xFFDCE4DF)
      ..style = PaintingStyle.fill;

    final activePaint = Paint()
      ..color = AppColors.primary
      ..style = PaintingStyle.fill;

    final outlinePaint = Paint()
      ..color = AppColors.border
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    // Check highlights
    final isFull = selectedAreas.contains('Full Body');
    final chestActive = isFull || selectedAreas.contains('Chest');
    final backActive = isFull || selectedAreas.contains('Back');
    final armsActive = isFull || selectedAreas.contains('Arms');
    final absActive = isFull || selectedAreas.contains('Abs');
    final glutesActive = isFull || selectedAreas.contains('Glutes');
    final legActive = isFull || selectedAreas.contains('Leg');

    // 1. Head & Neck
    canvas.drawCircle(Offset(cx, 26), 16, basePaint);
    canvas.drawCircle(Offset(cx, 26), 16, outlinePaint);
    final neckPath = Path()
      ..moveTo(cx - 7, 38)
      ..lineTo(cx + 7, 38)
      ..lineTo(cx + 10, 48)
      ..lineTo(cx - 10, 48)
      ..close();
    canvas.drawPath(neckPath, basePaint);

    // 2. Chest & Upper Torso (V-taper athletic shape)
    final chestPaint = (chestActive || backActive) ? activePaint : basePaint;
    final chestPath = Path()
      ..moveTo(cx - 40, 52)
      ..quadraticBezierTo(cx, 46, cx + 40, 52)
      ..quadraticBezierTo(cx + 34, 82, cx + 24, 102)
      ..lineTo(cx - 24, 102)
      ..quadraticBezierTo(cx - 34, 82, cx - 40, 52)
      ..close();
    canvas.drawPath(chestPath, chestPaint);
    canvas.drawPath(chestPath, outlinePaint);

    // Pec line details
    if (!chestActive && !backActive) {
      final pecPaint = Paint()..color = const Color(0xFFCAD6CE)..style = PaintingStyle.stroke..strokeWidth = 1.5;
      canvas.drawLine(Offset(cx - 24, 76), Offset(cx - 4, 78), pecPaint);
      canvas.drawLine(Offset(cx + 4, 78), Offset(cx + 24, 76), pecPaint);
      canvas.drawLine(Offset(cx, 54), Offset(cx, 96), pecPaint);
    }

    // 3. Abdominals & Core (Tapered 6-pack grid)
    final absPaint = absActive ? activePaint : basePaint;
    final absPath = Path()
      ..moveTo(cx - 24, 104)
      ..lineTo(cx + 24, 104)
      ..quadraticBezierTo(cx + 26, 130, cx + 28, 152)
      ..lineTo(cx - 28, 152)
      ..quadraticBezierTo(cx - 26, 130, cx - 24, 104)
      ..close();
    canvas.drawPath(absPath, absPaint);
    canvas.drawPath(absPath, outlinePaint);

    // 4. Arms (Deltoid + Bicep/Tricep + Forearm)
    final armPaint = armsActive ? activePaint : basePaint;
    // Left Arm
    final leftArm = Path()
      ..moveTo(cx - 42, 54)
      ..quadraticBezierTo(cx - 56, 70, cx - 50, 98) // Bicep curve
      ..quadraticBezierTo(cx - 52, 120, cx - 44, 142) // Forearm
      ..lineTo(cx - 36, 140)
      ..quadraticBezierTo(cx - 38, 116, cx - 36, 96)
      ..close();
    canvas.drawPath(leftArm, armPaint);
    canvas.drawPath(leftArm, outlinePaint);

    // Right Arm
    final rightArm = Path()
      ..moveTo(cx + 42, 54)
      ..quadraticBezierTo(cx + 56, 70, cx + 50, 98)
      ..quadraticBezierTo(cx + 52, 120, cx + 44, 142)
      ..lineTo(cx + 36, 140)
      ..quadraticBezierTo(cx + 38, 116, cx + 36, 96)
      ..close();
    canvas.drawPath(rightArm, armPaint);
    canvas.drawPath(rightArm, outlinePaint);

    // 5. Glutes & Pelvis
    final glutesPaint = glutesActive ? activePaint : basePaint;
    final glutesPath = Path()
      ..moveTo(cx - 28, 154)
      ..lineTo(cx + 28, 154)
      ..quadraticBezierTo(cx + 28, 172, cx + 20, 186)
      ..lineTo(cx - 20, 186)
      ..quadraticBezierTo(cx - 28, 172, cx - 28, 154)
      ..close();
    canvas.drawPath(glutesPath, glutesPaint);
    canvas.drawPath(glutesPath, outlinePaint);

    // 6. Legs (Quadriceps, Knee, Calf)
    final legPaintToUse = legActive ? activePaint : basePaint;
    // Left Leg
    final leftLeg = Path()
      ..moveTo(cx - 20, 188)
      ..lineTo(cx - 4, 188)
      ..quadraticBezierTo(cx - 4, 230, cx - 6, 252) // Inner quad
      ..quadraticBezierTo(cx - 4, 280, cx - 8, 316) // Calf/Ankle
      ..lineTo(cx - 18, 316)
      ..quadraticBezierTo(cx - 24, 280, cx - 20, 252)
      ..quadraticBezierTo(cx - 26, 224, cx - 20, 188)
      ..close();
    canvas.drawPath(leftLeg, legPaintToUse);
    canvas.drawPath(leftLeg, outlinePaint);

    // Right Leg
    final rightLeg = Path()
      ..moveTo(cx + 4, 188)
      ..lineTo(cx + 20, 188)
      ..quadraticBezierTo(cx + 26, 224, cx + 20, 252)
      ..quadraticBezierTo(cx + 24, 280, cx + 18, 316)
      ..lineTo(cx + 8, 316)
      ..quadraticBezierTo(cx + 4, 280, cx + 6, 252)
      ..quadraticBezierTo(cx + 4, 230, cx + 4, 188)
      ..close();
    canvas.drawPath(rightLeg, legPaintToUse);
    canvas.drawPath(rightLeg, outlinePaint);
  }

  @override
  bool shouldRepaint(covariant _AnatomySilhouettePainter oldDelegate) => true;
}

// Proportional Body Fat Transformation Painter (True athletic muscular curves)
class _PhysiqueBodyFatPainter extends CustomPainter {
  final String bodyFat;
  final String gender;
  final Color primaryColor;

  _PhysiqueBodyFatPainter({
    required this.bodyFat,
    required this.gender,
    required this.primaryColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;

    double chestSpread = 34.0;
    double waistSpread = 18.0;
    double hipSpread = 22.0;
    double armThickness = 12.0;
    double legThickness = 16.0;

    if (bodyFat == '<15%') {
      chestSpread = 38.0; // Wide V-taper
      waistSpread = 16.0; // Tight shredded waist
      hipSpread = 20.0;
      armThickness = 13.0;
      legThickness = 15.0;
    } else if (bodyFat == '20%') {
      chestSpread = 36.0;
      waistSpread = 20.0;
      hipSpread = 23.0;
      armThickness = 12.0;
      legThickness = 16.0;
    } else if (bodyFat == '25%') {
      chestSpread = 35.0;
      waistSpread = 25.0;
      hipSpread = 26.0;
      armThickness = 13.0;
      legThickness = 18.0;
    } else if (bodyFat == '30%') {
      chestSpread = 36.0;
      waistSpread = 32.0; // Noticeable belly expansion
      hipSpread = 30.0;
      armThickness = 14.0;
      legThickness = 20.0;
    } else if (bodyFat == '>40%') {
      chestSpread = 38.0;
      waistSpread = 42.0; // Significant adiposity
      hipSpread = 36.0;
      armThickness = 16.0;
      legThickness = 23.0;
    }

    final paint = Paint()
      ..color = primaryColor
      ..style = PaintingStyle.fill;

    final outline = Paint()
      ..color = Colors.black.withValues(alpha: 0.08)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    // Head
    canvas.drawCircle(Offset(cx, 22), 15, paint);

    // Torso (V-taper to round progression)
    final torso = Path()
      ..moveTo(cx - chestSpread, 44)
      ..quadraticBezierTo(cx, 38, cx + chestSpread, 44)
      ..quadraticBezierTo(cx + waistSpread + 2, 80, cx + hipSpread, 114)
      ..lineTo(cx - hipSpread, 114)
      ..quadraticBezierTo(cx - waistSpread - 2, 80, cx - chestSpread, 44)
      ..close();
    canvas.drawPath(torso, paint);
    canvas.drawPath(torso, outline);

    // Arms
    final leftArm = Path()
      ..moveTo(cx - chestSpread, 48)
      ..quadraticBezierTo(cx - chestSpread - armThickness - 2, 75, cx - chestSpread - 4, 108)
      ..lineTo(cx - chestSpread + 6, 106)
      ..quadraticBezierTo(cx - chestSpread + 4, 75, cx - chestSpread + 10, 56)
      ..close();
    canvas.drawPath(leftArm, paint);

    final rightArm = Path()
      ..moveTo(cx + chestSpread, 48)
      ..quadraticBezierTo(cx + chestSpread + armThickness + 2, 75, cx + chestSpread + 4, 108)
      ..lineTo(cx + chestSpread - 6, 106)
      ..quadraticBezierTo(cx + chestSpread - 4, 75, cx + chestSpread - 10, 56)
      ..close();
    canvas.drawPath(rightArm, paint);

    // Legs
    final leftLeg = Path()
      ..moveTo(cx - hipSpread, 116)
      ..lineTo(cx - 3, 116)
      ..quadraticBezierTo(cx - 3, 146, cx - 6, 172)
      ..lineTo(cx - 6 - legThickness, 172)
      ..quadraticBezierTo(cx - hipSpread - 2, 146, cx - hipSpread, 116)
      ..close();
    canvas.drawPath(leftLeg, paint);

    final rightLeg = Path()
      ..moveTo(cx + 3, 116)
      ..lineTo(cx + hipSpread, 116)
      ..quadraticBezierTo(cx + hipSpread + 2, 146, cx + 6 + legThickness, 172)
      ..lineTo(cx + 6, 172)
      ..quadraticBezierTo(cx + 3, 146, cx + 3, 116)
      ..close();
    canvas.drawPath(rightLeg, paint);
  }

  @override
  bool shouldRepaint(covariant _PhysiqueBodyFatPainter oldDelegate) => true;
}

class _PredictionCurvePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.primary
      ..strokeWidth = 4
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final path = Path();
    path.moveTo(0, 20);
    path.cubicTo(
      size.width * 0.4,
      20,
      size.width * 0.6,
      size.height - 20,
      size.width,
      size.height - 20,
    );

    canvas.drawPath(path, paint);

    final dotPaint = Paint()..color = AppColors.primary;
    canvas.drawCircle(Offset(size.width, size.height - 20), 8, dotPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}




// =========================================================
// Real Bodybuilder Glowing Muscle Highlight Painter
// Calibrated to 896 x 1200 Coordinate Space
// =========================================================
class _RealBodybuilderGlowPainter extends CustomPainter {
  final List<String> selectedAreas;

  _RealBodybuilderGlowPainter({required this.selectedAreas});

  @override
  void paint(Canvas canvas, Size size) {
    final isFull = selectedAreas.contains('Full Body');

    void drawGlowZone(Rect rect, {double blur = 20.0, double radius = 24.0}) {
      final glowPaint = Paint()
        ..color = AppColors.primary.withOpacity(0.50)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, blur);
      canvas.drawRRect(RRect.fromRectAndRadius(rect, Radius.circular(radius)), glowPaint);

      final fillPaint = Paint()
        ..color = AppColors.primary.withOpacity(0.20)
        ..style = PaintingStyle.fill;
      canvas.drawRRect(RRect.fromRectAndRadius(rect, Radius.circular(radius)), fillPaint);

      final strokePaint = Paint()
        ..color = AppColors.primary
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3.5;
      canvas.drawRRect(RRect.fromRectAndRadius(rect, Radius.circular(radius)), strokePaint);
    }

    // Chest (Pectorals)
    if (isFull || selectedAreas.contains('Chest')) {
      drawGlowZone(
        Rect.fromCenter(center: const Offset(448, 350), width: 270, height: 110),
        radius: 28,
      );
    }

    // Abs (6-pack & core)
    if (isFull || selectedAreas.contains('Abs')) {
      drawGlowZone(
        Rect.fromCenter(center: const Offset(448, 475), width: 170, height: 130),
        radius: 24,
      );
    }

    // Arms (Biceps, triceps & forearms)
    if (isFull || selectedAreas.contains('Arms')) {
      drawGlowZone(
        Rect.fromCenter(center: const Offset(290, 410), width: 95, height: 240),
        radius: 30,
      );
      drawGlowZone(
        Rect.fromCenter(center: const Offset(606, 410), width: 95, height: 240),
        radius: 30,
      );
    }

    // Back (Upper back / shoulders / traps)
    if (isFull || selectedAreas.contains('Back')) {
      drawGlowZone(
        Rect.fromCenter(center: const Offset(448, 255), width: 340, height: 85),
        radius: 26,
      );
    }

    // Glutes (Hips & glutes)
    if (isFull || selectedAreas.contains('Glutes')) {
      drawGlowZone(
        Rect.fromCenter(center: const Offset(448, 580), width: 230, height: 110),
        radius: 26,
      );
    }

    // Legs (Quads & calves)
    if (isFull || selectedAreas.contains('Leg')) {
      drawGlowZone(
        Rect.fromCenter(center: const Offset(390, 830), width: 130, height: 350),
        radius: 35,
      );
      drawGlowZone(
        Rect.fromCenter(center: const Offset(506, 830), width: 130, height: 350),
        radius: 35,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _RealBodybuilderGlowPainter oldDelegate) => true;
}

// =========================================================
// Real Bodybuilder Height Stadiometer Visualizer
// Mathematically calibrated ruler, laser line, & character scale
// =========================================================
class _HeightStadiometer extends StatelessWidget {
  final int heightCm;

  const _HeightStadiometer({required this.heightCm});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final totalH = constraints.maxHeight;
            const topMargin = 22.0;
            const bottomMargin = 28.0;
            final usableH = totalH - topMargin - bottomMargin;

            // Ruler range (130cm to 220cm)
            const double minCm = 130.0;
            const double maxCm = 220.0;

            double getY(double cm) {
              final ratio = (cm - minCm) / (maxCm - minCm);
              return topMargin + (1.0 - ratio.clamp(0.0, 1.0)) * usableH;
            }

            final currentLaserY = getY(heightCm.toDouble());
            final floorY = getY(minCm);
            final rulerTicks = [210, 200, 190, 180, 170, 160, 150, 140];
            final characterH = (floorY - currentLaserY).clamp(80.0, totalH);

            return Stack(
              clipBehavior: Clip.none,
              children: [
                // Floor / Platform base line
                Positioned(
                  left: 20,
                  right: 20,
                  top: floorY,
                  child: Container(
                    height: 2,
                    color: AppColors.border,
                  ),
                ),
                // Floor label
                Positioned(
                  left: 14,
                  top: floorY + 4,
                  child: const Text(
                    'BASE (130 cm)',
                    style: TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textSecondary,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),

                // Ruler vertical guide line
                Positioned(
                  left: 70,
                  top: topMargin,
                  bottom: bottomMargin,
                  child: Container(
                    width: 1.5,
                    color: AppColors.border,
                  ),
                ),

                // Ruler tick marks and labels
                ...rulerTicks.map((mark) {
                  final markY = getY(mark.toDouble());
                  final isPassed = heightCm >= mark;
                  final isCurrentNearest = (heightCm - mark).abs() <= 3;

                  return Positioned(
                    left: 10,
                    top: markY - 9,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        SizedBox(
                          width: 50,
                          child: Text(
                            '$mark cm',
                            textAlign: TextAlign.right,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: isCurrentNearest
                                  ? FontWeight.w900
                                  : (isPassed ? FontWeight.bold : FontWeight.w500),
                              color: isCurrentNearest
                                  ? AppColors.primary
                                  : (isPassed ? AppColors.textHeader : AppColors.textSecondary.withOpacity(0.55)),
                            ),
                          ),
                        ),
                        const SizedBox(width: 4),
                        Container(
                          width: mark % 20 == 0 ? 10 : 6,
                          height: 2,
                          color: isCurrentNearest
                              ? AppColors.primary
                              : (isPassed ? AppColors.primary.withOpacity(0.6) : AppColors.border),
                        ),
                      ],
                    ),
                  );
                }),

                // Real Bodybuilder character with head locked to laser line and feet at base
                Positioned(
                  left: 90,
                  right: 44,
                  top: currentLaserY - (characterH * 0.033),
                  height: characterH / 0.92,
                  child: Image.asset(
                    'assets/images/bodybuilder_physique.png',
                    fit: BoxFit.contain,
                    alignment: Alignment.topCenter,
                  ),
                ),

                // Glowing Laser Height Alignment Indicator
                Positioned(
                  left: 65,
                  right: 14,
                  top: currentLaserY - 10,
                  child: Row(
                    children: [
                      Container(
                        width: 9,
                        height: 9,
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.primary.withOpacity(0.7),
                              blurRadius: 6,
                              spreadRadius: 2,
                            ),
                          ],
                        ),
                      ),
                      Expanded(
                        child: Container(
                          height: 2,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                AppColors.primary,
                                AppColors.primary.withOpacity(0.7),
                                AppColors.primary.withOpacity(0.25),
                              ],
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.primary.withOpacity(0.4),
                                blurRadius: 4,
                              ),
                            ],
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          borderRadius: BorderRadius.circular(8),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.primary.withOpacity(0.35),
                              blurRadius: 6,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Text(
                          '$heightCm cm',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

// =========================================================
// Interactive Realistic Fitness Prediction Graph Widget
// =========================================================
class _InteractivePredictionGraph extends StatefulWidget {
  final double startWeight;
  final double targetWeight;
  final String targetDateStr;

  const _InteractivePredictionGraph({
    required this.startWeight,
    required this.targetWeight,
    required this.targetDateStr,
  });

  @override
  State<_InteractivePredictionGraph> createState() => _InteractivePredictionGraphState();
}

class _InteractivePredictionGraphState extends State<_InteractivePredictionGraph> {
  double _touchFraction = 0.5; // 0.0 to 1.0

  @override
  Widget build(BuildContext context) {
    final start = widget.startWeight;
    final target = widget.targetWeight;
    final diff = start - target;
    final currentPointWeight = start - (diff * _touchFraction);
    final week = (_touchFraction * 12).round();

    return Container(
      height: 220,
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final w = constraints.maxWidth;
          final h = constraints.maxHeight;

          return GestureDetector(
            onHorizontalDragUpdate: (details) {
              final box = context.findRenderObject() as RenderBox?;
              if (box != null) {
                final localPos = box.globalToLocal(details.globalPosition);
                setState(() {
                  _touchFraction = (localPos.dx / w).clamp(0.0, 1.0);
                });
              }
            },
            onTapDown: (details) {
              final box = context.findRenderObject() as RenderBox?;
              if (box != null) {
                final localPos = box.globalToLocal(details.globalPosition);
                setState(() {
                  _touchFraction = (localPos.dx / w).clamp(0.0, 1.0);
                });
              }
            },
            child: Stack(
              children: [
                // Custom Realistic Graph Canvas
                CustomPaint(
                  size: Size(w, h),
                  painter: _RealisticChartPainter(
                    touchFraction: _touchFraction,
                    startWeight: start,
                    targetWeight: target,
                  ),
                ),
                // Floating Active Tooltip Tag
                Positioned(
                  left: (w * _touchFraction - 55).clamp(8.0, w - 120),
                  top: 6,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.textHeader,
                      borderRadius: BorderRadius.circular(10),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.2),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Text(
                      'Wk $week: ${currentPointWeight.toStringAsFixed(1)} kg',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                // Target Goal Milestone Badge
                Positioned(
                  right: 12,
                  bottom: 12,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.emoji_events, color: Colors.white, size: 14),
                        const SizedBox(width: 4),
                        Text(
                          'Goal: ${widget.targetWeight.round()} kg',
                          style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _RealisticChartPainter extends CustomPainter {
  final double touchFraction;
  final double startWeight;
  final double targetWeight;

  _RealisticChartPainter({
    required this.touchFraction,
    required this.startWeight,
    required this.targetWeight,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final paddingBottom = 26.0;
    final paddingTop = 45.0;
    final graphH = h - paddingTop - paddingBottom;

    // 1. Horizontal Grid lines
    final gridPaint = Paint()
      ..color = AppColors.border.withOpacity(0.5)
      ..strokeWidth = 1.0;

    for (int i = 0; i <= 3; i++) {
      final y = paddingTop + (graphH * i / 3);
      canvas.drawLine(Offset(0, y), Offset(w, y), gridPaint);
    }

    // 2. Build Smooth Spline Curve
    final curvePath = Path();
    curvePath.moveTo(0, paddingTop + 8);
    curvePath.cubicTo(
      w * 0.35, paddingTop + 8,
      w * 0.65, paddingTop + graphH - 8,
      w, paddingTop + graphH - 8,
    );

    // 3. Shaded Gradient Fill Under Curve
    final fillPath = Path.from(curvePath);
    fillPath.lineTo(w, h - paddingBottom);
    fillPath.lineTo(0, h - paddingBottom);
    fillPath.close();

    final fillPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          AppColors.primary.withOpacity(0.35),
          AppColors.primary.withOpacity(0.01),
        ],
      ).createShader(Rect.fromLTWH(0, 0, w, h));

    canvas.drawPath(fillPath, fillPaint);

    // 4. Draw Main Green Neon Curve
    final linePaint = Paint()
      ..color = AppColors.primary
      ..strokeWidth = 3.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    canvas.drawPath(curvePath, linePaint);

    // 5. Scrubber Line & Dot at Touch Position
    final touchX = w * touchFraction;
    // Calculate Y along cubic curve approximation
    final t = touchFraction;
    final p0 = paddingTop + 8;
    final p3 = paddingTop + graphH - 8;
    final touchY = (1 - t) * (1 - t) * (1 - t) * p0 +
        3 * (1 - t) * (1 - t) * t * p0 +
        3 * (1 - t) * t * t * p3 +
        t * t * t * p3;

    final scrubberPaint = Paint()
      ..color = AppColors.primary.withOpacity(0.6)
      ..strokeWidth = 1.5;
    canvas.drawLine(Offset(touchX, paddingTop), Offset(touchX, h - paddingBottom), scrubberPaint);

    // Outer glow ring
    canvas.drawCircle(Offset(touchX, touchY), 10, Paint()..color = AppColors.primary.withOpacity(0.25));
    // Solid active dot
    canvas.drawCircle(Offset(touchX, touchY), 6, Paint()..color = AppColors.primary);
    canvas.drawCircle(Offset(touchX, touchY), 2.5, Paint()..color = Colors.white);

    // 6. X-Axis Time Labels
    final textStyle = TextStyle(color: AppColors.textSecondary.withOpacity(0.8), fontSize: 10, fontWeight: FontWeight.bold);
    void drawLabel(String text, double x) {
      final span = TextSpan(text: text, style: textStyle);
      final tp = TextPainter(text: span, textDirection: ui.TextDirection.ltr);
      tp.layout();
      tp.paint(canvas, Offset(x - tp.width / 2, h - 16));
    }

    drawLabel('Today', 18);
    drawLabel('Month 1', w * 0.35);
    drawLabel('Month 2', w * 0.65);
    drawLabel('Goal Date', w - 24);
  }

  @override
  bool shouldRepaint(covariant _RealisticChartPainter oldDelegate) => true;
}
