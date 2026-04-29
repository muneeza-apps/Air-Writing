import 'package:flutter/material.dart';

class MagneticEnergyCursor extends StatelessWidget {
  final Offset position;
  final double size;

  const MagneticEnergyCursor({
    Key? key,
    required this.position,
    this.size = 24.0,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return AnimatedPositioned(
      duration: const Duration(milliseconds: 120), // "Drag/Inertia" effect duration
      curve: Curves.easeOutBack, // Elastic bounce transition
      left: position.dx - (size / 2),
      top: position.dy - (size / 2),
      child: IgnorePointer(
        child: Container(
          width: size,
          height: size,
          decoration: ShapeDecoration(
            shape: const CircleBorder(),
            color: const Color(0xFFBB86FC), // Primary Color
            shadows: [
              BoxShadow(
                color: const Color(0xFFBB86FC).withOpacity(0.8),
                blurRadius: 25,
                spreadRadius: 8,
              ),
              BoxShadow(
                color: const Color(0xFFBB86FC).withOpacity(0.4),
                blurRadius: 50,
                spreadRadius: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
