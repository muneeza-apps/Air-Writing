import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'air_writer_provider.dart';

class FloatingToolbar extends StatelessWidget {
  final VoidCallback onSave;

  const FloatingToolbar({Key? key, required this.onSave}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<AirWriterProvider>(context);

    final List<Color> colors = [
      Colors.white,
      Colors.redAccent,
      Colors.orange,
      Colors.yellow,
      Colors.greenAccent,
      Colors.blueAccent,
      Colors.purpleAccent,
      Colors.pinkAccent,
      const Color(0xFF00FFFF), // Neon Cyan
      const Color(0xFFFFD700), // Gold
    ];

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.7),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: Colors.white.withOpacity(0.2)),
        boxShadow: const [
          BoxShadow(color: Colors.black54, blurRadius: 20, spreadRadius: 5),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Row 1: Color Palette
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: colors.map((c) {
                bool isSelected = provider.selectedColor == c;
                return GestureDetector(
                  onTap: () => provider.setColor(c),
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 8),
                    width: isSelected ? 36 : 28,
                    height: isSelected ? 36 : 28,
                    decoration: BoxDecoration(
                      color: c,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Colors.white,
                        width: isSelected ? 3 : 1,
                      ),
                      boxShadow: isSelected
                          ? [BoxShadow(color: c, blurRadius: 10, spreadRadius: 2)]
                          : [],
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 12),
          
          // Row 2: Sliders and Actions
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Brush Size
              Expanded(
                child: Row(
                  children: [
                    const Icon(Icons.brush, color: Colors.white70, size: 20),
                    Expanded(
                      child: Slider(
                        value: provider.brushSize,
                        min: 2.0,
                        max: 60.0,
                        activeColor: provider.selectedColor,
                        onChanged: provider.setBrushSize,
                      ),
                    ),
                  ],
                ),
              ),
              
              // Opacity
              Expanded(
                child: Row(
                  children: [
                    const Icon(Icons.opacity, color: Colors.white70, size: 20),
                    Expanded(
                      child: Slider(
                        value: provider.opacity,
                        min: 0.1,
                        max: 1.0,
                        activeColor: provider.selectedColor,
                        onChanged: provider.setOpacity,
                      ),
                    ),
                  ],
                ),
              ),

              // Glow Toggle
              Row(
                children: [
                  const Icon(Icons.auto_awesome, color: Colors.white70, size: 20),
                  Switch(
                    value: provider.isGlowEnabled,
                    activeColor: provider.selectedColor,
                    onChanged: (val) => provider.toggleGlow(),
                  ),
                ],
              ),
              
              // Actions
              IconButton(
                icon: const Icon(Icons.delete_sweep, color: Colors.redAccent),
                tooltip: "Clear Canvas",
                onPressed: provider.clearCanvas,
              ),
              IconButton(
                icon: const Icon(Icons.camera_alt, color: Colors.white),
                tooltip: "Save as PNG",
                onPressed: onSave,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
