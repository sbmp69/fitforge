import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'core/env_check.dart';
import 'core/theme.dart';
import 'router/app_router.dart';
import 'services/notification_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: '.env');
  await NotificationService().init();

  final supabaseUrl = dotenv.env['SUPABASE_URL'];
  final supabaseAnonKey = dotenv.env['SUPABASE_ANON_KEY'];

  if (isPlaceholderSupabaseConfig(supabaseUrl, supabaseAnonKey)) {
    runApp(const MisconfiguredApp());
    return;
  }

  await Supabase.initialize(
    url: supabaseUrl!,
    anonKey: supabaseAnonKey!, // ignore: deprecated_member_use
  );

  runApp(const FitForgeApp());
}

class MisconfiguredApp extends StatelessWidget {
  const MisconfiguredApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: AppTheme.dark,
      home: Scaffold(
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Icon(Icons.warning_amber_rounded, color: AppColors.amber, size: 48),
                SizedBox(height: 16),
                Text(
                  'Supabase not configured',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
                ),
                SizedBox(height: 12),
                Text(
                  'Edit mobile/.env with your real Supabase project URL and anon key from:\n'
                  'Supabase Dashboard → Project Settings → API',
                  style: TextStyle(color: AppColors.slate400, height: 1.5),
                ),
                SizedBox(height: 12),
                Text(
                  'SUPABASE_URL=https://YOUR_REF.supabase.co\n'
                  'SUPABASE_ANON_KEY=your-anon-key\n'
                  'API_BASE_URL=http://localhost:3000',
                  style: TextStyle(fontFamily: 'monospace', color: AppColors.primary, fontSize: 13),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class FitForgeApp extends StatelessWidget {
  const FitForgeApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'FitForge: Your AI Trainer',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.dark,
      routerConfig: AppRouter.create(),
    );
  }
}
