import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';

class FloatingCanvas extends StatefulWidget {
  final Widget? child;
  
  const FloatingCanvas({Key? key, this.child}) : super(key: key);

  @override
  State<FloatingCanvas> createState() => _FloatingCanvasState();
}

class _FloatingCanvasState extends State<FloatingCanvas> {
  Timer? _timer;
  Offset _shiftOffset = Offset.zero;

  @override
  void initState() {
    super.initState();
    
    // Set initial drift and start the 4-second zero-gravity cycle
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        setState(() {
          _shiftOffset = const Offset(0, -12); // Initial float up
        });
        
        _timer = Timer.periodic(const Duration(seconds: 4), (timer) {
          if (!mounted) return;
          setState(() {
            // Cycle between 3 soft positions for a more organic drift
            if (_shiftOffset.dy == -12) {
              _shiftOffset = const Offset(6, 12);
            } else if (_shiftOffset.dy == 12) {
              _shiftOffset = const Offset(-6, 0);
            } else {
              _shiftOffset = const Offset(0, -12);
            }
          });
        });
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // 1. Wrap the entire container in an AnimatedContainer
    return AnimatedContainer(
      duration: const Duration(seconds: 4),
      curve: Curves.easeInOutSine, // Buttery smooth anti-gravity feel
      transform: Matrix4.translationValues(_shiftOffset.dx, _shiftOffset.dy, 0),
      child: Container(
        margin: const EdgeInsets.all(32.0),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(30.0), // Rounded corners (30.0)
          boxShadow: [
            // Soft Blue BoxShadow with high blur
            BoxShadow(
              color: const Color(0xFF0055FF).withOpacity(0.25),
              blurRadius: 60.0,
              spreadRadius: 15.0,
              offset: const Offset(0, 25),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(30.0),
          // 2. BackdropFilter with sigma 15.0 for Glassmorphism
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 15.0, sigmaY: 15.0),
            child: Container(
              padding: const EdgeInsets.all(24.0),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.08), // Frosted tint
                borderRadius: BorderRadius.circular(30.0),
                border: Border.all(
                  // Thin white border (0.3 opacity)
                  color: Colors.white.withOpacity(0.3), 
                  width: 1.0,
                ),
              ),
              child: widget.child,
            ),
          ),
        ),
      ),
    );
  }
}
