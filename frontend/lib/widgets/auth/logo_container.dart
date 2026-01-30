import 'package:flutter/material.dart';

class LogoContainer extends StatelessWidget {
  final String logoAsset;
  final double size;
  final bool isFullWidth;

  const LogoContainer({
    super.key,
    required this.logoAsset,
    this.size = 180,
    this.isFullWidth = true,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: isFullWidth ? double.infinity : size,
      height: size,
      decoration: isFullWidth
          ? null
          : BoxDecoration(
              borderRadius: BorderRadius.circular(44),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.15),
                  blurRadius: 25,
                  offset: const Offset(0, 12),
                ),
              ],
            ),
      child: Stack(
        children: [
          // Minimalist Painter with exactly one separator wave
          Positioned.fill(
            child: CustomPaint(
              painter: _MinimalistSingleWavePainter(),
            ),
          ),

          // Branded Content (Logo + High-Contrast Branding)
          Center(
            child: Hero(
              tag: 'logo',
              child: SizedBox(
                width: size * 1.1,
                height: size * 1.1,
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: ColorFiltered(
                    colorFilter: const ColorFilter.matrix(<double>[
                      1.4,
                      0,
                      0,
                      0,
                      0,
                      0,
                      1.4,
                      0,
                      0,
                      0,
                      0,
                      0,
                      1.4,
                      0,
                      0,
                      1.8,
                      1.8,
                      1.8,
                      0,
                      -210,
                    ]),
                    child: Image.asset(
                      logoAsset,
                      fit: BoxFit.contain,
                      filterQuality: FilterQuality.high,
                      isAntiAlias: true,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MinimalistSingleWavePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;

    // 1. BASE: Main Branded Gradient
    final basePaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          Color(0xFF4338CA), // Indigo 700
          Color(0xFF6D28D9), // Purple 700
        ],
      ).createShader(rect);

    // The base purple fills the top portion with a wavy bottom cutoff
    final basePath = Path();
    basePath.lineTo(0, size.height * 0.85);
    basePath.cubicTo(
      size.width * 0.35,
      size.height * 0.72,
      size.width * 0.65,
      size.height * 0.98,
      size.width,
      size.height * 0.85,
    );
    basePath.lineTo(size.width, 0);
    basePath.close();
    canvas.drawPath(basePath, basePaint);

    // 2. THE SINGLE WAVE LINE: A clean, medium-thickness separator
    // Positioned directly below the purple background edge
    final linePaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.9) // Solid white for clarity
      ..style = PaintingStyle.fill;

    final linePath = Path();
    // Starting slightly overlapping for a seamless connection
    linePath.moveTo(0, size.height * 0.83);
    linePath.cubicTo(
      size.width * 0.35,
      size.height * 0.70,
      size.width * 0.65,
      size.height * 0.96,
      size.width,
      size.height * 0.83,
    );
    // Add thickness to the "line" to make it visible and premium
    linePath.lineTo(size.width, size.height * 0.87);
    linePath.cubicTo(
      size.width * 0.65,
      size.height * 1.0,
      size.width * 0.35,
      size.height * 0.74,
      0,
      size.height * 0.87,
    );
    linePath.close();

    canvas.drawPath(linePath, linePaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
