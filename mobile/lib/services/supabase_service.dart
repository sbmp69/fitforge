import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter/foundation.dart';
import 'dart:io';
import '../models/meal_plan.dart';
import '../models/profile.dart';
import '../models/program.dart';
import '../models/progress_log.dart';
import '../models/workout_plan.dart';

class SupabaseService {
  final client = Supabase.instance.client;
  static bool _isGoogleSignInInitialized = false;
  User? get currentUser => client.auth.currentUser;

  Future<Profile?> getProfile() async {
    final user = currentUser;
    if (user == null) return null;
    final data = await client.from('profiles').select().eq('id', user.id).maybeSingle();
    return data != null ? Profile.fromJson(data) : null;
  }

  Future<void> updatePhysiqueProfile({
    required int heightCm,
    required double weightKg,
    required String goal,
    required String level,
  }) async {
    final user = currentUser;
    if (user == null) return;
    await client.from('profiles').update({
      'height_cm': heightCm,
      'weight_kg': weightKg,
      'primary_goal': goal,
      'fitness_level': level,
    }).eq('id', user.id);
  }

  Future<WorkoutPlan?> getActiveWorkoutPlan() async {
    final user = currentUser;
    if (user == null) return null;
    final data = await client
        .from('workout_plans')
        .select()
        .eq('user_id', user.id)
        .eq('is_active', true)
        .order('created_at', ascending: false)
        .limit(1)
        .maybeSingle();
    return data != null ? WorkoutPlan.fromJson(data) : null;
  }

  Future<MealPlan?> getActiveMealPlan() async {
    final user = currentUser;
    if (user == null) return null;
    final data = await client
        .from('meal_plans')
        .select()
        .eq('user_id', user.id)
        .eq('is_active', true)
        .order('created_at', ascending: false)
        .limit(1)
        .maybeSingle();
    return data != null ? MealPlan.fromJson(data) : null;
  }

  Future<List<ProgressLog>> getProgressLogs({int limit = 90}) async {
    final user = currentUser;
    if (user == null) return [];
    final data = await client
        .from('progress_logs')
        .select()
        .eq('user_id', user.id)
        .order('log_date', ascending: false)
        .limit(limit);
    return (data as List).map((e) => ProgressLog.fromJson(e)).toList();
  }

  Future<void> upsertProgressLog({
    required String logDate,
    double? weightKg,
    required bool workoutCompleted,
    required int waterMl,
    double? sleepHours,
  }) async {
    final user = currentUser!;
    await client.from('progress_logs').upsert({
      'user_id': user.id,
      'log_date': logDate,
      'weight_kg': weightKg,
      'workout_completed': workoutCompleted,
      'water_ml': waterMl,
      'sleep_hours': sleepHours,
    });
  }

  Future<List<Program>> getPublishedPrograms() async {
    final data = await client
        .from('programs')
        .select()
        .eq('is_published', true)
        .order('purchase_count', ascending: false);
    return (data as List).map((e) => Program.fromJson(e)).toList();
  }

  Future<void> signIn(String email, String password) async {
    await client.auth.signInWithPassword(email: email, password: password);
  }

  Future<void> signUp(String email, String password, String fullName, String role) async {
    final url = Uri.parse('${dotenv.env['API_BASE_URL'] ?? 'http://192.168.1.5:3000'}/api/auth/register');
    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'email': email,
        'password': password,
        'full_name': fullName,
        'role': role,
      }),
    );

    if (response.statusCode != 200) {
      final body = jsonDecode(response.body);
      throw Exception(body['error'] ?? 'Failed to sign up');
    }

    // Login after successful creation
    await client.auth.signInWithPassword(email: email, password: password);
  }

  Future<void> signInWithGoogle() async {
    if (kIsWeb) {
      await client.auth.signInWithOAuth(OAuthProvider.google);
      return;
    }

    const webClientId = '232259821601-aiqlebtbcs52hsvko0mmfqmshi5p3koa.apps.googleusercontent.com';
    const iosClientId = 'YOUR_IOS_CLIENT_ID_HERE';

    if (!_isGoogleSignInInitialized) {
      try {
        await GoogleSignIn.instance.initialize(
          clientId: Platform.isIOS ? iosClientId : null,
          serverClientId: webClientId,
        );
      } catch (e) {
        debugPrint('GoogleSignIn initialization error: $e');
      }
      _isGoogleSignInInitialized = true;
    }
    
    final googleUser = await GoogleSignIn.instance.authenticate();
    
    final googleAuth = await googleUser.authentication;
    final idToken = googleAuth.idToken;

    if (idToken == null) throw 'No ID Token found.';

    await client.auth.signInWithIdToken(
      provider: OAuthProvider.google,
      idToken: idToken,
    );
  }

  Future<void> signOut() => client.auth.signOut();
}
