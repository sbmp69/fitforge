import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../core/theme.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../models/progress_log.dart';
import '../../services/api_service.dart';
import '../../services/supabase_service.dart';
import '../../services/notification_service.dart';
import '../../widgets/app_card.dart';

class ProgressScreen extends StatefulWidget {
  const ProgressScreen({super.key});

  @override
  State<ProgressScreen> createState() => _ProgressScreenState();
}

class _ProgressScreenState extends State<ProgressScreen> {
  final _supabase = SupabaseService();
  final _api = ApiService();
  List<ProgressLog> _logs = [];
  bool _loading = true;
  String _insight = '';

  final _weight = TextEditingController();
  final _water = TextEditingController(text: '2000');
  final _sleep = TextEditingController(text: '7');
  bool _workoutDone = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final logs = await _supabase.getProgressLogs();
    if (mounted) setState(() {
      _logs = logs;
      _loading = false;
    });
  }

  Future<void> _save() async {
    final today = DateFormat('yyyy-MM-dd').format(DateTime.now());
    await _supabase.upsertProgressLog(
      logDate: today,
      weightKg: double.tryParse(_weight.text),
      workoutCompleted: _workoutDone,
      waterMl: int.tryParse(_water.text) ?? 0,
      sleepHours: double.tryParse(_sleep.text),
    );
    
    // Cancel today's reminder since they logged their progress
    await NotificationService().cancel(1);
    
    await _load();
    if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Saved!')));
  }

  Future<void> _getInsight() async {
    try {
      final text = await _api.getWeeklyInsight();
      if (mounted) setState(() => _insight = text);
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final weightData = _logs.where((l) => l.weightKg != null).toList().reversed.toList();

    return Scaffold(
      appBar: AppBar(title: const Text('Progress')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 140),
        children: [
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text("Today's Log", style: TextStyle(fontWeight: FontWeight.w600, color: Colors.white)),
                const SizedBox(height: 12),
                TextField(controller: _weight, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Weight (kg)')),
                const SizedBox(height: 8),
                TextField(controller: _water, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Water (ml)')),
                const SizedBox(height: 8),
                TextField(controller: _sleep, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Sleep (hours)')),
                CheckboxListTile(
                  value: _workoutDone,
                  onChanged: (v) => setState(() => _workoutDone = v ?? false),
                  title: const Text('Workout completed'),
                  contentPadding: EdgeInsets.zero,
                ),
                ElevatedButton(onPressed: _save, child: const Text('Save')).animate(onPlay: (c) => c.repeat(reverse: true)).shimmer(duration: 2.seconds, color: Colors.white24),
              ],
            ),
          ),
          const SizedBox(height: 16),
          AppCard(
            child: SizedBox(
              height: 200,
              child: weightData.isEmpty
                  ? const Center(child: Text('Log weight to see chart', style: TextStyle(color: AppColors.slate400)))
                  : LineChart(
                      LineChartData(
                        gridData: FlGridData(show: true, drawVerticalLine: false, getDrawingHorizontalLine: (_) => const FlLine(color: AppColors.navy700)),
                        titlesData: FlTitlesData(
                          leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: 40, getTitlesWidget: (v, _) => Text(v.toStringAsFixed(0), style: const TextStyle(fontSize: 10, color: AppColors.slate400)))),
                          bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, getTitlesWidget: (v, meta) {
                            final i = v.toInt();
                            if (i < 0 || i >= weightData.length) return const SizedBox();
                            return Text(DateFormat('MMM d').format(DateTime.parse(weightData[i].logDate)), style: const TextStyle(fontSize: 9, color: AppColors.slate400));
                          })),
                          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                        ),
                        borderData: FlBorderData(show: false),
                        lineBarsData: [
                          LineChartBarData(
                            spots: weightData.asMap().entries.map((e) => FlSpot(e.key.toDouble(), e.value.weightKg!)).toList(),
                            isCurved: true,
                            color: AppColors.primary,
                            barWidth: 3,
                            dotData: const FlDotData(show: true),
                          ),
                        ],
                      ),
                    ),
            ),
          ),
          const SizedBox(height: 16),
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Weekly AI Insights', style: TextStyle(fontWeight: FontWeight.w600, color: Colors.white)),
                    TextButton(onPressed: _getInsight, child: const Text('Generate')),
                  ],
                ),
                const SizedBox(height: 8),
                Text(_insight.isEmpty ? 'Log progress and generate insights.' : _insight, style: const TextStyle(color: AppColors.slate300, height: 1.5)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
