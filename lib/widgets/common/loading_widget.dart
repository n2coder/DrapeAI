import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

import 'package:style_ai/core/theme/app_theme.dart';

class ShimmerBox extends StatelessWidget {
  final double? width;
  final double? height;
  final double borderRadius;

  const ShimmerBox({
    super.key,
    this.width,
    this.height,
    this.borderRadius = 12,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Shimmer.fromColors(
      baseColor: isDark ? const Color(0xFF2A2844) : const Color(0xFFE5E7EB),
      highlightColor: isDark ? const Color(0xFF3A3858) : const Color(0xFFF9FAFB),
      child: Container(
        width: width ?? double.infinity,
        height: height ?? 100,
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF2A2844) : const Color(0xFFE5E7EB),
          borderRadius: BorderRadius.circular(borderRadius),
        ),
      ),
    );
  }
}

class ShimmerList extends StatelessWidget {
  final int count;
  final double itemHeight;
  final double spacing;

  const ShimmerList({
    super.key,
    this.count = 5,
    this.itemHeight = 80,
    this.spacing = 12,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: List.generate(
        count,
        (index) => Padding(
          padding: EdgeInsets.only(bottom: index < count - 1 ? spacing : 0),
          child: ShimmerBox(height: itemHeight),
        ),
      ),
    );
  }
}

class LoadingOverlay extends StatelessWidget {
  final String? message;

  const LoadingOverlay({super.key, this.message});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      color: Colors.black54,
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
          decoration: BoxDecoration(
            color: theme.cardColor,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircularProgressIndicator(color: AppTheme.primaryColor),
              if (message != null) ...[
                const SizedBox(height: 16),
                Text(message!, style: theme.textTheme.bodyMedium),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class PulsingDot extends StatefulWidget {
  final Color? color;
  final double size;

  const PulsingDot({super.key, this.color, this.size = 10});

  @override
  State<PulsingDot> createState() => _PulsingDotState();
}

class _PulsingDotState extends State<PulsingDot>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..repeat(reverse: true);
    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.2).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: _scaleAnimation,
      child: Container(
        width: widget.size,
        height: widget.size,
        decoration: BoxDecoration(
          color: widget.color ?? AppTheme.primaryColor,
          shape: BoxShape.circle,
        ),
      ),
    );
  }
}

class ThreeDotsLoader extends StatelessWidget {
  const ThreeDotsLoader({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const PulsingDot(),
        const SizedBox(width: 6),
        const PulsingDot(),
        const SizedBox(width: 6),
        const PulsingDot(),
      ].asMap().entries.map((entry) {
        return AnimatedPadding(
          padding: EdgeInsets.only(top: entry.key % 2 == 0 ? 0 : 4),
          duration: Duration(milliseconds: 200 + entry.key * 100),
          child: entry.value,
        );
      }).toList(),
    );
  }
}
