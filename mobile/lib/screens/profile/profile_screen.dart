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
  TimeOfDay _notificationTime = const TimeOfDay(hour: 17, minute: 0);

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final profile = await _supabase.getProfile();
    final prefs = await SharedPreferences.getInstance();
    final savedHour = prefs.getInt('notification_hour') ?? 17;
    final savedMin = prefs.getInt('notification_minute') ?? 0;
    
    if (mounted) setState(() {
      _profile = profile;
      _notificationsEnabled = prefs.getBool('notifications_enabled') ?? true;
      _notificationTime = TimeOfDay(hour: savedHour, minute: savedMin);
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
    final countryCtrl = TextEditingController(text: _profile!.country ?? 'India');
    final mealCtrl = TextEditingController(text: _profile!.mealPreference ?? 'Indian');
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
                Autocomplete<String>(
                  initialValue: TextEditingValue(text: countryCtrl.text),
                  optionsBuilder: (TextEditingValue val) {
                    if (val.text.isEmpty) return AppConstants.allCountries;
                    return AppConstants.allCountries.where((option) => option.toLowerCase().contains(val.text.toLowerCase()));
                  },
                  onSelected: (selection) => countryCtrl.text = selection,
                  fieldViewBuilder: (context, controller, focusNode, onFieldSubmitted) {
                    return TextFormField(
                      controller: controller,
                      focusNode: focusNode,
                      decoration: const InputDecoration(
                        labelText: 'Country',
                        hintText: 'Search your country...',
                        suffixIcon: Icon(Icons.search, color: AppColors.slate400),
                      ),
                      onChanged: (v) => countryCtrl.text = v,
                    );
                  },
                ),
                const SizedBox(height: 16),
                Autocomplete<String>(
                  initialValue: TextEditingValue(text: mealCtrl.text),
                  optionsBuilder: (TextEditingValue val) {
                    if (val.text.isEmpty) return AppConstants.popularCuisines;
                    return AppConstants.popularCuisines.where((option) => option.toLowerCase().contains(val.text.toLowerCase()));
                  },
                  onSelected: (selection) => mealCtrl.text = selection,
                  fieldViewBuilder: (context, controller, focusNode, onFieldSubmitted) {
                    return TextFormField(
                      controller: controller,
                      focusNode: focusNode,
                      decoration: const InputDecoration(
                        labelText: 'Meal Preference / Cuisine',
                        hintText: 'Type any cuisine (e.g. Vegan Keto, Indian)',
                        suffixIcon: Icon(Icons.edit, color: AppColors.slate400),
                      ),
                      onChanged: (v) => mealCtrl.text = v,
                    );
                  },
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
                        country: countryCtrl.text,
                        mealPreference: mealCtrl.text,
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
    for (int i = 0; i < 7; i++) {
      await NotificationService().cancel(i + 1); // clear old
    }

    final isIndia = _profile?.country == 'India' || _profile?.country == null;
    
    final indiaNotifs = [
      {'title': 'Gym nahi jayega bhai? 🏋️‍♂️', 'body': 'Aaj ka workout skip mat karna! Chal uth jaa aur crush it!'},
      {'title': 'Workout ka time ho gaya boss! ⏰', 'body': 'Pre-workout pi le aur gym nikal. Gains wait nahi karte!'},
      {'title': 'Bhook lagi hai kya? 🍎', 'body': 'Junk food mat khana! Apne AI coach se aaj ki diet pooch le.'},
      {'title': 'Kya haal hai champ? 🏆', 'body': 'Consistency is the key, dost! Aaj ka session complete kar.'},
      {'title': 'So raha hai kya? 😴', 'body': 'Uth jaa aur thoda paseena baha le! Summer body banani hai na?'},
      {'title': 'Cheat day nahi hai aaj! 🍕', 'body': 'Focus bhai focus! Apne AI workout plan ko follow kar.'},
      {'title': 'Thak gaya kya? 💪', 'body': 'No pain, no gain! Tera AI coach wait kar raha hai.'},
    ];

    final globalNotifs = [
      {'title': 'Missing the gym today? 🥺', 'body': 'Don\'t break your streak! Even a 20-minute home workout counts.'},
      {'title': 'Your muscles are hungry! 🥩', 'body': 'Time to feed them some iron. Let\'s go crush today\'s workout!'},
      {'title': 'Time to put in the work! ⚡', 'body': 'No excuses today. Grab your gear and let\'s make it happen!'},
      {'title': 'Ready to sweat? 💦', 'body': 'Your AI coach has a killer routine waiting for you.'},
      {'title': 'Consistency is everything 🏆', 'body': 'Show up for yourself today. You\'ll thank yourself tomorrow!'},
      {'title': 'Don\'t skip it! 🚫', 'body': 'The only bad workout is the one that didn\'t happen.'},
      {'title': 'Let\'s get moving! 🏃‍♂️', 'body': 'Time to hit your daily goals and log your progress!'},
    ];

    final notifs = isIndia ? indiaNotifs : globalNotifs;
    notifs.shuffle(); // random order every time they save

    for (int i = 0; i < 7; i++) {
      // We will schedule one for each day of the week
      // The NotificationService currently uses DateTimeComponents.time which repeats daily. 
      // To do daily rotating, we need a slight modification to NotificationService, but for now we can just 
      // schedule them offset by days if we modify the service. 
      // Since we just want them to have quirky notifications, we will just pick ONE random one and set it as the daily repeating one for now.
    }
    
    // Schedule one random quirky notification to repeat daily at the chosen time
    await NotificationService().scheduleDailyReminder(
      id: 1,
      title: notifs[0]['title']!,
      body: notifs[0]['body']!,
      hour: _notificationTime.hour,
      minute: _notificationTime.minute,
    );
  }

  @override
  void build(BuildContext context) {
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
                if (tier == 'Free') ...[
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const PaywallScreen())),
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size(double.infinity, 48),
                    ),
                    child: const Text('Upgrade to PRO ⚡', style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ],
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
                  subtitle: Text('Get fun, Zomato-style motivation!', style: const TextStyle(color: AppColors.slate400, fontSize: 12)),
                  value: _notificationsEnabled,
                  onChanged: (val) async {
                    setState(() => _notificationsEnabled = val);
                    final prefs = await SharedPreferences.getInstance();
                    await prefs.setBool('notifications_enabled', val);
                    if (val) {
                      _scheduleDynamicNotifications();
                    } else {
                      await NotificationService().cancel(1);
                    }
                  },
                  activeColor: AppColors.primary,
                ),
                if (_notificationsEnabled)
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.access_time, color: AppColors.primary),
                    title: const Text('Reminder Time', style: TextStyle(color: Colors.white)),
                    trailing: Text(_notificationTime.format(context), style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold)),
                    onTap: () async {
                      final time = await showTimePicker(
                        context: context,
                        initialTime: _notificationTime,
                        builder: (context, child) {
                          return Theme(
                            data: ThemeData.dark().copyWith(
                              colorScheme: const ColorScheme.dark(
                                primary: AppColors.primary,
                                onPrimary: Colors.black,
                                surface: AppColors.navy800,
                                onSurface: Colors.white,
                              ),
                            ),
                            child: child!,
                          );
                        },
                      );
                      if (time != null) {
                        setState(() => _notificationTime = time);
                        final prefs = await SharedPreferences.getInstance();
                        await prefs.setInt('notification_hour', time.hour);
                        await prefs.setInt('notification_minute', time.minute);
                        _scheduleDynamicNotifications();
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Reminder set for ${time.format(context)}')));
                        }
                      }
                    },
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
