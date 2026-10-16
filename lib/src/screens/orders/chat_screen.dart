import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/booking.dart';
import '../../providers/bookings_provider.dart';
import '../../services/api.dart';
import '../../theme.dart';
import '../../widgets/ui.dart';

/// Messages with the desk about one booking. Replies show up while open.
class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key, required this.id});

  final String id;

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final _input = TextEditingController();
  final _scroll = ScrollController();
  List<SupportMessage> _messages = const [];
  bool _loading = true;
  bool _sending = false;
  String? _error;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _load();
    _timer = Timer.periodic(const Duration(seconds: 10), (_) => _load(quiet: true));
  }

  @override
  void dispose() {
    _timer?.cancel();
    _input.dispose();
    _scroll.dispose();
    super.dispose();
  }

  Future<void> _load({bool quiet = false}) async {
    try {
      final rows = await context.read<BookingsProvider>().messages(widget.id);
      if (!mounted) return;
      final grew = rows.length != _messages.length;
      setState(() {
        _messages = rows;
        _error = null;
      });
      if (grew) _toBottom();
    } catch (error) {
      if (mounted && !quiet) setState(() => _error = errorText(error));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _toBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scroll.hasClients) {
        _scroll.animateTo(_scroll.position.maxScrollExtent, duration: const Duration(milliseconds: 250), curve: Curves.easeOut);
      }
    });
  }

  Future<void> _send() async {
    final text = _input.text.trim();
    if (text.isEmpty || _sending) return;
    setState(() => _sending = true);
    try {
      await context.read<BookingsProvider>().sendMessage(widget.id, text);
      _input.clear();
      await _load(quiet: true);
    } catch (error) {
      if (mounted) showMessage(context, errorText(error));
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final booking = context.watch<BookingsProvider>().byId(widget.id);
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Support chat'),
            if (booking != null) Text('${booking.service} · #${booking.shortId}', style: AppText.tiny),
          ],
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _error != null
                    ? EmptyState(icon: Icons.wifi_off_rounded, title: 'Could not load messages', message: _error!, action: 'Retry', onAction: _load)
                    : _messages.isEmpty
                        ? const EmptyState(
                            icon: Icons.chat_bubble_outline_rounded,
                            title: 'Ask us anything',
                            message: 'Questions about timing, the address, or the wash? Our desk usually replies within a few minutes during working hours.',
                          )
                        : ListView.builder(
                            controller: _scroll,
                            padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
                            itemCount: _messages.length,
                            itemBuilder: (context, index) => _Bubble(_messages[index]),
                          ),
          ),
          DecoratedBox(
            decoration: const BoxDecoration(
              color: Colors.white,
              border: Border(top: BorderSide(color: AppColors.line)),
            ),
            child: SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 8, 8, 8),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _input,
                        minLines: 1,
                        maxLines: 4,
                        maxLength: 1000,
                        textCapitalization: TextCapitalization.sentences,
                        decoration: const InputDecoration(hintText: 'Type a message', counterText: ''),
                        onSubmitted: (_) => _send(),
                      ),
                    ),
                    const SizedBox(width: 6),
                    IconButton.filled(
                      tooltip: 'Send',
                      style: IconButton.styleFrom(backgroundColor: AppColors.yellow, foregroundColor: AppColors.ink),
                      onPressed: _sending ? null : _send,
                      icon: _sending
                          ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                          : const Icon(Icons.send_rounded),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Bubble extends StatelessWidget {
  const _Bubble(this.message);

  final SupportMessage message;

  @override
  Widget build(BuildContext context) {
    final mine = message.mine;
    final who = switch (message.fromRole) {
      'staff' => 'Washer',
      'admin' || 'superadmin' => 'Car Clean Plus desk',
      _ => 'You',
    };
    return Align(
      alignment: mine ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        constraints: BoxConstraints(maxWidth: MediaQuery.sizeOf(context).width * 0.78),
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
        decoration: BoxDecoration(
          color: mine ? AppColors.yellowSoft : Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(14),
            topRight: const Radius.circular(14),
            bottomLeft: Radius.circular(mine ? 14 : 4),
            bottomRight: Radius.circular(mine ? 4 : 14),
          ),
          border: Border.all(color: mine ? const Color(0xFFF3E1A0) : AppColors.line),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (!mine) Text(who, style: AppText.tiny.copyWith(color: AppColors.navy)),
            Text(message.body, style: AppText.body.copyWith(color: AppColors.ink)),
            const SizedBox(height: 2),
            Text(timeAgo(message.at), style: AppText.tiny.copyWith(fontSize: 10)),
          ],
        ),
      ),
    );
  }
}
