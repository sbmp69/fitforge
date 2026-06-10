class Exercise {
  final String name;
  final int sets;
  final String reps;
  final int restSeconds;
  final String? notes;

  const Exercise({
    required this.name,
    required this.sets,
    required this.reps,
    required this.restSeconds,
    this.notes,
  });

  factory Exercise.fromJson(Map<String, dynamic> json) => Exercise(
        name: json['name'] as String? ?? '',
        sets: json['sets'] as int? ?? 0,
        reps: json['reps']?.toString() ?? '',
        restSeconds: json['restSeconds'] as int? ?? 60,
        notes: json['notes'] as String?,
      );
}

class WorkoutDay {
  final String day;
  final String focus;
  final List<Exercise> exercises;
  final String? warmup;
  final String? cooldown;

  const WorkoutDay({
    required this.day,
    required this.focus,
    required this.exercises,
    this.warmup,
    this.cooldown,
  });

  factory WorkoutDay.fromJson(Map<String, dynamic> json) => WorkoutDay(
        day: json['day'] as String? ?? '',
        focus: json['focus'] as String? ?? '',
        exercises: (json['exercises'] as List<dynamic>? ?? [])
            .map((e) => Exercise.fromJson(e as Map<String, dynamic>))
            .toList(),
        warmup: json['warmup'] as String?,
        cooldown: json['cooldown'] as String?,
      );
}

class WorkoutPlan {
  final String id;
  final String title;
  final String goal;
  final String level;
  final int daysPerWeek;
  final List<WorkoutDay> days;
  final String? summary;

  const WorkoutPlan({
    required this.id,
    required this.title,
    required this.goal,
    required this.level,
    required this.daysPerWeek,
    required this.days,
    this.summary,
  });

  factory WorkoutPlan.fromJson(Map<String, dynamic> json) {
    final planData = json['plan_data'] as Map<String, dynamic>? ?? {};
    return WorkoutPlan(
      id: json['id'] as String,
      title: json['title'] as String? ?? 'Workout Plan',
      goal: json['goal'] as String? ?? '',
      level: json['level'] as String? ?? '',
      daysPerWeek: json['days_per_week'] as int? ?? 0,
      summary: planData['summary'] as String?,
      days: (planData['days'] as List<dynamic>? ?? [])
          .map((d) => WorkoutDay.fromJson(d as Map<String, dynamic>))
          .toList(),
    );
  }
}
