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
      );
}
