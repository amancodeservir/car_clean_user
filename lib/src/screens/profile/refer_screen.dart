import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../config.dart';
import '../../providers/account_provider.dart';
import '../../providers/auth_provider.dart';
import '../../services/api.dart';
import '../../theme.dart';
import '../../widgets/ui.dart';

class ReferScreen extends StatefulWidget {
  const ReferScreen({super.key});

  @override
  State<ReferScreen> createState() => _ReferScreenState();
}

class _ReferScreenState extends State<ReferScreen> {
  final _code = TextEditingController();
  bool _applying = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => context.read<AccountProvider>().refreshPlan());
  }

  @override
  void dispose() {
    _code.dispose();
    super.dispose();
  }

  Future<void> _apply() async {
    if (_code.text.trim().isEmpty) return;
    setState(() => _applying = true);
    try {
      final message = await context.read<AccountProvider>().applyReferral(_code.text);
      if (!mounted) return;
      _code.clear();
      showMessage(context, message);
    } catch (error) {
      if (mounted) showMessage(context, errorText(error));
    } finally {
      if (mounted) setState(() => _applying = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final plan = context.watch<AccountProvider>().plan;
    final code = plan.referralCode.isNotEmpty ? plan.referralCode : (context.watch<AuthProvider>().user?.referralCode ?? '');
    return Scaffold(
      appBar: AppBar(title: const Text('Refer and earn')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(gradient: AppColors.headerGradient, borderRadius: BorderRadius.circular(18)),
            child: Column(
              children: [
                const Icon(Icons.card_giftcard_rounded, size: 48),
                const SizedBox(height: 10),
                Text('Give ₹50, get ₹50', style: AppText.h1),
                const SizedBox(height: 6),
                Text(
                  'When a friend signs up with your code, you both get ₹50 credit for your next wash.',
                  style: AppText.body,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                if (code.isNotEmpty)
                  InkWell(
                    borderRadius: BorderRadius.circular(12),
                    onTap: () {
                      Clipboard.setData(ClipboardData(text: code));
                      showMessage(context, 'Code copied');
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.yellowDeep, style: BorderStyle.solid),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(code, style: AppText.h2.copyWith(letterSpacing: 2)),
                          const SizedBox(width: 10),
                          const Icon(Icons.copy_rounded, size: 18),
                        ],
                      ),
                    ),
                  ),
                const SizedBox(height: 14),
                Builder(
                  builder: (buttonContext) => PrimaryButton(
                    label: 'Share my code',
                    icon: Icons.share_rounded,
                    dark: true,
                    onPressed: code.isEmpty
                        ? null
                        : () {
                            final box = buttonContext.findRenderObject() as RenderBox?;
                            SharePlus.instance.share(
                              ShareParams(
                                text: 'Get your car washed at your doorstep with ${AppConfig.appName}. '
                                    'Sign up with my code $code and we both get ₹50 off.',
                                sharePositionOrigin: box == null ? null : box.localToGlobal(Offset.zero) & box.size,
                              ),
                            );
                          },
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          AppCard(
            child: Row(
              children: [
                const Icon(Icons.account_balance_wallet_outlined),
                const SizedBox(width: 12),
                Expanded(child: Text('Your credit', style: AppText.title)),
                Text(rupees(plan.credit), style: AppText.h2),
              ],
            ),
          ),
          const SizedBox(height: 22),
          Text('Have a friend’s code?', style: AppText.h3),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _code,
                  textCapitalization: TextCapitalization.characters,
                  decoration: const InputDecoration(hintText: 'Enter code', prefixIcon: Icon(Icons.redeem_rounded, size: 20)),
                  onSubmitted: (_) => _apply(),
                ),
              ),
              const SizedBox(width: 8),
              SizedBox(width: 100, child: PrimaryButton(label: 'Apply', loading: _applying, onPressed: _apply)),
            ],
          ),
          const SizedBox(height: 8),
          Text('A code can be added once per account.', style: AppText.small),
        ],
      ),
    );
  }
}
