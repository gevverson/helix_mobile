import 'dart:async';
import 'package:flutter/material.dart';
import '../config/app_constants.dart';
import '../services/dating_service.dart';
import '../widgets/safety_menu.dart';

/// A 1:1 chat thread with one of your matches. Messages from the other person
/// are identified by [otherUserId]; everything else is yours. Polls for new
/// messages every few seconds while the screen is open.
class ChatScreen extends StatefulWidget {
  final String matchId;
  final String otherUserId;
  final String name;

  const ChatScreen({
    super.key,
    required this.matchId,
    required this.otherUserId,
    required this.name,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final _controller = TextEditingController();
  final _scroll = ScrollController();
  List<Map<String, dynamic>> _messages = [];
  bool _loading = true;
  bool _loadFailed = false; // first load failed and we have nothing to show
  bool _fetching = false;   // a poll is in flight (cold starts can exceed 4s)
  bool _sending = false;
  Timer? _poll;

  @override
  void initState() {
    super.initState();
    _load(initial: true);
    _poll = Timer.periodic(const Duration(seconds: 4), (_) => _load());
  }

  @override
  void dispose() {
    _poll?.cancel();
    _controller.dispose();
    _scroll.dispose();
    super.dispose();
  }

  Future<void> _load({bool initial = false}) async {
    if (_fetching) return;
    _fetching = true;
    final list = await DatingService.fetchMessages(widget.matchId);
    _fetching = false;
    if (!mounted) return;
    if (list == null) {
      // Keep what's on screen; the next poll will try again.
      if (_loading) setState(() { _loading = false; _loadFailed = true; });
      return;
    }
    final grew = list.length != _messages.length;
    setState(() {
      _messages = list;
      _loading = false;
      _loadFailed = false;
    });
    if (initial || grew) _scrollToBottom();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scroll.hasClients) {
        _scroll.animateTo(
          _scroll.position.maxScrollExtent,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _send() async {
    final text = _controller.text.trim();
    if (text.isEmpty || _sending) return;
    setState(() => _sending = true);
    final msg = await DatingService.sendMessage(widget.matchId, text);
    if (!mounted) return;
    if (msg != null) {
      _controller.clear();
      setState(() => _messages = [..._messages, msg]);
      _scrollToBottom();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not send. Check your connection.')),
      );
    }
    setState(() => _sending = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppConstants.bgPrimary,
      appBar: AppBar(
        title: Text(widget.name),
        actions: [
          IconButton(
            icon: const Icon(Icons.more_horiz, color: AppConstants.textMuted),
            onPressed: () => showSafetyMenu(
              context,
              userId: widget.otherUserId,
              name: widget.name,
              onChanged: () async {
                if (mounted) Navigator.of(context).pop();
              },
            ),
          ),
        ],
      ),
      body: Container(
        decoration: const BoxDecoration(gradient: AppConstants.bgGradient),
        child: SafeArea(
          child: Column(
            children: [
              Expanded(
                child: _loading
                    ? const Center(child: CircularProgressIndicator(color: AppConstants.accentCyan))
                    : _messages.isEmpty
                        ? (_loadFailed ? _error() : _empty())
                        : ListView.builder(
                            controller: _scroll,
                            padding: const EdgeInsets.all(16),
                            itemCount: _messages.length,
                            itemBuilder: (ctx, i) => _bubble(_messages[i]),
                          ),
              ),
              _composer(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _error() {
    return const Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.cloud_off, color: AppConstants.textMuted, size: 52),
          SizedBox(height: 14),
          Text("Couldn't load messages",
              style: TextStyle(color: AppConstants.textPrimary, fontSize: 17, fontWeight: FontWeight.w700)),
          SizedBox(height: 6),
          Text('Check your connection — retrying automatically.',
              style: TextStyle(color: AppConstants.textSecondary)),
        ],
      ),
    );
  }

  Widget _empty() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.chat_bubble_outline, color: AppConstants.textMuted, size: 52),
          const SizedBox(height: 14),
          Text('Say hello to ${widget.name}',
              style: const TextStyle(color: AppConstants.textPrimary, fontSize: 17, fontWeight: FontWeight.w700)),
          const SizedBox(height: 6),
          const Text('You matched — start the conversation.',
              style: TextStyle(color: AppConstants.textSecondary)),
        ],
      ),
    );
  }

  Widget _bubble(Map<String, dynamic> m) {
    final mine = m['sender_id'] != widget.otherUserId;
    return Align(
      alignment: mine ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
        decoration: BoxDecoration(
          color: mine ? AppConstants.accentCyan.withValues(alpha: 0.15) : AppConstants.bgCard,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft: Radius.circular(mine ? 16 : 4),
            bottomRight: Radius.circular(mine ? 4 : 16),
          ),
          border: Border.all(
            color: mine ? AppConstants.accentCyan.withValues(alpha: 0.3) : AppConstants.borderColor,
          ),
        ),
        child: Text(
          m['body'] as String? ?? '',
          style: const TextStyle(color: AppConstants.textPrimary, fontSize: 15, height: 1.35),
        ),
      ),
    );
  }

  Widget _composer() {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
      decoration: const BoxDecoration(
        color: AppConstants.bgPrimary,
        border: Border(top: BorderSide(color: AppConstants.borderColor)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            child: TextField(
              controller: _controller,
              minLines: 1,
              maxLines: 5,
              textCapitalization: TextCapitalization.sentences,
              style: const TextStyle(color: AppConstants.textPrimary),
              decoration: InputDecoration(
                hintText: 'Message…',
                hintStyle: const TextStyle(color: AppConstants.textMuted),
                filled: true,
                fillColor: AppConstants.bgElevated,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide.none,
                ),
              ),
              onSubmitted: (_) => _send(),
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: _send,
            child: Container(
              width: 46,
              height: 46,
              decoration: const BoxDecoration(
                gradient: AppConstants.accentGradient,
                shape: BoxShape.circle,
              ),
              child: _sending
                  ? const Padding(
                      padding: EdgeInsets.all(13),
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : const Icon(Icons.send_rounded, color: Colors.white, size: 20),
            ),
          ),
        ],
      ),
    );
  }
}
