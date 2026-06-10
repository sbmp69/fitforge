import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/meal_plan.dart';
import '../models/profile.dart';
import '../models/program.dart';
import '../models/progress_log.dart';
import '../models/workout_plan.dart';

class SupabaseService {
  SupabaseClient get client => Supabase.instance.client;
  User? get currentUser => client.auth.currentUser;

  Future<Profile?> getProfile() async {
    final user = currentUser;
    if (user == null) return null;
    final data = await client.from('profiles').select().eq('id', user.id).maybeSingle();
    return data != null ? Profile.fromJson(data) : null;
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
    await client.auth.signUp(
      email: email,
      password: password,
      data: {'full_name': fullName, 'role': role},
    );
    final user = currentUser;
    if (user != null) {
      await client.from('profiles').update({'role': role, 'full_name': fullName}).eq('id', user.id);
    }
  }

  Future<void> signOut() => client.auth.signOut();
}
