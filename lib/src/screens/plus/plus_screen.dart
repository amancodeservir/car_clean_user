import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../models/catalog.dart';
import '../../providers/account_provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/catalog_provider.dart';
import '../../services/api.dart';
import '../../theme.dart';
import '../../widgets/ui.dart';

class PlusScreen extends StatefulWidget {
  const PlusScreen({super.key});

  @override
  State<PlusScreen> createState() => _PlusScreenState();
}

class _PlusScreenState extends State<PlusScreen> with WidgetsBindingObserver {
  String? _buying;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  // Coming back from the payment page: check whether the plan is on.
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) context.read<AccountProvider>().refreshPlan();
  }

  Future<void> _buy(WashPlan plan) async {
    if (!context.read<AuthProvider>().isSignedIn) {
      context.push('/login?from=/plus');
      return;
    }
    setState(() => _buying = plan.name);
    try {
      final url = await context.read<AccountProvider>().buyPlan(plan);
      if (mounted) await openLink(context, url);
    } catch (error) {
      if (mounted) showMessage(context, errorText(error));
    } finally {
      if (mounted) setState(() => _buying = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    final plans = context.watch<CatalogProvider>().plans;
    final account = context.watch<AccountProvider>();
    final plan = account.plan;
    final catalog = context.watch<CatalogProvider>();
    String serviceTitle(String name) => catalog.service(name)?.title ?? name;

    return Scaffold(
      appBar: statusBarBackdrop(AppColors.ink, dark: true),
      body: RefreshIndicator(
        color: AppColors.ink,
        onRefresh: account.refreshPlan,
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            Container(
              padding: const EdgeInsets.fromLTRB(20, 18, 20, 24),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [AppColors.ink, Color(0xFF273449)],
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.workspace_premium_rounded, color: AppColors.yellow, size: 28),
                      const SizedBox(width: 8),
                      Text('Car Clean Plus', style: AppText.h2.copyWith(color: AppColors.yellow)),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Text('Wash more,\npay less.', style: AppText.hero.copyWith(color: Colors.white)),
                  const SizedBox(height: 8),
                  Text(
                    'Buy a pack of doorstep washes and use them over 30 days.',
                    style: AppText.body.copyWith(color: Colors.white70),
                  ),
                  if (plan.isActive) ...[
                    const SizedBox(height: 18),
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: Colors.white24),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Your plan: ${plan.planName}', style: AppText.title.copyWith(color: Colors.white)),
                                if (plan.expiresAt != null)
                                  Text(
                                    'Valid till ${plan.expiresAt!.day} ${month(plan.expiresAt!)} ${plan.expiresAt!.year}',
                                    style: AppText.small.copyWith(color: Colors.white70),
                                  ),
                              ],
                            ),
                          ),
                          Column(
                            children: [
                              Text('${plan.washesLeft}', style: AppText.h1.copyWith(color: AppColors.yellow)),
                              Text('washes left', style: AppText.tiny.copyWith(color: Colors.white70)),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 18, 16, 28),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (plan.pendingPlan.isNotEmpty) ...[
                    AppCard(
                      color: AppColors.yellowWash,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text('${plan.pendingPlan} is waiting for payment', style: AppText.title),
                          const SizedBox(height: 4),
                          Text('It turns on as soon as the payment goes through.', style: AppText.small),
                          const SizedBox(height: 10),
                          Row(
                            children: [
                              Expanded(
                                child: OutlinedButton(onPressed: account.refreshPlan, child: const Text('I have paid')),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: PrimaryButton(
                                  label: 'Pay now',
                                  onPressed: plan.pendingUrl.startsWith('http') ? () => openLink(context, plan.pendingUrl) : null,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                  Text('Choose a plan', style: AppText.h2),
                  const SizedBox(height: 12),
                  for (final row in plans) ...[
                    _PlanCard(
                      plan: row,
                      serviceTitle: serviceTitle(row.service),
                      single: catalog.startingPrice(row.service).amount,
                      best: row == plans.reduce((a, b) => a.perWash <= b.perWash ? a : b) && plans.length > 1,
                      busy: _buying == row.name,
                      onBuy: () => _buy(row),
                    ),
                    const SizedBox(height: 12),
                  ],
                  if (!plan.paymentsEnabled)
                    Text('Online payment is not switched on yet. Call us to buy a plan.', style: AppText.small, textAlign: TextAlign.center),
                  const SizedBox(height: 12),
                  Text('What you get', style: AppText.h3),
                  const SizedBox(height: 10),
                  const Bullet('Doorstep washes at a lower price per wash', icon: Icons.savings_rounded),
                  const Bullet('Use a plan wash at checkout with one tap', icon: Icons.touch_app_rounded),
                  const Bullet('Same trained washers and before/after photos', icon: Icons.verified_rounded),
                  const Bullet('Valid for 30 days from purchase', icon: Icons.event_available_rounded),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PlanCard extends StatelessWidget {
  const _PlanCard({
    required this.plan,
    required this.serviceTitle,
    required this.single,
    required this.best,
    required this.busy,
    required this.onBuy,
  });

  final WashPlan plan;
  final String serviceTitle;
  final int single;
  final bool best;
  final bool busy;
  final VoidCallback onBuy;

  @override
  Widget build(BuildContext context) {
    final saving = single > 0 ? (single * plan.washes) - plan.amount : 0;
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: best ? AppColors.yellowDeep : AppColors.line, width: best ? 2 : 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (best)
            Container(
              padding: const EdgeInsets.symmetric(vertical: 5),
              decoration: const BoxDecoration(
                color: AppColors.yellow,
                borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
              ),
              child: Text('BEST VALUE', textAlign: TextAlign.center, style: AppText.tiny.copyWith(color: AppColors.ink, letterSpacing: 1)),
            ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(plan.name, style: AppText.h3),
                      Text('${plan.washes} × $serviceTitle', style: AppText.small),
                      const SizedBox(height: 8),
                      Text(rupees(plan.amount), style: AppText.h1),
                      Text('${rupees(plan.perWash)} per wash', style: AppText.smallStrong.copyWith(color: AppColors.green)),
                      if (saving > 0)
                        Text('Save up to ${rupees(saving)} on hatchback prices', style: AppText.tiny),
                    ],
                  ),
                ),
                SizedBox(width: 110, child: PrimaryButton(label: 'Buy', loading: busy, onPressed: onBuy)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
