import 'package:flutter/material.dart';
import '../core/theme.dart';

class StreakFire extends StatelessWidget {
  final int streak;

  const StreakFire({super.key, required this.streak});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.local_fire_department, color: Colors.orange.shade400, size: 36),
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '$streak',
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
            ),
            const Text('day streak', style: TextStyle(fontSize: 12, color: AppColors.slate400)),
          ],
        ),
      ],
    );
  }
}
