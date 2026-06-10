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
  });

  factory Profile.fromJson(Map<String, dynamic> json) => Profile(
        id: json['id'] as String,
        email: json['email'] as String,
        fullName: json['full_name'] as String?,
        avatarUrl: json['avatar_url'] as String?,
        role: json['role'] as String? ?? 'fitness_user',
        subscriptionTier: json['subscription_tier'] as String? ?? 'free',
        aiPlansUsedThisMonth: json['ai_plans_used_this_month'] as int? ?? 0,
        followerCount: json['follower_count'] as int? ?? 0,
        bio: json['bio'] as String?,
        heightCm: json['height_cm'] as int?,
        weightKg: (json['weight_kg'] as num?)?.toDouble(),
        primaryGoal: json['primary_goal'] as String?,
        fitnessLevel: json['fitness_level'] as String?,
      );
}
