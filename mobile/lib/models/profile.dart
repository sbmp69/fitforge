class Profile {
  final String id;
  final String email;
  final String? fullName;
  final String? avatarUrl;
  final String role;
  final String subscriptionTier;
  final int aiPlansUsedThisMonth;
  final int followerCount;
  final String? bio;
  final int? heightCm;
  final double? weightKg;
  final String? primaryGoal;
  final String? fitnessLevel;
  final String? country;
  final String? mealPreference;
  final DateTime? dateOfBirth;
  final String? gender;
  final List<String> targetFocusAreas;
  final String? bodyFatRange;
  final String? desiredBodyFat;
  final double? targetWeightKg;
  final String? targetPace;
  final String? weightLossHistory;
  final List<String> lifestyleIssues;
  final List<String> injuries;
  final List<String> equipment;
  final List<String> workoutDays;
  final bool workoutReminder;

  const Profile({
    required this.id,
    required this.email,
    this.fullName,
    this.avatarUrl,
    required this.role,
    required this.subscriptionTier,
    required this.aiPlansUsedThisMonth,
    required this.followerCount,
    this.bio,
    this.heightCm,
    this.weightKg,
    this.primaryGoal,
    this.fitnessLevel,
    this.country,
    this.mealPreference,
    this.dateOfBirth,
    this.gender,
    this.targetFocusAreas = const [],
    this.bodyFatRange,
    this.desiredBodyFat,
    this.targetWeightKg,
    this.targetPace,
    this.weightLossHistory,
    this.lifestyleIssues = const [],
    this.injuries = const [],
    this.equipment = const [],
    this.workoutDays = const [],
    this.workoutReminder = false,
  });

  factory Profile.fromJson(Map<String, dynamic> json) => Profile(
        id: json['id'] as String,
        email: json['email'] as String,
        fullName: json['full_name'] as String?,
        avatarUrl: json['avatar_url'] as String?,
        role: json['role'] as String? ?? 'fitness_user',
        subscriptionTier: json['subscription_tier'] as String? ?? 'free',
        aiPlansUsedThisMonth: (json['ai_plans_used_this_month'] as num?)?.toInt() ?? 0,
        followerCount: (json['follower_count'] as num?)?.toInt() ?? 0,
        bio: json['bio'] as String?,
        heightCm: (json['height_cm'] as num?)?.toInt(),
        weightKg: (json['weight_kg'] as num?)?.toDouble(),
        primaryGoal: json['primary_goal'] as String?,
        fitnessLevel: json['fitness_level'] as String?,
        country: json['country'] as String?,
        mealPreference: json['meal_preference'] as String?,
        dateOfBirth: json['date_of_birth'] != null ? DateTime.tryParse(json['date_of_birth'] as String) : null,
        gender: json['gender'] as String?,
        targetFocusAreas: (json['target_focus_areas'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? const [],
        bodyFatRange: json['body_fat_range'] as String?,
        desiredBodyFat: json['desired_body_fat'] as String?,
        targetWeightKg: (json['target_weight_kg'] as num?)?.toDouble(),
        targetPace: json['target_pace'] as String?,
        weightLossHistory: json['weight_loss_history'] as String?,
        lifestyleIssues: (json['lifestyle_issues'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? const [],
        injuries: (json['injuries'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? const [],
        equipment: (json['equipment'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? const [],
        workoutDays: (json['workout_days'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? const [],
        workoutReminder: json['workout_reminder'] as bool? ?? false,
      );
}
