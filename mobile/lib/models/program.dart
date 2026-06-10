class Program {
  final String id;
  final String name;
  final String description;
  final int durationWeeks;
  final int priceInr;
  final String? coverImageUrl;
  final double avgRating;
  final int reviewCount;
  final int purchaseCount;

  const Program({
    required this.id,
    required this.name,
    required this.description,
    required this.durationWeeks,
    required this.priceInr,
    this.coverImageUrl,
    required this.avgRating,
    required this.reviewCount,
    required this.purchaseCount,
  });

  factory Program.fromJson(Map<String, dynamic> json) => Program(
        id: json['id'] as String,
        name: json['name'] as String,
        description: json['description'] as String? ?? '',
        durationWeeks: json['duration_weeks'] as int? ?? 0,
        priceInr: json['price_inr'] as int? ?? 0,
        coverImageUrl: json['cover_image_url'] as String?,
        avgRating: (json['avg_rating'] as num?)?.toDouble() ?? 0,
        reviewCount: json['review_count'] as int? ?? 0,
        purchaseCount: json['purchase_count'] as int? ?? 0,
      );
}
