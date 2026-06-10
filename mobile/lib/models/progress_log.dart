class ProgressLog {
  final String id;
  final String logDate;
  final double? weightKg;
  final bool workoutCompleted;
  final int waterMl;
  final double? sleepHours;

  const ProgressLog({
    required this.id,
    required this.logDate,
    this.weightKg,
    required this.workoutCompleted,
    required this.waterMl,
    this.sleepHours,
  });

  factory ProgressLog.fromJson(Map<String, dynamic> json) => ProgressLog(
        id: json['id'] as String,
        logDate: json['log_date'] as String,
        weightKg: (json['weight_kg'] as num?)?.toDouble(),
        workoutCompleted: json['workout_completed'] as bool? ?? false,
        waterMl: json['water_ml'] as int? ?? 0,
        sleepHours: (json['sleep_hours'] as num?)?.toDouble(),
      );
}
