import 'package:flutter/material.dart';
import '../../core/theme.dart';
import '../../services/api_service.dart';

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

  Future<void> _send() async {
    final text = _controller.text.trim();
    if (text.isEmpty || _loading) return;
    setState(() {
      _messages.add(_Msg(true, text));
      _controller.clear();
      _loading = true;
    });
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
      appBar: AppBar(title: const Text('AI Coach')),
      body: Column(
        children: [
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
                          child: Text(m.text, style: const TextStyle(color: Colors.white)),
                        ),
                      );
                    },
                  ),
          ),
          if (_loading) const LinearProgressIndicator(minHeight: 2),
          Padding(
            padding: const EdgeInsets.all(12),
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
    );
  }
}

class _Msg {
  final bool isUser;
  final String text;
  _Msg(this.isUser, this.text);
}
