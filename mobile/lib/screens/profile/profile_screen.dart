import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/constants.dart';
import '../../core/theme.dart';
import '../../models/profile.dart';
import '../../services/subscription_service.dart';
import '../../services/supabase_service.dart';
import '../../services/notification_service.dart';
import '../../widgets/app_card.dart';
import '../paywall/paywall_screen.dart';


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

  @override
  void dispose() {

    super.dispose();
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

  Future<void> _deleteAccount() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Text('Delete Account', style: TextStyle(color: AppColors.textHeader)),
        content: const Text('Are you sure you want to permanently delete your account and all associated data? This action cannot be undone.', style: TextStyle(color: AppColors.textSecondary)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel', style: TextStyle(color: AppColors.textHeader)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete', style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      if (!mounted) return;
      showDialog(
        context: context, 
        barrierDismissible: false,
        builder: (ctx) => const Center(child: CircularProgressIndicator(color: AppColors.primary)),
      );
      try {
        await _supabase.deleteAccount();
        if (!mounted) return;
        Navigator.pop(context); // close progress dialog
        context.go('/login');
      } catch (e) {
        if (!mounted) return;
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error deleting account: $e')));
      }
    }
  }

  Future<void> _showEditNameDialog(BuildContext context) async {
    if (_profile == null) return;
    final nameCtrl = TextEditingController(text: _profile!.fullName);
    bool saving = false;

    await showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text('Edit Name', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.textHeader)),
          content: TextField(
            controller: nameCtrl,
            autofocus: true,
            decoration: const InputDecoration(labelText: 'Full Name', hintText: 'Enter your name'),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel', style: TextStyle(color: AppColors.textSecondary)),
            ),
            ElevatedButton(
              onPressed: saving ? null : () async {
                final newName = nameCtrl.text.trim();
                if (newName.isEmpty) return;
                setDialogState(() => saving = true);
                try {
                  await Supabase.instance.client.from('profiles').update({'full_name': newName}).eq('id', _profile!.id);
                  await _load();
                  if (context.mounted) Navigator.pop(context);
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
                    setDialogState(() => saving = false);
                  }
                }
              },
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
              child: saving
                  ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Text('Save', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }
  void _scheduleDynamicNotifications() async {
    await NotificationService().requestPermissions();
    for (int i = 1; i <= 21; i++) {
      await NotificationService().cancel(i); // clear old 21 notifs
    }

    final isIndia = _profile?.country == 'India' || _profile?.country == null;
    
    final indiaMornings = [
      {'title': 'Uth jaa champ! ☀️', 'body': 'Subah ho gayi hai! Aaj ka workout miss nahi karna hai.'},
      {'title': 'Morning motivation! 🚀', 'body': 'Bistar chhod aur gym bhaag! Gains tera wait kar rahe hain.'},
      {'title': 'Gym nahi jayega bhai? 🏋️‍♂️', 'body': 'Aaj leg day hai, skip mat karna! Chal uth jaa.'},
      {'title': 'Good morning fitness freak! ☕', 'body': 'Pre-workout pi le aur workout shuru kar.'},
      {'title': 'So raha hai kya? 😴', 'body': 'Uth jaa aur thoda paseena baha le! Summer body banani hai!'},
      {'title': 'Aaj ka din tera hai! 💥', 'body': 'Uth aur apne goals ko crush kar de aaj.'},
      {'title': 'Aalas chhod dost! 🥱', 'body': '20 min ka workout bhi tujhe aage le jayega.'},
      {'title': 'Wake up and work out! 🔥', 'body': 'Kal jis body ki tu baat kar raha tha, wo aaj banani hai.'},
    ];

    final indiaLunches = [
      {'title': 'Bhook lagi hai kya? 🍎', 'body': 'Junk food mat khana! Apne AI coach se diet pooch le.'},
      {'title': 'Lunch time boss! 🍛', 'body': 'Protein aur veggies yaad rakhna! Calorie goal hit kar.'},
      {'title': 'Bahar ka khana cancel! 🍔🚫', 'body': 'Ghar ka khana kha aur macros track kar.'},
      {'title': 'Cheat day nahi hai aaj! 🍕', 'body': 'Focus bhai focus! Apne diet plan ko strictly follow kar.'},
      {'title': 'Paani piya kya? 💧', 'body': 'Hydration is key! 3 litre ka goal poora karna hai aaj.'},
      {'title': 'Snack time? 🥜', 'body': 'Healthy snack liyo, chips nahi!'},
      {'title': 'Protein shake piya? 🥤', 'body': 'Muscle recovery ke liye protein zaroori hai.'},
      {'title': 'Diet on track? 🥗', 'body': 'Bina diet ke gym bekaar hai. Sahi kha bhai!'},
    ];

    final indiaNights = [
      {'title': 'Aaj ka progress log kiya? 🌙', 'body': 'Sone se pehle apne stats aur workout app me daal de!'},
      {'title': 'Kya haal hai champ? 🏆', 'body': 'Consistency is the key, dost! Check-in karna mat bhoolna.'},
      {'title': 'Din kaisa raha? 🌟', 'body': 'Apne AI coach ko bata aaj ka din kaisa tha aur water track kar.'},
      {'title': 'Thak gaya kya? 💪', 'body': 'No pain, no gain! Tera daily log wait kar raha hai.'},
      {'title': 'Sone ka time! 🛏️', 'body': 'Recovery utni hi zaroori hai. Progress log karke 8 ghante so jaa.'},
      {'title': 'Streak tootni nahi chahiye! 🔥', 'body': 'Jaldi app khol aur aaj ka progress update kar de!'},
      {'title': 'Kal ki taiyaari! 📅', 'body': 'Kal ke workout aur meals app me check kar le soney se pehle.'},
      {'title': 'Good job today! 👏', 'body': 'Aise hi mehnat karta reh! Ab jaake progress log kar de.'},
    ];

    final globalMornings = [
      {'title': 'Rise and grind! ☀️', 'body': 'Time to wake up and hit the gym. Let\'s get those gains!'},
      {'title': 'Morning motivation! 🚀', 'body': 'Your muscles are hungry. Time to put in the work!'},
      {'title': 'Ready to sweat? 💦', 'body': 'Your AI coach has a killer routine waiting for you.'},
      {'title': 'Don\'t skip it! 🚫', 'body': 'The only bad workout is the one that didn\'t happen. Wake up!'},
      {'title': 'Let\'s get moving! 🏃‍♂️', 'body': 'Start your day with a win. Get your workout done now!'},
      {'title': 'Missing the gym today? 🥺', 'body': 'Don\'t break your streak! Even a 20-minute home workout counts.'},
      {'title': 'Time to crush it! 💪', 'body': 'Grab your gear and let\'s make it happen!'},
    ];

    final globalLunches = [
      {'title': 'Lunch time! 🥗', 'body': 'Remember your macros. Feed your body what it needs!'},
      {'title': 'Feeling hungry? 🍎', 'body': 'Skip the junk. Ask your AI coach for a healthy snack idea.'},
      {'title': 'Hydration check! 💧', 'body': 'Have you drank enough water today? Go grab a glass right now.'},
      {'title': 'Stay on track! 🎯', 'body': 'Consistency is everything. Stick to your AI meal plan today!'},
      {'title': 'Protein time! 🥩', 'body': 'Make sure you are hitting your protein goals for optimal recovery.'},
      {'title': 'Mid-day check-in! ⚡', 'body': 'How are you feeling? Keep your energy up with a healthy snack.'},
      {'title': 'Don\'t ruin your progress! 🍔🚫', 'body': 'Say no to the fast food. Stick to the plan!'},
    ];

    final globalNights = [
      {'title': 'Log your progress! 🌙', 'body': 'Before you sleep, don\'t forget to update your stats in the app.'},
      {'title': 'How was today? 🌟', 'body': 'Consistency is everything. Show up for yourself and log your day!'},
      {'title': 'Time to recover! 🛏️', 'body': 'Sleep is when the gains happen. Log your day and get some rest.'},
      {'title': 'Don\'t break your streak! 🔥', 'body': 'Keep the fire alive. Log your workout before midnight!'},
      {'title': 'Plan for tomorrow! 📅', 'body': 'Check your AI meal and workout plan for tomorrow so you\'re ready.'},
      {'title': 'Great work today! 👏', 'body': 'You crushed it. Log your progress and give yourself a pat on the back.'},
      {'title': 'End the day right! 💯', 'body': 'Track your water, sleep, and workouts. Your AI coach is waiting.'},
    ];

    var mornings = isIndia ? indiaMornings : globalMornings;
    var lunches = isIndia ? indiaLunches : globalLunches;
    var nights = isIndia ? indiaNights : globalNights;
    
    mornings.shuffle();
    lunches.shuffle();
    nights.shuffle();

    int idCounter = 1;
    for (int day = 1; day <= 7; day++) { // 1 = Monday, 7 = Sunday
      // Morning (8:00 AM)
      await NotificationService().scheduleWeeklyReminder(
        id: idCounter++,
        title: mornings[day % mornings.length]['title']!,
        body: mornings[day % mornings.length]['body']!,
        dayOfWeek: day, hour: 8, minute: 0,
      );
      // Lunch (1:00 PM)
      await NotificationService().scheduleWeeklyReminder(
        id: idCounter++,
        title: lunches[day % lunches.length]['title']!,
        body: lunches[day % lunches.length]['body']!,
        dayOfWeek: day, hour: 13, minute: 0,
      );
      // Night (8:00 PM)
      await NotificationService().scheduleWeeklyReminder(
        id: idCounter++,
        title: nights[day % nights.length]['title']!,
        body: nights[day % nights.length]['body']!,
        dayOfWeek: day, hour: 20, minute: 0,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final tier = SubscriptionService.isPremium ? 'PRO' : (AppConstants.tierLabels[_profile?.subscriptionTier] ?? 'Free');
    final country = _profile?.country ?? 'India';
    
    String cur = '₹';
    String proPrice = '299';
    String proYearlyPrice = '2999';

    if (country == 'United States') { cur = '\$'; proPrice = '3.99'; proYearlyPrice = '39.99'; }
    else if (country == 'United Kingdom') { cur = '£'; proPrice = '3.50'; proYearlyPrice = '34.99'; }
    else if (country == 'Europe') { cur = '€'; proPrice = '3.99'; proYearlyPrice = '39.99'; }
    else if (country == 'Australia') { cur = 'A\$'; proPrice = '5.99'; proYearlyPrice = '59.99'; }
    else if (country != 'India') { cur = '\$'; proPrice = '3.99'; proYearlyPrice = '39.99'; }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 140),
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
                      Row(
                        children: [
                          Expanded(
                            child: Text(_profile?.fullName ?? 'User', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.textHeader), overflow: TextOverflow.ellipsis),
                          ),
                          InkWell(
                            onTap: () => _showEditNameDialog(context),
                            borderRadius: BorderRadius.circular(20),
                            child: const Padding(
                              padding: EdgeInsets.all(4),
                              child: Icon(Icons.edit, size: 18, color: AppColors.primary),
                            ),
                          ),
                        ],
                      ),
                      Text(_profile?.email ?? '', style: const TextStyle(color: AppColors.textSecondary)),
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
                Row(
                  children: [
                    const Icon(Icons.analytics_outlined, color: AppColors.primary),
                    const SizedBox(width: 8),
                    const Text('Your Fitness Profile', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.textHeader)),
                    const Spacer(),
                    TextButton.icon(
                      onPressed: () => context.go('/onboarding'),
                      icon: const Icon(Icons.tune, size: 16, color: AppColors.primary),
                      label: const Text('Edit Assessment', style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold, fontSize: 13)),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(color: AppColors.primaryLight, borderRadius: BorderRadius.circular(12)),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Height', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                            const SizedBox(height: 4),
                            Text('${_profile?.heightCm ?? 175} cm', style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.textHeader, fontSize: 15)),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(color: AppColors.primaryLight, borderRadius: BorderRadius.circular(12)),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Weight', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                            const SizedBox(height: 4),
                            Text('${_profile?.weightKg?.toStringAsFixed(1) ?? "70.0"} kg', style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.textHeader, fontSize: 15)),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(color: AppColors.primaryLight, borderRadius: BorderRadius.circular(12)),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Target', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                            const SizedBox(height: 4),
                            Text('${_profile?.targetWeightKg?.toStringAsFixed(1) ?? _profile?.weightKg?.toStringAsFixed(1) ?? "65.0"} kg', style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.textHeader, fontSize: 15)),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(color: AppColors.background, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.border)),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.fitness_center, size: 16, color: AppColors.primary),
                          const SizedBox(width: 8),
                          Text('Goal: ${AppConstants.goalLabels[_profile?.primaryGoal] ?? _profile?.primaryGoal ?? "Build Muscle"}', style: const TextStyle(fontSize: 13, color: AppColors.textHeader, fontWeight: FontWeight.w600)),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          const Icon(Icons.restaurant, size: 16, color: AppColors.primary),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text('Cuisine: ${_profile?.mealPreference ?? "Traditional Indian"}', style: const TextStyle(fontSize: 13, color: AppColors.textHeader, fontWeight: FontWeight.w600), overflow: TextOverflow.ellipsis),
                          ),
                        ],
                      ),
                      if (_profile?.targetFocusAreas.isNotEmpty == true) ...[
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            const Icon(Icons.track_changes, size: 16, color: AppColors.primary),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text('Focus: ${_profile!.targetFocusAreas.join(', ')}', style: const TextStyle(fontSize: 13, color: AppColors.textHeader, fontWeight: FontWeight.w600), overflow: TextOverflow.ellipsis),
                            ),
                          ],
                        ),
                      ],
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
                const Text('Subscription', style: TextStyle(fontWeight: FontWeight.w600, color: AppColors.textHeader)),
                const SizedBox(height: 8),
                _PlanRow(name: 'Free', price: '', current: tier == 'Free'),
                _PlanRow(name: 'Pro', price: '', current: tier == 'PRO'),
                _PlanRow(name: 'Pro+', price: '', current: false),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const PaywallScreen())),
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 48),
                  ),
                  child: Text(tier == 'Free' ? 'Upgrade to PRO ⚡' : 'Change Plan ⚡', style: const TextStyle(fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          AppCard(
            child: Column(
              children: [
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Daily Reminders', style: TextStyle(color: AppColors.textHeader, fontWeight: FontWeight.bold)),
                  subtitle: const Text('Get fun, personalized motivation!', style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                  value: _notificationsEnabled,
                  onChanged: (val) async {
                    setState(() => _notificationsEnabled = val);
                    final prefs = await SharedPreferences.getInstance();
                    await prefs.setBool('notifications_enabled', val);
                    if (val) {
                      _scheduleDynamicNotifications();
                      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Reminders scheduled!')));
                    } else {
                      for (int i = 1; i <= 21; i++) {
                        await NotificationService().cancel(i);
                      }
                    }
                  },
                  activeColor: AppColors.primary,
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          ListTile(
            leading: const Icon(Icons.chat_bubble_outline, color: AppColors.primary),
            title: const Text('AI Coach'),
            onTap: () => context.go('/coach'),
          ),
          ListTile(
            leading: const Icon(Icons.logout, color: Colors.redAccent),
            title: const Text('Log out', style: TextStyle(color: Colors.redAccent)),
            onTap: _logout,
          ),
          ListTile(
            leading: const Icon(Icons.delete_forever, color: Colors.redAccent),
            title: const Text('Delete Account', style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold)),
            onTap: _deleteAccount,
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
          Expanded(child: Text(name, style: const TextStyle(color: AppColors.textHeader))),
          Text(price, style: const TextStyle(color: AppColors.textSecondary)),
          if (current) ...[
            const SizedBox(width: 8),
            const Icon(Icons.check_circle, color: AppColors.primary, size: 18),
          ],
        ],
      ),
    );
  }
}
