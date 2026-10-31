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
        padding: const EdgeInsets.fromLTRB(14, 8, 14, 16),
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(gradient: AppColors.headerGradient, borderRadius: BorderRadius.circular(14)),
            child: Column(
              children: [
                const Icon(Icons.card_giftcard_rounded, size: 34),
                const SizedBox(height: 8),
                Text('Give ₹50, get ₹50', style: AppText.h2),
                const SizedBox(height: 4),
                Text(
                  'When a friend signs up with your code, you both get ₹50 credit for your next wash.',
                  style: AppText.small,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                if (code.isNotEmpty)
                  InkWell(
                    borderRadius: BorderRadius.circular(10),
                    onTap: () {
                      Clipboard.setData(ClipboardData(text: code));
                      showMessage(context, 'Code copied');
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: AppColors.brandDeep, style: BorderStyle.solid),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(code, style: AppText.h3.copyWith(letterSpacing: 1.5)),
                          const SizedBox(width: 8),
                          const Icon(Icons.copy_rounded, size: 16),
                        ],
                      ),
                    ),
                  ),
                const SizedBox(height: 12),
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
          const SizedBox(height: 12),
          AppCard(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: Row(
              children: [
                const Icon(Icons.account_balance_wallet_outlined, size: 20),
                const SizedBox(width: 10),
                Expanded(child: Text('Your credit', style: AppText.bodyStrong)),
                Text(rupees(plan.credit), style: AppText.title),
              ],
            ),
          ),
          const SizedBox(height: 14),
          Text('Have a friend’s code?', style: AppText.bodyStrong),
          const SizedBox(height: 6),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _code,
                  textCapitalization: TextCapitalization.characters,
                  decoration: const InputDecoration(hintText: 'Enter code', prefixIcon: Icon(Icons.redeem_rounded, size: 18)),
                  onSubmitted: (_) => _apply(),
                ),
              ),
              const SizedBox(width: 8),
              SizedBox(width: 90, child: PrimaryButton(label: 'Apply', loading: _applying, onPressed: _apply)),
            ],
          ),
          const SizedBox(height: 6),
          Text('A code can be added once per account.', style: AppText.tiny),
        ],
      ),
    );
  }
}
