import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:style_ai/core/theme/app_theme.dart';
import 'package:style_ai/features/auth/providers/auth_provider.dart';
import 'package:style_ai/widgets/common/primary_button.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen>
    with SingleTickerProviderStateMixin {
  final _phoneController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  String _selectedCountryCode = '+91';
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _fadeAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOutCubic),
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _phoneController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    ref.listenManual(authProvider, (previous, next) {
      if (next.status == AuthStatus.otpSent) {
        context.push('/otp');
      } else if (next.status == AuthStatus.authenticated) {
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
  }

  void _sendOtp() {
    if (_formKey.currentState?.validate() ?? false) {
      final phone = '$_selectedCountryCode${_phoneController.text.trim()}';
      ref.read(authProvider.notifier).sendOtp(phone);
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final theme = Theme.of(context);
    final size = MediaQuery.of(context).size;

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: SlideTransition(
              position: _slideAnimation,
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(height: size.height * 0.08),
                    // Logo & Branding
                    Center(
                      child: Column(
                        children: [
                          Image.asset(
                            'assets/images/logo.png',
                            width: 90,
                            height: 90,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'DrapeAI',
                            style: theme.textTheme.displaySmall?.copyWith(
                              fontWeight: FontWeight.w800,
                              foreground: Paint()
                                ..shader = const LinearGradient(
                                  colors: [
                                    AppTheme.primaryColor,
                                    AppTheme.secondaryColor,
                                  ],
                                ).createShader(
                                  const Rect.fromLTWH(0, 0, 200, 70),
                                ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Your Personal Fashion AI',
                            style: theme.textTheme.bodyMedium,
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: size.height * 0.06),
                    Text(
                      'Welcome back 👋',
                      style: theme.textTheme.headlineMedium,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Enter your phone number to get started',
                      style: theme.textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 32),
                    // Phone number field
                    TextFormField(
                      controller: _phoneController,
                      keyboardType: TextInputType.phone,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                        LengthLimitingTextInputFormatter(10),
                      ],
                      style: theme.textTheme.bodyLarge,
                      decoration: InputDecoration(
                        hintText: '98765 43210',
                        prefixIcon: GestureDetector(
                          onTap: _showCountryPicker,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 16,
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Text(
                                  '🇮🇳',
                                  style: TextStyle(fontSize: 20),
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  _selectedCountryCode,
                                  style: theme.textTheme.titleMedium,
                                ),
                                const SizedBox(width: 4),
                                Icon(
                                  Icons.keyboard_arrow_down_rounded,
                                  size: 18,
                                  color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                                ),
                                Container(
                                  width: 1,
                                  height: 20,
                                  margin: const EdgeInsets.only(left: 8),
                                  color: theme.dividerColor,
                                ),
                              ],
                            ),
                          ),
                        ),
                        prefixIconConstraints: const BoxConstraints(minWidth: 0),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter your phone number';
                        }
                        if (value.length != 10) {
                          return 'Please enter a valid 10-digit phone number';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'We\'ll send you a one-time verification code',
                      style: theme.textTheme.bodySmall,
                    ),
                    const SizedBox(height: 32),
                    PrimaryButton(
                      label: 'Send OTP',
                      isLoading: authState.isLoading,
                      onPressed: _sendOtp,
                      icon: Icons.send_rounded,
                    ),
                    const SizedBox(height: 24),
                    // Terms
                    Center(
                      child: Text.rich(
                        TextSpan(
                          text: 'By continuing, you agree to our ',
                          style: theme.textTheme.bodySmall,
                          children: [
                            TextSpan(
                              text: 'Terms of Service',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: AppTheme.primaryColor,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            TextSpan(
                              text: ' and ',
                              style: theme.textTheme.bodySmall,
                            ),
                            TextSpan(
                              text: 'Privacy Policy',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: AppTheme.primaryColor,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    SizedBox(height: size.height * 0.05),
                    // Feature highlights
                    _buildFeatureHighlights(theme),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFeatureHighlights(ThemeData theme) {
    final features = [
      (Icons.checkroom_rounded, 'AI-powered outfit recommendations'),
      (Icons.wb_sunny_rounded, 'Weather-aware styling'),
      (Icons.add_photo_alternate_rounded, 'Smart wardrobe management'),
    ];
    return Column(
      children: features
          .map(
            (f) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: AppTheme.primaryColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(f.$1, color: AppTheme.primaryColor, size: 18),
                  ),
                  const SizedBox(width: 12),
                  Text(f.$2, style: theme.textTheme.bodyMedium),
                ],
              ),
            ),
          )
          .toList(),
    );
  }

  void _showCountryPicker() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        final codes = [
          ('🇮🇳', '+91', 'India'),
          ('🇺🇸', '+1', 'United States'),
          ('🇬🇧', '+44', 'United Kingdom'),
          ('🇦🇺', '+61', 'Australia'),
          ('🇨🇦', '+1', 'Canada'),
          ('🇸🇬', '+65', 'Singapore'),
          ('🇦🇪', '+971', 'UAE'),
        ];
        return ListView(
          shrinkWrap: true,
          children: [
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text(
                'Select Country',
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 18),
              ),
            ),
            ...codes.map(
              (c) => ListTile(
                leading: Text(c.$1, style: const TextStyle(fontSize: 24)),
                title: Text(c.$3),
                trailing: Text(
                  c.$2,
                  style: const TextStyle(color: AppTheme.primaryColor),
                ),
                onTap: () {
                  setState(() => _selectedCountryCode = c.$2);
                  Navigator.pop(context);
                },
              ),
            ),
          ],
        );
      },
    );
  }
}
