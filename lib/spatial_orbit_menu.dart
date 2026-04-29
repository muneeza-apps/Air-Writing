import 'dart:math' as math;
import 'dart:ui';
import 'package:flutter/material.dart';

class SpatialOrbitMenu extends StatefulWidget {
  final Offset centerPosition;
  final Offset handPosition;

  const SpatialOrbitMenu({
    Key? key,
    required this.centerPosition,
    required this.handPosition,
  }) : super(key: key);

  @override
  State<SpatialOrbitMenu> createState() => _SpatialOrbitMenuState();
}

class _SpatialOrbitMenuState extends State<SpatialOrbitMenu> with TickerProviderStateMixin {
  late AnimationController _orbitController;
  late AnimationController _pulseController;

  // Radius of the orbital menu
  final double radius = 130.0;

  // Tools in the menu
  final List<OrbitItem> items = [
    OrbitItem(icon: Icons.cloud_upload_outlined, label: "Save to Cloud"),
    OrbitItem(icon: Icons.share_outlined, label: "Share"),
    OrbitItem(icon: Icons.delete_outline, label: "Clear"),
    OrbitItem(icon: Icons.settings_outlined, label: "Settings"),
  ];

  @override
  void initState() {
    super.initState();
    
    // Controls the slow rotation of the planets
    _orbitController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 25), // Very slow orbital rotation
    )..repeat();

    // Controls the glowing border pulsing effect
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _orbitController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      // Rebuilds on both orbit movement and pulse updates
      animation: Listenable.merge([_orbitController, _pulseController]),
      builder: (context, child) {
        return Stack(
          clipBehavior: Clip.none,
          children: List.generate(items.length, (index) {
            final item = items[index];
            
            // 1. Calculate orbital angle (offset evenly for 4 items)
            final double baseAngle = (index * 2 * math.pi) / items.length;
            final double currentAngle = baseAngle + (_orbitController.value * 2 * math.pi);

            // 2. Trigonometry for Circular Orbit (X = cos, Y = sin)
            final double dx = widget.centerPosition.dx + radius * math.cos(currentAngle);
            final double dy = widget.centerPosition.dy + radius * math.sin(currentAngle);
            final Offset itemPosition = Offset(dx, dy);

            // 3. Distance logic for interactive scaling
            final double distance = (widget.handPosition - itemPosition).distance;
            final bool isHovered = distance < 75.0; // Proximity threshold

            // Scale up if hovered
            final double scale = isHovered ? 1.4 : 1.0;
            // Pulsing logic: map 0.0-1.0 to an opacity range
            final double pulseOpacity = 0.2 + (_pulseController.value * 0.4); 

            return Positioned(
              left: dx,
              top: dy,
              child: FractionalTranslation(
                // Accurately center the widget on dx, dy
                translation: const Offset(-0.5, -0.5),
                child: _buildPlanet(item, scale, pulseOpacity, isHovered),
              ),
            );
          }),
        );
      },
    );
  }

  Widget _buildPlanet(OrbitItem item, double scale, double pulseOpacity, bool isHovered) {
    return AnimatedScale(
      scale: scale,
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeInOutSine, // Smooth anti-gravity scale
      child: Stack(
        alignment: Alignment.center,
        clipBehavior: Clip.none,
        children: [
          // Glassmorphic Orb
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFBB86FC).withOpacity(isHovered ? 0.8 : pulseOpacity),
                  blurRadius: isHovered ? 40 : 25,
                  spreadRadius: isHovered ? 12 : 5,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: ClipOval(
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                child: Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withOpacity(0.05),
                    border: Border.all(
                      color: isHovered 
                          ? Colors.white 
                          : Colors.white.withOpacity(pulseOpacity + 0.2), // Pulses when idle
                      width: isHovered ? 2.0 : 1.0,
                    ),
                  ),
                  child: Icon(
                    item.icon,
                    color: Colors.white,
                    size: 26,
                  ),
                ),
              ),
            ),
          ),
          
          // Hover Text Label (Fades in below the planet)
          Positioned(
            bottom: -35,
            child: AnimatedOpacity(
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeInOutSine,
              opacity: isHovered ? 1.0 : 0.0,
              child: IgnorePointer(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.7),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: const Color(0xFFBB86FC).withOpacity(0.6),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.4),
                        blurRadius: 20,
                        spreadRadius: 5,
                        offset: const Offset(0, 12),
                      ),
                    ],
                  ),
                  child: Text(
                    item.label,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      fontFamily: 'Roboto Mono',
                      letterSpacing: 0.5,
                    ),
                    textAlign: TextAlign.center,
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

class OrbitItem {
  final IconData icon;
  final String label;

  OrbitItem({required this.icon, required this.label});
}
