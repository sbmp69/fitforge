import 'dart:async';
import 'package:flutter/material.dart';
import '../core/theme.dart';

class WorkoutTimer extends StatefulWidget {
  final int restSeconds;
  final VoidCallback? onComplete;

  const WorkoutTimer({super.key, required this.restSeconds, this.onComplete});

  @override
  State<WorkoutTimer> createState() => _WorkoutTimerState();
}

class _WorkoutTimerState extends State<WorkoutTimer> {
  late int _seconds;
  Timer? _timer;
  bool _running = false;

  @override
  void initState() {
    super.initState();
    _seconds = widget.restSeconds;
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _toggle() {
    if (_running) {
      _timer?.cancel();
      setState(() => _running = false);
      return;
    }
    setState(() => _running = true);
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (_seconds <= 1) {
        t.cancel();
        setState(() {
          _running = false;
          _seconds = 0;
        });
        widget.onComplete?.call();
      } else {
        setState(() => _seconds--);
      }
    });
  }

  void _reset() {
    _timer?.cancel();
    setState(() {
      _running = false;
      _seconds = widget.restSeconds;
    });
  }

  @override
  Widget build(BuildContext context) {
    final mins = _seconds ~/ 60;
    final secs = _seconds % 60;
    final isUrgent = _seconds <= 5 && _running;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const Text('Rest Timer', style: TextStyle(color: AppColors.slate400)),
            const SizedBox(height: 12),
            Text(
              '$mins:${secs.toString().padLeft(2, '0')}',
              style: TextStyle(
                fontSize: 40,
                fontWeight: FontWeight.bold,
                color: isUrgent ? Colors.redAccent : Colors.white,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton(onPressed: _toggle, child: Text(_running ? 'Pause' : 'Start')),
                const SizedBox(width: 8),
                OutlinedButton(onPressed: _reset, child: const Text('Reset')),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
