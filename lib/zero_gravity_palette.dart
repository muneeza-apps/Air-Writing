import 'package:flutter/material.dart';

class ZeroGravityPalette extends StatelessWidget {
  final Offset cursorPosition;
  
  const ZeroGravityPalette({
    Key? key,
    required this.cursorPosition,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // A palette of floating tools on the left side of the screen
    return Stack(
      children: [
        Positioned(
          left: 40,
          top: 150,
          child: FloatingIcon(
            icon: Icons.edit,
            cursorPosition: cursorPosition,
            basePosition: const Offset(40, 150),
            floatDuration: const Duration(seconds: 2),
          ),
        ),
        Positioned(
          left: 40,
          top: 250,
          child: FloatingIcon(
            icon: Icons.cleaning_services, // Eraser
            cursorPosition: cursorPosition,
            basePosition: const Offset(40, 250),
            floatDuration: const Duration(milliseconds: 2500),
          ),
        ),
        Positioned(
          left: 40,
          top: 350,
          child: FloatingIcon(
            icon: Icons.document_scanner, // OCR
            cursorPosition: cursorPosition,
            basePosition: const Offset(40, 350),
            floatDuration: const Duration(milliseconds: 2200),
          ),
        ),
      ],
    );
  }
}

class FloatingIcon extends StatefulWidget {
  final IconData icon;
  final Offset cursorPosition;
  final Offset basePosition;
  final Duration floatDuration;

  const FloatingIcon({
    Key? key,
    required this.icon,
    required this.cursorPosition,
    required this.basePosition,
    required this.floatDuration,
  }) : super(key: key);

  @override
  State<FloatingIcon> createState() => _FloatingIconState();
}

class _FloatingIconState extends State<FloatingIcon> with SingleTickerProviderStateMixin {
  late final AnimationController _floatController;
  late final Animation<double> _floatAnimation;

  @override
  void initState() {
    super.initState();
    _floatController = AnimationController(
      vsync: this,
      duration: widget.floatDuration,
    )..repeat(reverse: true);
    
    _floatAnimation = Tween<double>(begin: -6.0, end: 6.0).animate(
      CurvedAnimation(parent: _floatController, curve: Curves.easeInOutSine)
    );
  }

  @override
  void dispose() {
    _floatController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Approximate the center of the icon
    final iconCenter = widget.basePosition + const Offset(30, 30);
    // Distance between hand cursor and the icon
    final distance = (widget.cursorPosition - iconCenter).distance;
    
    // Proximity logic
    final isNear = distance < 100.0;
    
    final scale = isNear ? 1.3 : 1.0;
    final glowOpacity = isNear ? 0.9 : 0.2;
    final borderColor = isNear ? Colors.white : Colors.white.withOpacity(0.4);

    return AnimatedBuilder(
      animation: _floatController,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, _floatAnimation.value),
          child: child,
        );
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOutBack,
        width: 60,
        height: 60,
        transform: Matrix4.identity()..scale(scale),
        transformAlignment: Alignment.center,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.white.withOpacity(0.1),
          border: Border.all(color: borderColor, width: 1.5),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFFBB86FC).withOpacity(glowOpacity),
              blurRadius: isNear ? 40 : 20,
              spreadRadius: isNear ? 15 : 5,
              offset: const Offset(0, 10),
            )
          ]
        ),
        child: Icon(
          widget.icon, 
          color: Colors.white,
          size: 28,
        ),
      ),
    );
  }
}
