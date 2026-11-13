import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/food_scan_result.dart';

class ApiService {
  String get baseUrl => dotenv.env['API_BASE_URL'] ?? 'http://10.0.2.2:3000';

  Future<Map<String, String>> _headers() async {
    final session = Supabase.instance.client.auth.currentSession;
    return {
      'Content-Type': 'application/json',
      if (session != null) 'Authorization': 'Bearer ${session.accessToken}',
    };
  }

  Future<Map<String, dynamic>> generateWorkout({
    required String goal,
    required String level,
    required int daysPerWeek,
    required List<String> equipment,
  }) async {
    final res = await http.post(
      Uri.parse('$baseUrl/api/ai/workout'),
      headers: await _headers(),
      body: jsonEncode({
        'goal': goal,
        'level': level,
        'daysPerWeek': daysPerWeek,
        'equipment': equipment,
      }),
    );
    final data = jsonDecode(res.body) as Map<String, dynamic>;
    if (res.statusCode != 200) throw Exception(data['error'] ?? 'Failed to generate workout');

    final session = Supabase.instance.client.auth.currentSession;
    if (session != null) {
      final profile = await Supabase.instance.client.from('profiles').select('ai_plans_used_this_month').eq('id', session.user.id).single();
      final used = profile['ai_plans_used_this_month'] as int? ?? 0;
      await Supabase.instance.client.from('profiles').update({'ai_plans_used_this_month': used + 1}).eq('id', session.user.id);
    }

    return data;
  }

  Future<Map<String, dynamic>> generateMeals({
    required String dietaryPreference,
    required List<String> allergies,
  }) async {
    final res = await http.post(
      Uri.parse('$baseUrl/api/ai/meals'),
      headers: await _headers(),
      body: jsonEncode({
        'dietaryPreference': dietaryPreference,
        'allergies': allergies,
      }),
    );
    final data = jsonDecode(res.body) as Map<String, dynamic>;
    if (res.statusCode != 200) throw Exception(data['error'] ?? 'Failed to generate meals');

    final session = Supabase.instance.client.auth.currentSession;
    if (session != null) {
      final profile = await Supabase.instance.client.from('profiles').select('ai_plans_used_this_month').eq('id', session.user.id).single();
      final used = profile['ai_plans_used_this_month'] as int? ?? 0;
      await Supabase.instance.client.from('profiles').update({'ai_plans_used_this_month': used + 1}).eq('id', session.user.id);
    }

    return data;
  }

  Future<String> getInsights({bool refresh = false}) async {
    final uri = Uri.parse('$baseUrl/api/ai/insights${refresh ? '?refresh=true' : ''}');
    final headers = await _headers();
    var res = await http.get(uri, headers: headers);
    if (res.statusCode != 200) {
      res = await http.post(uri, headers: headers);
    }
    if (res.statusCode != 200) {
      throw Exception('Failed to generate insights: HTTP ${res.statusCode}');
    }
    final data = jsonDecode(res.body) as Map<String, dynamic>;
    return data['insight']?['insight_text'] as String? ?? '';
  }

  Future<String> getWeeklyInsight({bool refresh = false}) => getInsights(refresh: refresh);

  Future<String> chatWithCoach(String message) async {
    final res = await http.post(
      Uri.parse('$baseUrl/api/ai/coach'),
      headers: await _headers(),
      body: jsonEncode({'message': message}),
    );
    final data = jsonDecode(res.body) as Map<String, dynamic>;
    if (res.statusCode != 200) throw Exception(data['error'] ?? 'Coach unavailable');
    return data['reply'] as String? ?? '';
  }

  Future<String?> getCachedOrGeneratedImageUrl({
    required String name,
    required String category,
    bool generate = false,
  }) async {
    try {
      final res = await http.post(
        Uri.parse('$baseUrl/api/ai/media'),
        headers: await _headers(),
        body: jsonEncode({
          'name': name,
          'category': category,
          'generate': generate,
        }),
      );
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body) as Map<String, dynamic>;
        if (data['imageUrl'] != null && data['imageUrl'].toString().isNotEmpty) {
          return data['imageUrl'] as String;
        }
      }
    } catch (_) {}
    return null;
  }

  Future<FoodScanResult> scanFood({
    String? text,
    String? imageBase64,
    String? mimeType,
    String? localImagePath,
  }) async {
    final res = await http.post(
      Uri.parse('$baseUrl/api/ai/scan-food'),
      headers: await _headers(),
      body: jsonEncode({
        if (text != null && text.trim().isNotEmpty) 'text': text.trim(),
        if (imageBase64 != null && imageBase64.isNotEmpty) 'imageBase64': imageBase64,
        if (mimeType != null) 'mimeType': mimeType,
      }),
    );
    final data = jsonDecode(res.body) as Map<String, dynamic>;
    if (res.statusCode == 422 || data['is_food'] == false) {
      throw NonFoodItemException(
        message: data['error']?.toString() ?? 'This does not appear to be food.',
        detectedSubject: data['detected_subject']?.toString() ?? 'Non-food item',
      );
    }
    if (res.statusCode != 200) {
      throw Exception(data['error'] ?? 'Failed to analyze food');
    }
    return FoodScanResult.fromJson(data, imagePath: localImagePath);
  }
}
