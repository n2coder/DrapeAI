import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:style_ai/core/theme/app_theme.dart';
import 'package:style_ai/features/onboarding/providers/onboarding_provider.dart';
import 'package:style_ai/features/onboarding/screens/gender_screen.dart';
import 'package:style_ai/features/onboarding/screens/location_screen.dart';
import 'package:style_ai/features/onboarding/screens/style_preference_screen.dart';
import 'package:style_ai/widgets/common/primary_button.dart';

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final _pageController = PageController();
  int _currentPage = 0;

  final List<_OnboardingStep> _steps = const [
    _OnboardingStep(
      title: 'Tell us about you',
      subtitle: 'Step 1 of 3',
      icon: Icons.person_outline_rounded,
    ),
    _OnboardingStep(
      title: 'Your location',
      subtitle: 'Step 2 of 3',
      icon: Icons.location_on_outlined,
    ),
    _OnboardingStep(
      title: 'Your style',
      subtitle: 'Step 3 of 3',
      icon: Icons.style_outlined,
    ),
  ];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  bool _canProceed(OnboardingState state) {
    switch (_currentPage) {
      case 0:
        return state.isStep1Complete;
      case 1:
        return state.isStep2Complete;
      case 2:
        return state.isStep3Complete;
      default:
        return false;
    }
  }

  void _nextPage() {
    if (_currentPage < _steps.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOutCubic,
      );
    }
  }

  Future<void> _submit() async {
    final success = await ref.read(onboardingProvider.notifier).submitOnboarding();
    if (success && mounted) {
      context.go('/home');
    } else if (mounted) {
      final error = ref.read(onboardingProvider).errorMessage;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error ?? 'Something went wrong'),
          backgroundColor: AppTheme.errorColor,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final onboardingState = ref.watch(onboardingProvider);
    final theme = Theme.of(context);
    final isLastPage = _currentPage == _steps.length - 1;

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      if (_currentPage > 0)
                        GestureDetector(
                          onTap: () {
                            _pageController.previousPage(
                              duration: const Duration(milliseconds: 300),
                              curve: Curves.easeInOut,
                            );
                          },
                          child: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
                        )
                      else
                        const SizedBox(width: 20),
                      Text(
                        _steps[_currentPage].subtitle,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: AppTheme.primaryColor,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      TextButton(
                        onPressed: () => context.go('/home'),
                        child: Text(
                          'Skip',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurface.withOpacity(0.5),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  // Progress indicator
                  Row(
                    children: List.generate(_steps.length, (index) {
                      return Expanded(
                        child: Padding(
                          padding: EdgeInsets.only(
                            right: index < _steps.length - 1 ? 6 : 0,
                          ),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 300),
                            height: 4,
                            decoration: BoxDecoration(
                              color: index <= _currentPage
                                  ? AppTheme.primaryColor
                                  : theme.dividerColor,
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                        ),
                      );
                    }),
                  ),
                ],
              ),
            ),
            // Content
            Expanded(
              child: PageView(
                controller: _pageController,
                physics: const NeverScrollableScrollPhysics(),
                onPageChanged: (index) {
                  setState(() => _currentPage = index);
                },
                children: const [
                  _PageWrapper(child: GenderScreen()),
                  _PageWrapper(child: LocationScreen()),
                  _PageWrapper(child: StylePreferenceScreen()),
                ],
              ),
            ),
            // Bottom CTA
            Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  PrimaryButton(
                    label: isLastPage ? 'Get Started' : 'Continue',
                    isLoading: onboardingState.isLoading,
                    onPressed: _canProceed(onboardingState)
                        ? (isLastPage ? _submit : _nextPage)
                        : null,
                    icon: isLastPage
                        ? Icons.rocket_launch_rounded
                        : Icons.arrow_forward_rounded,
                  ),
                  if (!isLastPage) ...[
                    const SizedBox(height: 12),
                    TextButton(
                      onPressed: _nextPage,
                      child: Text(
                        'Skip this step',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurface.withOpacity(0.5),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _OnboardingStep {
  final String title;
  final String subtitle;
  final IconData icon;

  const _OnboardingStep({
    required this.title,
    required this.subtitle,
    required this.icon,
  });
}

class _PageWrapper extends StatelessWidget {
  final Widget child;

  const _PageWrapper({required this.child});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: child,
    );
  }
}
