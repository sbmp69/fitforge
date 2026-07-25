import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'package:flutter_timezone/flutter_timezone.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _plugin = FlutterLocalNotificationsPlugin();
  bool _initialized = false;

  Future<void> init() async {
    if (_initialized || kIsWeb) return;

    tz.initializeTimeZones();
    if (!kIsWeb) {
      try {
        final currentTimeZoneInfo = await FlutterTimezone.getLocalTimezone();
        tz.setLocalLocation(tz.getLocation(currentTimeZoneInfo.identifier));
      } catch (e) {
        debugPrint('Timezone error: $e');
      }
    }

    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );
    
    const initSettings = InitializationSettings(android: androidSettings, iOS: iosSettings);

    await _plugin.initialize(settings: initSettings);
    _initialized = true;
  }

  Future<void> requestPermissions() async {
    if (kIsWeb) return;
    await _plugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()?.requestNotificationsPermission();
    await _plugin.resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>()?.requestPermissions(
      alert: true,
      badge: true,
      sound: true,
    );
  }

  Future<void> _scheduleZoned({
    required int id,
    required String title,
    required String body,
    required tz.TZDateTime scheduledDate,
    required DateTimeComponents match,
  }) async {
    const androidDetails = AndroidNotificationDetails(
      'daily_reminders',
      'Daily Reminders',
      channelDescription: 'Notifications for daily fitness tracking',
      importance: Importance.high,
      priority: Priority.high,
    );
    const iosDetails = DarwinNotificationDetails();
    const details = NotificationDetails(android: androidDetails, iOS: iosDetails);

    try {
      await _plugin.zonedSchedule(
        id: id,
        title: title,
        body: body,
        scheduledDate: scheduledDate,
        notificationDetails: details,
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        matchDateTimeComponents: match,
      );
    } catch (e) {
      print('Failed to schedule notification: $e');
    }
  }

  Future<void> scheduleDailyReminder({
    required int id,
    required String title,
    required String body,
    required int hour,
    required int minute,
  }) async {
    if (kIsWeb) return;
    
    final now = tz.TZDateTime.now(tz.local);
    var scheduledDate = tz.TZDateTime(tz.local, now.year, now.month, now.day, hour, minute);
    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }

    await _scheduleZoned(id: id, title: title, body: body, scheduledDate: scheduledDate, match: DateTimeComponents.time);
  }

  Future<void> scheduleWeeklyReminder({
    required int id,
    required String title,
    required String body,
    required int dayOfWeek, // 1 = Monday, 7 = Sunday
    required int hour,
    required int minute,
  }) async {
    if (kIsWeb) return;
    
    final now = tz.TZDateTime.now(tz.local);
    var scheduledDate = tz.TZDateTime(tz.local, now.year, now.month, now.day, hour, minute);
    
    // Adjust to the correct day of the week
    while (scheduledDate.weekday != dayOfWeek) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }
    
    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 7));
    }

    await _scheduleZoned(id: id, title: title, body: body, scheduledDate: scheduledDate, match: DateTimeComponents.dayOfWeekAndTime);
  }

  Future<void> cancel(int id) async {
    if (kIsWeb) return;
    await _plugin.cancel(id: id);
  }

  static const List<String> hinglishMessages = [
    "Uth jao! Morning workout ka time ho gaya hai 💪",
    "Aaj ka target complete kiya kya? Time to crush it bhai!",
    "Bina mehnat ke kuch nahi milta. Get moving! 🔥",
    "Pani piya aaj? Hydration is key! 💧",
    "Ek aur din, ek aur mauka. Let's do this! 🏋️‍♂️",
    "Excuses mat banao, gains banao! Get up! 🚀",
    "Thoda aur push kar! You are stronger than you think. 💯",
    "Aaj leg day hai kya? Skip mat karna! 🦵",
    "Mehnat itni shanti se karo ki safalta shor macha de! 🏆",
    "Rest zaroori hai, par aalas nahi. Let's train! 😤",
    "Khaana theek se kha raha hai na? Nutrition is 80%! 🥗",
    "Consistency hi secret hai. Gym jao chup chap! 🏃‍♂️",
    "Aaj ka sweat, kal ka strength! Pasina bahao! 💦",
    "Don't stop when you're tired, stop when you're done! 🛑",
    "Aise hi baithe rahoge toh fit kaise banoge? Utho! ⏰",
    "Dream body chahiye toh kaam bhi waisa karna padega! ✨",
    "Log progress notice karna shuru karenge, just wait! 👀",
    "Bhai thoda stretch kar le, recovery zaroori hai. 🧘‍♂️",
    "Sote reh gaye toh gains sapno mein hi milenge! 🛌",
    "Din bhar baithe the na? Ab thoda hil lo! 🕺",
    "Workout skip kiya toh kal double karna padega! ⚠️",
    "You are just one workout away from a good mood! 😊",
    "Tera competition tu khud hai. Be better today! 🥊",
    "Bas 30 minute ka workout... you can do it! ⏱️",
    "Apne fitness goals ke liye commit kar! No backing down! 🤝",
  ];

  static const List<String> englishMessages = [
    "Wake up! It's time for your morning workout 💪",
    "Have you hit today's target? Time to crush it!",
    "No pain, no gain. Get moving! 🔥",
    "Did you drink enough water today? Hydrate! 💧",
    "Another day, another opportunity. Let's do this! 🏋️‍♂️",
    "Stop making excuses and start making gains! 🚀",
    "Push a little harder! You are stronger than you think. 💯",
    "Is it leg day? Don't even think about skipping it! 🦵",
    "Train in silence, let success make the noise! 🏆",
    "Rest is important, but don't be lazy. Let's train! 😤",
    "Are you eating right? Nutrition is 80% of the game! 🥗",
    "Consistency is the secret. Just show up! 🏃‍♂️",
    "Today's sweat is tomorrow's strength! 💦",
    "Don't stop when you're tired, stop when you're done! 🛑",
    "You won't get fit just sitting there. Get up! ⏰",
    "Want that dream body? Put in the work! ✨",
    "People will start noticing your progress, just wait! 👀",
    "Take some time to stretch, recovery is crucial. 🧘‍♂️",
    "If you keep sleeping, your gains will only be dreams! 🛌",
    "Been sitting all day? Time to move! 🕺",
    "If you skip today, you'll have to work twice as hard tomorrow! ⚠️",
    "You are just one workout away from a good mood! 😊",
    "Your only competition is yourself. Be better today! 🥊",
    "Just a 30-minute workout... you can absolutely do it! ⏱️",
    "Commit to your fitness goals! No backing down! 🤝",
  ];

  Future<void> scheduleSmartCycling(String? country) async {
    if (kIsWeb) return;
    
    // First, cancel all previous notifications to prevent overlap
    await _plugin.cancelAll();

    final List<String> pool = List<String>.from((country?.toLowerCase() == 'india') ? hinglishMessages : englishMessages);
    pool.shuffle(); // Shuffle for randomness

    final now = tz.TZDateTime.now(tz.local);
    int notificationId = 100;
    
    // Schedule 3 notifications a day for 7 days
    int messageIndex = 0;
    
    for (int dayOffset = 0; dayOffset < 7; dayOffset++) {
      // Morning (9 AM), Afternoon (2 PM), Night (8 PM)
      final List<int> hours = [9, 14, 20];
      
      for (int hour in hours) {
        if (messageIndex >= pool.length) break; // Ensure we don't go out of bounds
        
        var scheduledDate = tz.TZDateTime(tz.local, now.year, now.month, now.day, hour, 0).add(Duration(days: dayOffset));
        
        // If the scheduled time for today has already passed, skip it (don't schedule in the past)
        if (scheduledDate.isAfter(now)) {
          await _scheduleZoned(
            id: notificationId++,
            title: 'FitForge',
            body: pool[messageIndex],
            scheduledDate: scheduledDate,
            match: DateTimeComponents.dateAndTime, // Fire exactly at this date and time
          );
        }
        messageIndex++;
      }
    }
  }
}
