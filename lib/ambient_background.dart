import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';

class AmbientBackground extends StatefulWidget {
  final Widget? child;
  
  const AmbientBackground({Key? key, this.child}) : super(key: key);

  @override
  State<AmbientBackground> createState() => _AmbientBackgroundState();
}

class _AmbientBackgroundState extends State<AmbientBackground> with SingleTickerProviderStateMixin {
  late final AnimationController _starController;
  Timer? _timer;
  final Random _random = Random();

  // Nebula Positions
  double _nebula1Top = -200;
  double _nebula1Left = -200;
  
  double _nebula2Top = 200;
  double _nebula2Left = 200;

  double _nebula3Top = 0;
  double _nebula3Left = 0;

  @override
  void initState() {
    super.initState();
    
    // Ticker for twinkling stars
    _starController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat(reverse: true);
    
    // Set initial random positions and start the floating animation timer
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _randomizePositions();
      _timer = Timer.periodic(const Duration(seconds: 12), (timer) {
        _randomizePositions();
      });
    });
  }

  void _randomizePositions() {
    if (!mounted) return;
    final size = MediaQuery.of(context).size;
    
    // Randomize positions slightly outside the screen to allow floating across
    setState(() {
      _nebula1Top = _random.nextDouble() * size.height;
      _nebula1Left = _random.nextDouble() * size.width;
      
      _nebula2Top = _random.nextDouble() * size.height;
      _nebula2Left = _random.nextDouble() * size.width;
      
      _nebula3Top = _random.nextDouble() * size.height;
      _nebula3Left = _random.nextDouble() * size.width;
    });
  }

  @override
  void dispose() {
    _starController.dispose();
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Background Gradient
        Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Color(0xFF000000), // Pitch Black
                Color(0xFF0A1128), // Deep Navy
              ],
            ),
          ),
        ),
        
        // Nebula 1 (Soft Purple)
        AnimatedPositioned(
          duration: const Duration(seconds: 12),
          curve: Curves.easeInOut,
          top: _nebula1Top - 150, 
          left: _nebula1Left - 150,
          child: _buildNebula(const Color(0x666A0DAD), 300), 
        ),
        
        // Nebula 2 (Soft Blue)
        AnimatedPositioned(
          duration: const Duration(seconds: 15),
          curve: Curves.easeInOut,
          top: _nebula2Top - 200,
          left: _nebula2Left - 200,
          child: _buildNebula(const Color(0x550000FF), 400),
        ),

        // Nebula 3 (Indigo)
        AnimatedPositioned(
          duration: const Duration(seconds: 18),
          curve: Curves.easeInOut,
          top: _nebula3Top - 100,
          left: _nebula3Left - 100,
          child: _buildNebula(const Color(0x444B0082), 200),
        ),

        // Stars CustomPainter
        AnimatedBuilder(
          animation: _starController,
          builder: (context, child) {
            return CustomPaint(
              painter: StarsPainter(animationValue: _starController.value),
              size: Size.infinite,
            );
          },
        ),

        // Optional Child Content
        if (widget.child != null)
          Positioned.fill(child: widget.child!),
      ],
    );
  }

  Widget _buildNebula(Color color, double size) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color.withOpacity(0.3),
        boxShadow: [
          BoxShadow(
            color: color,
            blurRadius: 150,
            spreadRadius: 50,
          ),
        ],
      ),
    );
  }
}

class StarsPainter extends CustomPainter {
  final double animationValue;
  final int starCount;
  
  static final Random _random = Random();
  static bool _initialized = false;
  static late List<Star> _cachedStars;

  StarsPainter({required this.animationValue, this.starCount = 100}) {
    if (!_initialized) {
      _cachedStars = List.generate(starCount, (index) => Star(
        x: _random.nextDouble(),
        y: _random.nextDouble(),
        maxOpacity: _random.nextDouble() * 0.8 + 0.2, // Range: 0.2 to 1.0
        size: _random.nextDouble() * 2 + 1, // Range: 1 to 3
        blinkPhase: _random.nextDouble() * 2 * pi, // Random starting phase
      ));
      _initialized = true;
    }
  }

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;
    
    for (var star in _cachedStars) {
      // Calculate twinkling effect
      double opacity = (sin(animationValue * pi * 2 + star.blinkPhase) + 1) / 2;
      opacity = opacity * star.maxOpacity;
      
      paint.color = Colors.white.withOpacity(opacity);
      canvas.drawCircle(
        Offset(star.x * size.width, star.y * size.height),
        star.size,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant StarsPainter oldDelegate) {
    return oldDelegate.animationValue != animationValue;
  }
}

class Star {
  final double x;
  final double y;
  final double maxOpacity;
  final double size;
  final double blinkPhase;

  Star({
    required this.x,
    required this.y,
    required this.maxOpacity,
    required this.size,
    required this.blinkPhase,
  });
}
