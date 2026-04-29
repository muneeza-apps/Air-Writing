import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

class HandwritingPainterWidget extends StatefulWidget {
  final Widget? child;
  
  const HandwritingPainterWidget({Key? key, this.child}) : super(key: key);

  @override
  State<HandwritingPainterWidget> createState() => _HandwritingPainterWidgetState();
}

class _HandwritingPainterWidgetState extends State<HandwritingPainterWidget> with SingleTickerProviderStateMixin {
  final List<Offset?> _points = [];
  final List<EnergyDust> _particles = [];
  
  late Ticker _ticker;
  Duration _lastElapsed = Duration.zero;
  final Random _random = Random();
  
  final ValueNotifier<int> _strokeNotifier = ValueNotifier(0);
  final ValueNotifier<int> _particleNotifier = ValueNotifier(0);

  @override
  void initState() {
    super.initState();
    _ticker = createTicker(_onTick)..start();
  }

  void _onTick(Duration elapsed) {
    final double dt = (elapsed - _lastElapsed).inMilliseconds / 1000.0;
    _lastElapsed = elapsed;

    if (_particles.isNotEmpty) {
      // Remove particles whose lifeSpan is over 1 second
      _particles.removeWhere((p) => !p.update(dt));
      _particleNotifier.value++; 
    }
  }

  void _addPoint(Offset point) {
    _points.add(point);
    _strokeNotifier.value++;
    
    // Emit 2-3 tiny "energy dust" particles per stroke point
    int particleCount = _random.nextInt(2) + 2; 
    for (int i = 0; i < particleCount; i++) {
      _particles.add(EnergyDust(
        position: point,
        // Small random upward drift
        velocity: Offset((_random.nextDouble() - 0.5) * 40, -_random.nextDouble() * 50 - 10),
        lifeSpan: 1.0, // Fade out exactly after 1 second
        size: _random.nextDouble() * 2.0 + 0.5,
        color: Color.lerp(
          const Color(0xFF00FFFF), // Electric Cyan
          const Color(0xFFB026FF), // Neon Purple
          _random.nextDouble()
        )!,
      ));
    }
  }

  @override
  void dispose() {
    _ticker.dispose();
    _strokeNotifier.dispose();
    _particleNotifier.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onPanStart: (details) => _addPoint(details.localPosition),
      onPanUpdate: (details) => _addPoint(details.localPosition),
      onPanEnd: (details) {
        _points.add(null); // Null acts as a break in the path
        _strokeNotifier.value++;
      },
      child: Container(
        color: Colors.transparent, // Capture pan events over empty areas
        child: Stack(
          children: [
            if (widget.child != null) widget.child!,
            
            // 1. Solid Neon Path Layer
            RepaintBoundary(
              child: CustomPaint(
                painter: StrokePathPainter(points: _points, repaint: _strokeNotifier),
                size: Size.infinite,
                isComplex: true,
              ),
            ),
            
            // 2. High-Frequency Dust Particle Layer
            RepaintBoundary(
              child: CustomPaint(
                painter: EnergyDustPainter(particles: _particles, repaint: _particleNotifier),
                size: Size.infinite,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class EnergyDust {
  Offset position;
  final Offset velocity;
  final double lifeSpan;
  double age = 0;
  final double size;
  final Color color;

  EnergyDust({
    required this.position,
    required this.velocity,
    required this.lifeSpan,
    required this.size,
    required this.color,
  });

  bool update(double dt) {
    age += dt;
    position += velocity * dt; 
    return age < lifeSpan; // Alive if age < 1.0s
  }
}

class StrokePathPainter extends CustomPainter {
  final List<Offset?> points;

  StrokePathPainter({required this.points, required Listenable repaint}) : super(repaint: repaint);

  @override
  void paint(Canvas canvas, Size size) {
    if (points.isEmpty) return;

    // Gradient for the Pen: Electric Cyan to Neon Purple
    final Rect rect = Offset.zero & size;
    final Gradient gradient = const LinearGradient(
      colors: [Color(0xFF00FFFF), Color(0xFFB026FF)], 
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    );

    // Glow Paint with MaskFilter.blur
    final glowPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 14.0
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..shader = gradient.createShader(rect)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8.0); // Creates true Neon Glow

    // Solid Core Paint (Brighter inner line)
    final corePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4.0
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..shader = gradient.createShader(rect); 

    // Convert Points into a continuous Path
    Path path = Path();
    bool isNewPath = true;

    for (int i = 0; i < points.length; i++) {
      if (points[i] == null) {
        isNewPath = true;
      } else {
        if (isNewPath) {
          path.moveTo(points[i]!.dx, points[i]!.dy);
          isNewPath = false;
        } else {
          path.lineTo(points[i]!.dx, points[i]!.dy);
        }
      }
    }

    // Draw the blurred glow behind
    canvas.drawPath(path, glowPaint);
    // Draw the sharp core on top
    canvas.drawPath(path, corePaint);
  }

  @override
  bool shouldRepaint(covariant StrokePathPainter oldDelegate) => true; 
}

class EnergyDustPainter extends CustomPainter {
  final List<EnergyDust> particles;

  EnergyDustPainter({required this.particles, required Listenable repaint}) : super(repaint: repaint);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..blendMode = BlendMode.screen;

    for (var p in particles) {
      // Linear fade out over 1 second
      double opacity = 1.0 - (p.age / p.lifeSpan);
      if (opacity < 0) opacity = 0;

      paint.color = p.color.withOpacity(opacity);
      canvas.drawCircle(p.position, p.size, paint);
    }
  }

  @override
  bool shouldRepaint(covariant EnergyDustPainter oldDelegate) => true;
}
