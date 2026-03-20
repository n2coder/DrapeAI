import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:style_ai/core/theme/app_theme.dart';
import 'package:style_ai/features/recommendation/models/outfit_model.dart';
import 'package:style_ai/features/recommendation/providers/recommendation_provider.dart';
import 'package:style_ai/features/wardrobe/models/clothing_item.dart';
import 'package:style_ai/widgets/common/loading_widget.dart';
import 'package:style_ai/widgets/common/primary_button.dart';

class OutfitResultScreen extends ConsumerWidget {
  const OutfitResultScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final recState = ref.watch(recommendationProvider);
    final theme = Theme.of(context);

    if (recState.isLoading) {
      return Scaffold(
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded),
            onPressed: () => context.pop(),
          ),
        ),
        body: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(color: AppTheme.primaryColor),
              SizedBox(height: 16),
              Text('AI is creating your perfect outfit...'),
            ],
          ),
        ),
      );
    }

    final outfit = recState.currentOutfit;
    if (outfit == null) {
      return Scaffold(
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded),
            onPressed: () => context.pop(),
          ),
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 56, color: AppTheme.errorColor),
              const SizedBox(height: 16),
              const Text('No outfit found'),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () => context.pop(),
                child: const Text('Go Back'),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 0,
            floating: true,
            snap: true,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new_rounded),
              onPressed: () => context.pop(),
            ),
            title: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Your Outfit', style: theme.textTheme.titleMedium),
                Text(
                  outfit.occasion,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: AppTheme.primaryColor,
                  ),
                ),
              ],
            ),
            actions: [
              IconButton(
                icon: Icon(
                  outfit.isSaved ? Icons.bookmark_rounded : Icons.bookmark_outline_rounded,
                  color: outfit.isSaved ? AppTheme.primaryColor : null,
                ),
                onPressed: () => _saveOutfit(context, ref),
              ),
              IconButton(
                icon: const Icon(Icons.share_outlined),
                onPressed: () {},
              ),
            ],
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Match score
                  _buildScoreBanner(outfit, theme),
                  const SizedBox(height: 24),
                  // Outfit grid - 3 images
                  _buildOutfitGrid(outfit, theme),
                  const SizedBox(height: 24),
                  // Why this works section
                  _buildWhyThisWorks(outfit, theme),
                  const SizedBox(height: 24),
                  // Style notes
                  if (outfit.styleNotes.isNotEmpty)
                    _buildStyleNotes(outfit, theme),
                  const SizedBox(height: 24),
                  // Weather context
                  _buildWeatherContext(outfit, theme),
                  const SizedBox(height: 32),
                  // Action buttons
                  PrimaryButton(
                    label: outfit.isSaved ? 'Saved to Collection' : 'Save Outfit',
                    onPressed: outfit.isSaved
                        ? null
                        : () => _saveOutfit(context, ref),
                    icon: outfit.isSaved
                        ? Icons.check_circle_rounded
                        : Icons.bookmark_add_rounded,
                  ),
                  const SizedBox(height: 12),
                  OutlinedButton.icon(
                    onPressed: () {
                      ref.read(recommendationProvider.notifier).tryAnother();
                    },
                    icon: const Icon(Icons.refresh_rounded, size: 18),
                    label: const Text('Try Another Outfit'),
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size(double.infinity, 56),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScoreBanner(OutfitModel outfit, ThemeData theme) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppTheme.primaryColor.withOpacity(0.1),
            AppTheme.accentColor.withOpacity(0.08),
          ],
        ),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: AppTheme.primaryColor.withOpacity(0.2),
        ),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.auto_awesome_rounded,
            color: AppTheme.primaryColor,
            size: 20,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  outfit.scoreLabel,
                  style: theme.textTheme.titleSmall?.copyWith(
                    color: AppTheme.primaryColor,
                  ),
                ),
                Text(
                  'AI Confidence: ${outfit.scorePercentage}%',
                  style: theme.textTheme.bodySmall,
                ),
              ],
            ),
          ),
          SizedBox(
            width: 56,
            height: 56,
            child: Stack(
              children: [
                CircularProgressIndicator(
                  value: outfit.score,
                  strokeWidth: 5,
                  backgroundColor: AppTheme.primaryColor.withOpacity(0.1),
                  color: AppTheme.primaryColor,
                ),
                Center(
                  child: Text(
                    '${outfit.scorePercentage}',
                    style: theme.textTheme.labelLarge?.copyWith(
                      color: AppTheme.primaryColor,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOutfitGrid(OutfitModel outfit, ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('The Look', style: theme.textTheme.titleMedium),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              flex: 3,
              child: _ClothingItemTile(
                item: outfit.top,
                label: 'Top',
                height: 220,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              flex: 2,
              child: Column(
                children: [
                  _ClothingItemTile(
                    item: outfit.bottom,
                    label: 'Bottom',
                    height: 105,
                  ),
                  const SizedBox(height: 10),
                  _ClothingItemTile(
                    item: outfit.footwear,
                    label: 'Footwear',
                    height: 105,
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildWhyThisWorks(OutfitModel outfit, ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.dividerColor, width: 0.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.psychology_outlined,
                color: AppTheme.primaryColor,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text('Why This Works', style: theme.textTheme.titleSmall),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            outfit.explanation.isNotEmpty
                ? outfit.explanation
                : 'This combination balances style and comfort, '
                    'creating a cohesive look appropriate for ${outfit.occasion}.',
            style: theme.textTheme.bodyMedium,
          ),
        ],
      ),
    );
  }

  Widget _buildStyleNotes(OutfitModel outfit, ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Styling Tips', style: theme.textTheme.titleMedium),
        const SizedBox(height: 10),
        ...outfit.styleNotes.map(
          (note) => Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  margin: const EdgeInsets.only(top: 6),
                  width: 6,
                  height: 6,
                  decoration: const BoxDecoration(
                    color: AppTheme.primaryColor,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(note, style: theme.textTheme.bodyMedium),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildWeatherContext(OutfitModel outfit, ThemeData theme) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: AppTheme.accentColor.withOpacity(0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: AppTheme.accentColor.withOpacity(0.2),
        ),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.wb_sunny_outlined,
            color: AppTheme.accentColor,
            size: 18,
          ),
          const SizedBox(width: 8),
          Text(
            'Optimized for ${outfit.weatherContext} weather',
            style: theme.textTheme.bodySmall?.copyWith(
              color: AppTheme.accentColor,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _saveOutfit(BuildContext context, WidgetRef ref) async {
    final success = await ref.read(recommendationProvider.notifier).saveCurrentOutfit();
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            success ? 'Outfit saved to your collection!' : 'Failed to save outfit',
          ),
          backgroundColor:
              success ? AppTheme.successColor : AppTheme.errorColor,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }
}

class _ClothingItemTile extends StatelessWidget {
  final ClothingItem item;
  final String label;
  final double height;

  const _ClothingItemTile({
    required this.item,
    required this.label,
    required this.height,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Stack(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(14),
          child: CachedNetworkImage(
            imageUrl: item.imageUrl,
            width: double.infinity,
            height: height,
            fit: BoxFit.cover,
            placeholder: (context, url) => ShimmerBox(
              height: height,
              borderRadius: 14,
            ),
            errorWidget: (context, url, error) => Container(
              height: height,
              decoration: BoxDecoration(
                color: theme.colorScheme.surface,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(
                Icons.image_not_supported_outlined,
                color: theme.colorScheme.onSurface.withOpacity(0.3),
              ),
            ),
          ),
        ),
        Positioned(
          bottom: 8,
          left: 8,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.6),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
