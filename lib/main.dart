import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'dart:js_interop';

// Setup JS Interop to receive MediaPipe Hands data
@JS()
external JSObject get window;

extension WindowExtension on JSObject {
  @JS('onMediaPipeHands')
  external set onMediaPipeHands(JSFunction value);
}

void main() {
  runApp(const AirWritingApp());
}

class AirWritingApp extends StatelessWidget {
  const AirWritingApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Air Writing Pro',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: Colors.transparent, // Let HTML video show through
      ),
      home: const AirWritingScreen(),
    );
  }
}

class AirWritingScreen extends StatefulWidget {
  const AirWritingScreen({super.key});

  @override
  State<AirWritingScreen> createState() => _AirWritingScreenState();
}

class _AirWritingScreenState extends State<AirWritingScreen> {
  List<Offset> _currentLine = [];
  List<Map<String, dynamic>> _lines = []; // Stores {points: [], color: Color, thickness: double}
  
  Color _currentColor = const Color(0xFF00FFFF);
  double _currentThickness = 6.0;
  
  String _modeText = "Loading Model";
  Offset? _cursorPosition;
  bool _isWriting = false;

  @override
  void initState() {
    super.initState();
    // Register the JS callback
    window.onMediaPipeHands = ((JSString jsonString) {
      _processLandmarks(jsonString.toDart);
    }).toJS;
  }

  double _dist3D(Map<String, dynamic> p1, Map<String, dynamic> p2) {
    final dx = p1['x'] - p2['x'];
    final dy = p1['y'] - p2['y'];
    final dz = p1['z'] - p2['z'];
    return sqrt(dx * dx + dy * dy + dz * dz);
  }

  bool _isPalmExtended(List<dynamic> landmarks) {
    final wrist = landmarks[0];
    final tips = [8, 12, 16, 20];
    final mcps = [5, 9, 13, 17];
    int extendedCount = 0;
    for (int i = 0; i < 4; i++) {
      if (_dist3D(wrist, landmarks[tips[i]]) > _dist3D(wrist, landmarks[mcps[i]])) {
        extendedCount++;
      }
    }
    return extendedCount == 4;
  }

  bool _isClosedFist(List<dynamic> landmarks) {
    final wrist = landmarks[0];
    final tips = [8, 12, 16, 20];
    final mcps = [5, 9, 13, 17];
    int curledCount = 0;
    for (int i = 0; i < 4; i++) {
      if (_dist3D(wrist, landmarks[tips[i]]) < _dist3D(wrist, landmarks[mcps[i]])) {
        curledCount++;
      }
    }
    return curledCount == 4;
  }

  void _processLandmarks(String jsonString) {
    if (jsonString == "[]") {
      setState(() {
        _modeText = "Waiting for Hand";
        _cursorPosition = null;
        _isWriting = false;
        _currentLine = [];
      });
      return;
    }

    final List<dynamic> landmarks = jsonDecode(jsonString);
    final size = MediaQuery.of(context).size;
    
    final indexTip = landmarks[8];
    final thumbTip = landmarks[4];

    // Mirror X coordinates since we flipped the video
    double drawX = size.width * (1 - indexTip['x']);
    double drawY = size.height * indexTip['y'];

    final pinchDistance = _dist3D(indexTip, thumbTip);

    String newMode = "Hovering";
    bool writing = false;

    if (_isPalmExtended(landmarks)) {
      newMode = "Clear Canvas";
      _lines.clear();
      _currentLine = [];
    } else if (_isClosedFist(landmarks)) {
      newMode = "Paused";
      _currentLine = [];
    } else if (pinchDistance < 0.05) {
      newMode = "Writing";
      writing = true;
    }

    setState(() {
      _modeText = newMode;
      _isWriting = writing;
      _cursorPosition = Offset(drawX, drawY);

      if (_isWriting) {
        if (_currentLine.isEmpty) {
          _currentLine = [_cursorPosition!];
          _lines.add({
            'points': _currentLine,
            'color': _currentColor,
            'thickness': _currentThickness,
          });
        } else {
          _currentLine.add(_cursorPosition!);
        }
      } else {
        _currentLine = []; // Break the line
      }
    });
  }

