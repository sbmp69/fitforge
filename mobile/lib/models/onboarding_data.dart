class OnboardingData {
  String gender;
  String goal; // 'weight_loss', 'build_muscle', 'tone'
  String weightLossHistory; // 'succeeded_improve', 'succeeded_rebound', 'tried_failed', 'never_tried'
  List<String> targetFocusAreas; // ['Chest', 'Arms', 'Abs', etc.]
  int age;
  int heightCm;
  double currentWeightKg;
  double targetWeightKg;
  String targetPace; // 'fast', 'normal', 'steady', 'ai_decide'
  String currentBodyFat; // '<15%', '20%', '25%', '30%', '>40%'
  String desiredBodyFat;
  List<String> lifestyleIssues; // ['Prolonged sitting', 'Poor sleep quality', etc.]
  List<String> injuries; // ['No injuries', 'Shoulders', 'Knee', etc.]
  String fitnessLevel; // 'Beginner', 'Intermediate', 'Advanced'
  List<String> equipment; // ['Bodyweight', 'Portable', 'Gym']
  List<String> workoutDays; // ['Mon', 'Tue', 'Wed', 'Fri']
  bool workoutReminder;

  OnboardingData({
    this.gender = 'Male',
    this.goal = 'weight_loss',
    this.weightLossHistory = 'never_tried',
    List<String>? targetFocusAreas,
    this.age = 22,
    this.heightCm = 175,
    this.currentWeightKg = 75.0,
    this.targetWeightKg = 70.0,
    this.targetPace = 'normal',
    this.currentBodyFat = '25%',
    this.desiredBodyFat = '15%',
    List<String>? lifestyleIssues,
    List<String>? injuries,
    this.fitnessLevel = 'Beginner',
    List<String>? equipment,
    List<String>? workoutDays,
    this.workoutReminder = true,
  })  : targetFocusAreas = targetFocusAreas ?? ['Full Body'],
        lifestyleIssues = lifestyleIssues ?? [],
        injuries = injuries ?? ['No injuries'],
        equipment = equipment ?? ['Bodyweight'],
        workoutDays = workoutDays ?? ['Mon', 'Wed', 'Fri'];

  double get bmi {
    if (heightCm <= 0) return 22.0;
    final hMeters = heightCm / 100.0;
    return double.parse((currentWeightKg / (hMeters * hMeters)).toStringAsFixed(1));
  }

  String get bmiCategory {
    final b = bmi;
    if (b < 18.5) return 'Underweight';
    if (b < 25.0) return 'Normal';
    if (b < 30.0) return 'Overweight';
    return 'Obese';
  }

  DateTime get predictedTargetDate {
    final diffKg = (currentWeightKg - targetWeightKg).abs();
    double weeklyRate = 0.5; // standard healthy rate (0.5kg/week)
    if (targetPace == 'fast') weeklyRate = 0.8;
    else if (targetPace == 'steady') weeklyRate = 0.3;
    final weeks = (diffKg / weeklyRate).clamp(2.0, 52.0);
    return DateTime.now().add(Duration(days: (weeks * 7).round()));
  }

  Map<String, dynamic> toJson() => {
        'gender': gender,
        'goal': goal,
        'weight_loss_history': weightLossHistory,
        'target_focus_areas': targetFocusAreas,
        'age': age,
        'height_cm': heightCm,
        'current_weight_kg': currentWeightKg,
        'target_weight_kg': targetWeightKg,
        'target_pace': targetPace,
        'current_body_fat': currentBodyFat,
        'desired_body_fat': desiredBodyFat,
        'lifestyle_issues': lifestyleIssues,
        'injuries': injuries,
        'fitness_level': fitnessLevel,
        'equipment': equipment,
        'workout_days': workoutDays,
        'workout_reminder': workoutReminder,
      };
}
