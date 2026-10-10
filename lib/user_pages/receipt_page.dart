import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';

import '../providers/auth_provider.dart';
import '../services/api_service.dart';
import '../theme/brand_theme.dart';
import '../utils/constants.dart';

class ReceiptPage extends StatefulWidget {
  const ReceiptPage({super.key, required this.bookingId});

  final String bookingId;

  @override
  State<ReceiptPage> createState() => _ReceiptPageState();
}

class _ReceiptPageState extends State<ReceiptPage> {
  Map<String, dynamic>? _data;
  String? _error;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    final token = context.read<AuthProvider>().user?.token ?? '';
    try {
      final response = await ApiService.getJson(AppConstants.receiptBooking(widget.bookingId), token);
      final data = response['data'];
      if (!mounted) return;
      if (data is! Map) {
        setState(() {
          _loading = false;
          _error = 'Receipt is not available';
        });
        return;
      }
      setState(() {
        _data = Map<String, dynamic>.from(data);
        _loading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = error.toString().replaceFirst('Exception: ', '');
      });
    }
  }

  String _money(dynamic value) => '₹${(num.tryParse('$value') ?? 0).round()}';

  String _shareText() {
    final data = _data ?? {};
    final name = (context.read<AuthProvider>().user?.name ?? '').trim();
    final vehicle = [
      '${data['vehicle'] ?? ''}'.trim(),
      '${data['category'] ?? ''}'.trim(),
    ].where((part) => part.isNotEmpty).join(' · ');
    final place = [
      '${data['address'] ?? ''}'.trim(),
      '${data['city'] ?? ''}'.trim(),
    ].where((part) => part.isNotEmpty).join(', ');
    final when = [
      '${data['date'] ?? ''}'.trim(),
      '${data['timeSlot'] ?? ''}'.trim(),
    ].where((part) => part.isNotEmpty).join(' · ');
    final lines = <String>[
      'Car Clean Plus',
      'Receipt ${data['receiptNo'] ?? ''}'.trim(),
      if (name.isNotEmpty) 'Billed to $name',
      '${data['service'] ?? 'Wash'}',
      if (vehicle.isNotEmpty) vehicle,
      if (when.isNotEmpty) when,
      if (place.isNotEmpty) place,
    ];
    final addons = data['addons'];
    if (addons is List) {
      for (final item in addons) {
        if (item is Map && '${item['name'] ?? ''}'.trim().isNotEmpty) {
          lines.add('${item['name']}  ${_money(item['price'])}');
        }
      }
    }
    final travel = num.tryParse('${data['travelFee'] ?? 0}') ?? 0;
    final discount = num.tryParse('${data['discount'] ?? 0}') ?? 0;
    lines.add('Taxable  ${_money(data['taxable'])}');
    lines.add('GST ${data['gstPercent'] ?? 0}%  ${_money(data['gstAmount'])}');
    if (travel > 0) lines.add('Travel  ${_money(travel)}');
    if (discount > 0) lines.add('Discount  -${_money(discount)}');
    lines.add('Total  ${_money(data['total'])}');
    final pay = [
      '${data['paymentMethod'] ?? ''}'.trim(),
      '${data['paymentStatus'] ?? ''}'.trim(),
    ].where((part) => part.isNotEmpty).join(' · ');
    if (pay.isNotEmpty) lines.add(pay);
    return lines.join('\n');
  }

  Future<void> _share(BuildContext buttonContext) async {
    final box = buttonContext.findRenderObject() as RenderBox?;
    final origin = box == null ? null : box.localToGlobal(Offset.zero) & box.size;
    await SharePlus.instance.share(
      ShareParams(
        text: _shareText(),
        subject: 'Car Clean Plus receipt ${_data?['receiptNo'] ?? ''}'.trim(),
        sharePositionOrigin: origin,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final data = _data;
    return Scaffold(
      appBar: AppBar(title: const Text('Receipt')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(_error!, textAlign: TextAlign.center, style: AppType.body),
                        const SizedBox(height: 12),
                        TextButton(onPressed: _load, child: const Text('Try again')),
                      ],
                    ),
                  ),
                )
              : ListView(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                  children: [
                    Container(
                      padding: const EdgeInsets.fromLTRB(16, 18, 16, 16),
                      decoration: BrandTheme.card,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('CAR CLEAN PLUS', style: AppType.label.copyWith(letterSpacing: 1.1)),
                          const SizedBox(height: 6),
                          Text(
                            data?['receiptNo']?.toString() ?? 'Receipt',
                            style: AppType.display.copyWith(fontWeight: FontWeight.w800),
                          ),
                          const SizedBox(height: 14),
                          Text('${data?['service'] ?? 'Wash'}', style: AppType.title),
                          const SizedBox(height: 4),
                          Text(
                            [
                              if ('${data?['vehicle'] ?? ''}'.trim().isNotEmpty) data?['vehicle'],
                              if ('${data?['category'] ?? ''}'.trim().isNotEmpty) data?['category'],
                            ].join(' · '),
                            style: AppType.body.copyWith(color: AppConstants.mute),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '${data?['date'] ?? ''} · ${data?['timeSlot'] ?? ''}',
                            style: AppType.body,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            [
                              if ('${data?['address'] ?? ''}'.trim().isNotEmpty) data?['address'],
                              if ('${data?['city'] ?? ''}'.trim().isNotEmpty) data?['city'],
                            ].join(', '),
                            style: AppType.body.copyWith(color: AppConstants.mute),
                          ),
                          const Padding(
                            padding: EdgeInsets.symmetric(vertical: 14),
                            child: Divider(height: 1),
                          ),
                          _AmountRow(label: 'Taxable', value: _money(data?['taxable'])),
                          _AmountRow(
                            label: 'GST ${data?['gstPercent'] ?? 0}%',
                            value: _money(data?['gstAmount']),
                          ),
                          if ((num.tryParse('${data?['travelFee'] ?? 0}') ?? 0) > 0)
                            _AmountRow(label: 'Travel', value: _money(data?['travelFee'])),
                          if ((num.tryParse('${data?['discount'] ?? 0}') ?? 0) > 0)
                            _AmountRow(label: 'Discount', value: '-${_money(data?['discount'])}'),
                          const SizedBox(height: 8),
                          _AmountRow(label: 'Total', value: _money(data?['total']), strong: true),
                          const SizedBox(height: 8),
                          Text(
                            [
                              if ('${data?['paymentMethod'] ?? ''}'.trim().isNotEmpty) data?['paymentMethod'],
                              if ('${data?['paymentStatus'] ?? ''}'.trim().isNotEmpty) data?['paymentStatus'],
                            ].join(' · '),
                            style: AppType.label.copyWith(color: AppConstants.mute),
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
                  builder: (buttonContext) => FilledButton.icon(
                    onPressed: () => _share(buttonContext),
                    icon: const Icon(Icons.ios_share_rounded, size: 18),
                    label: const Text('Share receipt'),
                  ),
                ),
              ),
            ),
    );
  }
}

class _AmountRow extends StatelessWidget {
  const _AmountRow({required this.label, required this.value, this.strong = false});

  final String label;
  final String value;
  final bool strong;

  @override
  Widget build(BuildContext context) {
    final style = strong ? AppType.title : AppType.body;
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          Expanded(child: Text(label, style: style)),
          Text(value, style: style.copyWith(fontWeight: strong ? FontWeight.w800 : FontWeight.w600)),
        ],
      ),
    );
  }
}
