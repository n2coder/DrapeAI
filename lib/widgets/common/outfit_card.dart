import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import 'package:style_ai/core/theme/app_theme.dart';
import 'package:style_ai/features/recommendation/models/outfit_model.dart';
import 'package:style_ai/widgets/common/loading_widget.dart';

class OutfitCard extends StatelessWidget {
  final OutfitModel outfit;
  final VoidCallback? onTap;
  final bool showScore;
  final bool showOccasion;

  const OutfitCard({
    super.key,
    required this.outfit,
    this.onTap,
    this.showScore = true,
    this.showOccasion = true,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: theme.cardColor,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: theme.dividerColor, width: 0.5),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Images row
            ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
              child: SizedBox(
                height: 240,
                child: Row(
                  children: [
                    // Top - larger
                    Expanded(
                      flex: 3,
                      child: _OutfitImage(
                        imageUrl: outfit.top.imageUrl,
                        label: 'Top',
                      ),
                    ),
                    Container(width: 2, color: theme.scaffoldBackgroundColor),
                    // Bottom + Footwear stacked
                    Expanded(
                      flex: 2,
                      child: Column(
                        children: [
                          Expanded(
                            child: _OutfitImage(
                              imageUrl: outfit.bottom.imageUrl,
                              label: 'Bottom',
                            ),
                          ),
                          Container(
                            height: 2,
                            color: theme.scaffoldBackgroundColor,
                          ),
                          Expanded(
                            child: _OutfitImage(
                              imageUrl: outfit.footwear.imageUrl,
                              label: 'Footwear',
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            // Card footer
            Padding(
              padding: const EdgeInsets.all(14),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (showOccasion)
                          Text(
                            outfit.occasion,
                            style: theme.textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        Text(
                          '${outfit.top.color} · ${outfit.top.style}',
                          style: theme.textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                  if (showScore)
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: AppTheme.primaryColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.auto_awesome_rounded,
                                size: 12,
                                color: AppTheme.primaryColor,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                '${outfit.scorePercentage}%',
                                style: theme.textTheme.labelSmall?.copyWith(
                                  color: AppTheme.primaryColor,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        Icon(
                          Icons.arrow_forward_ios_rounded,
                          size: 14,
                          color: theme.colorScheme.onSurface.withOpacity(0.4),
                        ),
                      ],
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _OutfitImage extends StatelessWidget {
  final String imageUrl;
  final String label;

  const _OutfitImage({
    required this.imageUrl,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        CachedNetworkImage(
          imageUrl: imageUrl,
          fit: BoxFit.cover,
          placeholder: (context, url) => const ShimmerBox(borderRadius: 0),
          errorWidget: (context, url, error) => Container(
            color: Theme.of(context).colorScheme.surface,
            child: Center(
              child: Icon(
                Icons.image_not_supported_outlined,
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.2),
                size: 28,
              ),
            ),
          ),
        ),
        Positioned(
          bottom: 6,
          left: 6,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.55),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 10,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class MiniOutfitCard extends StatelessWidget {
  final OutfitModel outfit;
  final VoidCallback? onTap;

  const MiniOutfitCard({super.key, required this.outfit, this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 160,
        decoration: BoxDecoration(
          color: theme.cardColor,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: theme.dividerColor, width: 0.5),
        ),
        child: Column(
          children: [
            ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(14)),
              child: SizedBox(
                height: 100,
                child: Row(
                  children: [
                    Expanded(
                      child: CachedNetworkImage(
                        imageUrl: outfit.top.imageUrl,
                        fit: BoxFit.cover,
                        errorWidget: (_, __, ___) => Container(
                          color: theme.colorScheme.surface,
                        ),
                      ),
                    ),
                    Container(width: 1, color: theme.scaffoldBackgroundColor),
                    Expanded(
                      child: Column(
                        children: [
                          Expanded(
                            child: CachedNetworkImage(
                              imageUrl: outfit.bottom.imageUrl,
                              fit: BoxFit.cover,
                              errorWidget: (_, __, ___) => Container(
                                color: theme.colorScheme.surface,
                              ),
                            ),
                          ),
                          Container(
                            height: 1,
                            color: theme.scaffoldBackgroundColor,
                          ),
                          Expanded(
                            child: CachedNetworkImage(
                              imageUrl: outfit.footwear.imageUrl,
                              fit: BoxFit.cover,
                              errorWidget: (_, __, ___) => Container(
                                color: theme.colorScheme.surface,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(8),
              child: Text(
                outfit.occasion,
                style: theme.textTheme.labelSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
