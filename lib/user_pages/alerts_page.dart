import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/app_provider.dart';
import '../providers/auth_provider.dart';
import '../services/api_service.dart';
import '../theme/brand_theme.dart';
import '../utils/constants.dart';

class AlertsPage extends StatefulWidget {
  const AlertsPage({super.key});

  @override
  State<AlertsPage> createState() => _AlertsPageState();
}

class _AlertsPageState extends State<AlertsPage> {
  List<Map<String, dynamic>> _items = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final token = context.read<AuthProvider>().user?.token ?? '';
    try {
      final response = await ApiService.getJson(AppConstants.notifications, token);
      final data = response['data'];
      if (data is List) {
        _items = data.whereType<Map>().map((item) => Map<String, dynamic>.from(item)).toList();
      }
      await ApiService.sendJson('PUT', '${AppConstants.notifications}/read', token, {});
      if (mounted) await context.read<AppProvider>().refreshUnread(token);
    } catch (_) {}
    if (mounted) setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Alerts')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _items.isEmpty
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const BrandIconWell(icon: Icons.notifications_none),
                      const SizedBox(height: 12),
                      Text(
                        'No alerts yet.',
                        style: AppType.body.copyWith(color: AppConstants.mute, fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                )
              : ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: _items.length,
                  separatorBuilder: (context, index) => const SizedBox(height: 10),
                  itemBuilder: (context, index) {
                    final item = _items[index];
                    return Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BrandTheme.card,
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const BrandIconWell(
                            icon: Icons.notifications_none,
                            box: 40,
                            iconSize: 22,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  item['title']?.toString() ?? '',
                                  style: AppType.item,
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  item['body']?.toString() ?? '',
                                  style: AppType.body.copyWith(color: AppConstants.mute),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
    );
  }
}
