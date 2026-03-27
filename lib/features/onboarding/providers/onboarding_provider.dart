import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:style_ai/core/services/api_service.dart';
import 'package:style_ai/features/auth/providers/auth_provider.dart';

class OnboardingState {
  final String? gender;
  final String? ageRange;
  final String? city;
  final List<String> stylePreferences;
  final bool isLoading;
  final String? errorMessage;
  final bool isComplete;

  const OnboardingState({
    this.gender,
    this.ageRange,
    this.city,
    this.stylePreferences = const [],
    this.isLoading = false,
    this.errorMessage,
    this.isComplete = false,
  });

  OnboardingState copyWith({
    String? gender,
    String? ageRange,
    String? city,
    List<String>? stylePreferences,
    bool? isLoading,
    String? errorMessage,
    bool? isComplete,
  }) {
    return OnboardingState(
      gender: gender ?? this.gender,
      ageRange: ageRange ?? this.ageRange,
      city: city ?? this.city,
      stylePreferences: stylePreferences ?? this.stylePreferences,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
      isComplete: isComplete ?? this.isComplete,
    );
  }

  bool get isStep1Complete => gender != null;
  bool get isStep2Complete => city != null && city!.isNotEmpty;
  bool get isStep3Complete => stylePreferences.isNotEmpty;
}

class OnboardingNotifier extends StateNotifier<OnboardingState> {
  final ApiService _apiService;
  final AuthNotifier _authNotifier;

  OnboardingNotifier({
    required ApiService apiService,
    required AuthNotifier authNotifier,
  })  : _apiService = apiService,
        _authNotifier = authNotifier,
        super(const OnboardingState());

  void setGender(String gender) {
    state = state.copyWith(gender: gender);
  }

  void setAgeRange(String ageRange) {
    state = state.copyWith(ageRange: ageRange);
  }

  void setCity(String city) {
    state = state.copyWith(city: city);
  }

  void toggleStylePreference(String style) {
    final prefs = List<String>.from(state.stylePreferences);
    if (prefs.contains(style)) {
      prefs.remove(style);
    } else if (prefs.length < 2) {
      prefs.add(style);
    }
    state = state.copyWith(stylePreferences: prefs);
  }

  Future<bool> submitOnboarding() async {
    if (state.gender == null || state.city == null || state.stylePreferences.isEmpty) {
      state = state.copyWith(
        errorMessage: 'Please complete all onboarding steps',
      );
      return false;
    }

    state = state.copyWith(isLoading: true, errorMessage: null);

    try {
      await _apiService.completeOnboarding(
        gender: state.gender!,
        ageRange: state.ageRange ?? '18-24',
        city: state.city!,
        stylePreferences: state.stylePreferences,
      );
      // Persist city locally so weather loads correctly on home screen
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('user_city', state.city!);
      await _authNotifier.markOnboardingComplete();
      state = state.copyWith(isLoading: false, isComplete: true);
      return true;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.toString(),
      );
      return false;
    }
  }

  void clearError() {
    state = state.copyWith(errorMessage: null);
  }
}

final onboardingProvider =
    StateNotifierProvider<OnboardingNotifier, OnboardingState>((ref) {
  return OnboardingNotifier(
    apiService: ApiService(),
    authNotifier: ref.read(authProvider.notifier),
  );
});
