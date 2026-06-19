import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/theme.dart';
import '../../services/api_service.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import '../../widgets/animated_mesh_background.dart';
import 'package:flutter_animate/flutter_animate.dart';

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
    } catch (e) {
      debugPrint(e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _send() async {
    final text = _controller.text.trim();
    if (text.isEmpty || _loading) return;
    setState(() {
      _messages.add(_Msg(true, text));
      _controller.clear();
      _loading = true;
    });
    
    final session = Supabase.instance.client.auth.currentSession;
    try {
      final reply = await _api.chatWithCoach(text);
      
      if (mounted) setState(() => _messages.add(_Msg(false, reply)));
    } catch (e) {
      if (mounted) setState(() => _messages.add(_Msg(false, 'Sorry, try again.')));
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
            const SizedBox(height: kToolbarHeight), // padding for transparent appbar
            Expanded(
            child: _messages.isEmpty
                ? const Center(child: Text('Ask anything about fitness & nutrition', style: TextStyle(color: AppColors.slate400)))
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _messages.length,
                    itemBuilder: (_, i) {
                      final m = _messages[i];
                      return Align(
                        alignment: m.isUser ? Alignment.centerRight : Alignment.centerLeft,
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                          constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
                          decoration: BoxDecoration(
                            color: m.isUser ? AppColors.primary : AppColors.navy700,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: MarkdownBody(
                            data: m.text,
                            styleSheet: MarkdownStyleSheet(
                              p: const TextStyle(color: Colors.white),
                              listBullet: const TextStyle(color: Colors.white),
                              strong: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ).animate(key: ValueKey(m.text)).fadeIn(duration: 400.ms).slideY(begin: 0.2, curve: Curves.easeOut),
                      );
                    },
                  ),
          ),
          if (_loading) 
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text('Coach is typing...', style: TextStyle(color: AppColors.slate400, fontStyle: FontStyle.italic)),
              ),
            ),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Row(
              children: [
                _QuickChip(label: 'Swap an exercise', onTap: () => _sendQuick('I need to swap an exercise in my workout.')),
                _QuickChip(label: 'What is my next meal?', onTap: () => _sendQuick('Based on my meal plan, what should I eat next?')),
                _QuickChip(label: 'I feel too sore', onTap: () => _sendQuick('I feel too sore to train today, what should I do?')),
              ],
            ),
          ),
          Padding(
            padding: EdgeInsets.fromLTRB(12, 12, 12, MediaQuery.of(context).viewInsets.bottom > 0 ? 12 : 120),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    decoration: const InputDecoration(hintText: 'Ask your coach...'),
                    onSubmitted: (_) => _send(),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(onPressed: _send, icon: const Icon(Icons.send, color: AppColors.primary)),
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
}

class _QuickChip extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  
  const _QuickChip({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 8.0),
      child: ActionChip(
        label: Text(label, style: const TextStyle(fontSize: 12)),
        onPressed: onTap,
        backgroundColor: AppColors.navy700,
        side: BorderSide.none,
      ),
    );
  }
}
