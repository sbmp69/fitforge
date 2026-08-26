import 'dart:io';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:screenshot/screenshot.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
import '../../core/theme.dart';
import '../../models/progress_log.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';

class FlexCardScreen extends StatefulWidget {
  final ProgressLog log;
  final int currentStreak;
  final String userName;

  const FlexCardScreen({super.key, required this.log, required this.currentStreak, required this.userName});

  @override
  State<FlexCardScreen> createState() => _FlexCardScreenState();
}

class _FlexCardScreenState extends State<FlexCardScreen> {
  final ScreenshotController _screenshotController = ScreenshotController();
  bool _isCapturing = false;

  Future<void> _shareToInstagram() async {
    setState(() => _isCapturing = true);
    try {
      final image = await _screenshotController.capture(delay: const Duration(milliseconds: 10));
      if (image == null) return;
      
      final directory = await getApplicationDocumentsDirectory();
      final imagePath = await File('${directory.path}/flex_card.png').create();
      await imagePath.writeAsBytes(image);

      await Share.shareXFiles([XFile(imagePath.path)], text: 'Crushed my goals today on FitForge! 🔥');
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to share: $e')));
    } finally {
      if (mounted) setState(() => _isCapturing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.all(16),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Stack(
              clipBehavior: Clip.none,
              alignment: Alignment.topRight,
              children: [
                Screenshot(
                  controller: _screenshotController,
                  child: Container(
                    width: 320,
                    height: 480,
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(24),
                      gradient: const LinearGradient(
                        colors: [Color(0xFF1E293B), Color(0xFF0F172A)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      boxShadow: [
                        BoxShadow(color: Colors.black.withValues(alpha: 0.5), blurRadius: 20, spreadRadius: 5),
                      ],
                    ),
                    child: Stack(
                      children: [
                        Positioned(
                          top: -50,
                          right: -50,
                          child: Container(
                            width: 150,
                            height: 150,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: AppColors.primary.withValues(alpha: 0.1),
                            ),
                          ),
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Image.asset('assets/logo.png', height: 32, color: AppColors.primary),
                                Text('FITFORGE', style: GoogleFonts.montserrat(fontWeight: FontWeight.bold, letterSpacing: 2, color: AppColors.textHeader)),
                              ],
                            ),
                            const Spacer(),
                            Text(widget.userName.toUpperCase(), style: const TextStyle(fontSize: 14, color: AppColors.textSecondary, letterSpacing: 1.5)),
                            const SizedBox(height: 8),
                            Text('DAY CRUSHED', style: GoogleFonts.oswald(fontSize: 48, fontWeight: FontWeight.bold, color: AppColors.textHeader, height: 1.1)),
                            const SizedBox(height: 24),
                            if (widget.currentStreak > 0)
                              Row(
                                children: [
                                  const Text('🔥', style: TextStyle(fontSize: 24)),
                                  const SizedBox(width: 8),
                                  Text('${widget.currentStreak} Day Streak', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.orangeAccent)),
                                ],
                              ),
                            const SizedBox(height: 16),
                            Row(
                              children: [
                                _MiniStat(icon: Icons.fitness_center, value: widget.log.workoutCompleted ? 'Done' : 'Rest'),
                                const SizedBox(width: 12),
                                _MiniStat(icon: Icons.water_drop, value: '${widget.log.waterMl}ml'),
                              ],
                            ),
                            const Spacer(),
                            const Center(
                              child: Text("Search 'FitForge' on Google Play", style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ).animate().scale(curve: Curves.easeOutBack, duration: 600.ms),
                Positioned(
                  top: -10,
                  right: -10,
                  child: IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close, color: AppColors.textHeader),
                    style: IconButton.styleFrom(backgroundColor: Colors.black54),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            if (_isCapturing)
              const CircularProgressIndicator()
            else
              ElevatedButton.icon(
                onPressed: _shareToInstagram,
                icon: const Icon(Icons.share),
                label: const Text('Share to Instagram Story', style: TextStyle(fontWeight: FontWeight.bold)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.purpleAccent,
                  foregroundColor: AppColors.textHeader,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                ),
              ).animate().slideY(begin: 1, curve: Curves.easeOut),
          ],
        ),
      ),
    );
  }
}

class _MiniStat extends StatelessWidget {
  final IconData icon;
  final String value;
  const _MiniStat({required this.icon, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.textHeader.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(icon, size: 16, color: AppColors.primary),
          const SizedBox(width: 6),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w600, color: AppColors.textHeader)),
        ],
      ),
    );
  }
}
