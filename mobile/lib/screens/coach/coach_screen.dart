import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/theme.dart';
import '../../services/api_service.dart';
import '../../services/subscription_service.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import '../../widgets/animated_mesh_background.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../paywall/paywall_screen.dart';
import '../../widgets/ai_outage_dialog.dart';

class CoachScreen extends StatefulWidget {
  const CoachScreen({super.key});

  @override
  State<CoachScreen> createState() => _CoachScreenState();
}

class _CoachScreenState extends State<CoachScreen> {
  final _api = ApiService();
  final _controller = TextEditingController();
  final _messages = <_Msg>[];
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _loadMessages();
  }

  Future<void> _loadMessages() async {
    setState(() => _loading = true);
    final prefs = await SharedPreferences.getInstance();
    try {
      final session = Supabase.instance.client.auth.currentSession;
      if (session == null) return;
      final data = await Supabase.instance.client
          .from('ai_chat_messages')
          .select()
          .eq('user_id', session.user.id)
          .order('created_at', ascending: true);
      
      final msgs = (data as List).map((row) => _Msg(row['role'] == 'user', row['content'])).toList();
      if (mounted) setState(() {
        _messages.clear();
        _messages.addAll(msgs);
      });
      await prefs.setString('cached_chat_messages', jsonEncode(_messages.map((m) => m.toJson()).toList()));
    } catch (e) {
      debugPrint(e.toString());
      final cached = prefs.getString('cached_chat_messages');
      if (cached != null) {
        final List<dynamic> decoded = jsonDecode(cached);
        if (mounted) setState(() {
          _messages.clear();
          _messages.addAll(decoded.map((d) => _Msg(d['role'] == 'user', d['content'])).toList());
        });
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _send() async {
    final text = _controller.text.trim();
    if (text.isEmpty || _loading) return;

    // Check message limit (Free users get 15 messages total)
    final userMessageCount = _messages.where((m) => m.isUser).length;
    if (!SubscriptionService.isPremium && userMessageCount >= 15) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const PaywallScreen()),
      );
      return;
    }

    setState(() {
      _messages.add(_Msg(true, text));
      _controller.clear();
      _loading = true;
    });
    
    final session = Supabase.instance.client.auth.currentSession;
    try {
      final reply = await _api.chatWithCoach(text);
      
      if (mounted) setState(() => _messages.add(_Msg(false, reply)));
      
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('cached_chat_messages', jsonEncode(_messages.map((m) => m.toJson()).toList()));
    } catch (e) {
      if (mounted) {
        showDialog(
          context: context,
          builder: (context) => const AiOutageDialog(),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('AI Coach'), backgroundColor: Colors.transparent),
      extendBodyBehindAppBar: true,
      body: AnimatedMeshBackground(
        child: Column(
          children: [
            Expanded(
            child: _messages.isEmpty
                ? const Center(child: Text('Ask anything about fitness & nutrition', style: TextStyle(color: AppColors.textSecondary)))
                : ListView.builder(
                    reverse: true,
                    padding: const EdgeInsets.only(left: 16, right: 16, bottom: 16, top: kToolbarHeight + 16),
                    itemCount: _messages.length,
                    itemBuilder: (_, i) {
                      final m = _messages[_messages.length - 1 - i];
                      return Align(
                        alignment: m.isUser ? Alignment.centerRight : Alignment.centerLeft,
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.8),
                          decoration: BoxDecoration(
                            color: m.isUser ? AppColors.primaryLight : AppColors.surface,
                            borderRadius: BorderRadius.only(
                              topLeft: const Radius.circular(20),
                              topRight: const Radius.circular(20),
                              bottomLeft: Radius.circular(m.isUser ? 20 : 4),
                              bottomRight: Radius.circular(m.isUser ? 4 : 20),
                            ),
                            border: m.isUser ? null : Border.all(color: AppColors.border),
                            boxShadow: [
                              if (!m.isUser) BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 8, offset: const Offset(0, 4)),
                            ],
                          ),
                          child: MarkdownBody(
                            data: m.text,
                            styleSheet: MarkdownStyleSheet(
                              p: const TextStyle(color: AppColors.textHeader, fontSize: 15, height: 1.4),
                              listBullet: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold),
                              strong: const TextStyle(color: AppColors.textHeader, fontWeight: FontWeight.w700),
                              h1: const TextStyle(color: AppColors.textHeader, fontWeight: FontWeight.bold),
                              h2: const TextStyle(color: AppColors.textHeader, fontWeight: FontWeight.bold),
                              h3: const TextStyle(color: AppColors.textHeader, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ).animate(key: ValueKey(m.text)).fadeIn(duration: 400.ms).slideY(begin: 0.1, curve: Curves.easeOut),
                      );
                    },
                  ),
          ),
          if (_loading) 
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text('Coach is typing...', style: TextStyle(color: AppColors.textSecondary, fontStyle: FontStyle.italic)),
              ),
            ),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                _QuickChip(label: 'Swap an exercise', icon: Icons.swap_horiz, onTap: () => _sendQuick('I need to swap an exercise in my workout.')),
                _QuickChip(label: 'What is my next meal?', icon: Icons.restaurant, onTap: () => _sendQuick('Based on my meal plan, what should I eat next?')),
                _QuickChip(label: 'I feel too sore', icon: Icons.healing, onTap: () => _sendQuick('I feel too sore to train today, what should I do?')),
              ],
            ),
          ),
          if (!SubscriptionService.isPremium)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Align(
                alignment: Alignment.centerRight,
                child: Text('${(15 - _messages.where((m) => m.isUser).length).clamp(0, 15)} free messages left', style: const TextStyle(color: AppColors.primary, fontSize: 12, fontWeight: FontWeight.bold)),
              ),
            ),
          Padding(
            padding: EdgeInsets.fromLTRB(16, 8, 16, MediaQuery.of(context).viewInsets.bottom > 0 ? 12 : 110),
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(30),
                      border: Border.all(color: AppColors.border),
                      boxShadow: [
                        BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 4)),
                      ],
                    ),
                    child: TextField(
                      controller: _controller,
                      decoration: const InputDecoration(
                        hintText: 'Ask your coach...',
                        hintStyle: TextStyle(color: AppColors.textSecondary),
                        prefixIcon: Icon(Icons.auto_awesome, color: AppColors.primary),
                        border: InputBorder.none,
                        enabledBorder: InputBorder.none,
                        focusedBorder: InputBorder.none,
                        filled: false,
                        contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                      ),
                      onSubmitted: (_) => _send(),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: _send,
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: const BoxDecoration(
                      color: AppColors.primary,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.arrow_upward, color: Colors.white),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      ),
    );
  }

  void _sendQuick(String text) {
    _controller.text = text;
    _send();
  }
}

class _Msg {
  final bool isUser;
  final String text;
  _Msg(this.isUser, this.text);
  Map<String, dynamic> toJson() => {'role': isUser ? 'user' : 'coach', 'content': text};
}

class _QuickChip extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  final IconData? icon;
  
  const _QuickChip({required this.label, required this.onTap, this.icon});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 8.0),
      child: ActionChip(
        avatar: icon != null ? Icon(icon, color: AppColors.primary, size: 16) : null,
        label: Text(label, style: const TextStyle(fontSize: 13, color: AppColors.primary, fontWeight: FontWeight.w600)),
        onPressed: onTap,
        backgroundColor: AppColors.surface,
        side: const BorderSide(color: AppColors.primaryLight, width: 1.5),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
    );
  }
}
