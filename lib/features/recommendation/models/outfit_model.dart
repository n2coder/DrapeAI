import 'package:style_ai/features/wardrobe/models/clothing_item.dart';

class OutfitModel {
  final String? id;
  final ClothingItem top;
  final ClothingItem bottom;
  final ClothingItem footwear;
  final String occasion;
  final String weatherContext;
  final double score;
  /// AI explanation — joined from the backend list.
  final String explanation;
  /// Raw style_notes string from backend, e.g. "[gpt-4o-mini] Keep it polished…"
  final String styleNotes;
  final bool isSaved;
  final DateTime? createdAt;
  final List<Map<String, dynamic>> trendingCombos;

  const OutfitModel({
    this.id,
    required this.top,
    required this.bottom,
    required this.footwear,
    required this.occasion,
    required this.weatherContext,
    required this.score,
    required this.explanation,
    this.styleNotes = '',
    this.isSaved = false,
    this.createdAt,
    this.trendingCombos = const [],
  });

  factory OutfitModel.fromJson(Map<String, dynamic> json) {
    // explanation is List<String> on backend
    final rawExplanation = json['explanation'];
    final String explanation;
    if (rawExplanation is List) {
      explanation = rawExplanation.cast<String>().join(' ');
    } else {
      explanation = rawExplanation as String? ?? '';
    }

    // style_notes is a String on backend: "[engine] tip text"
    final styleNotes = json['style_notes'] as String? ?? '';

    // weather_context is a map on backend
    final rawWeather = json['weather_context'];
    final String weatherContext;
    if (rawWeather is Map) {
      weatherContext = rawWeather['condition'] as String? ?? 'mild';
    } else {
      weatherContext = rawWeather as String? ?? 'mild';
    }

    final rawTrending = json['trending_combos'] as List<dynamic>? ?? [];

    return OutfitModel(
      id: json['id'] as String?,
      top: ClothingItem.fromJson((json['top'] as Map<String, dynamic>?) ?? {}),
      bottom: ClothingItem.fromJson((json['bottom'] as Map<String, dynamic>?) ?? {}),
      footwear: ClothingItem.fromJson((json['footwear'] as Map<String, dynamic>?) ?? {}),
      occasion: json['occasion'] as String? ?? 'Casual',
      weatherContext: weatherContext,
      score: (json['score'] as num?)?.toDouble() ?? 0.0,
      explanation: explanation,
      styleNotes: styleNotes,
      isSaved: json['is_saved'] as bool? ?? false,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'] as String)
          : null,
      trendingCombos: rawTrending
          .whereType<Map<String, dynamic>>()
          .toList(),
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
    'trending_combos': trendingCombos,
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
    String? styleNotes,
    bool? isSaved,
    DateTime? createdAt,
    List<Map<String, dynamic>>? trendingCombos,
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
      trendingCombos: trendingCombos ?? this.trendingCombos,
    );
  }

  /// Extracts the engine tag from style_notes, e.g. "gpt-4o-mini" or "rule-based".
  String? get engineLabel {
    final match = RegExp(r'^\[([^\]]+)\]').firstMatch(styleNotes);
    return match?.group(1);
  }

  /// Style tip text with the [engine] prefix stripped.
  String get styleNotesClean =>
      styleNotes.replaceFirst(RegExp(r'^\[[^\]]+\]\s*'), '');

  String get scoreLabel {
    if (score >= 90) return 'Perfect Match';
    if (score >= 75) return 'Great Match';
    if (score >= 60) return 'Good Match';
    return 'Decent Match';
  }

  int get scorePercentage => score.round().clamp(0, 100);
}
