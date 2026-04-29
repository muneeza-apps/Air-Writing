import 'dart:math';
import 'package:flutter/material.dart';

class AntiGravityBase extends StatefulWidget {
  final Widget? child;

  const AntiGravityBase({Key? key, this.child}) : super(key: key);

  @override
  State<AntiGravityBase> createState() => _AntiGravityBaseState();
}

class _AntiGravityBaseState extends State<AntiGravityBase> {
  bool _isUp = false;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // 1. Deep Space Linear Gradient
        Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Color(0xFF000000), // Deep Black
                Color(0xFF001933), // Midnight Blue
              ],
            ),
          ),
        ),

        // 2. Stars with vertical floating/bobbing effect
        TweenAnimationBuilder<double>(
          tween: Tween<double>(begin: 0.0, end: _isUp ? 25.0 : -25.0),
          duration: const Duration(seconds: 4), // Slow bobbing duration
          curve: Curves.easeInOutSine, // Smooth weightless curve
          onEnd: () {
            // Loop the animation infinitely
            if (mounted) {
              setState(() {
                _isUp = !_isUp;
              });
            }
          },
          builder: (context, value, child) {
            return Transform.translate(
              offset: Offset(0, value),
              child: child,
            );
          },
          child: CustomPaint(
            painter: FloatingStarsPainter(starCount: 100),
            size: Size.infinite,
          ),
        ),

        // 3. Optional Child Content
        if (widget.child != null)
          Positioned.fill(child: widget.child!),
      ],
    );
  }
}

class FloatingStarsPainter extends CustomPainter {
  final int starCount;
  
  static final Random _random = Random();
  static bool _initialized = false;
  static late List<StaticStar> _cachedStars;

  FloatingStarsPainter({this.starCount = 100}) {
    if (!_initialized) {
      // Pre-calculate positions and properties so they remain consistent across repaints
      _cachedStars = List.generate(starCount, (index) => StaticStar(
        x: _random.nextDouble(),
        y: _random.nextDouble(), // Distribute outside screen slightly due to bobbing
        opacity: _random.nextDouble() * 0.7 + 0.3, // Opacity: 0.3 to 1.0
        size: _random.nextDouble() * 2.0 + 1.0,    // Size: 1.0 to 3.0
      ));
      _initialized = true;
    }
  }

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;
    
    for (var star in _cachedStars) {
      paint.color = Colors.white.withOpacity(star.opacity);
      
      // We extend the drawing area slightly beyond 0.0-1.0 to account for translation offsets
      canvas.drawCircle(
        Offset(star.x * size.width, (star.y * 1.2 - 0.1) * size.height),
        star.size,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant FloatingStarsPainter oldDelegate) {
    return false; // The translation handles the motion, so no repainting needed
  }
}

class StaticStar {
  final double x;
  final double y;
  final double opacity;
  final double size;

  StaticStar({
    required this.x,
    required this.y,
    required this.opacity,
    required this.size,
  });
}
