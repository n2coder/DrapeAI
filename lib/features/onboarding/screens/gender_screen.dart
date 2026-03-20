import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:style_ai/core/constants/app_constants.dart';
import 'package:style_ai/core/theme/app_theme.dart';
import 'package:style_ai/features/onboarding/providers/onboarding_provider.dart';

class GenderScreen extends ConsumerWidget {
  const GenderScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final onboardingState = ref.watch(onboardingProvider);
    final theme = Theme.of(context);

    final genderOptions = [
      (
        'Male',
        Icons.male_rounded,
        const Color(0xFF3B82F6),
        const Color(0xFFEFF6FF)
      ),
      (
        'Female',
        Icons.female_rounded,
        const Color(0xFFEC4899),
        const Color(0xFFFDF2F8)
      ),
      (
        'Other',
        Icons.transgender_rounded,
        AppTheme.primaryColor,
        const Color(0xFFF5F3FF)
      ),
      (
        'Prefer not to say',
        Icons.person_outline_rounded,
        const Color(0xFF6B7280),
        const Color(0xFFF9FAFB)
      ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'What\'s your gender?',
          style: theme.textTheme.headlineMedium,
        ),
        const SizedBox(height: 8),
        Text(
          'This helps us personalize your style recommendations',
          style: theme.textTheme.bodyMedium,
        ),
        const SizedBox(height: 32),
        ...genderOptions.map(
          (option) => Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _GenderOptionCard(
              label: option.$1,
              icon: option.$2,
              iconColor: option.$3,
              bgColor: option.$4,
              isSelected: onboardingState.gender == option.$1,
              onTap: () {
                ref.read(onboardingProvider.notifier).setGender(option.$1);
              },
            ),
          ),
        ),
        const SizedBox(height: 24),
        Text(
          'Select your age range:',
          style: theme.textTheme.titleSmall,
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: AppConstants.ageRanges.map((age) {
            final isSelected = onboardingState.ageRange == age;
            return ChoiceChip(
              label: Text(age),
              selected: isSelected,
              onSelected: (_) {
                ref.read(onboardingProvider.notifier).setAgeRange(age);
              },
            );
          }).toList(),
        ),
      ],
    );
  }
}

class _GenderOptionCard extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color iconColor;
  final Color bgColor;
  final bool isSelected;
  final VoidCallback onTap;

  const _GenderOptionCard({
    required this.label,
    required this.icon,
    required this.iconColor,
    required this.bgColor,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      decoration: BoxDecoration(
        color: isSelected
            ? AppTheme.primaryColor.withOpacity(0.08)
            : theme.cardColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isSelected ? AppTheme.primaryColor : theme.dividerColor,
          width: isSelected ? 2 : 1,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(14),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: isSelected
                        ? AppTheme.primaryColor.withOpacity(0.15)
                        : bgColor,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    icon,
                    color: isSelected ? AppTheme.primaryColor : iconColor,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    label,
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: isSelected ? AppTheme.primaryColor : null,
                      fontWeight:
                          isSelected ? FontWeight.w700 : FontWeight.w500,
                    ),
                  ),
                ),
                if (isSelected)
                  Container(
                    width: 24,
                    height: 24,
                    decoration: const BoxDecoration(
                      color: AppTheme.primaryColor,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.check_rounded,
                      color: Colors.white,
                      size: 16,
                    ),
                  )
                else
                  Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: theme.dividerColor,
                        width: 2,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
