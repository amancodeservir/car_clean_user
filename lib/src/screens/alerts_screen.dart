import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../providers/account_provider.dart';
import '../theme.dart';
import '../widgets/ui.dart';

class AlertsScreen extends StatefulWidget {
  const AlertsScreen({super.key});

  @override
  State<AlertsScreen> createState() => _AlertsScreenState();
}

class _AlertsScreenState extends State<AlertsScreen> {
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final account = context.read<AccountProvider>();
      await account.refreshUnread();
      if (!mounted) return;
      setState(() => _loading = false);
      // Seen now; the list keeps its highlight until the next visit.
      account.markAlertsRead();
    });
  }

  @override
  Widget build(BuildContext context) {
    final account = context.watch<AccountProvider>();
    final alerts = account.alerts;
    return Scaffold(
      appBar: AppBar(title: const Text('Notifications')),
      body: RefreshIndicator(
        color: AppColors.ink,
        onRefresh: account.refreshUnread,
        child: alerts.isEmpty
            ? ListView(
                children: [
                  if (_loading)
                    const Padding(padding: EdgeInsets.all(48), child: Center(child: CircularProgressIndicator()))
                  else
                    const EmptyState(
                      icon: Icons.notifications_none_rounded,
                      title: 'No notifications yet',
                      message: 'Wash updates, payments and offers will show up here.',
                    ),
                ],
              )
            : ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: alerts.length,
                separatorBuilder: (_, __) => const SizedBox(height: 10),
                itemBuilder: (context, index) {
                  final alert = alerts[index];
                  final linked = alert.bookingId.isNotEmpty && alert.bookingId != 'null';
                  return AppCard(
                    color: alert.read ? null : AppColors.yellowWash,
                    onTap: linked ? () => context.push('/booking/${alert.bookingId}') : null,
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 38,
                          height: 38,
                          decoration: BoxDecoration(color: AppColors.yellowSoft, borderRadius: BorderRadius.circular(10)),
                          child: const Icon(Icons.local_car_wash_rounded, size: 20),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Expanded(child: Text(alert.title, style: AppText.title)),
                                  Text(timeAgo(alert.at), style: AppText.tiny),
                                ],
                              ),
                              if (alert.body.isNotEmpty) ...[
                                const SizedBox(height: 2),
                                Text(alert.body, style: AppText.small),
                              ],
                            ],
                          ),
                        ),
                        if (linked) const Icon(Icons.chevron_right_rounded, color: AppColors.faint),
                      ],
                    ),
                  );
                },
              ),
      ),
    );
  }
}
