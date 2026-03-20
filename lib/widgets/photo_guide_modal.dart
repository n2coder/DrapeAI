import 'dart:math' as math;
import 'package:flutter/material.dart';

/// Animated photography guide shown before the user takes a clothing photo.
///
/// Shows 4 steps with icon animations:
///   1. Lay flat on a clean surface
///   2. Smooth out wrinkles
///   3. Natural / bright lighting
///   4. Shoot from directly above
class PhotoGuideModal extends StatefulWidget {
  const PhotoGuideModal({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const PhotoGuideModal(),
    );
  }

  @override
  State<PhotoGuideModal> createState() => _PhotoGuideModalState();
}

class _PhotoGuideModalState extends State<PhotoGuideModal>
    with TickerProviderStateMixin {
  late final PageController _pageController;
  late final AnimationController _pulseController;
  late final AnimationController _floatController;

  int _currentStep = 0;

  static const _steps = [
    _GuideStep(
      icon: Icons.flatware_rounded,
      title: 'Lay it flat',
      subtitle: 'Spread the item on a clean, smooth surface — bed, table, or floor.',
      tip: 'A white or neutral background gives the cleanest result.',
      color: Color(0xFF6C63FF),
      iconWidget: _FlatLayIcon(),
    ),
    _GuideStep(
      icon: Icons.iron_rounded,
      title: 'Smooth it out',
      subtitle: 'Remove all wrinkles and folds. Straighten collars, cuffs, and hems.',
      tip: 'Our AI will try to remove wrinkles, but a smooth start is best.',
      color: Color(0xFF43A69E),
      iconWidget: _SmoothIcon(),
    ),
    _GuideStep(
      icon: Icons.wb_sunny_rounded,
      title: 'Good lighting',
      subtitle: 'Use natural daylight or a bright lamp. Avoid harsh shadows.',
      tip: 'Shoot near a window for the softest, most flattering light.',
      color: Color(0xFFF5A623),
      iconWidget: _LightIcon(),
    ),
    _GuideStep(
      icon: Icons.camera_alt_rounded,
      title: 'Shoot from above',
      subtitle: 'Hold your phone directly overhead, centred on the item.',
      tip: 'Fill the frame — crop tight so the clothing takes up ~80% of the shot.',
      color: Color(0xFFE85D75),
      iconWidget: _CameraIcon(),
    ),
  ];

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);
    _floatController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pageController.dispose();
    _pulseController.dispose();
    _floatController.dispose();
    super.dispose();
  }

  void _next() {
    if (_currentStep < _steps.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeInOut,
      );
    } else {
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final step = _steps[_currentStep];

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.18),
            blurRadius: 32,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag handle
          const SizedBox(height: 12),
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 8),

          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
            child: Row(
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: step.color.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(Icons.tips_and_updates_rounded,
                      color: step.color, size: 20),
                ),
                const SizedBox(width: 10),
                Text(
                  'Photo Guide',
                  style: theme.textTheme.titleMedium
                      ?.copyWith(fontWeight: FontWeight.w700),
                ),
                const Spacer(),
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Skip'),
                ),
              ],
            ),
          ),

          // Page view
          SizedBox(
            height: 340,
            child: PageView.builder(
              controller: _pageController,
              onPageChanged: (i) => setState(() => _currentStep = i),
              itemCount: _steps.length,
              itemBuilder: (_, i) => _StepPage(
                step: _steps[i],
                pulseAnim: _pulseController,
                floatAnim: _floatController,
                isActive: i == _currentStep,
              ),
            ),
          ),

          // Step indicators
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(_steps.length, (i) {
              final active = i == _currentStep;
              return AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                margin: const EdgeInsets.symmetric(horizontal: 4),
                width: active ? 24 : 8,
                height: 8,
                decoration: BoxDecoration(
                  color: active ? step.color : Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(4),
                ),
              );
            }),
          ),
          const SizedBox(height: 20),

          // CTA button
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              width: double.infinity,
              child: FilledButton.icon(
                style: FilledButton.styleFrom(
                  backgroundColor: step.color,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                onPressed: _next,
                icon: Icon(
                  _currentStep == _steps.length - 1
                      ? Icons.camera_alt_rounded
                      : Icons.arrow_forward_rounded,
                ),
                label: Text(
                  _currentStep == _steps.length - 1
                      ? 'Got it — take photo'
                      : 'Next tip',
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}

// ── Step data ─────────────────────────────────────────────────────────────────

class _GuideStep {
  final IconData icon;
  final String title;
  final String subtitle;
  final String tip;
  final Color color;
  final Widget iconWidget;

  const _GuideStep({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.tip,
    required this.color,
    required this.iconWidget,
  });
}

// ── Step page widget ──────────────────────────────────────────────────────────

class _StepPage extends StatelessWidget {
  final _GuideStep step;
  final AnimationController pulseAnim;
  final AnimationController floatAnim;
  final bool isActive;

  const _StepPage({
    required this.step,
    required this.pulseAnim,
    required this.floatAnim,
    required this.isActive,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Animated illustration
          AnimatedBuilder(
            animation: floatAnim,
            builder: (_, child) {
              final offset = math.sin(floatAnim.value * math.pi) * 8;
              return Transform.translate(
                offset: Offset(0, offset),
                child: child,
              );
            },
            child: Container(
              width: 130,
              height: 130,
              decoration: BoxDecoration(
                color: step.color.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: AnimatedBuilder(
                animation: pulseAnim,
                builder: (_, child) {
                  return Container(
                    margin: EdgeInsets.all(10 + pulseAnim.value * 6),
                    decoration: BoxDecoration(
                      color: step.color.withValues(alpha: 0.15 + pulseAnim.value * 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Center(child: step.iconWidget),
                  );
                },
              ),
            ),
          ),
          const SizedBox(height: 24),

          Text(
            step.title,
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w700,
              color: step.color,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            step.subtitle,
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.75),
              height: 1.5,
            ),
          ),
          const SizedBox(height: 16),

          // Tip chip
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: step.color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: step.color.withValues(alpha: 0.3)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.lightbulb_outline_rounded,
                    color: step.color, size: 14),
                const SizedBox(width: 6),
                Flexible(
                  child: Text(
                    step.tip,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: step.color,
                      fontWeight: FontWeight.w500,
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
}

// ── Animated icon widgets ─────────────────────────────────────────────────────

class _FlatLayIcon extends StatelessWidget {
  const _FlatLayIcon();
  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        Container(
          width: 64,
          height: 44,
          decoration: BoxDecoration(
            color: const Color(0xFF6C63FF).withValues(alpha: 0.3),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: const Color(0xFF6C63FF),
              width: 2,
            ),
          ),
        ),
        const Icon(Icons.checkroom_rounded,
            color: Color(0xFF6C63FF), size: 28),
      ],
    );
  }
}

class _SmoothIcon extends StatelessWidget {
  const _SmoothIcon();
  @override
  Widget build(BuildContext context) {
    return const CustomPaint(
      size: Size(70, 50),
      painter: _WavePainter(color: Color(0xFF43A69E)),
    );
  }
}

class _LightIcon extends StatelessWidget {
  const _LightIcon();
  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        ...List.generate(8, (i) {
          final angle = i * math.pi / 4;
          return Transform.translate(
            offset: Offset(
              math.cos(angle) * 30,
              math.sin(angle) * 30,
            ),
            child: Container(
              width: 6,
              height: 6,
              decoration: const BoxDecoration(
                color: Color(0xFFF5A623),
                shape: BoxShape.circle,
              ),
            ),
          );
        }),
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: const Color(0xFFF5A623).withValues(alpha: 0.2),
            shape: BoxShape.circle,
            border: Border.all(color: const Color(0xFFF5A623), width: 2),
          ),
          child: const Icon(Icons.wb_sunny_rounded,
              color: Color(0xFFF5A623), size: 22),
        ),
      ],
    );
  }
}

class _CameraIcon extends StatelessWidget {
  const _CameraIcon();
  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        Container(
          width: 60,
          height: 60,
          decoration: BoxDecoration(
            border: Border.all(
                color: const Color(0xFFE85D75).withValues(alpha: 0.4), width: 1.5),
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        const Icon(Icons.camera_alt_rounded,
            color: Color(0xFFE85D75), size: 36),
        Positioned(
          top: 2,
          child: Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: const Color(0xFFE85D75).withValues(alpha: 0.6),
              shape: BoxShape.circle,
            ),
          ),
        ),
      ],
    );
  }
}

class _WavePainter extends CustomPainter {
  final Color color;
  const _WavePainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    for (int row = 0; row < 3; row++) {
      final y = size.height * (0.25 + row * 0.25);
      final path = Path()..moveTo(0, y);
      for (double x = 0; x <= size.width; x += 2) {
        path.lineTo(x, y + math.sin((x / size.width) * math.pi * 2) * 5);
      }
      canvas.drawPath(path, paint..color = color.withValues(alpha: 1 - row * 0.2));
    }
  }

  @override
  bool shouldRepaint(_WavePainter old) => old.color != color;
}
