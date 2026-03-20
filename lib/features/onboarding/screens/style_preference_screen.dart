import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:style_ai/core/constants/app_constants.dart';
import 'package:style_ai/core/theme/app_theme.dart';
import 'package:style_ai/features/onboarding/providers/onboarding_provider.dart';

class StylePreferenceScreen extends ConsumerWidget {
  const StylePreferenceScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final onboardingState = ref.watch(onboardingProvider);
    final theme = Theme.of(context);
    final selectedPrefs = onboardingState.stylePreferences;

    final styleOptions = [
      (
        'Ethnic',
        Icons.temple_hindu_outlined,
        'Sarees, kurtas, traditional wear',
        const Color(0xFFFF6B35),
      ),
      (
        'Casual',
        Icons.weekend_outlined,
        'Everyday comfortable fits',
        const Color(0xFF4ECDC4),
      ),
      (
        'Urban',
        Icons.location_city_outlined,
        'Streetwear, sneakers, hoodies',
        const Color(0xFF45B7D1),
      ),
      (
        'Formal',
        Icons.business_center_outlined,
        'Office wear, suits, blazers',
        const Color(0xFF6C63FF),
      ),
      (
        'Streetwear',
        Icons.style_outlined,
        'Bold graphics, oversized silhouettes',
        const Color(0xFFFF4757),
      ),
      (
        'Bohemian',
        Icons.spa_outlined,
        'Flowy, natural, earthy tones',
        const Color(0xFF8BC34A),
      ),
      (
        'Minimalist',
        Icons.remove_outlined,
        'Clean lines, neutral palette',
        const Color(0xFF9E9E9E),
      ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'What\'s your style?',
          style: theme.textTheme.headlineMedium,
        ),
        const SizedBox(height: 8),
        Text(
          'Choose up to 2 styles that best describe you',
          style: theme.textTheme.bodyMedium,
        ),
        const SizedBox(height: 16),
        if (selectedPrefs.isNotEmpty)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: AppTheme.primaryColor.withOpacity(0.08),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.check_circle_outline_rounded,
                  color: AppTheme.primaryColor,
                  size: 16,
                ),
                const SizedBox(width: 6),
                Text(
                  '${selectedPrefs.length}/2 selected: ${selectedPrefs.join(', ')}',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: AppTheme.primaryColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        const SizedBox(height: 16),
        ...styleOptions.map((option) {
          final isSelected = selectedPrefs.contains(option.$1);
          final isDisabled = selectedPrefs.length >= 2 && !isSelected;

          return Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              decoration: BoxDecoration(
                color: isSelected
                    ? option.$4.withOpacity(0.08)
                    : theme.cardColor,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: isSelected ? option.$4 : theme.dividerColor,
                  width: isSelected ? 2 : 1,
                ),
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: isDisabled
                      ? null
                      : () {
                          ref
                              .read(onboardingProvider.notifier)
                              .toggleStylePreference(option.$1);
                        },
                  borderRadius: BorderRadius.circular(14),
                  child: Opacity(
                    opacity: isDisabled ? 0.4 : 1.0,
                    child: Padding(
                      padding: const EdgeInsets.all(14),
                      child: Row(
                        children: [
                          Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? option.$4.withOpacity(0.15)
                                  : option.$4.withOpacity(0.08),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(
                              option.$2,
                              color: option.$4,
                              size: 22,
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  option.$1,
                                  style: theme.textTheme.titleSmall?.copyWith(
                                    color: isSelected ? option.$4 : null,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  option.$3,
                                  style: theme.textTheme.bodySmall,
                                ),
                              ],
                            ),
                          ),
                          if (isSelected)
                            Container(
                              width: 22,
                              height: 22,
                              decoration: BoxDecoration(
                                color: option.$4,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.check_rounded,
                                color: Colors.white,
                                size: 14,
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          );
        }),
      ],
    );
  }
}
