class MealItem {
  final String name;
  final int calories;
  final int protein;
  final int carbs;
  final int fat;

  const MealItem({
    required this.name,
    required this.calories,
    required this.protein,
    required this.carbs,
    required this.fat,
  });

  factory MealItem.fromJson(Map<String, dynamic> json) => MealItem(
        name: json['name'] as String? ?? '',
        calories: json['calories'] as int? ?? 0,
        protein: json['protein'] as int? ?? 0,
        carbs: json['carbs'] as int? ?? 0,
        fat: json['fat'] as int? ?? 0,
      );
}

class DayMeals {
  final String day;
  final MealItem breakfast;
  final MealItem lunch;
  final MealItem dinner;
  final List<MealItem> snacks;

  const DayMeals({
    required this.day,
    required this.breakfast,
    required this.lunch,
    required this.dinner,
    required this.snacks,
  });

  factory DayMeals.fromJson(Map<String, dynamic> json) => DayMeals(
        day: json['day'] as String? ?? '',
        breakfast: MealItem.fromJson(json['breakfast'] as Map<String, dynamic>? ?? {}),
        lunch: MealItem.fromJson(json['lunch'] as Map<String, dynamic>? ?? {}),
        dinner: MealItem.fromJson(json['dinner'] as Map<String, dynamic>? ?? {}),
        snacks: (json['snacks'] as List<dynamic>? ?? [])
            .map((s) => MealItem.fromJson(s as Map<String, dynamic>))
            .toList(),
      );
}

class MealPlan {
  final String id;
  final String title;
  final int calorieTarget;
  final String dietaryPreference;
  final List<DayMeals> days;

  const MealPlan({
    required this.id,
    required this.title,
    required this.calorieTarget,
    required this.dietaryPreference,
    required this.days,
  });

  factory MealPlan.fromJson(Map<String, dynamic> json) {
    final planData = json['plan_data'] as Map<String, dynamic>? ?? {};
    return MealPlan(
      id: json['id'] as String,
      title: json['title'] as String? ?? 'Meal Plan',
      calorieTarget: json['calorie_target'] as int? ?? 2000,
      dietaryPreference: json['dietary_preference'] as String? ?? 'non_veg',
      days: (planData['days'] as List<dynamic>? ?? [])
          .map((d) => DayMeals.fromJson(d as Map<String, dynamic>))
          .toList(),
    );
  }
}
