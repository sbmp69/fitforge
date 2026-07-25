import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';

class AiOutageDialog extends StatelessWidget {
  const AiOutageDialog({super.key});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: const Color(0xFF142419),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: const Color(0xFF39FF14).withOpacity(0.3),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF39FF14).withOpacity(0.1),
              blurRadius: 20,
              spreadRadius: -5,
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF39FF14).withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Text(
                '😮‍💨',
                style: TextStyle(fontSize: 48),
              ),
            ).animate().scale(delay: 100.ms, duration: 400.ms, curve: Curves.easeOutBack),
            const SizedBox(height: 24),
            Text(
              'Our AI Coach is Catching Its Breath!',
              textAlign: TextAlign.center,
              style: GoogleFonts.outfit(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold,
                height: 1.2,
              ),
            ).animate().fade(delay: 200.ms).slideY(begin: 0.2),
            const SizedBox(height: 16),
            Text(
              'Wow, you guys are working out so hard today that our AI servers needed a quick water break! We are currently experiencing a slight delay.\n\nGrab a sip of water, stretch for a minute, and try again shortly!',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.grey[400],
                fontSize: 15,
                height: 1.5,
              ),
            ).animate().fade(delay: 300.ms).slideY(begin: 0.2),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              height: 54,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF39FF14),
                  foregroundColor: Colors.black,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: Text(
                  'Got it, Coach!',
                  style: GoogleFonts.outfit(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ).animate().fade(delay: 400.ms).scale(),
          ],
        ),
      ),
    );
  }
}
