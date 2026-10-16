import 'package:flutter/material.dart';

import '../../config.dart';
import '../../theme.dart';
import '../../widgets/ui.dart';

class HelpScreen extends StatelessWidget {
  const HelpScreen({super.key});

  static const _faq = [
    (
      'Do I need to give water or power?',
      'No. Washers bring what they need. If you can share a tap and a socket, turn on the water and power option at checkout and save ₹100.'
    ),
    (
      'How do I pay?',
      'Pay the washer by cash or UPI after the service, or pick "Pay online now" at checkout. You can also pay online later from the booking.'
    ),
    (
      'Can I reschedule or cancel?',
      'Yes, from the booking page, until a washer accepts the job. After that, chat with us from the booking and we will sort it out.'
    ),
    (
      'What if I am not happy with the wash?',
      'Open the booking and tap "Report an issue". Add a photo if you can. The desk will get back to you.'
    ),
    (
      'Which cities do you serve?',
      'You can see every city we serve when you change the city on the home screen.'
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Help and support')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text('Talk to us', style: AppText.h3),
          const SizedBox(height: 10),
          Row(
            children: [
              _Contact(Icons.call_rounded, 'Call', () => openLink(context, 'tel:${AppConfig.supportPhone}')),
              const SizedBox(width: 10),
              _Contact(Icons.chat_rounded, 'WhatsApp', () => openLink(context, 'https://wa.me/${AppConfig.supportWhatsApp}')),
              const SizedBox(width: 10),
              _Contact(Icons.mail_rounded, 'Email', () => openLink(context, 'mailto:${AppConfig.supportEmail}')),
            ],
          ),
          const SizedBox(height: 10),
          Text('${AppConfig.supportPhoneLabel} · ${AppConfig.supportEmail}', style: AppText.small, textAlign: TextAlign.center),
          const SizedBox(height: 8),
          Text('For a booking, the fastest way is "Chat with us" on the booking page.', style: AppText.small, textAlign: TextAlign.center),
          const SizedBox(height: 22),
          Text('Common questions', style: AppText.h3),
          const SizedBox(height: 6),
          for (final (question, answer) in _faq)
            Theme(
              data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
              child: ExpansionTile(
                tilePadding: EdgeInsets.zero,
                childrenPadding: const EdgeInsets.only(bottom: 12),
                expandedAlignment: Alignment.centerLeft,
                title: Text(question, style: AppText.title),
                children: [Text(answer, style: AppText.body)],
              ),
            ),
        ],
      ),
    );
  }
}

class _Contact extends StatelessWidget {
  const _Contact(this.icon, this.label, this.onTap);

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: AppCard(
        onTap: onTap,
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Column(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: const BoxDecoration(color: AppColors.yellow, shape: BoxShape.circle),
              child: Icon(icon),
            ),
            const SizedBox(height: 8),
            Text(label, style: AppText.smallStrong),
          ],
        ),
      ),
    );
  }
}
