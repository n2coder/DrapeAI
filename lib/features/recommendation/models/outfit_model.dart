import 'package:style_ai/features/wardrobe/models/clothing_item.dart';

class OutfitModel {
  final String? id;
  final ClothingItem top;
  final ClothingItem bottom;
  final ClothingItem footwear;
  final String occasion;
  final String weatherContext;
  final double score;
  final String explanation;
  final List<String> styleNotes;
  final bool isSaved;
  final DateTime? createdAt;

  const OutfitModel({
    this.id,
    required this.top,
    required this.bottom,
    required this.footwear,
    required this.occasion,
    required this.weatherContext,
    required this.score,
    required this.explanation,
    this.styleNotes = const [],
    this.isSaved = false,
    this.createdAt,
  });

  factory OutfitModel.fromJson(Map<String, dynamic> json) {
    return OutfitModel(
      id: json['id'] as String?,
      top: ClothingItem.fromJson(json['top'] as Map<String, dynamic>),
      bottom: ClothingItem.fromJson(json['bottom'] as Map<String, dynamic>),
      footwear: ClothingItem.fromJson(json['footwear'] as Map<String, dynamic>),
      occasion: json['occasion'] as String,
      weatherContext: json['weather_context'] as String? ?? 'mild',
      score: (json['score'] as num?)?.toDouble() ?? 0.0,
      explanation: json['explanation'] as String? ?? '',
      styleNotes: (json['style_notes'] as List<dynamic>?)
              ?.cast<String>()
              .toList() ??
          [],
      isSaved: json['is_saved'] as bool? ?? false,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
    if (id != null) 'id': id,
    'top': top.toJson(),
    'bottom': bottom.toJson(),
    'footwear': footwear.toJson(),
    'occasion': occasion,
    'weather_context': weatherContext,
    'score': score,
    'explanation': explanation,
    'style_notes': styleNotes,
    'is_saved': isSaved,
    if (createdAt != null) 'created_at': createdAt!.toIso8601String(),
  };

  OutfitModel copyWith({
    String? id,
    ClothingItem? top,
    ClothingItem? bottom,
    ClothingItem? footwear,
    String? occasion,
    String? weatherContext,
    double? score,
    String? explanation,
    List<String>? styleNotes,
    bool? isSaved,
    DateTime? createdAt,
  }) {
    return OutfitModel(
      id: id ?? this.id,
      top: top ?? this.top,
      bottom: bottom ?? this.bottom,
      footwear: footwear ?? this.footwear,
      occasion: occasion ?? this.occasion,
      weatherContext: weatherContext ?? this.weatherContext,
      score: score ?? this.score,
      explanation: explanation ?? this.explanation,
      styleNotes: styleNotes ?? this.styleNotes,
      isSaved: isSaved ?? this.isSaved,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  String get scoreLabel {
    if (score >= 0.9) return 'Perfect Match';
    if (score >= 0.75) return 'Great Match';
    if (score >= 0.6) return 'Good Match';
    return 'Decent Match';
  }

  int get scorePercentage => (score * 100).round();
}
