import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants.dart';
import '../../core/theme.dart';
import '../../models/profile.dart';
import '../../services/supabase_service.dart';
import '../../widgets/app_card.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _supabase = SupabaseService();
  Profile? _profile;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final profile = await _supabase.getProfile();
    if (mounted) setState(() => _profile = profile);
  }

  Future<void> _logout() async {
    await _supabase.signOut();
    if (mounted) context.go('/login');
  }

  @override
  Widget build(BuildContext context) {
    final tier = AppConstants.tierLabels[_profile?.subscriptionTier] ?? 'Free';

    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          AppCard(
            child: Row(
              children: [
                CircleAvatar(
                  radius: 32,
                  backgroundColor: AppColors.primary.withValues(alpha: 0.2),
                  child: Text(
                    (_profile?.fullName?.isNotEmpty == true ? _profile!.fullName![0] : 'F').toUpperCase(),
                    style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppColors.primary),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(_profile?.fullName ?? 'User', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white)),
                      Text(_profile?.email ?? '', style: const TextStyle(color: AppColors.slate400)),
                      const SizedBox(height: 4),
                      Chip(label: Text(tier), backgroundColor: AppColors.primary.withValues(alpha: 0.15)),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Subscription', style: TextStyle(fontWeight: FontWeight.w600, color: Colors.white)),
                const SizedBox(height: 8),
                _PlanRow(name: 'Free', price: '₹0', current: tier == 'Free'),
                _PlanRow(name: 'Pro', price: '₹299/mo', current: tier == 'Pro'),
                _PlanRow(name: 'Trainer', price: '₹799/mo', current: tier == 'Trainer'),
              ],
            ),
          ),
          const SizedBox(height: 16),
          ListTile(
            leading: const Icon(Icons.chat_bubble_outline, color: AppColors.primary),
            title: const Text('AI Coach'),
            onTap: () => context.push('/coach'),
          ),
          ListTile(
            leading: const Icon(Icons.logout, color: Colors.redAccent),
            title: const Text('Log out', style: TextStyle(color: Colors.redAccent)),
            onTap: _logout,
          ),
        ],
      ),
    );
  }
}

class _PlanRow extends StatelessWidget {
  final String name;
  final String price;
  final bool current;

  const _PlanRow({required this.name, required this.price, required this.current});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Expanded(child: Text(name, style: const TextStyle(color: Colors.white))),
          Text(price, style: const TextStyle(color: AppColors.slate400)),
          if (current) ...[
            const SizedBox(width: 8),
            const Icon(Icons.check_circle, color: AppColors.primary, size: 18),
          ],
        ],
      ),
    );
  }
}
