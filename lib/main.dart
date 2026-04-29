import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

// Import Global State
import 'air_writer_provider.dart';

// Import All Anti-Gravity Components
import 'ambient_background.dart';
import 'floating_canvas.dart';
import 'handwriting_painter.dart';
import 'spatial_orbit_menu.dart';
import 'spatial_menu.dart'; 
import 'magnetic_energy_cursor.dart';
import 'zero_gravity_palette.dart';
import 'text_ascension_animation.dart';
import 'ink_flow_particle_engine.dart';
import 'anti_gravity_base.dart';

void main() {
  runApp(
    // Wrap the app with ChangeNotifierProvider to manage global state
    ChangeNotifierProvider(
      create: (context) => AirWriterProvider(),
      child: const AirWriterApp(),
    ),
  );
}

class AirWriterApp extends StatelessWidget {
  const AirWriterApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'AirWriter Pro',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: Colors.black,
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFFBB86FC), // Neon Purple
          secondary: Color(0xFF00FFFF), // Electric Cyan
        ),
      ),
      home: const AirWriterHome(),
    );
  }
}

class AirWriterHome extends StatefulWidget {
  const AirWriterHome({Key? key}) : super(key: key);

  @override
  State<AirWriterHome> createState() => _AirWriterHomeState();
}

class _AirWriterHomeState extends State<AirWriterHome> {
  @override
  Widget build(BuildContext context) {
    // Access global state
    final provider = Provider.of<AirWriterProvider>(context);

    return Scaffold(
      // Use MouseRegion to simulate hand tracking with mouse cursor if testing on Web/Desktop
      body: MouseRegion(
        onHover: (event) {
          provider.updateHandPosition(event.position);
        },
        child: GestureDetector(
          onPanUpdate: (details) {
            // Update hand position while dragging/writing
            provider.updateHandPosition(details.globalPosition);
          },
          onDoubleTap: () {
            // Double tap to toggle Spatial Menu
            provider.toggleMenu();
          },
          child: Stack(
            children: [
              // 1. Ambient Background (Deep space stars and nebulas)
              const AmbientBackground(),
              
              // 2. Main Writing Canvas Area
              Center(
                child: SizedBox(
                  width: MediaQuery.of(context).size.width * 0.8,
                  height: MediaQuery.of(context).size.height * 0.7,
                  child: FloatingCanvas(
                    // Wrapping the specific Handwriting Painter inside the Glass Canvas
                    child: const HandwritingPainterWidget(),
                  ),
                ),
              ),
              
              // 3. Floating Zero Gravity Palette
              ZeroGravityPalette(cursorPosition: provider.handPosition),
              
              // 4. Spatial Orbit Menu (Toggled via double tap)
              if (provider.isMenuOpen)
                SpatialOrbitMenu(
                  centerPosition: MediaQuery.of(context).size.center(Offset.zero),
                  handPosition: provider.handPosition,
                ),
              
              // 5. Magnetic Energy Cursor following the hand
              MagneticEnergyCursor(position: provider.handPosition),
            ],
          ),
        ),
      ),
    );
  }
}
