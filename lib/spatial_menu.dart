import 'dart:math';
import 'package:flutter/material.dart';

class SpatialMenu extends StatefulWidget {
  final bool isMenuOpen;
  final Offset handPosition;
  final Offset centerPosition; // Point around which the menu orbits

  const SpatialMenu({
    Key? key,
    required this.isMenuOpen,
    required this.handPosition,
    required this.centerPosition,
  }) : super(key: key);

  @override
  State<SpatialMenu> createState() => _SpatialMenuState();
}

class _SpatialMenuState extends State<SpatialMenu> with SingleTickerProviderStateMixin {
  late AnimationController _orbitController;
  final double radius = 110.0; // Distance of FABs from the center

  final List<IconData> icons = [
    Icons.save_rounded,
    Icons.share_rounded,
    Icons.delete_rounded,
    Icons.settings_rounded,
  ];

  @override
  void initState() {
    super.initState();
    // Controls the slow orbital rotation of the entire menu
    _orbitController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 15),
    )..repeat();
  }

  @override
  void dispose() {
    _orbitController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.isMenuOpen) return const SizedBox.shrink();

    return Positioned(
      // Center the bounding box exactly on the centerPosition
      left: widget.centerPosition.dx - radius,
      top: widget.centerPosition.dy - radius,
      width: radius * 2,
      height: radius * 2,
      child: AnimatedBuilder(
        animation: _orbitController,
        builder: (context, child) {
          // 1. Transform.rotate to orbit the entire layout slowly
          return Transform.rotate(
            angle: _orbitController.value * 2 * pi,
            child: Stack(
              clipBehavior: Clip.none,
              children: List.generate(icons.length, (index) {
                // Calculate local fixed positions inside the rotating box
                final double localAngle = (index * 2 * pi) / icons.length;
                final double localDx = radius + radius * cos(localAngle);
                final double localDy = radius + radius * sin(localAngle);
                
                // Calculate true global position for proximity detection
                // (Accounting for the continuous rotation of the parent)
                final double globalAngle = localAngle + (_orbitController.value * 2 * pi);
                final double globalDx = widget.centerPosition.dx + radius * cos(globalAngle);
                final double globalDy = widget.centerPosition.dy + radius * sin(globalAngle);
                final Offset globalItemPos = Offset(globalDx, globalDy);

                // Proximity Logic
                final double distance = (widget.handPosition - globalItemPos).distance;
                final bool isHovered = distance < 65.0; // Proximity threshold

                return Positioned(
                  left: localDx - 28, // Offset by half of standard FAB size (56/2)
                  top: localDy - 28,
                  child: Transform.rotate(
                    // 2. Counter-rotate the FAB so icons remain upright while orbiting
                    angle: -(_orbitController.value * 2 * pi),
                    // 3. AnimatedScale from 1.0 to 1.4 on hover
                    child: AnimatedScale(
                      scale: isHovered ? 1.4 : 1.0,
                      duration: const Duration(milliseconds: 200),
                      curve: Curves.easeInOutSine, // Soft floating transition
                      child: FloatingActionButton(
                        heroTag: 'spatial_menu_fab_$index', // Unique tags prevent Hero errors
                        onPressed: () {},
                        backgroundColor: isHovered ? const Color(0xFFBB86FC) : Colors.white,
                        elevation: isHovered ? 16 : 8,
                        child: Icon(
                          icons[index],
                          color: isHovered ? Colors.white : const Color(0xFF333333),
                        ),
                      ),
                    ),
                  ),
                );
              }),
            ),
          );
        },
      ),
    );
  }
}
