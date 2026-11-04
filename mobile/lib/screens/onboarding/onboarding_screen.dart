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
  final int _totalSteps = 15;
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
                  _buildEquipmentAndDaysStep(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

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

  Widget _buildWeightLossHistoryStep() {
    final options = [
      {'key': 'succeeded_improve', 'title': 'Succeeded, Want to Improve', 'emoji': '💪'},
      {'key': 'succeeded_rebound', 'title': 'Succeeded but Rebounded', 'emoji': '😅'},
      {'key': 'tried_failed', 'title': 'Tried but Failed', 'emoji': '😫'},
      {'key': 'never_tried', 'title': 'Never Tried', 'emoji': '🌱'},
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
                  Text(opt['emoji'] as String, style: const TextStyle(fontSize: 32)),
                  const SizedBox(height: 12),
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

  Widget _buildFocusAreasStep() {
    final muscleGroups = ['Back', 'Chest', 'Arms', 'Abs', 'Glutes', 'Leg', 'Full Body'];

    return _StepContainer(
      title: "Which areas do you want to focus on?",
      subtitle: "Select a target area for more accurate workout recommendations.",
      bottomAction: _PrimaryButton(title: 'CONTINUE', onPressed: _nextPage),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            flex: 5,
            child: Center(
              child: Image.asset(
                'assets/images/anatomy_body.jpeg',
                height: 380,
                fit: BoxFit.contain,
                errorBuilder: (_, __, ___) => const Icon(Icons.accessibility_new, size: 180, color: AppColors.accent),
              ),
            ),
          ),
          const SizedBox(width: 8),
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

  Widget _buildHeightStep() {
    return _StepContainer(
      title: "Your height",
      subtitle: "Height information helps us calculate your BMI more accurately",
      bottomAction: _PrimaryButton(title: 'CONTINUE', onPressed: _nextPage),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                '${_data.heightCm}',
                style: const TextStyle(fontSize: 48, fontWeight: FontWeight.bold, color: AppColors.textHeader),
              ),
              const SizedBox(width: 6),
              const Text('cm', style: TextStyle(fontSize: 20, color: AppColors.textSecondary, fontWeight: FontWeight.bold)),
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
          const SizedBox(height: 16),
          Expanded(
            child: Image.asset(
              'assets/images/height_guy.jpeg',
              fit: BoxFit.contain,
              errorBuilder: (_, __, ___) => const Icon(Icons.person, size: 160, color: AppColors.primary),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWeightStep() {
    final bmi = _data.bmi;
    final category = _data.bmiCategory;

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
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(16),
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
                    const Text('Current BMI', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textHeader)),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        bmi.toStringAsFixed(1),
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: Row(
                    children: [
                      Expanded(flex: 3, child: Container(height: 8, color: Colors.blueAccent)),
                      Expanded(flex: 5, child: Container(height: 8, color: AppColors.primary)),
                      Expanded(flex: 4, child: Container(height: 8, color: Colors.orangeAccent)),
                    ],
                  ),
                ),
                const SizedBox(height: 6),
                const Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Underweight', style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                    Text('Normal', style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                    Text('Overweight', style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                  ],
                ),
                const SizedBox(height: 14),
                Text(
                  category == 'Normal'
                      ? 'Being within the normal range of BMI, continue to maintain it through fitness!'
                      : 'We will personalize your calories and cardio pace to bring you into your peak optimal zone.',
                  style: const TextStyle(fontSize: 13, color: AppColors.textSecondary, height: 1.4),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

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
              child: Image.asset(
                'assets/images/WhatsApp_Image_2026-11-04_at_10.14.08.jpeg',
                fit: BoxFit.contain,
                errorBuilder: (_, __, ___) => const Icon(Icons.person, size: 180, color: AppColors.primary),
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
              child: Image.asset(
                'assets/images/WhatsApp_Image_2026-11-04_at_10.14.08_2.jpeg',
                fit: BoxFit.contain,
                errorBuilder: (_, __, ___) => const Icon(Icons.fitness_center, size: 180, color: AppColors.primary),
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

  Widget _buildEquipmentAndDaysStep() {
    final equips = ['Bodyweight', 'Portable', 'Gym'];
    final days = ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];

    return _StepContainer(
      title: "Training Equipment & Schedule",
      subtitle: "Final step! Choose your tools and which days you want to train.",
      bottomAction: _PrimaryButton(
        title: 'BUILD MY PERSONALIZED PLAN 🚀',
        onPressed: _finishOnboarding,
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Preferred Equipment', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.textHeader)),
            const SizedBox(height: 8),
            Row(
              children: equips.map((eq) {
                final isSel = _data.equipment.contains(eq);
                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: InkWell(
                      onTap: () {
                        setState(() {
                          if (isSel && _data.equipment.length > 1) {
                            _data.equipment.remove(eq);
                          } else if (!isSel) {
                            _data.equipment.add(eq);
                          }
                        });
                      },
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          color: isSel ? AppColors.primary : AppColors.surface,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: isSel ? AppColors.primary : AppColors.border),
                        ),
                        child: Text(
                          eq,
                          textAlign: TextAlign.center,
                          style: TextStyle(fontWeight: FontWeight.bold, color: isSel ? Colors.white : AppColors.textHeader),
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 24),
            const Text('Which days will you train?', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.textHeader)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: days.map((d) {
                final isSel = _data.workoutDays.contains(d);
                return FilterChip(
                  label: Text(d),
                  selected: isSel,
                  selectedColor: AppColors.primary,
                  checkmarkColor: Colors.white,
                  labelStyle: TextStyle(color: isSel ? Colors.white : AppColors.textHeader, fontWeight: FontWeight.bold),
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
            const SizedBox(height: 16),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Training Reminder', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.textHeader)),
              subtitle: const Text('Never miss your training day', style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
              value: _data.workoutReminder,
              activeColor: AppColors.primary,
              onChanged: (val) => setState(() => _data.workoutReminder = val),
            ),
          ],
        ),
      ),
    );
  }
}

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
