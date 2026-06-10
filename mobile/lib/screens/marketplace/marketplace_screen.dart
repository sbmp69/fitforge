import 'package:flutter/material.dart';
import '../../core/theme.dart';
import '../../models/program.dart';
import '../../services/supabase_service.dart';
import '../../widgets/app_card.dart';

class MarketplaceScreen extends StatefulWidget {
  const MarketplaceScreen({super.key});

  @override
  State<MarketplaceScreen> createState() => _MarketplaceScreenState();
}

class _MarketplaceScreenState extends State<MarketplaceScreen> {
  final _supabase = SupabaseService();
  List<Program> _programs = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final programs = await _supabase.getPublishedPrograms();
    if (mounted) setState(() {
      _programs = programs;
      _loading = false;
    });
  }

  String _formatInr(int amount) => '₹$amount';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Marketplace')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _programs.isEmpty
              ? const Center(child: Text('No programs yet', style: TextStyle(color: AppColors.slate400)))
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _programs.length,
                  itemBuilder: (_, i) {
                    final p = _programs[i];
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: AppCard(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (p.coverImageUrl != null)
                              ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: Image.network(p.coverImageUrl!, height: 120, width: double.infinity, fit: BoxFit.cover,
                                    errorBuilder: (_, __, ___) => Container(height: 120, color: AppColors.navy700, child: const Icon(Icons.image))),
                              )
                            else
                              Container(
                                height: 120,
                                decoration: BoxDecoration(color: AppColors.navy700, borderRadius: BorderRadius.circular(12)),
                                child: const Center(child: Icon(Icons.shopping_bag, size: 40, color: AppColors.slate400)),
                              ),
                            const SizedBox(height: 12),
                            Text(p.name, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: Colors.white)),
                            const SizedBox(height: 4),
                            Text(p.description, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(color: AppColors.slate400)),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                const Icon(Icons.star, size: 16, color: AppColors.amber),
                                Text(' ${p.avgRating.toStringAsFixed(1)} (${p.reviewCount})'),
                                const SizedBox(width: 12),
                                Text('${p.durationWeeks}w', style: const TextStyle(color: AppColors.slate400)),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(_formatInr(p.priceInr), style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.primary)),
                                OutlinedButton(onPressed: () {}, child: const Text('Preview')),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}
