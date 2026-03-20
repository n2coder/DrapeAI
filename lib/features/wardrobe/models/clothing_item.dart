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
  });

  factory ClothingItem.fromJson(Map<String, dynamic> json) {
    return ClothingItem(
      id: json['id'] as String,
      category: json['category'] as String,
      color: json['color'] as String,
      style: json['style'] as String,
      imageUrl: json['image_url'] as String,
      userId: json['user_id'] as String,
      brand: json['brand'] as String?,
      notes: json['notes'] as String?,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'] as String)
          : null,
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
