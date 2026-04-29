import 'dart:math';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'air_writer_provider.dart';

class StrokePoint {
  final Offset position;
  final double width;
  StrokePoint(this.position, this.width);
}

class Stroke {
  final List<StrokePoint> points = [];
  final Color color;
  final double opacity;
  final double baseSize;
  final bool isGlowEnabled;

  Stroke({
    required this.color,
    required this.opacity,
    required this.baseSize,
    required this.isGlowEnabled,
  });

  void addPoint(Offset point) {
    double width = baseSize;
    if (points.isNotEmpty) {
      final double distance = (point - points.last.position).distance;
      double speedFactor = (1.0 - (distance / 40.0)).clamp(0.3, 1.5);
      width = baseSize * speedFactor;
    }
    points.add(StrokePoint(point, width));
  }
}

class HandwritingPainterWidget extends StatefulWidget {
  final Widget? child;
  final Map<int, Offset> activeHands;
  final AirWriterProvider provider;
  final int clearSignal;
  
  const HandwritingPainterWidget({
    Key? key, 
    this.child, 
    required this.activeHands,
    required this.provider,
    required this.clearSignal,
  }) : super(key: key);

  @override
  State<HandwritingPainterWidget> createState() => _HandwritingPainterWidgetState();
}

class _HandwritingPainterWidgetState extends State<HandwritingPainterWidget> with SingleTickerProviderStateMixin {
  final Map<int, Stroke> _activeStrokes = {};
  final List<Stroke> _completedStrokes = [];
  final List<EnergyDust> _particles = [];
  
  late Ticker _ticker;
  Duration _lastElapsed = Duration.zero;
  final Random _random = Random();
  final ValueNotifier<int> _repaintNotifier = ValueNotifier(0);

  @override
  void initState() {
    super.initState();
    _ticker = createTicker(_onTick)..start();
  }

  @override
  void didUpdateWidget(covariant HandwritingPainterWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    
    // ✅ FIX: Clear canvas
    if (widget.clearSignal != oldWidget.clearSignal) {
      _activeStrokes.clear();
      _completedStrokes.clear();
      _particles.clear();
      _repaintNotifier.value++;
      return;
    }

    _processHandUpdates(oldWidget.activeHands, widget.activeHands);
  }

  void _processHandUpdates(Map<int, Offset> oldHands, Map<int, Offset> newHands) {
    bool changed = false;

    newHands.forEach((id, pos) {
      if (!_activeStrokes.containsKey(id)) {
        _activeStrokes[id] = Stroke(
          color: widget.provider.selectedColor,
          opacity: widget.provider.opacity,
          baseSize: widget.provider.brushSize,
          isGlowEnabled: widget.provider.isGlowEnabled,
        );
      }
      
      if (oldHands[id] != pos) {
        _activeStrokes[id]!.addPoint(pos);
        if (widget.provider.isGlowEnabled) {
          _spawnParticles(pos, _activeStrokes[id]!.color);
        }
        changed = true;
      }
    });

    // ✅ FIX: Finger lift = stroke complete = letters nahi joingi
    List<int> toRemove = [];
    _activeStrokes.forEach((id, stroke) {
      if (!newHands.containsKey(id)) {
        if (stroke.points.isNotEmpty) {
          _completedStrokes.add(stroke);
        }
        toRemove.add(id);
        changed = true;
      }
    });

    for (int id in toRemove) {
      _activeStrokes.remove(id);
    }

    if (changed) _repaintNotifier.value++;
  }

  void _spawnParticles(Offset point, Color color) {
    int particleCount = _random.nextInt(2) + 1; 
    for (int i = 0; i < particleCount; i++) {
      _particles.add(EnergyDust(
        position: point,
        velocity: Offset((_random.nextDouble() - 0.5) * 30, -_random.nextDouble() * 40 - 10),
        lifeSpan: 0.8,
        size: _random.nextDouble() * 2.0 + 0.5,
        color: color,
      ));
    }
  }

  void _onTick(Duration elapsed) {
    final double dt = (elapsed - _lastElapsed).inMilliseconds / 1000.0;
    _lastElapsed = elapsed;

    if (_particles.isNotEmpty) {
      _particles.removeWhere((p) => !p.update(dt));
      _repaintNotifier.value++; 
    }
  }

  @override
  void dispose() {
    _ticker.dispose();
    _repaintNotifier.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // ✅ FIX: GestureDetector completely removed — no mouse drawing
    return Container(
      color: Colors.transparent,
      child: Stack(
        children: [
          if (widget.child != null) widget.child!,
          RepaintBoundary(
            child: CustomPaint(
              painter: AdvancedStrokePainter(
                activeStrokes: _activeStrokes,
                completedStrokes: _completedStrokes,
                particles: _particles,
                repaint: _repaintNotifier,
              ),
              size: Size.infinite,
              isComplex: true,
            ),
          ),
        ],
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
    return age < lifeSpan;
  }
}

class AdvancedStrokePainter extends CustomPainter {
  final Map<int, Stroke> activeStrokes;
  final List<Stroke> completedStrokes;
  final List<EnergyDust> particles;

  AdvancedStrokePainter({
    required this.activeStrokes, 
    required this.completedStrokes, 
    required this.particles, 
    required Listenable repaint,
  }) : super(repaint: repaint);

  @override
  void paint(Canvas canvas, Size size) {
    for (var stroke in completedStrokes) {
      _drawStroke(canvas, stroke);
    }
    for (var stroke in activeStrokes.values) {
      _drawStroke(canvas, stroke);
    }

    final particlePaint = Paint()..blendMode = BlendMode.screen;
    for (var p in particles) {
      double opacity = (1.0 - (p.age / p.lifeSpan)).clamp(0.0, 1.0);
      particlePaint.color = p.color.withOpacity(opacity);
      canvas.drawCircle(p.position, p.size, particlePaint);
    }
  }

  void _drawStroke(Canvas canvas, Stroke stroke) {
    if (stroke.points.isEmpty) return;

    final paint = Paint()
      ..color = stroke.color.withOpacity(stroke.opacity)
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final glowPaint = stroke.isGlowEnabled 
      ? (Paint()
          ..color = stroke.color.withOpacity(stroke.opacity * 0.4)
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.round
          ..strokeJoin = StrokeJoin.round
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12.0))
      : null;

    if (stroke.points.length == 1) {
      paint.strokeWidth = stroke.points.first.width;
      canvas.drawPoints(ui.PointMode.points, [stroke.points.first.position], paint);
      if (glowPaint != null) {
        glowPaint.strokeWidth = stroke.points.first.width * 2;
        canvas.drawPoints(ui.PointMode.points, [stroke.points.first.position], glowPaint);
      }
      return;
    }

    for (int i = 0; i < stroke.points.length - 1; i++) {
      final p1 = stroke.points[i];
      final p2 = stroke.points[i + 1];
      
      final path = Path();
      path.moveTo(p1.position.dx, p1.position.dy);
      
      if (i < stroke.points.length - 2) {
        final p3 = stroke.points[i + 2];
        final mid = Offset(
          (p2.position.dx + p3.position.dx) / 2,
          (p2.position.dy + p3.position.dy) / 2,
        );
        path.quadraticBezierTo(p2.position.dx, p2.position.dy, mid.dx, mid.dy);
      } else {
        path.lineTo(p2.position.dx, p2.position.dy);
      }
      
      paint.strokeWidth = p2.width;
      if (glowPaint != null) {
        glowPaint.strokeWidth = p2.width * 2.5;
        canvas.drawPath(path, glowPaint);
      }
      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(covariant AdvancedStrokePainter oldDelegate) => true;
}