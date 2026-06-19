import 'dart:ui';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../core/theme.dart';

class AnimatedMeshBackground extends StatelessWidget {
  final Widget child;

  const AnimatedMeshBackground({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Base dark background
        Container(color: AppColors.navy900),
        
        // Floating Mesh Orbs
        Positioned(
          top: -100,
          left: -50,
          child: _buildOrb(AppColors.primary.withValues(alpha: 0.15), 300)
              .animate(onPlay: (controller) => controller.repeat())
              .move(
                duration: 10.seconds,
                begin: const Offset(0, 0),
                end: const Offset(50, 50),
                curve: Curves.easeInOutSine,
              )
              .then()
              .move(
                duration: 10.seconds,
                begin: const Offset(50, 50),
                end: const Offset(0, 0),
                curve: Curves.easeInOutSine,
              ),
        ),
        Positioned(
          bottom: -50,
          right: -100,
          child: _buildOrb(AppColors.accent.withValues(alpha: 0.15), 400)
              .animate(onPlay: (controller) => controller.repeat())
              .move(
                duration: 12.seconds,
                begin: const Offset(0, 0),
                end: const Offset(-50, -50),
                curve: Curves.easeInOutSine,
              )
              .then()
              .move(
                duration: 12.seconds,
                begin: const Offset(-50, -50),
                end: const Offset(0, 0),
                curve: Curves.easeInOutSine,
              ),
        ),
        
        // Blur filter to blend orbs into a mesh gradient
        Positioned.fill(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 80, sigmaY: 80),
            child: Container(color: Colors.transparent),
          ),
        ),
        
        // Content
        SafeArea(bottom: false, child: child),
      ],
    );
  }

  Widget _buildOrb(Color color, double size) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color,
      ),
    );
  }
}
