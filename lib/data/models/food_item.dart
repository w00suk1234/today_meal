class FoodItem {
  const FoodItem({
    required this.id,
    required this.name,
    required this.category,
    required this.servingGram,
    required this.kcalPer100g,
    required this.carbPer100g,
    required this.proteinPer100g,
    required this.fatPer100g,
  });

  final String id;
  final String name;
  final String category;
  final double servingGram;
  final double kcalPer100g;
  final double carbPer100g;
  final double proteinPer100g;
  final double fatPer100g;

  factory FoodItem.fromJson(Map<String, dynamic> json) {
    double toDouble(Object? value) => value is num ? value.toDouble() : double.tryParse('$value') ?? 0;
    return FoodItem(
      id: json['id'] as String,
      name: json['name'] as String,
      category: json['category'] as String,
      servingGram: toDouble(json['servingGram']),
      kcalPer100g: toDouble(json['kcalPer100g']),
      carbPer100g: toDouble(json['carbPer100g']),
      proteinPer100g: toDouble(json['proteinPer100g']),
      fatPer100g: toDouble(json['fatPer100g']),
    );
  }
}
