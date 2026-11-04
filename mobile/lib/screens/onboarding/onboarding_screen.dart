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
  final int _totalSteps = 18;
  final OnboardingData _data = OnboardingData();

  void _nextPage() {
    if (_currentStep < _totalSteps - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeInOut,
      );
    } else {
      _finishOnboarding();
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
    if (mounted) {
      context.go('/signup');
    }
  }

  @override
  Widget build(BuildContext context) {
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
                  TextButton(
                    onPressed: () => context.go('/login'),
                    child: const Text('Log In', style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold)),
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

  // --- Step 4: Focus Areas (Custom Vector Anatomy Diagram) ---
  Widget _buildFocusAreasStep() {
    final muscleGroups = ['Back', 'Chest', 'Arms', 'Abs', 'Glutes', 'Leg', 'Full Body'];

    return _StepContainer(
      title: "Which areas do you want to focus on?",
      subtitle: "Select a target area for more accurate workout recommendations.",
      bottomAction: _PrimaryButton(title: 'CONTINUE', onPressed: _nextPage),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Dynamic FitForge Vector Anatomy Illustration
          Expanded(
            flex: 5,
            child: Center(
              child: CustomPaint(
                size: const Size(160, 340),
                painter: _AnatomySilhouettePainter(
                  selectedAreas: _data.targetFocusAreas,
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          // Target Muscle Buttons
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
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 14),
                      decoration: BoxDecoration(
                        color: isSelected ? AppColors.primary : AppColors.surface,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isSelected ? AppColors.primary : AppColors.border,
                        ),
                      ),
                      child: Text(
                        group,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: isSelected ? Colors.white : AppColors.textHeader,
                        ),
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

  // --- Step 6: Height (Interactive Height Stadiometer) ---
  Widget _buildHeightStep() {
    final ft = (_data.heightCm / 30.48);
    final feet = ft.floor();
    final inches = ((ft - feet) * 12).round();

    return _StepContainer(
      title: "Your height",
      subtitle: "Height information helps us calculate your BMI more accurately",
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
              Text('($feet\' $inches")', style: const TextStyle(fontSize: 16, color: AppColors.textSecondary)),
            ],
          ),
          const SizedBox(height: 12),
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
          const SizedBox(height: 20),
          // Dynamic Stadiometer Graphic
          Expanded(
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppColors.border),
              ),
              child: Row(
                children: [
                  // Stadiometer Ruler Marks
                  SizedBox(
                    width: 70,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildRulerMark('210 cm', _data.heightCm >= 210),
                        _buildRulerMark('190 cm', _data.heightCm >= 190),
                        _buildRulerMark('175 cm', _data.heightCm >= 175),
                        _buildRulerMark('160 cm', _data.heightCm >= 160),
                        _buildRulerMark('140 cm', _data.heightCm >= 140),
                      ],
                    ),
                  ),
                  const VerticalDivider(width: 1, color: AppColors.border),
                  // Dynamic Height Vector Avatar
                  Expanded(
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Icon(
                            Icons.accessibility_new_rounded,
                            size: (_data.heightCm / 220.0 * 220).clamp(120.0, 220.0),
                            color: AppColors.primary,
                          ),
                          const SizedBox(height: 8),
                          Container(
                            height: 4,
                            width: 120,
                            decoration: BoxDecoration(
                              color: AppColors.primary.withValues(alpha: 0.3),
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRulerMark(String text, bool active) {
    return Row(
      children: [
        Container(
          width: active ? 16 : 8,
          height: 2,
          color: active ? AppColors.primary : AppColors.border,
        ),
        const SizedBox(width: 6),
        Text(
          text,
          style: TextStyle(
            fontSize: 11,
            fontWeight: active ? FontWeight.bold : FontWeight.normal,
            color: active ? AppColors.primary : AppColors.textSecondary,
          ),
        ),
      ],
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

  // --- Step 8: Desired Pace ---
  Widget _buildPaceStep() {
    final options = [
      {'key': 'fast', 'title': 'Fast and Intense'},
      {'key': 'normal', 'title': 'Normal pace is OK'},
      {'key': 'steady', 'title': 'Steady and gradual'},
      {'key': 'ai_decide', 'title': 'Let FitForge decide'},
    ];

    return _StepContainer(
      title: "What Pace Would You Like To Achieve Your Goal?",
      subtitle: "Choose the intensity that best matches your daily schedule and stamina.",
      child: Column(
        children: options.map((opt) {
          final isSelected = _data.targetPace == opt['key'];
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _SelectableOptionCard(
              title: opt['title'] as String,
              isSelected: isSelected,
              onTap: () {
                setState(() => _data.targetPace = opt['key'] as String);
                _nextPage();
              },
            ),
          );
        }).toList(),
      ),
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
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: AppColors.border),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Dynamic Custom Avatar reflecting chosen body fat
                    CustomPaint(
                      size: const Size(140, 180),
                      painter: _PhysiqueBodyFatPainter(
                        bodyFat: _data.currentBodyFat,
                        gender: _data.gender,
                        primaryColor: AppColors.primary,
                      ),
                    ),
                    const SizedBox(height: 16),
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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: tiers.map((t) {
              final isSel = _data.currentBodyFat == t;
              return ChoiceChip(
                label: Text(t, style: TextStyle(color: isSel ? Colors.white : AppColors.textHeader, fontWeight: FontWeight.bold)),
                selected: isSel,
                selectedColor: AppColors.primary,
                backgroundColor: AppColors.surface,
                onSelected: (_) => setState(() => _data.currentBodyFat = t),
              );
            }).toList(),
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

  // --- Step 10: Target Date Prediction Graph ---
  Widget _buildWeightPredictionStep() {
    final date = _data.predictedTargetDate;
    final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    final dateStr = '${months[date.month - 1]} ${date.day}';

    return _StepContainer(
      title: "We predict that you'll be",
      subtitle: "We've got a clear understanding of you and your body.",
      bottomAction: _PrimaryButton(title: 'CONTINUE', onPressed: _nextPage),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                '${_data.targetWeightKg.round()}kg on ',
                style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: AppColors.textHeader),
              ),
              Text(
                dateStr,
                style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: AppColors.primary),
              ),
            ],
          ),
          const SizedBox(height: 32),
          Container(
            height: 200,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.border),
            ),
            child: Stack(
              children: [
                Center(
                  child: CustomPaint(
                    size: const Size(double.infinity, 120),
                    painter: _PredictionCurvePainter(),
                  ),
                ),
                Positioned(
                  right: 20,
                  top: 20,
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.primaryLight,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.emoji_events, color: AppColors.primary, size: 36),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'Excellent! Based on your metabolism and schedule, this realistic progression safeguards muscle while burning stubborn fat.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 14, color: AppColors.textSecondary, height: 1.5),
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
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: AppColors.border),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CustomPaint(
                      size: const Size(140, 180),
                      painter: _PhysiqueBodyFatPainter(
                        bodyFat: _data.desiredBodyFat,
                        gender: _data.gender,
                        primaryColor: const Color(0xFF10B981),
                      ),
                    ),
                    const SizedBox(height: 16),
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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: tiers.map((t) {
              final isSel = _data.desiredBodyFat == t;
              return ChoiceChip(
                label: Text(t, style: TextStyle(color: isSel ? Colors.white : AppColors.textHeader, fontWeight: FontWeight.bold)),
                selected: isSel,
                selectedColor: AppColors.primary,
                backgroundColor: AppColors.surface,
                onSelected: (_) => setState(() => _data.desiredBodyFat = t),
              );
            }).toList(),
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

  // --- Step 13: Injuries ---
  Widget _buildInjuriesStep() {
    final injuryList = ['No injuries', 'Shoulders', 'Back', 'Waist', 'Wrist', 'Knee'];

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
        childAspectRatio: 1.6,
        children: injuryList.map((inj) {
          final isSelected = _data.injuries.contains(inj);
          return InkWell(
            onTap: () {
              setState(() {
                if (inj == 'No injuries') {
                  _data.injuries = ['No injuries'];
                } else {
                  _data.injuries.remove('No injuries');
                  if (isSelected) {
                    _data.injuries.remove(inj);
                  } else {
                    _data.injuries.add(inj);
                  }
                  if (_data.injuries.isEmpty) _data.injuries.add('No injuries');
                }
              });
            },
            borderRadius: BorderRadius.circular(16),
            child: Container(
              padding: const EdgeInsets.all(16),
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
                  Checkbox(
                    value: isSelected,
                    activeColor: AppColors.primary,
                    onChanged: (_) {},
                  ),
                  Expanded(
                    child: Text(
                      inj,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: isSelected ? AppColors.primary : AppColors.textHeader,
                      ),
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
      {'level': 'Beginner', 'desc': 'New to working out or coming back after a long break'},
      {'level': 'Intermediate', 'desc': 'Work out regularly and know fundamental exercise form'},
      {'level': 'Advanced', 'desc': 'Consistent high-intensity training with solid lifting experience'},
    ];

    return _StepContainer(
      title: "How would you rate your fitness level?",
      subtitle: "We'll tune the workout volume, sets, and rest intervals accordingly.",
      child: Column(
        children: levels.map((l) {
          final isSelected = _data.fitnessLevel == l['level'];
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _SelectableOptionCard(
              title: l['level'] as String,
              subtitle: l['desc'] as String,
              isSelected: isSelected,
              onTap: () {
                setState(() => _data.fitnessLevel = l['level'] as String);
                _nextPage();
              },
            ),
          );
        }).toList(),
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
        onPressed: _finishOnboarding,
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


