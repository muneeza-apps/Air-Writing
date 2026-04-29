import 'dart:ui' as ui;
import 'dart:js' as js;
import 'dart:convert';
import 'package:flutter/rendering.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

// Import Global State
import 'air_writer_provider.dart';

// Import Anti-Gravity Components
import 'handwriting_painter.dart';
import 'magnetic_energy_cursor.dart';
import 'floating_toolbar.dart';

void main() {
  runApp(
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
        scaffoldBackgroundColor: Colors.transparent, // Crucial for HTML video overlay
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
  final GlobalKey _canvasKey = GlobalKey();

  Future<void> _saveScreenshot() async {
    try {
      final boundary = _canvasKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
      if (boundary == null) return;
      
      // Capture High-Res Image
      final image = await boundary.toImage(pixelRatio: 2.0);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      if (byteData == null) return;
      
      final base64str = base64Encode(byteData.buffer.asUint8List());
      
      // Trigger Web Download via JS Interop
      js.context.callMethod('eval', [
        '''
        var a = document.createElement("a");
        a.href = "data:image/png;base64," + "$base64str";
        a.download = "AirWriter_Masterpiece.png";
        a.click();
        '''
      ]);
    } catch (e) {
      debugPrint("Error saving screenshot: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<AirWriterProvider>(context);

    return Scaffold(
      backgroundColor: Colors.transparent, // Ensures the HTML video feed is visible behind Flutter
      body: Stack(
        children: [
          // 1. Full Screen Drawing Area wrapped in RepaintBoundary for Saving
          Positioned.fill(
            child: RepaintBoundary(
              key: _canvasKey,
              child: HandwritingPainterWidget(
                activeHands: provider.activeHands,
                provider: provider,
                clearSignal: provider.clearSignal,
              ),
            ),
          ),
          
          // 2. Magnetic Energy Cursors for ALL detected hands
          ...provider.activeHands.values.map((pos) {
            return MagneticEnergyCursor(position: pos);
          }).toList(),
          
          // 3. Floating Toolbar at the bottom
          Align(
            alignment: Alignment.bottomCenter,
            child: SafeArea(
              child: FloatingToolbar(onSave: _saveScreenshot),
            ),
          ),
        ],
      ),
    );
  }
}
