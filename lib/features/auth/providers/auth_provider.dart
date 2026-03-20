import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import 'package:style_ai/core/constants/app_constants.dart';
import 'package:style_ai/core/services/api_service.dart';

enum AuthStatus {
  initial,
  unauthenticated,
  otpSent,
  verifying,
  authenticated,
  onboardingRequired,
  error,
}

class AuthState {
  final AuthStatus status;
  final String? phoneNumber;
  final String? verificationId;
  final String? jwtToken;
  final String? userId;
  final String? errorMessage;
  final bool isLoading;

  const AuthState({
    this.status = AuthStatus.initial,
    this.phoneNumber,
    this.verificationId,
    this.jwtToken,
    this.userId,
    this.errorMessage,
    this.isLoading = false,
  });

  AuthState copyWith({
    AuthStatus? status,
    String? phoneNumber,
    String? verificationId,
    String? jwtToken,
    String? userId,
    String? errorMessage,
    bool? isLoading,
  }) {
    return AuthState(
      status: status ?? this.status,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      verificationId: verificationId ?? this.verificationId,
      jwtToken: jwtToken ?? this.jwtToken,
      userId: userId ?? this.userId,
      errorMessage: errorMessage,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}

class AuthNotifier extends StateNotifier<AuthState> {
  final FirebaseAuth _firebaseAuth;
  final ApiService _apiService;
  final _secureStorage = const FlutterSecureStorage();

  AuthNotifier({
    FirebaseAuth? firebaseAuth,
    ApiService? apiService,
  })  : _firebaseAuth = firebaseAuth ?? FirebaseAuth.instance,
        _apiService = apiService ?? ApiService(),
        super(const AuthState()) {
    _init();
  }

  Future<void> _init() async {
    try {
      final token = await _secureStorage.read(key: AppConstants.jwtTokenKey);
      final userId = await _secureStorage.read(key: AppConstants.userIdKey);
      final onboardingCompleteStr = await _secureStorage.read(key: AppConstants.onboardingCompleteKey);
      final onboardingComplete = onboardingCompleteStr == 'true';

      if (token != null && userId != null) {
        state = state.copyWith(
          status: onboardingComplete
              ? AuthStatus.authenticated
              : AuthStatus.onboardingRequired,
          jwtToken: token,
          userId: userId,
        );
      } else {
        state = state.copyWith(status: AuthStatus.unauthenticated);
      }
    } catch (_) {
      state = state.copyWith(status: AuthStatus.unauthenticated);
    }
  }

  Future<void> sendOtp(String phoneNumber) async {
    state = state.copyWith(
      isLoading: true,
      errorMessage: null,
      phoneNumber: phoneNumber,
    );

    try {
      await _firebaseAuth.verifyPhoneNumber(
        phoneNumber: phoneNumber,
        timeout: const Duration(seconds: 60),
        verificationCompleted: (PhoneAuthCredential credential) async {
          await _signInWithCredential(credential);
        },
        verificationFailed: (FirebaseAuthException e) {
          state = state.copyWith(
            isLoading: false,
            status: AuthStatus.error,
            errorMessage: e.message ?? 'Phone verification failed',
          );
        },
        codeSent: (String verificationId, int? resendToken) {
          state = state.copyWith(
            isLoading: false,
            status: AuthStatus.otpSent,
            verificationId: verificationId,
          );
        },
        codeAutoRetrievalTimeout: (String verificationId) {
          state = state.copyWith(verificationId: verificationId);
        },
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        status: AuthStatus.error,
        errorMessage: e.toString(),
      );
    }
  }

  Future<void> verifyOtp(String otp) async {
    if (state.verificationId == null) {
      state = state.copyWith(
        status: AuthStatus.error,
        errorMessage: 'Verification ID not found. Please resend OTP.',
      );
      return;
    }

    state = state.copyWith(isLoading: true, status: AuthStatus.verifying);

    try {
      final credential = PhoneAuthProvider.credential(
        verificationId: state.verificationId!,
        smsCode: otp,
      );
      await _signInWithCredential(credential);
    } on FirebaseAuthException catch (e) {
      state = state.copyWith(
        isLoading: false,
        status: AuthStatus.otpSent,
        errorMessage: e.message ?? 'Invalid OTP. Please try again.',
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        status: AuthStatus.otpSent,
        errorMessage: 'Verification failed. Please try again.',
      );
    }
  }

  Future<void> _signInWithCredential(PhoneAuthCredential credential) async {
    try {
      final userCredential = await _firebaseAuth.signInWithCredential(credential);
      final firebaseToken = await userCredential.user?.getIdToken();

      if (firebaseToken == null) {
        throw Exception('Failed to get Firebase token');
      }

      final response = await _apiService.verifyOtp(
        phoneNumber: state.phoneNumber ?? '',
        otp: '',
        firebaseToken: firebaseToken,
      );

      final jwtToken = response['access_token'] as String;
      final userId = response['user_id'] as String;
      final isNewUser = response['is_new_user'] as bool? ?? false;

      await _secureStorage.write(key: AppConstants.jwtTokenKey, value: jwtToken);
      await _secureStorage.write(key: AppConstants.userIdKey, value: userId);

      state = state.copyWith(
        isLoading: false,
        status: isNewUser ? AuthStatus.onboardingRequired : AuthStatus.authenticated,
        jwtToken: jwtToken,
        userId: userId,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        status: AuthStatus.error,
        errorMessage: e.toString(),
      );
    }
  }

  Future<void> markOnboardingComplete() async {
    await _secureStorage.write(key: AppConstants.onboardingCompleteKey, value: 'true');
    state = state.copyWith(status: AuthStatus.authenticated);
  }

  Future<void> signOut() async {
    try {
      await _firebaseAuth.signOut();
      await _apiService.logout();
      await _secureStorage.delete(key: AppConstants.jwtTokenKey);
      await _secureStorage.delete(key: AppConstants.userIdKey);
      await _secureStorage.delete(key: AppConstants.onboardingCompleteKey);
      state = const AuthState(status: AuthStatus.unauthenticated);
    } catch (e) {
      state = state.copyWith(errorMessage: e.toString());
    }
  }

  void clearError() {
    state = state.copyWith(errorMessage: null);
  }
}

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier();
});

final isAuthenticatedProvider = Provider<bool>((ref) {
  final status = ref.watch(authProvider).status;
  return status == AuthStatus.authenticated;
});
