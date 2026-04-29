import 'package:flutter/material.dart';

class TextAscensionAnimation extends StatelessWidget {
  final bool isRecognized;
  final String digitalText;
  final Widget inkWidget;

  const TextAscensionAnimation({
    Key? key,
    required this.isRecognized,
    required this.digitalText,
    required this.inkWidget,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      clipBehavior: Clip.none,
      children: [
        // 1. Original Ink strokes fading out
        AnimatedOpacity(
          opacity: isRecognized ? 0.0 : 1.0,
          duration: const Duration(milliseconds: 400),
          curve: Curves.easeInOutSine,
          child: inkWidget,
        ),
        
        // 2. Rising digital text fading in
        AnimatedOpacity(
          opacity: isRecognized ? 1.0 : 0.0,
          duration: const Duration(milliseconds: 500),
          curve: Curves.easeInOutSine,
          child: TweenAnimationBuilder<double>(
            // Moves up by 30 units when recognized
            tween: Tween<double>(begin: 0.0, end: isRecognized ? -30.0 : 0.0),
            duration: const Duration(milliseconds: 600),
            curve: Curves.easeInOutSine, // Smooth, weightless anti-gravity feel
            builder: (context, dy, child) {
              return Transform.translate(
                offset: Offset(0, dy),
                child: child,
              );
            },
            child: Text(
              digitalText,
              style: const TextStyle(
                fontFamily: 'Roboto Mono', // Futuristic / Monospace look
                fontSize: 32,
                color: Color(0xFFBB86FC), // Themed energy color (matching cursor)
                fontWeight: FontWeight.bold,
                letterSpacing: 2.0,
                shadows: [
                  Shadow(
                    color: Color(0x88BB86FC),
                    blurRadius: 12,
                    offset: Offset(0, 2),
                  )
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
