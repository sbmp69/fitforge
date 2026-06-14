import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/constants.dart';
import '../../core/theme.dart';
import '../../models/profile.dart';
import '../../services/supabase_service.dart';
import '../../services/notification_service.dart';
import '../../widgets/app_card.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _supabase = SupabaseService();
  Profile? _profile;
  bool _notificationsEnabled = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final profile = await _supabase.getProfile();
    final prefs = await SharedPreferences.getInstance();
    if (mounted) setState(() {
      _profile = profile;
      _notificationsEnabled = prefs.getBool('notifications_enabled') ?? true;
    });
  }

  Future<void> _logout() async {
    await _supabase.signOut();
    if (mounted) context.go('/login');
  }

  Future<void> _showEditProfileDialog(BuildContext context) async {
    if (_profile == null) return;
    final nameCtrl = TextEditingController(text: _profile!.fullName);
    final goalCtrl = TextEditingController(text: _profile!.primaryGoal);
    final levelCtrl = TextEditingController(text: _profile!.fitnessLevel);
    bool saving = false;

    List<String> goals = ['Weight Loss', 'Muscle Gain', 'Endurance', 'General Fitness'];
    if (goalCtrl.text.isNotEmpty && !goals.contains(goalCtrl.text)) {
      goals.add(goalCtrl.text);
    }
    List<String> levels = ['Beginner', 'Intermediate', 'Advanced'];
    if (levelCtrl.text.isNotEmpty && !levels.contains(levelCtrl.text)) {
      levels.add(levelCtrl.text);
    }

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.navy800,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) {
          return Padding(
            padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom, left: 24, right: 24, top: 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text('Edit Profile', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white)),
                const SizedBox(height: 24),
                TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Full Name')),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: goalCtrl.text.isNotEmpty ? goalCtrl.text : goals.first,
                  decoration: const InputDecoration(labelText: 'Primary Goal'),
                  items: goals.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
                  onChanged: (val) => goalCtrl.text = val!,
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: levelCtrl.text.isNotEmpty ? levelCtrl.text : levels.first,
                  decoration: const InputDecoration(labelText: 'Fitness Level'),
                  items: levels.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
                  onChanged: (val) => levelCtrl.text = val!,
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: saving ? null : () async {
                    HapticFeedback.lightImpact();
                    setModalState(() => saving = true);
                    try {
                      await _supabase.updateProfileDetails(
                        fullName: nameCtrl.text.trim(),
                        goal: goalCtrl.text,
                        level: levelCtrl.text,
                      );
                      await _load();
                      if (context.mounted) Navigator.pop(context);
                    } catch (e) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
                        setModalState(() => saving = false);
                      }
                    }
                  },
                  child: saving
                      ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2))
                      : const Text('Save Changes'),
                ),
                const SizedBox(height: 32),
              ],
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final tier = AppConstants.tierLabels[_profile?.subscriptionTier] ?? 'Free';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit, color: AppColors.primary),
            onPressed: () => _showEditProfileDialog(context),
          ),
        ],
      ),
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
          SwitchListTile(
            title: const Text('Daily Reminders', style: TextStyle(color: Colors.white)),
            subtitle: const Text('Remind me to log progress at 5 PM', style: TextStyle(color: AppColors.slate400, fontSize: 12)),
            value: _notificationsEnabled,
            onChanged: (val) async {
              setState(() => _notificationsEnabled = val);
              final prefs = await SharedPreferences.getInstance();
              await prefs.setBool('notifications_enabled', val);
              if (val) {
                await NotificationService().requestPermissions();
                await NotificationService().scheduleDailyReminder(
                  id: 1, 
                  title: 'Time to crush it! 💪', 
                  body: 'Don\'t forget to complete your workout today and log your progress!', 
                  hour: 17, minute: 0,
                );
              } else {
                await NotificationService().cancel(1);
              }
            },
            activeColor: AppColors.primary,
          ),
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
