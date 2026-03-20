import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:style_ai/core/services/api_service.dart';
import 'package:style_ai/features/wardrobe/models/clothing_item.dart';

class WardrobeState {
  final List<ClothingItem> items;
  final bool isLoading;
  final String? errorMessage;
  final String? selectedCategory;
  final bool isUploading;

  const WardrobeState({
    this.items = const [],
    this.isLoading = false,
    this.errorMessage,
    this.selectedCategory,
    this.isUploading = false,
  });

  WardrobeState copyWith({
    List<ClothingItem>? items,
    bool? isLoading,
    String? errorMessage,
    String? selectedCategory,
    bool? isUploading,
  }) {
    return WardrobeState(
      items: items ?? this.items,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
      selectedCategory: selectedCategory ?? this.selectedCategory,
      isUploading: isUploading ?? this.isUploading,
    );
  }

  List<ClothingItem> get filteredItems {
    if (selectedCategory == null || selectedCategory == 'All') {
      return items;
    }
    return items.where((item) => item.category == selectedCategory).toList();
  }

  Map<String, int> get categoryCounts {
    final counts = <String, int>{'All': items.length};
    for (final item in items) {
      counts[item.category] = (counts[item.category] ?? 0) + 1;
    }
    return counts;
  }
}

class WardrobeNotifier extends StateNotifier<WardrobeState> {
  final ApiService _apiService;

  WardrobeNotifier({ApiService? apiService})
      : _apiService = apiService ?? ApiService(),
        super(const WardrobeState());

  Future<void> fetchItems() async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final items = await _apiService.getWardrobeItems();
      final clothingItems = items
          .cast<Map<String, dynamic>>()
          .map(ClothingItem.fromJson)
          .toList();
      state = state.copyWith(isLoading: false, items: clothingItems);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Failed to load wardrobe: ${e.toString()}',
      );
    }
  }

  Future<bool> addItem({
    required File imageFile,
    required String category,
    required String color,
    required String style,
    String? brand,
    String? notes,
  }) async {
    state = state.copyWith(isUploading: true, errorMessage: null);
    try {
      final imageUrl = await _apiService.uploadImage(imageFile);
      final data = await _apiService.addClothingItem(
        category: category,
        color: color,
        style: style,
        imageUrl: imageUrl,
        brand: brand,
        notes: notes,
      );
      final newItem = ClothingItem.fromJson(data);
      state = state.copyWith(
        isUploading: false,
        items: [...state.items, newItem],
      );
      return true;
    } catch (e) {
      state = state.copyWith(
        isUploading: false,
        errorMessage: 'Failed to add item: ${e.toString()}',
      );
      return false;
    }
  }

  Future<bool> updateItem({
    required String itemId,
    String? category,
    String? color,
    String? style,
    String? brand,
    String? notes,
    File? newImageFile,
  }) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final updates = <String, dynamic>{};
      if (category != null) updates['category'] = category;
      if (color != null) updates['color'] = color;
      if (style != null) updates['style'] = style;
      if (brand != null) updates['brand'] = brand;
      if (notes != null) updates['notes'] = notes;
      if (newImageFile != null) {
        final imageUrl = await _apiService.uploadImage(newImageFile);
        updates['image_url'] = imageUrl;
      }

      final data = await _apiService.updateClothingItem(
        itemId: itemId,
        updates: updates,
      );
      final updatedItem = ClothingItem.fromJson(data);
      final updatedItems = state.items.map((item) {
        return item.id == itemId ? updatedItem : item;
      }).toList();
      state = state.copyWith(isLoading: false, items: updatedItems);
      return true;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Failed to update item: ${e.toString()}',
      );
      return false;
    }
  }

  Future<bool> deleteItem(String itemId) async {
    try {
      await _apiService.deleteClothingItem(itemId);
      final updatedItems = state.items.where((item) => item.id != itemId).toList();
      state = state.copyWith(items: updatedItems);
      return true;
    } catch (e) {
      state = state.copyWith(
        errorMessage: 'Failed to delete item: ${e.toString()}',
      );
      return false;
    }
  }

  void setCategory(String? category) {
    state = state.copyWith(selectedCategory: category);
  }

  void clearError() {
    state = state.copyWith(errorMessage: null);
  }
}

final wardrobeProvider = StateNotifierProvider<WardrobeNotifier, WardrobeState>((ref) {
  return WardrobeNotifier();
});

final filteredWardrobeProvider = Provider<List<ClothingItem>>((ref) {
  return ref.watch(wardrobeProvider).filteredItems;
});
