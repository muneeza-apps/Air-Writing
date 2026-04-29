import 'package:flutter/material.dart';
import 'dart:js' as js;
import 'dart:js' show allowInterop;
import 'dart:ui' as ui;
import 'dart:convert';

class AirWriterProvider extends ChangeNotifier {
  Offset _handPosition = const Offset(0, 0);
  Map<int, Offset> _activeHands = {};
  
  Color _selectedColor = const Color(0xFF00FFFF);
  double _brushSize = 14.0;
  double _opacity = 1.0;
  bool _isGlowEnabled = true;
  bool _isMenuOpen = false;
  int _clearSignal = 0;

  Offset get handPosition => _handPosition;
  Map<int, Offset> get activeHands => _activeHands;
  Color get selectedColor => _selectedColor;
  double get brushSize => _brushSize;
  double get opacity => _opacity;
  bool get isGlowEnabled => _isGlowEnabled;
  bool get isMenuOpen => _isMenuOpen;
  int get clearSignal => _clearSignal;

  AirWriterProvider() {
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
        // ✅ Only add hand if finger is UP (drawing: true)
        bool isDrawing = h['drawing'] == true;
        if (!isDrawing) continue;

        int id = h['id'] as int;
        double screenX = (h['x'] as num).toDouble() * size.width;
        double screenY = (h['y'] as num).toDouble() * size.height;
        newHands[id] = Offset(screenX, screenY);
      }

      _activeHands = newHands;
      
      if (newHands.isNotEmpty) {
        _handPosition = newHands.values.first;
      }
      
      notifyListeners();
    } catch (e) {
      debugPrint("Hand tracking JS error: $e");
    }
  }

  void setColor(Color c) { _selectedColor = c; notifyListeners(); }
  void setBrushSize(double s) { _brushSize = s; notifyListeners(); }
  void setOpacity(double o) { _opacity = o; notifyListeners(); }
  void toggleGlow() { _isGlowEnabled = !_isGlowEnabled; notifyListeners(); }
  void toggleMenu() { _isMenuOpen = !_isMenuOpen; notifyListeners(); }

  // ✅ FIX: Clear button — Flutter canvas + JS canvas dono clear
  void clearCanvas() {
    _clearSignal++;
    js.context.callMethod('clearDrawingCanvas', []);
    notifyListeners();
  }

  // ✅ updateHandPosition REMOVED — mouse drawing band
}