  Widget _buildColorBtn(Color color) {
    bool isActive = _currentColor == color;
    return GestureDetector(
      onTap: () => setState(() => _currentColor = color),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: isActive ? 40 : 30,
        height: isActive ? 40 : 30,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white, width: isActive ? 2 : 1),
          boxShadow: [
            if (isActive)
              BoxShadow(
                color: color,
                blurRadius: 15,
                spreadRadius: 2,
              )
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent, // Background video shows through
      body: Stack(
        children: [
          // Drawing Canvas Layer
          CustomPaint(
            size: Size.infinite,
            painter: NeonPainter(lines: _lines),
          ),
          
          // Cursor Layer
          if (_cursorPosition != null)
            Positioned(
              left: _cursorPosition!.dx - 10,
              top: _cursorPosition!.dy - 10,
              child: Container(
                width: _isWriting ? _currentThickness * 2 : 20,
                height: _isWriting ? _currentThickness * 2 : 20,
                decoration: BoxDecoration(
                  color: _isWriting ? Colors.white : _currentColor,
                  shape: BoxShape.circle,
                  boxShadow: [
                    if (!_isWriting)
                      BoxShadow(
                        color: _currentColor,
                        blurRadius: 20,
                      )
                  ],
                ),
              ),
            ),

          // Top Left Status UI
          Positioned(
            top: 40,
            left: 40,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Mode: $_modeText",
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: _modeText == "Writing" 
                        ? _currentColor 
                        : (_modeText == "Clear Canvas" ? Colors.redAccent : Colors.white),
                    shadows: [
                      Shadow(
                        color: _modeText == "Writing" ? _currentColor : Colors.white54,
                        blurRadius: 10,
                      )
                    ]
                  ),
                ),
                const SizedBox(height: 5),
                const Text(
                  "Pinch to Write | Fist to Pause | Palm to Clear",
                  style: TextStyle(fontSize: 14, color: Colors.white70),
                ),
              ],
            ),
          ),

          // Bottom Glassmorphism Control Dock
          Positioned(
            bottom: 40,
            left: 0,
            right: 0,
            child: Center(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(30),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
                  color: Colors.black.withOpacity(0.6),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        children: [
                          _buildColorBtn(const Color(0xFF00FFFF)), // Cyan
                          const SizedBox(width: 15),
                          _buildColorBtn(const Color(0xFFFF00FF)), // Pink
                          const SizedBox(width: 15),
                          _buildColorBtn(const Color(0xFF00FF00)), // Lime
                        ],
                      ),
                      const SizedBox(width: 40),
                      Row(
                        children: [
                          const Text("THICKNESS", style: TextStyle(fontSize: 12, letterSpacing: 1)),
                          const SizedBox(width: 15),
                          SizedBox(
                            width: 120,
                            child: Slider(
                              value: _currentThickness,
                              min: 2,
                              max: 25,
                              activeColor: Colors.white,
                              inactiveColor: Colors.white24,
                              onChanged: (val) => setState(() => _currentThickness = val),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // Watermark
          Positioned(
            bottom: 30,
            right: 40,
            child: Text.rich(
              TextSpan(
                text: "Developed by ",
                children: [
                  TextSpan(
                    text: "Muneeza Qureshi",
                    style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white70),
                  )
                ]
              ),
              style: TextStyle(color: Colors.white38, fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }
}

class NeonPainter extends CustomPainter {
  final List<Map<String, dynamic>> lines;

  NeonPainter({required this.lines});

  @override
  void paint(Canvas canvas, Size size) {
    for (var lineData in lines) {
      List<Offset> points = lineData['points'];
      Color color = lineData['color'];
      double thickness = lineData['thickness'];

      if (points.length < 2) continue;

      Path path = Path();
      path.moveTo(points.first.dx, points.first.dy);
      for (int i = 1; i < points.length; i++) {
        path.lineTo(points[i].dx, points[i].dy);
      }

      // 1. Draw Neon Glow (Outer Stroke)
      Paint outerPaint = Paint()
        ..color = color
        ..strokeWidth = thickness
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..style = PaintingStyle.stroke
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10.0);
        
      canvas.drawPath(path, outerPaint);

      // 2. Draw Core Bright Line (Inner Stroke)
      Paint innerPaint = Paint()
        ..color = Colors.white
        ..strokeWidth = thickness * 0.4
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..style = PaintingStyle.stroke;
        
      canvas.drawPath(path, innerPaint);
    }
  }

  @override
  bool shouldRepaint(covariant NeonPainter oldDelegate) {
    return true; // We want continuous repainting
  }
}
