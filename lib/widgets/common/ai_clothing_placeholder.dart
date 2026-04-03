import 'package:flutter/material.dart';

/// Animated AI-style placeholder for wardrobe items.
/// Renders a visually rich canvas based on the item's category, color, and style
/// — so every card looks unique and representative even without a real photo.
class AiClothingPlaceholder extends StatefulWidget {
  final String category;
  final String color;
  final String style;
  final double borderRadius;

  const AiClothingPlaceholder({
    super.key,
    required this.category,
    required this.color,
    required this.style,
    this.borderRadius = 0,
  });

  @override
  State<AiClothingPlaceholder> createState() => _AiClothingPlaceholderState();
}

class _AiClothingPlaceholderState extends State<AiClothingPlaceholder>
    with TickerProviderStateMixin {
  late final AnimationController _pulseCtrl;
  late final AnimationController _shimmerCtrl;
  late final AnimationController _floatCtrl;

  late final Animation<double> _pulse;
  late final Animation<double> _shimmer;
  late final Animation<double> _float;

  @override
  void initState() {
    super.initState();

    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    )..repeat(reverse: true);

    _shimmerCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat();

    _floatCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3200),
    )..repeat(reverse: true);

    _pulse = Tween<double>(begin: 0.92, end: 1.08).animate(
      CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut),
    );
    _shimmer = Tween<double>(begin: -1.5, end: 2.5).animate(
      CurvedAnimation(parent: _shimmerCtrl, curve: Curves.easeInOut),
    );
    _float = Tween<double>(begin: -6, end: 6).animate(
      CurvedAnimation(parent: _floatCtrl, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    _shimmerCtrl.dispose();
    _floatCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = _resolveColors(widget.color, widget.category);
    final emoji = _categoryEmoji(widget.category);
    final label = _shortLabel(widget.category, widget.style);

    return ClipRRect(
      borderRadius: BorderRadius.circular(widget.borderRadius),
      child: AnimatedBuilder(
        animation: Listenable.merge([_pulseCtrl, _shimmerCtrl, _floatCtrl]),
        builder: (context, _) {
          return CustomPaint(
            painter: _BgPainter(
              color1: colors[0],
              color2: colors[1],
              color3: colors[2],
              shimmerProgress: _shimmer.value,
              pulse: _pulse.value,
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Floating clothing shape
                Transform.translate(
                  offset: Offset(0, _float.value),
                  child: Transform.scale(
                    scale: _pulse.value,
                    child: _ClothingShape(
                      category: widget.category,
                      primaryColor: colors[0],
                      secondaryColor: colors[1],
                    ),
                  ),
                ),

                // Bottom label strip
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 8),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          Colors.black.withValues(alpha: 0.55),
                        ],
                      ),
                    ),
                    child: Row(
                      children: [
                        Text(emoji,
                            style: const TextStyle(fontSize: 12)),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            label,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 0.3,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        // AI badge
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 5, vertical: 2),
                          decoration: BoxDecoration(
                            color: colors[0].withValues(alpha: 0.85),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Text(
                            '✦ AI',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 8,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // Shimmer sweep overlay
                Positioned.fill(
                  child: CustomPaint(
                    painter: _ShimmerPainter(
                      progress: _shimmer.value,
                      color: Colors.white.withValues(alpha: 0.06),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  // ── Helpers ──────────────────────────────────────────────────────────────

  List<Color> _resolveColors(String colorName, String category) {
    final base = _nameToColor(colorName.toLowerCase());
    final cat = category.toLowerCase();

    // Give each category a characteristic secondary hue
    Color secondary;
    Color accent;

    if (cat.contains('top') || cat.contains('shirt') || cat.contains('jacket')) {
      secondary = Color.lerp(base, const Color(0xFF6C63FF), 0.35)!;
      accent = Color.lerp(base, const Color(0xFFFF6584), 0.25)!;
    } else if (cat.contains('bottom') || cat.contains('trouser') || cat.contains('pant')) {
      secondary = Color.lerp(base, const Color(0xFF1A237E), 0.4)!;
      accent = Color.lerp(base, const Color(0xFF43E97B), 0.2)!;
    } else if (cat.contains('footwear') || cat.contains('shoe') || cat.contains('boot')) {
      secondary = Color.lerp(base, const Color(0xFF795548), 0.4)!;
      accent = Color.lerp(base, const Color(0xFFF59E0B), 0.3)!;
    } else if (cat.contains('dress') || cat.contains('ethnic')) {
      secondary = Color.lerp(base, const Color(0xFFE91E63), 0.35)!;
      accent = Color.lerp(base, const Color(0xFFFF9800), 0.25)!;
    } else {
      secondary = Color.lerp(base, const Color(0xFF00F5D4), 0.3)!;
      accent = Color.lerp(base, const Color(0xFF9B5DE5), 0.3)!;
    }

    return [base, secondary, accent];
  }

  Color _nameToColor(String name) {
    const map = {
      'black': Color(0xFF212121),
      'white': Color(0xFFEEEEEE),
      'navy': Color(0xFF1A237E),
      'grey': Color(0xFF607D8B),
      'gray': Color(0xFF607D8B),
      'beige': Color(0xFFD7CCC8),
      'brown': Color(0xFF795548),
      'red': Color(0xFFE53935),
      'blue': Color(0xFF1E88E5),
      'green': Color(0xFF43A047),
      'yellow': Color(0xFFFDD835),
      'pink': Color(0xFFE91E63),
      'purple': Color(0xFF8E24AA),
      'orange': Color(0xFFEF6C00),
      'maroon': Color(0xFF880E4F),
      'olive': Color(0xFF827717),
      'teal': Color(0xFF00897B),
      'cream': Color(0xFFFFF8E1),
      'mustard': Color(0xFFF9A825),
      'lavender': Color(0xFF9575CD),
      'coral': Color(0xFFFF7043),
      'multi-color': Color(0xFF6C63FF),
      'multicolor': Color(0xFF6C63FF),
    };

    for (final entry in map.entries) {
      if (name.contains(entry.key)) return entry.value;
    }
    // Hash fallback for unknown colors
    final hash = name.codeUnits.fold(0, (a, b) => a + b);
    return Color(0xFF000000 | (hash * 6364136223846793005 & 0xFFFFFF));
  }

  String _categoryEmoji(String cat) {
    final c = cat.toLowerCase();
    if (c.contains('top') || c.contains('shirt') || c.contains('tee')) return '👕';
    if (c.contains('jacket') || c.contains('coat') || c.contains('blazer')) return '🧥';
    if (c.contains('bottom') || c.contains('pant') || c.contains('trouser')) return '👖';
    if (c.contains('short')) return '🩳';
    if (c.contains('skirt') || c.contains('dress')) return '👗';
    if (c.contains('footwear') || c.contains('shoe')) return '👟';
    if (c.contains('boot')) return '🥾';
    if (c.contains('ethnic') || c.contains('kurta') || c.contains('saree')) return '🥻';
    if (c.contains('sweat') || c.contains('hoodie')) return '🧥';
    return '👔';
  }

  String _shortLabel(String category, String style) {
    final cat = category.length > 14
        ? '${category.substring(0, 13)}…'
        : category;
    return '$cat · $style';
  }
}

// ── Background painter ─────────────────────────────────────────────────────

class _BgPainter extends CustomPainter {
  final Color color1, color2, color3;
  final double shimmerProgress, pulse;

  const _BgPainter({
    required this.color1,
    required this.color2,
    required this.color3,
    required this.shimmerProgress,
    required this.pulse,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // Base gradient background
    final bgPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          Color.lerp(color1, Colors.black, 0.72)!,
          Color.lerp(color2, Colors.black, 0.65)!,
        ],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), bgPaint);

    // Soft radial glow top-right
    final glowPaint = Paint()
      ..shader = RadialGradient(
        colors: [
          color1.withValues(alpha: 0.28 * pulse.clamp(0.8, 1.2)),
          Colors.transparent,
        ],
      ).createShader(Rect.fromCircle(
        center: Offset(size.width * 0.75, size.height * 0.2),
        radius: size.width * 0.7,
      ));
    canvas.drawCircle(
        Offset(size.width * 0.75, size.height * 0.2), size.width * 0.7, glowPaint);

    // Soft radial glow bottom-left
    final glow2Paint = Paint()
      ..shader = RadialGradient(
        colors: [
          color3.withValues(alpha: 0.2 * pulse.clamp(0.85, 1.15)),
          Colors.transparent,
        ],
      ).createShader(Rect.fromCircle(
        center: Offset(size.width * 0.2, size.height * 0.8),
        radius: size.width * 0.6,
      ));
    canvas.drawCircle(
        Offset(size.width * 0.2, size.height * 0.8), size.width * 0.6, glow2Paint);

    // Subtle dot grid
    final dotPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.04)
      ..strokeCap = StrokeCap.round;
    const spacing = 16.0;
    for (double x = spacing; x < size.width; x += spacing) {
      for (double y = spacing; y < size.height; y += spacing) {
        canvas.drawCircle(Offset(x, y), 1.2, dotPaint);
      }
    }
  }

  @override
  bool shouldRepaint(_BgPainter old) =>
      old.shimmerProgress != shimmerProgress || old.pulse != pulse;
}

// ── Shimmer sweep painter ──────────────────────────────────────────────────

class _ShimmerPainter extends CustomPainter {
  final double progress;
  final Color color;

  const _ShimmerPainter({required this.progress, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final x = size.width * progress;
    final paint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.centerLeft,
        end: Alignment.centerRight,
        colors: [
          Colors.transparent,
          color,
          Colors.transparent,
        ],
        stops: const [0.0, 0.5, 1.0],
      ).createShader(Rect.fromLTWH(x - 60, 0, 120, size.height));
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), paint);
  }

  @override
  bool shouldRepaint(_ShimmerPainter old) => old.progress != progress;
}

// ── Clothing silhouette shape ──────────────────────────────────────────────

class _ClothingShape extends StatelessWidget {
  final String category;
  final Color primaryColor;
  final Color secondaryColor;

  const _ClothingShape({
    required this.category,
    required this.primaryColor,
    required this.secondaryColor,
  });

  @override
  Widget build(BuildContext context) {
    final cat = category.toLowerCase();
    const size = 72.0;

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: [
            primaryColor.withValues(alpha: 0.22),
            primaryColor.withValues(alpha: 0.06),
          ],
        ),
        border: Border.all(
          color: primaryColor.withValues(alpha: 0.35),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: primaryColor.withValues(alpha: 0.3),
            blurRadius: 24,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Center(
        child: CustomPaint(
          size: Size(size * 0.55, size * 0.55),
          painter: _SilhouettePainter(
            category: cat,
            color: primaryColor,
            secondaryColor: secondaryColor,
          ),
        ),
      ),
    );
  }
}

class _SilhouettePainter extends CustomPainter {
  final String category;
  final Color color;
  final Color secondaryColor;

  const _SilhouettePainter({
    required this.category,
    required this.color,
    required this.secondaryColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color.withValues(alpha: 0.9)
      ..style = PaintingStyle.fill;

    final outline = Paint()
      ..color = color.withValues(alpha: 0.5)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    final w = size.width;
    final h = size.height;

    if (category.contains('top') || category.contains('shirt') ||
        category.contains('tee') || category.contains('jacket') ||
        category.contains('coat') || category.contains('sweat') ||
        category.contains('hoodie')) {
      _drawTShirt(canvas, paint, outline, w, h);
    } else if (category.contains('bottom') || category.contains('pant') ||
        category.contains('trouser') || category.contains('short') ||
        category.contains('jeans')) {
      _drawTrousers(canvas, paint, outline, w, h);
    } else if (category.contains('dress') || category.contains('skirt') ||
        category.contains('ethnic') || category.contains('saree')) {
      _drawDress(canvas, paint, outline, w, h);
    } else if (category.contains('footwear') || category.contains('shoe') ||
        category.contains('boot') || category.contains('sneaker')) {
      _drawShoe(canvas, paint, outline, w, h);
    } else {
      // Generic shirt fallback
      _drawTShirt(canvas, paint, outline, w, h);
    }
  }

  void _drawTShirt(Canvas canvas, Paint fill, Paint outline, double w, double h) {
    final path = Path()
      // Collar
      ..moveTo(w * 0.35, 0)
      ..quadraticBezierTo(w * 0.5, h * 0.12, w * 0.65, 0)
      // Right shoulder
      ..lineTo(w, h * 0.22)
      // Right sleeve bottom
      ..lineTo(w * 0.82, h * 0.38)
      // Right body
      ..lineTo(w * 0.82, h)
      // Bottom
      ..lineTo(w * 0.18, h)
      // Left body
      ..lineTo(w * 0.18, h * 0.38)
      // Left sleeve bottom
      ..lineTo(0, h * 0.22)
      ..close();
    canvas.drawPath(path, fill);
    canvas.drawPath(path, outline);
  }

  void _drawTrousers(Canvas canvas, Paint fill, Paint outline, double w, double h) {
    // Waistband
    final waist = RRect.fromRectAndRadius(
      Rect.fromLTWH(0, 0, w, h * 0.12),
      const Radius.circular(3),
    );
    canvas.drawRRect(waist, fill);

    // Left leg
    final leftLeg = Path()
      ..moveTo(0, h * 0.12)
      ..lineTo(w * 0.48, h * 0.12)
      ..lineTo(w * 0.44, h)
      ..lineTo(w * 0.04, h)
      ..close();
    canvas.drawPath(leftLeg, fill);
    canvas.drawPath(leftLeg, outline);

    // Right leg
    final rightLeg = Path()
      ..moveTo(w * 0.52, h * 0.12)
      ..lineTo(w, h * 0.12)
      ..lineTo(w * 0.96, h)
      ..lineTo(w * 0.56, h)
      ..close();
    canvas.drawPath(rightLeg, fill);
    canvas.drawPath(rightLeg, outline);
  }

  void _drawDress(Canvas canvas, Paint fill, Paint outline, double w, double h) {
    final path = Path()
      ..moveTo(w * 0.3, 0)
      ..lineTo(w * 0.7, 0)
      // Right shoulder strap
      ..lineTo(w * 0.72, h * 0.3)
      // Skirt flare right
      ..quadraticBezierTo(w * 1.05, h * 0.5, w, h)
      ..lineTo(0, h)
      // Skirt flare left
      ..quadraticBezierTo(w * -0.05, h * 0.5, w * 0.28, h * 0.3)
      ..close();
    canvas.drawPath(path, fill);
    canvas.drawPath(path, outline);
  }

  void _drawShoe(Canvas canvas, Paint fill, Paint outline, double w, double h) {
    // Sole
    final sole = Path()
      ..moveTo(0, h * 0.75)
      ..quadraticBezierTo(w * 0.5, h, w, h * 0.75)
      ..lineTo(w, h * 0.82)
      ..quadraticBezierTo(w * 0.5, h * 1.05, 0, h * 0.82)
      ..close();
    canvas.drawPath(sole, fill);

    // Upper
    final upper = Path()
      ..moveTo(w * 0.05, h * 0.75)
      ..lineTo(w * 0.1, h * 0.3)
      ..quadraticBezierTo(w * 0.25, 0, w * 0.55, h * 0.1)
      ..quadraticBezierTo(w, h * 0.2, w * 0.95, h * 0.75)
      ..close();
    canvas.drawPath(upper, fill);
    canvas.drawPath(upper, outline);
  }

  @override
  bool shouldRepaint(_SilhouettePainter old) => old.category != category;
}
