import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

class InkFlowParticleEngine extends StatefulWidget {
  final Widget? child;

  const InkFlowParticleEngine({Key? key, this.child}) : super(key: key);

  @override
  State<InkFlowParticleEngine> createState() => _InkFlowParticleEngineState();
}

class _InkFlowParticleEngineState extends State<InkFlowParticleEngine> with SingleTickerProviderStateMixin {
  final List<Offset?> _points = [];
  final List<Particle> _particles = [];
  
  late Ticker _ticker;
  Duration _lastElapsed = Duration.zero;
  final Random _random = Random();
  
  // Using ValueNotifiers to isolate repaint scopes for maximum performance
  final ValueNotifier<int> _strokeNotifier = ValueNotifier(0);
  final ValueNotifier<int> _particleNotifier = ValueNotifier(0);

  @override
  void initState() {
    super.initState();
    // Ticker runs at screen refresh rate (e.g. 60fps or 120fps)
    _ticker = createTicker(_onTick)..start();
  }

  void _onTick(Duration elapsed) {
    final double dt = (elapsed - _lastElapsed).inMilliseconds / 1000.0;
    _lastElapsed = elapsed;

    if (_particles.isNotEmpty) {
      // Update particle physics and remove dead particles
      _particles.removeWhere((p) => !p.update(dt));
      // Notify only the particle layer to repaint
      _particleNotifier.value++; 
    }
  }

  void _addPoint(Offset point) {
    _points.add(point);
    _strokeNotifier.value++; // Notify stroke layer to repaint
    
    // Generate 2-4 Particles per touch point for the Anti-Gravity Engine
    int particleCount = _random.nextInt(3) + 2; 
    for (int i = 0; i < particleCount; i++) {
      _particles.add(Particle(
        position: point,
        // Anti-gravity: upward drift (negative dy) with slight horizontal spread
        velocity: Offset((_random.nextDouble() - 0.5) * 50, -_random.nextDouble() * 80 - 40),
        // Random lifespan between 500ms and 1s
        lifeSpan: _random.nextDouble() * 0.5 + 0.5, 
        size: _random.nextDouble() * 2.5 + 1.0,
        color: Color.lerp(const Color(0xFF00FFFF), const Color(0xFF0055FF), _random.nextDouble())!,
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
        _points.add(null);
        _strokeNotifier.value++;
      },
      child: Container(
        color: Colors.transparent, // Ensures GestureDetector captures events
        child: Stack(
          children: [
            if (widget.child != null) widget.child!,
            
            // 1. Static/Growing Stroke Layer
            RepaintBoundary(
              child: CustomPaint(
                painter: StrokePainter(points: _points, repaint: _strokeNotifier),
                size: Size.infinite,
                isComplex: true, // Optimizes caching for complex paths
              ),
            ),
            
            // 2. High-Frequency Particle Layer
            RepaintBoundary(
              child: CustomPaint(
                painter: ParticlePainter(particles: _particles, repaint: _particleNotifier),
                size: Size.infinite,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class Particle {
  Offset position;
  final Offset velocity;
  final double lifeSpan;
  double age = 0;
  final double size;
  final Color color;

  Particle({
    required this.position,
    required this.velocity,
    required this.lifeSpan,
    required this.size,
    required this.color,
  });

  bool update(double dt) {
    age += dt;
    position += velocity * dt; 
    return age < lifeSpan; // Returns true if alive
  }
}

class StrokePainter extends CustomPainter {
  final List<Offset?> points;

  StrokePainter({required this.points, required Listenable repaint}) : super(repaint: repaint);

  @override
  void paint(Canvas canvas, Size size) {
    final basePaint = Paint()
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke
      ..blendMode = BlendMode.screen; // Neon glow overlap

    for (int i = 0; i < points.length - 1; i++) {
      if (points[i] != null && points[i + 1] != null) {
        // Dynamic gradient flow based on stroke progression
        double fraction = (i % 150) / 150.0; 
        Color? color = Color.lerp(const Color(0xFF00FFFF), const Color(0xFF0055FF), fraction);

        // Glow Layer (Thicker, Transparent)
        canvas.drawLine(
          points[i]!, 
          points[i + 1]!, 
          basePaint
            ..strokeWidth = 16.0
            ..color = color!.withOpacity(0.15)
        );

        // Core Layer (Thinner, Opaque)
        canvas.drawLine(
          points[i]!, 
          points[i + 1]!, 
          basePaint
            ..strokeWidth = 3.5
            ..color = color.withOpacity(0.9)
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant StrokePainter oldDelegate) => true; 
}

class ParticlePainter extends CustomPainter {
  final List<Particle> particles;

  ParticlePainter({required this.particles, required Listenable repaint}) : super(repaint: repaint);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..blendMode = BlendMode.screen; // Brightens when overlapping strokes/background

    for (var p in particles) {
      // Calculate opacity fade based on remaining lifespan
      double opacity = 1.0 - (p.age / p.lifeSpan);
      if (opacity < 0) opacity = 0;

      paint.color = p.color.withOpacity(opacity);
      canvas.drawCircle(p.position, p.size, paint);
    }
  }

  @override
  bool shouldRepaint(covariant ParticlePainter oldDelegate) => true;
}
