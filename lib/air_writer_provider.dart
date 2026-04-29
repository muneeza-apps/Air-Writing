import 'package:flutter/material.dart';

class AirWriterProvider extends ChangeNotifier {
  Offset _handPosition = const Offset(0, 0);
  bool _isMenuOpen = false;

  Offset get handPosition => _handPosition;
  bool get isMenuOpen => _isMenuOpen;

  void updateHandPosition(Offset newPosition) {
    _handPosition = newPosition;
    notifyListeners();
  }

  void toggleMenu() {
    _isMenuOpen = !_isMenuOpen;
    notifyListeners();
  }
}
