import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:style_ai/core/constants/app_constants.dart';
import 'package:style_ai/core/theme/app_theme.dart';
import 'package:style_ai/features/recommendation/providers/recommendation_provider.dart';
import 'package:style_ai/widgets/common/primary_button.dart';

class OccasionScreen extends ConsumerStatefulWidget {
  const OccasionScreen({super.key});

  @override
  ConsumerState<OccasionScreen> createState() => _OccasionScreenState();
}

class _OccasionScreenState extends ConsumerState<OccasionScreen> {
  String? _selectedOccasion;

  final Map<String, _OccasionData> _occasionMeta = {
    'Office': _OccasionData(
      icon: Icons.business_center_rounded,
      color: const Color(0xFF3B82F6),
      description: 'Professional & polished',
    ),
    'Casual': _OccasionData(
      icon: Icons.weekend_rounded,
      color: const Color(0xFF10B981),
      description: 'Relaxed & comfortable',
    ),
    'Party': _OccasionData(
      icon: Icons.celebration_rounded,
      color: const Color(0xFFEC4899),
      description: 'Bold & statement-making',
    ),
    'Wedding': _OccasionData(
      icon: Icons.favorite_rounded,
      color: const Color(0xFFEF4444),
      description: 'Elegant & festive',
    ),
    'Date': _OccasionData(
      icon: Icons.restaurant_rounded,
      color: const Color(0xFFF59E0B),
      description: 'Charming & put-together',
    ),
    'Gym': _OccasionData(
      icon: Icons.fitness_center_rounded,
      color: const Color(0xFF8B5CF6),
      description: 'Athletic & functional',
    ),
    'Travel': _OccasionData(
      icon: Icons.flight_rounded,
      color: const Color(0xFF06B6D4),
      description: 'Comfortable & versatile',
    ),
  };

  void _getOutfit() {
    if (_selectedOccasion == null) return;
    ref
        .read(recommendationProvider.notifier)
        .fetchRecommendationByOccasion(_selectedOccasion!);
    context.push('/outfit-result');
  }

  @override
  Widget build(BuildContext context) {
    final recState = ref.watch(recommendationProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Choose Occasion'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => context.pop(),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'What\'s the occasion?',
                    style: theme.textTheme.headlineMedium,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'We\'ll pick the perfect outfit for your moment',
                    style: theme.textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 28),
                  // Grid of occasion cards
                  GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                      childAspectRatio: 1.1,
                    ),
                    itemCount: _occasionMeta.length,
                    itemBuilder: (context, index) {
                      final occasion = _occasionMeta.keys.elementAt(index);
                      final meta = _occasionMeta[occasion]!;
                      final isSelected = _selectedOccasion == occasion;

                      return _OccasionCard(
                        occasion: occasion,
                        meta: meta,
                        isSelected: isSelected,
                        onTap: () => setState(() => _selectedOccasion = occasion),
                      );
                    },
                  ),
                  if (_selectedOccasion != null) ...[
                    const SizedBox(height: 20),
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryColor.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.auto_awesome_rounded,
                            color: AppTheme.primaryColor,
                            size: 18,
                          ),
                          const SizedBox(width: 10),
                          Text(
                            'Generating AI outfit for $_selectedOccasion...',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: AppTheme.primaryColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
          // Bottom CTA
          Padding(
            padding: const EdgeInsets.all(24),
            child: PrimaryButton(
              label: _selectedOccasion != null
                  ? 'Get $_selectedOccasion Outfit'
                  : 'Select an Occasion',
              isLoading: recState.isLoading,
              onPressed: _selectedOccasion != null ? _getOutfit : null,
              icon: Icons.auto_awesome_rounded,
            ),
          ),
        ],
      ),
    );
  }
}

class _OccasionData {
  final IconData icon;
  final Color color;
  final String description;

  const _OccasionData({
    required this.icon,
    required this.color,
    required this.description,
  });
}

class _OccasionCard extends StatelessWidget {
  final String occasion;
  final _OccasionData meta;
  final bool isSelected;
  final VoidCallback onTap;

  const _OccasionCard({
    required this.occasion,
    required this.meta,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          color: isSelected ? meta.color.withOpacity(0.1) : theme.cardColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? meta.color : theme.dividerColor,
            width: isSelected ? 2 : 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: meta.color.withOpacity(0.2),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ]
              : null,
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: isSelected
                          ? meta.color.withOpacity(0.15)
                          : meta.color.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(meta.icon, color: meta.color, size: 22),
                  ),
                  if (isSelected)
                    Container(
                      width: 22,
                      height: 22,
                      decoration: BoxDecoration(
                        color: meta.color,
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
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    occasion,
                    style: theme.textTheme.titleSmall?.copyWith(
                      color: isSelected ? meta.color : null,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    meta.description,
                    style: theme.textTheme.bodySmall,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
