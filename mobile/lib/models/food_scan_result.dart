class FoodScanResult {
  final String foodName;
  final String portionSize;
  final int calories;
  final double proteinG;
  final double carbsG;
  final double fatG;
  final double fiberG;
  final int healthScore; // 0 to 100
  final String healthCategory; // 'healthy', 'moderate', 'unhealthy'
  final String categoryColor; // 'green', 'yellow', 'red'
  final double meterPosition; // 0.0 to 1.0
  final List<String> ingredients;
  final String coachVerdict;
  final List<String> pros;
  final List<String> cons;
  final String? scannedImagePath;

  FoodScanResult({
    required this.foodName,
    required this.portionSize,
    required this.calories,
    required this.proteinG,
    required this.carbsG,
    required this.fatG,
    required this.fiberG,
    required this.healthScore,
    required this.healthCategory,
    required this.categoryColor,
    required this.meterPosition,
    required this.ingredients,
    required this.coachVerdict,
    required this.pros,
    required this.cons,
    this.scannedImagePath,
  });

  factory FoodScanResult.fromJson(Map<String, dynamic> json, {String? imagePath}) {
    return FoodScanResult(
      foodName: json['food_name'] as String? ?? 'Scanned Meal',
      portionSize: json['portion_size'] as String? ?? '1 serving',
      calories: (json['calories'] as num?)?.toInt() ?? 0,
      proteinG: (json['protein_g'] as num?)?.toDouble() ?? 0.0,
      carbsG: (json['carbs_g'] as num?)?.toDouble() ?? 0.0,
      fatG: (json['fat_g'] as num?)?.toDouble() ?? 0.0,
      fiberG: (json['fiber_g'] as num?)?.toDouble() ?? 0.0,
      healthScore: (json['health_score'] as num?)?.toInt() ?? 50,
      healthCategory: json['health_category'] as String? ?? 'moderate',
      categoryColor: json['category_color'] as String? ?? 'yellow',
      meterPosition: (json['meter_position'] as num?)?.toDouble() ?? 0.5,
      ingredients: (json['ingredients'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      coachVerdict: json['coach_verdict'] as String? ?? '',
      pros: (json['pros'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      cons: (json['cons'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      scannedImagePath: imagePath,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'food_name': foodName,
      'portion_size': portionSize,
      'calories': calories,
      'protein_g': proteinG,
      'carbs_g': carbsG,
      'fat_g': fatG,
      'fiber_g': fiberG,
      'health_score': healthScore,
      'health_category': healthCategory,
      'category_color': categoryColor,
      'meter_position': meterPosition,
      'ingredients': ingredients,
      'coach_verdict': coachVerdict,
      'pros': pros,
      'cons': cons,
    };
  }
}

class NonFoodItemException implements Exception {
  final String message;
  final String detectedSubject;

  NonFoodItemException({
    required this.message,
    this.detectedSubject = 'Non-food item',
  });

  @override
  String toString() => message;
}
