import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:pin_code_fields/pin_code_fields.dart';

import 'package:style_ai/core/theme/app_theme.dart';
import 'package:style_ai/features/auth/providers/auth_provider.dart';
import 'package:style_ai/widgets/common/primary_button.dart';

class OtpScreen extends ConsumerStatefulWidget {
  const OtpScreen({super.key});

  @override
  ConsumerState<OtpScreen> createState() => _OtpScreenState();
}

class _OtpScreenState extends ConsumerState<OtpScreen> {
  final _otpController = TextEditingController();
  String _otp = '';
  int _resendTimer = 30;
  Timer? _timer;
  bool _canResend = false;
  bool _disposed = false;

  @override
  void initState() {
    super.initState();
    _startResendTimer();
  }

  @override
  void dispose() {
    _disposed = true;
    _timer?.cancel();
    _otpController.dispose();
    super.dispose();
  }

  void _startResendTimer() {
    if (!mounted) return;
    setState(() {
      _resendTimer = 30;
      _canResend = false;
    });
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_disposed || !mounted) {
        timer.cancel();
        return;
      }
      if (_resendTimer <= 1) {
        timer.cancel();
        setState(() => _canResend = true);
      } else {
        setState(() => _resendTimer--);
      }
    });
  }

  void _verifyOtp() {
    if (_otp.length == 6) {
      ref.read(authProvider.notifier).verifyOtp(_otp);
    }
  }

  void _resendOtp() {
    if (_canResend) {
      final phoneNumber = ref.read(authProvider).phoneNumber;
      if (phoneNumber != null) {
        ref.read(authProvider.notifier).sendOtp(phoneNumber);
        _startResendTimer();
      }
    }
  }


  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final theme = Theme.of(context);
    final phoneNumber = authState.phoneNumber ?? '';

    ref.listen(authProvider, (previous, next) {
      if (!mounted) return;
      if (next.status == AuthStatus.authenticated) {
        context.go('/home');
      } else if (next.status == AuthStatus.onboardingRequired) {
        context.go('/onboarding');
      } else if (next.status == AuthStatus.error && next.errorMessage != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(next.errorMessage!),
            backgroundColor: AppTheme.errorColor,
            behavior: SnackBarBehavior.floating,
          ),
        );
        ref.read(authProvider.notifier).clearError();
      }
    });

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => context.pop(),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 16),
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(
                  Icons.lock_outline_rounded,
                  color: AppTheme.primaryColor,
                  size: 28,
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'Verify your number',
                style: theme.textTheme.headlineMedium,
              ),
              const SizedBox(height: 10),
              Text.rich(
                TextSpan(
                  text: 'We\'ve sent a 6-digit code to ',
                  style: theme.textTheme.bodyMedium,
                  children: [
                    TextSpan(
                      text: phoneNumber,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 40),
              PinCodeTextField(
                appContext: context,
                length: 6,
                controller: _otpController,
                animationType: AnimationType.fade,
                keyboardType: TextInputType.number,
                pinTheme: PinTheme(
                  shape: PinCodeFieldShape.box,
                  borderRadius: BorderRadius.circular(12),
                  fieldHeight: 56,
                  fieldWidth: 48,
                  activeFillColor: theme.colorScheme.surface,
                  inactiveFillColor: theme.colorScheme.surface,
                  selectedFillColor: theme.colorScheme.surface,
                  activeColor: AppTheme.primaryColor,
                  inactiveColor: theme.dividerColor,
                  selectedColor: AppTheme.primaryColor,
                ),
                enableActiveFill: true,
                onChanged: (value) {
                  setState(() => _otp = value);
                },
                onCompleted: (value) {
                  setState(() => _otp = value);
                  _verifyOtp();
                },
                textStyle: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: AppTheme.primaryColor,
                ),
              ),
              const SizedBox(height: 32),
              PrimaryButton(
                label: 'Verify OTP',
                isLoading: authState.isLoading,
                onPressed: _otp.length == 6 ? _verifyOtp : null,
              ),
              const SizedBox(height: 24),
              Center(
                child: _canResend
                    ? TextButton(
                        onPressed: _resendOtp,
                        child: Text.rich(
                          TextSpan(
                            text: 'Didn\'t receive the code? ',
                            style: theme.textTheme.bodyMedium,
                            children: [
                              TextSpan(
                                text: 'Resend',
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: AppTheme.primaryColor,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      )
                    : Text.rich(
                        TextSpan(
                          text: 'Resend code in ',
                          style: theme.textTheme.bodyMedium,
                          children: [
                            TextSpan(
                              text: '${_resendTimer}s',
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: AppTheme.primaryColor,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
              ),
              const Spacer(),
              // Security badge
              Center(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.shield_outlined,
                      size: 16,
                      color: AppTheme.successColor,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'Secured by Firebase Authentication',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: AppTheme.successColor,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}
