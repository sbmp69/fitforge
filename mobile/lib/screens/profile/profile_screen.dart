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
import '../../services/ad_service.dart';

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
    AdService.suppressAds = true;
    _load();
  }

  @override
  void dispose() {
    AdService.suppressAds = false;
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
        backgroundColor: AppColors.navy800,
        title: const Text('Delete Account', style: TextStyle(color: Colors.white)),
        content: const Text('Are you sure you want to permanently delete your account and all associated data? This action cannot be undone.', style: TextStyle(color: AppColors.slate400)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel', style: TextStyle(color: Colors.white)),
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

  Future<void> _showEditProfileDialog(BuildContext context) async {
    if (_profile == null) return;
    final nameCtrl = TextEditingController(text: _profile!.fullName);
    final goalCtrl = TextEditingController(text: _profile!.primaryGoal);
    final levelCtrl = TextEditingController(text: _profile!.fitnessLevel);
    String country = _profile!.country ?? 'India';
    if (!AppConstants.allCountries.contains(country)) country = AppConstants.allCountries.first;
    String meal = _profile!.mealPreference ?? 'Indian';
    if (!AppConstants.popularCuisines.contains(meal)) meal = AppConstants.popularCuisines.first;
    double heightCm = (_profile!.heightCm ?? 175).toDouble();
    double weightKg = _profile!.weightKg ?? 70.0;
    DateTime? dateOfBirth = _profile!.dateOfBirth;
    String gender = _profile!.gender ?? 'Male';
    bool saving = false;

    List<String> goals = ['Weight Loss', 'Muscle Gain', 'Endurance', 'General Fitness'];
    if (goalCtrl.text.isNotEmpty && !goals.contains(goalCtrl.text)) goals.add(goalCtrl.text);
    List<String> levels = ['Beginner', 'Intermediate', 'Advanced'];
    if (levelCtrl.text.isNotEmpty && !levels.contains(levelCtrl.text)) levels.add(levelCtrl.text);

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useRootNavigator: true,
      backgroundColor: AppColors.navy800,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) {
          return Padding(
            padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom + 24, left: 24, right: 24, top: 24),
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
                const SizedBox(height: 16),
                Text('Height: ${heightCm.round()} cm', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
                Slider(
                  value: heightCm,
                  min: 140,
                  max: 220,
                  divisions: 80,
                  onChanged: (v) => setModalState(() => heightCm = v),
                ),
                const SizedBox(height: 16),
                Text('Weight: ${weightKg.toStringAsFixed(1)} kg', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
                Slider(
                  value: weightKg,
                  min: 40,
                  max: 150,
                  divisions: 220,
                  onChanged: (v) => setModalState(() => weightKg = v),
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: country,
                  isExpanded: true,
                  decoration: const InputDecoration(labelText: 'Country'),
                  items: AppConstants.allCountries.map((e) => DropdownMenuItem(value: e, child: Text(e, overflow: TextOverflow.ellipsis))).toList(),
                  onChanged: (v) => setModalState(() => country = v!),
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: meal,
                  isExpanded: true,
                  decoration: const InputDecoration(labelText: 'Meal Preference / Cuisine'),
                  items: AppConstants.popularCuisines.map((e) => DropdownMenuItem(value: e, child: Text(e, overflow: TextOverflow.ellipsis))).toList(),
                  onChanged: (v) => setModalState(() => meal = v!),
                ),
                const SizedBox(height: 16),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Date of Birth', style: TextStyle(color: Colors.white, fontSize: 16)),
                  subtitle: Text(
                    dateOfBirth == null ? 'Select your birthday' : '${dateOfBirth!.year}-${dateOfBirth!.month.toString().padLeft(2, '0')}-${dateOfBirth!.day.toString().padLeft(2, '0')}',
                    style: TextStyle(color: dateOfBirth == null ? AppColors.slate400 : AppColors.primary),
                  ),
                  trailing: const Icon(Icons.calendar_today, color: AppColors.slate400),
                  onTap: () async {
                    final date = await showDatePicker(
                      context: context,
                      initialDate: dateOfBirth ?? DateTime(2000, 1, 1),
                      firstDate: DateTime(1920),
                      lastDate: DateTime.now(),
                    );
                    if (date != null) setModalState(() => dateOfBirth = date);
                  },
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: gender,
                  isExpanded: true,
                  decoration: const InputDecoration(labelText: 'Gender'),
                  items: ['Male', 'Female', 'Other'].map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
                  onChanged: (v) => setModalState(() => gender = v!),
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
                        country: country,
                        mealPreference: meal,
                        heightCm: heightCm.round(),
                        weightKg: weightKg,
                        dateOfBirth: dateOfBirth,
                        gender: gender,
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
        actions: [
          IconButton(
            icon: const Icon(Icons.edit, color: AppColors.primary),
            onPressed: () => _showEditProfileDialog(context),
          ),
        ],
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
                _PlanRow(name: 'Free', price: '${cur}0', current: tier == 'Free'),
                _PlanRow(name: 'Pro (Monthly)', price: '$cur$proPrice/mo', current: tier == 'PRO'),
                _PlanRow(name: 'Pro (Yearly)', price: '$cur$proYearlyPrice/yr', current: false),
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
                  title: const Text('Daily Reminders', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  subtitle: const Text('Get fun, personalized motivation!', style: TextStyle(color: AppColors.slate400, fontSize: 12)),
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
