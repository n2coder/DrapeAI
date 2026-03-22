class ClothingItem {
  final String id;
  final String category;
  final String color;
  final String style;
  final String imageUrl;
  final String userId;
  final String? brand;
  final String? notes;
  final DateTime? createdAt;
  // AI-enhanced versions — populated async after upload (~5s)
  final String? enhancedUrl;  // Cloudinary BG-removed / colour-corrected
  final String? dalleUrl;     // DALL-E clean render (low-quality photos only)

  const ClothingItem({
    required this.id,
    required this.category,
    required this.color,
    required this.style,
    required this.imageUrl,
    required this.userId,
    this.brand,
    this.notes,
    this.createdAt,
    this.enhancedUrl,
    this.dalleUrl,
  });

  /// Best available image: cloudinary-enhanced > original (DALL-E excluded from grid — unreliable garment type)
  String get displayUrl => enhancedUrl ?? imageUrl;

  /// True once any AI-enhanced version is available
  bool get isEnhanced => enhancedUrl != null || dalleUrl != null;

  /// Converts backend lowercase_underscore enum values to Title Case with spaces.
  /// e.g. "ethnic_wear" → "Ethnic Wear", "bottom" → "Bottom"
  static String _normalizeLabel(String? v) {
    if (v == null || v.isEmpty) return '';
    return v
        .split('_')
        .map((w) => w.isEmpty ? '' : '${w[0].toUpperCase()}${w.substring(1)}')
        .join(' ');
  }

  factory ClothingItem.fromJson(Map<String, dynamic> json) {
    return ClothingItem(
      id: json['id'] as String? ?? '',
      category: _normalizeLabel(json['category'] as String? ?? 'other'),
      color: _normalizeLabel(json['color'] as String? ?? ''),
      style: _normalizeLabel(json['style'] as String?),
      imageUrl: json['image_url'] as String? ?? '',
      userId: json['user_id'] as String? ?? '',
      brand: json['brand'] as String?,
      notes: json['notes'] as String?,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'] as String)
          : null,
      enhancedUrl: json['enhanced_url'] as String?,
      dalleUrl: json['dalle_url'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'category': category,
    'color': color,
    'style': style,
    'image_url': imageUrl,
    'user_id': userId,
    if (brand != null) 'brand': brand,
    if (notes != null) 'notes': notes,
    if (createdAt != null) 'created_at': createdAt!.toIso8601String(),
    if (enhancedUrl != null) 'enhanced_url': enhancedUrl,
    if (dalleUrl != null) 'dalle_url': dalleUrl,
  };

  ClothingItem copyWith({
    String? id,
    String? category,
    String? color,
    String? style,
    String? imageUrl,
    String? userId,
    String? brand,
    String? notes,
    DateTime? createdAt,
    String? enhancedUrl,
    String? dalleUrl,
  }) {
    return ClothingItem(
      id: id ?? this.id,
      category: category ?? this.category,
      color: color ?? this.color,
      style: style ?? this.style,
      imageUrl: imageUrl ?? this.imageUrl,
      userId: userId ?? this.userId,
      brand: brand ?? this.brand,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
      enhancedUrl: enhancedUrl ?? this.enhancedUrl,
      dalleUrl: dalleUrl ?? this.dalleUrl,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ClothingItem && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() =>
      'ClothingItem(id: $id, category: $category, color: $color, style: $style)';
}
