import 'package:flutter/material.dart';
import 'dart:js' as js;
import 'dart:js' show allowInterop;
import 'dart:ui' as ui;
import 'dart:convert';

class AirWriterProvider extends ChangeNotifier {
  // Legacy single position (used by cursors/menus fallback)
  Offset _handPosition = const Offset(0, 0);
  
  // Dual Hand Tracking State
  Map<int, Offset> _activeHands = {};
  
  // Styling States
  Color _selectedColor = const Color(0xFF00FFFF); // Default Neon Cyan
  double _brushSize = 14.0;
  double _opacity = 1.0;
  bool _isGlowEnabled = true;

  bool _isMenuOpen = false;
  int _clearSignal = 0;

  // Getters
  Offset get handPosition => _handPosition;
  Map<int, Offset> get activeHands => _activeHands;
  Color get selectedColor => _selectedColor;
  double get brushSize => _brushSize;
  double get opacity => _opacity;
  bool get isGlowEnabled => _isGlowEnabled;
  bool get isMenuOpen => _isMenuOpen;
  int get clearSignal => _clearSignal;

  AirWriterProvider() {
    // Expose Dart function to JavaScript for Dual Hand Tracking
    js.context['updateDualHandTracking'] = allowInterop((dynamic jsonStr) {
      if (jsonStr != null) {
        _updateDualHands(jsonStr.toString());
      }
    });
  }

  void _updateDualHands(String jsonStr) {
    try {
      final List<dynamic> handsList = jsonDecode(jsonStr);
      final view = ui.PlatformDispatcher.instance.views.first;
      final size = view.physicalSize / view.devicePixelRatio;

      Map<int, Offset> newHands = {};
      for (var h in handsList) {
        int id = h['id'] as int;
        double screenX = (h['x'] as num).toDouble() * size.width;
        double screenY = (h['y'] as num).toDouble() * size.height;
        newHands[id] = Offset(screenX, screenY);
      }

      _activeHands = newHands;
      
      // Update legacy handPosition for the main cursor if at least 1 hand is present
      if (newHands.isNotEmpty) {
        _handPosition = newHands.values.first;
      }
      
      notifyListeners();
    } catch (e) {
      debugPrint("Hand tracking JS error: $e");
    }
  }

  // UI Actions
  void setColor(Color c) { _selectedColor = c; notifyListeners(); }
  void setBrushSize(double s) { _brushSize = s; notifyListeners(); }
  void setOpacity(double o) { _opacity = o; notifyListeners(); }
  void toggleGlow() { _isGlowEnabled = !_isGlowEnabled; notifyListeners(); }
  void toggleMenu() { _isMenuOpen = !_isMenuOpen; notifyListeners(); }
  void clearCanvas() { _clearSignal++; notifyListeners(); }

  // Fallback setter for mouse testing
  void updateHandPosition(Offset newPosition) {
    _handPosition = newPosition;
    _activeHands = {0: newPosition};
    notifyListeners();
  }
}
