import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:style_ai/core/services/api_service.dart';
import 'package:style_ai/core/services/weather_service.dart';
import 'package:style_ai/features/recommendation/models/outfit_model.dart';

class RecommendationState {
  final OutfitModel? todayOutfit;
  final OutfitModel? currentOutfit;
  final List<OutfitModel> savedOutfits;
  final bool isLoading;
  final String? errorMessage;
  final String? selectedOccasion;
  final WeatherData? weather;
  final bool isWeatherLoading;

  const RecommendationState({
    this.todayOutfit,
    this.currentOutfit,
    this.savedOutfits = const [],
    this.isLoading = false,
    this.errorMessage,
    this.selectedOccasion,
    this.weather,
    this.isWeatherLoading = false,
  });

  RecommendationState copyWith({
    OutfitModel? todayOutfit,
    OutfitModel? currentOutfit,
    List<OutfitModel>? savedOutfits,
    bool? isLoading,
    String? errorMessage,
    String? selectedOccasion,
    WeatherData? weather,
    bool? isWeatherLoading,
  }) {
    return RecommendationState(
      todayOutfit: todayOutfit ?? this.todayOutfit,
      currentOutfit: currentOutfit ?? this.currentOutfit,
      savedOutfits: savedOutfits ?? this.savedOutfits,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
      selectedOccasion: selectedOccasion ?? this.selectedOccasion,
      weather: weather ?? this.weather,
      isWeatherLoading: isWeatherLoading ?? this.isWeatherLoading,
    );
  }
}

class RecommendationNotifier extends StateNotifier<RecommendationState> {
  final ApiService _apiService;
  final WeatherService _weatherService;

  RecommendationNotifier({
    ApiService? apiService,
    WeatherService? weatherService,
  })  : _apiService = apiService ?? ApiService(),
        _weatherService = weatherService ?? WeatherService(),
        super(const RecommendationState());

  Future<void> fetchTodayRecommendation({String? city}) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      if (city != null) {
        await _fetchWeather(city);
      }
      final data = await _apiService.getTodayRecommendation();
      final outfit = OutfitModel.fromJson(data);
      state = state.copyWith(
        isLoading: false,
        todayOutfit: outfit,
        currentOutfit: outfit,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Failed to load recommendation: ${e.toString()}',
      );
    }
  }

  Future<void> fetchRecommendationByOccasion(String occasion) async {
    state = state.copyWith(
      isLoading: true,
      errorMessage: null,
      selectedOccasion: occasion,
    );
    try {
      final weatherContext = state.weather != null
          ? _weatherService.getWeatherOutfitContext(state.weather!)
          : null;
      final data = await _apiService.getRecommendationByOccasion(
        occasion: occasion,
        weatherContext: weatherContext,
      );
      final outfit = OutfitModel.fromJson(data);
      state = state.copyWith(isLoading: false, currentOutfit: outfit);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Failed to get recommendation: ${e.toString()}',
      );
    }
  }

  Future<void> tryAnother() async {
    final occasion = state.selectedOccasion;
    if (occasion != null) {
      await fetchRecommendationByOccasion(occasion);
    } else {
      await fetchTodayRecommendation();
    }
  }

  Future<bool> saveCurrentOutfit() async {
    final outfit = state.currentOutfit;
    if (outfit == null) return false;
    if (outfit.id == null) {
      state = state.copyWith(errorMessage: 'Cannot save: outfit has no ID');
      return false;
    }

    try {
      await _apiService.saveRecommendation(outfit.id!);
      final updatedOutfit = outfit.copyWith(isSaved: true);
      state = state.copyWith(
        currentOutfit: updatedOutfit,
        savedOutfits: [...state.savedOutfits, updatedOutfit],
      );
      return true;
    } catch (e) {
      state = state.copyWith(errorMessage: 'Failed to save outfit');
      return false;
    }
  }

  Future<void> fetchSavedOutfits() async {
    try {
      final data = await _apiService.getSavedOutfits();
      final outfits = data
          .cast<Map<String, dynamic>>()
          .map(OutfitModel.fromJson)
          .toList();
      state = state.copyWith(savedOutfits: outfits);
    } catch (e) {
      state = state.copyWith(
        errorMessage: 'Failed to load saved outfits',
      );
    }
  }

  Future<void> _fetchWeather(String city) async {
    state = state.copyWith(isWeatherLoading: true);
    try {
      final weather = await _weatherService.getWeatherByCity(city);
      state = state.copyWith(weather: weather, isWeatherLoading: false);
    } catch (_) {
      state = state.copyWith(isWeatherLoading: false);
    }
  }

  void setOccasion(String occasion) {
    state = state.copyWith(selectedOccasion: occasion);
  }

  void clearError() {
    state = state.copyWith(errorMessage: null);
  }
}

final recommendationProvider =
    StateNotifierProvider<RecommendationNotifier, RecommendationState>((ref) {
  return RecommendationNotifier();
});

final currentOutfitProvider = Provider<OutfitModel?>((ref) {
  return ref.watch(recommendationProvider).currentOutfit;
});

final weatherProvider = Provider<WeatherData?>((ref) {
  return ref.watch(recommendationProvider).weather;
});
