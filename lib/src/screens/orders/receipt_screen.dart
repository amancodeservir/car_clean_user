import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../config.dart';
import '../../providers/auth_provider.dart';
import '../../providers/bookings_provider.dart';
import '../../services/api.dart';
import '../../theme.dart';
import '../../widgets/ui.dart';

class ReceiptScreen extends StatefulWidget {
  const ReceiptScreen({super.key, required this.id});

  final String id;

  @override
  State<ReceiptScreen> createState() => _ReceiptScreenState();
}

class _ReceiptScreenState extends State<ReceiptScreen> {
  Map<String, dynamic>? _data;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _error = null);
    try {
      final data = await context.read<BookingsProvider>().receipt(widget.id);
      if (mounted) setState(() => _data = data);
    } catch (error) {
      if (mounted) setState(() => _error = errorText(error));
    }
  }

  int _num(String key) => (num.tryParse('${_data?[key] ?? 0}') ?? 0).round();
  String _text(String key) => '${_data?[key] ?? ''}'.trim();

  String _shareText() {
    final name = context.read<AuthProvider>().user?.name ?? '';
    final lines = [
      AppConfig.appName,
      'Receipt ${_text('receiptNo')}',
      if (name.isNotEmpty) 'Billed to $name',
      _text('service'),
      [_text('vehicle'), _text('category')].where((part) => part.isNotEmpty).join(' · '),
      '${_text('date')} · ${_text('timeSlot')}',
      [_text('address'), _text('city')].where((part) => part.isNotEmpty).join(', '),
      'Taxable value  ${rupees(_num('taxable'))}',
      'GST ${_num('gstPercent')}%  ${rupees(_num('gstAmount'))}',
      if (_num('discount') > 0) 'Discount  -${rupees(_num('discount'))}',
      if (_num('travelFee') > 0) 'Travel fee  ${rupees(_num('travelFee'))}',
      'Total  ${rupees(_num('total'))}',
      [_text('paymentMethod'), _text('paymentStatus')].where((part) => part.isNotEmpty).join(' · '),
    ];
    return lines.where((line) => line.trim().isNotEmpty).join('\n');
  }

  Future<void> _share(BuildContext buttonContext) async {
    final box = buttonContext.findRenderObject() as RenderBox?;
    await SharePlus.instance.share(
      ShareParams(
        text: _shareText(),
        subject: '${AppConfig.appName} receipt ${_text('receiptNo')}',
        sharePositionOrigin: box == null ? null : box.localToGlobal(Offset.zero) & box.size,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final data = _data;
    return Scaffold(
      appBar: AppBar(title: const Text('Receipt')),
      body: data == null
          ? Center(
              child: _error == null
                  ? const CircularProgressIndicator()
                  : EmptyState(icon: Icons.receipt_long_rounded, title: 'Receipt not available', message: _error!, action: 'Try again', onAction: _load),
            )
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                AppCard(
                  padding: const EdgeInsets.all(18),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        children: [
                          Image.asset(Photos.logo, height: 34),
                          const Spacer(),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text('RECEIPT', style: AppText.tiny.copyWith(letterSpacing: 1.2)),
                              Text(_text('receiptNo'), style: AppText.title),
                            ],
                          ),
                        ],
                      ),
                      const Padding(padding: EdgeInsets.symmetric(vertical: 14), child: Divider()),
                      Text(_text('service'), style: AppText.h3),
                      const SizedBox(height: 4),
                      Text([_text('vehicle'), _text('category')].where((part) => part.isNotEmpty).join(' · '), style: AppText.body),
                      Text('${dayLabel(_text('date'))} · ${_text('timeSlot')}', style: AppText.body),
                      Text([_text('address'), _text('city')].where((part) => part.isNotEmpty).join(', '), style: AppText.small),
                      const Padding(padding: EdgeInsets.symmetric(vertical: 14), child: Divider()),
                      if (data['addons'] is List)
                        for (final addon in (data['addons'] as List).whereType<Map>())
                          _row('${addon['name']}', rupees((num.tryParse('${addon['price']}') ?? 0).round())),
                      if (_num('discount') > 0) _row('Discount', '-${rupees(_num('discount'))}'),
                      if (_num('travelFee') > 0) _row('Travel fee', rupees(_num('travelFee'))),
                      _row('Taxable value', rupees(_num('taxable'))),
                      _row('GST (${_num('gstPercent')}%)', rupees(_num('gstAmount'))),
                      const Padding(padding: EdgeInsets.symmetric(vertical: 8), child: Divider()),
                      _row('Total', rupees(_num('total')), strong: true),
                      const SizedBox(height: 8),
                      Text(
                        [_text('paymentMethod'), _text('paymentStatus')].where((part) => part.isNotEmpty).join(' · ').toUpperCase(),
                        style: AppText.tiny,
                      ),
                    ],
                  ),
                ),
              ],
            ),
      bottomNavigationBar: data == null
          ? null
          : SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                child: Builder(
                  builder: (buttonContext) => PrimaryButton(
                    label: 'Share receipt',
                    icon: Icons.ios_share_rounded,
                    onPressed: () => _share(buttonContext),
                  ),
                ),
              ),
            ),
    );
  }

  Widget _row(String label, String value, {bool strong = false}) {
    final style = strong ? AppText.h3 : AppText.body;
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          Expanded(child: Text(label, style: style)),
          Text(value, style: style.copyWith(fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }
}
