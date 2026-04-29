import 'dart:ui';
import 'package:flutter/material.dart';

class FloatingGlassCanvas extends StatefulWidget {
  final Widget? child;
  final double width;
  final double height;
  final EdgeInsetsGeometry padding;

  const FloatingGlassCanvas({
    Key? key,
    this.child,
    this.width = double.infinity,
    this.height = double.infinity,
    this.padding = const EdgeInsets.all(24.0),
  }) : super(key: key);

  @override
  State<FloatingGlassCanvas> createState() => _FloatingGlassCanvasState();
}

class _FloatingGlassCanvasState extends State<FloatingGlassCanvas> {
  bool _isUp = false;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0, end: _isUp ? 10 : -10),
      duration: const Duration(seconds: 3),
      curve: Curves.easeInOutSine,
      onEnd: () {
        if (mounted) {
          setState(() {
            _isUp = !_isUp;
          });
        }
      },
      builder: (context, value, child) {
        return Transform.translate(
          offset: Offset(0, value),
          child: child,
        );
      },
      child: Container(
        width: widget.width,
        height: widget.height,
        margin: const EdgeInsets.all(32.0),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24.0),
          boxShadow: [
            // Deep depth shadow
            BoxShadow(
              color: Colors.black.withOpacity(0.15),
              blurRadius: 60,
              spreadRadius: 25,
              offset: const Offset(0, 30),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24.0),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 15.0, sigmaY: 15.0),
            child: Container(
              padding: widget.padding,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.1),
                borderRadius: BorderRadius.circular(24.0),
                border: Border.all(
                  color: Colors.white.withOpacity(0.2),
                  width: 1.5,
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
