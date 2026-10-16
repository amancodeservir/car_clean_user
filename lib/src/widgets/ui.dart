import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

import '../models/booking.dart';
import '../models/catalog.dart';
import '../theme.dart';

// Formatting

/// `1234567` → `12,34,567` (Indian grouping).
String rupees(int amount) {
  final negative = amount < 0;
  final digits = amount.abs().toString();
  String grouped;
  if (digits.length <= 3) {
    grouped = digits;
  } else {
    final last = digits.substring(digits.length - 3);
    var rest = digits.substring(0, digits.length - 3);
    final parts = <String>[];
    while (rest.length > 2) {
      parts.insert(0, rest.substring(rest.length - 2));
      rest = rest.substring(0, rest.length - 2);
    }
    if (rest.isNotEmpty) parts.insert(0, rest);
    grouped = '${parts.join(',')},$last';
  }
  return '${negative ? '-' : ''}₹$grouped';
}

String compactCount(int value) {
  if (value >= 100000) return '${(value / 100000).toStringAsFixed(1).replaceAll('.0', '')}L';
  if (value >= 1000) return '${(value / 1000).toStringAsFixed(1).replaceAll('.0', '')}k';
  return '$value';
}

const _weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
const _months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];

String weekday(DateTime day) => _weekdays[day.weekday - 1];
String month(DateTime day) => _months[day.month - 1];

String ymd(DateTime day) =>
    '${day.year}-${day.month.toString().padLeft(2, '0')}-${day.day.toString().padLeft(2, '0')}';

/// `Today`, `Tomorrow` or `Sat, 21 Feb`.
String dayLabel(String raw) {
  final parsed = DateTime.tryParse(raw);
  if (parsed == null) return raw;
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final day = DateTime(parsed.year, parsed.month, parsed.day);
  if (day == today) return 'Today';
  if (day == today.add(const Duration(days: 1))) return 'Tomorrow';
  return '${weekday(day)}, ${day.day} ${month(day)}';
}

/// `21 Feb, 10:30 AM` for a server timestamp.
String stamp(String raw) {
  final parsed = DateTime.tryParse(raw)?.toLocal();
  if (parsed == null) return raw;
  final hour = parsed.hour % 12 == 0 ? 12 : parsed.hour % 12;
  final minute = parsed.minute.toString().padLeft(2, '0');
  return '${parsed.day} ${month(parsed)}, $hour:$minute ${parsed.hour >= 12 ? 'PM' : 'AM'}';
}

String timeAgo(String raw) {
  final parsed = DateTime.tryParse(raw)?.toLocal();
  if (parsed == null) return '';
  final gap = DateTime.now().difference(parsed);
  if (gap.inMinutes < 1) return 'Just now';
  if (gap.inMinutes < 60) return '${gap.inMinutes} min ago';
  if (gap.inHours < 24) return '${gap.inHours} hr ago';
  if (gap.inDays < 7) return '${gap.inDays} d ago';
  return stamp(raw);
}

// Feedback

void showMessage(BuildContext context, String text) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(text)));
}

Future<bool> confirm(
  BuildContext context, {
  required String title,
  required String message,
  String confirmLabel = 'Yes',
  String cancelLabel = 'No',
  bool danger = false,
}) async {
  final result = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(title),
      content: Text(message),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context, false), child: Text(cancelLabel)),
        FilledButton(
          style: danger ? FilledButton.styleFrom(backgroundColor: AppColors.red, foregroundColor: Colors.white) : null,
          onPressed: () => Navigator.pop(context, true),
          child: Text(confirmLabel),
        ),
      ],
    ),
  );
  return result == true;
}

Future<void> openLink(BuildContext context, String url) async {
  final uri = Uri.tryParse(url);
  final ok = uri != null && await launchUrl(uri, mode: LaunchMode.externalApplication);
  if (!ok && context.mounted) showMessage(context, 'Could not open $url');
}

// Building blocks

class AppCard extends StatelessWidget {
  const AppCard({super.key, required this.child, this.padding = const EdgeInsets.all(14), this.onTap, this.color});

  final Widget child;
  final EdgeInsetsGeometry padding;
  final VoidCallback? onTap;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(16);
    return Material(
      color: color ?? Colors.white,
      borderRadius: radius,
      child: InkWell(
        borderRadius: radius,
        onTap: onTap,
        child: Ink(
          decoration: BoxDecoration(
            borderRadius: radius,
            border: Border.all(color: AppColors.line),
          ),
          child: Padding(padding: padding, child: child),
        ),
      ),
    );
  }
}

class SectionTitle extends StatelessWidget {
  const SectionTitle(this.title, {super.key, this.action, this.onAction, this.subtitle});

  final String title;
  final String? subtitle;
  final String? action;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: AppText.h3),
                if (subtitle != null) ...[
                  const SizedBox(height: 2),
                  Text(subtitle!, style: AppText.small),
                ],
              ],
            ),
          ),
          if (action != null)
            TextButton(
              onPressed: onAction,
              style: TextButton.styleFrom(visualDensity: VisualDensity.compact, padding: const EdgeInsets.symmetric(horizontal: 6)),
              child: Text(action!),
            ),
        ],
      ),
    );
  }
}

class PrimaryButton extends StatelessWidget {
  const PrimaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.loading = false,
    this.icon,
    this.expand = true,
    this.dark = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool loading;
  final IconData? icon;
  final bool expand;
  final bool dark;

  @override
  Widget build(BuildContext context) {
    final style = dark
        ? FilledButton.styleFrom(backgroundColor: AppColors.ink, foregroundColor: Colors.white)
        : null;
    final child = loading
        ? SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(strokeWidth: 2.2, color: dark ? Colors.white : AppColors.ink),
          )
        : Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[Icon(icon, size: 19), const SizedBox(width: 8)],
              Flexible(child: Text(label, overflow: TextOverflow.ellipsis)),
            ],
          );
    final button = FilledButton(style: style, onPressed: loading ? null : onPressed, child: child);
    return expand ? SizedBox(width: double.infinity, child: button) : button;
  }
}

/// `₹249  ~~₹498~~  40% OFF`. The struck price only shows for a real discount.
class PriceLine extends StatelessWidget {
  const PriceLine(this.price, {super.key, this.prefix = '', this.big = false});

  final PriceTag price;
  final String prefix;
  final bool big;

  @override
  Widget build(BuildContext context) {
    if (!price.isKnown) return Text('Price on request', style: AppText.small);
    final main = (big ? AppText.h2 : AppText.h3);
    return Wrap(
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: 6,
      runSpacing: 2,
      children: [
        if (prefix.isNotEmpty) Text(prefix, style: AppText.small),
        Text(rupees(price.amount), style: main),
        if (price.hasDiscount) ...[
          Text(
            rupees(price.before),
            style: AppText.small.copyWith(decoration: TextDecoration.lineThrough, color: AppColors.faint),
          ),
          DiscountBadge(price.percentOff),
        ],
      ],
    );
  }
}

class DiscountBadge extends StatelessWidget {
  const DiscountBadge(this.percent, {super.key});

  final int percent;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(Icons.local_offer_rounded, size: 13, color: AppColors.green),
        const SizedBox(width: 3),
        Text('$percent% OFF', style: AppText.tiny.copyWith(color: AppColors.green, fontWeight: FontWeight.w800)),
      ],
    );
  }
}

/// Rating and recent bookings, shown only when there is real data.
class ServiceProof extends StatelessWidget {
  const ServiceProof(this.stats, {super.key});

  final ServiceStats stats;

  @override
  Widget build(BuildContext context) {
    final rating = stats.rating;
    final children = <Widget>[
      if (rating != null && stats.ratingCount > 0)
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.star_rounded, size: 16, color: Color(0xFFF59E0B)),
            const SizedBox(width: 2),
            Text(rating.toStringAsFixed(1), style: AppText.smallStrong),
            Text(' (${compactCount(stats.ratingCount)} ratings)', style: AppText.tiny),
          ],
        ),
      if (stats.bookings30d > 0)
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(color: AppColors.yellowSoft, borderRadius: BorderRadius.circular(6)),
          child: Text(
            '${compactCount(stats.bookings30d)}+ bookings in last 30 days',
            style: AppText.tiny.copyWith(color: const Color(0xFF8A6400), fontWeight: FontWeight.w700),
          ),
        ),
    ];
    if (children.isEmpty) return const SizedBox.shrink();
    return Wrap(spacing: 8, runSpacing: 6, crossAxisAlignment: WrapCrossAlignment.center, children: children);
  }
}

class Bullet extends StatelessWidget {
  const Bullet(this.text, {super.key, this.icon = Icons.check_rounded, this.color = AppColors.green});

  final String text;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(padding: const EdgeInsets.only(top: 1), child: Icon(icon, size: 16, color: color)),
          const SizedBox(width: 8),
          Expanded(child: Text(text, style: AppText.body.copyWith(fontSize: 13))),
        ],
      ),
    );
  }
}

class StatusPill extends StatelessWidget {
  const StatusPill(this.booking, {super.key});

  final Booking booking;

  @override
  Widget build(BuildContext context) {
    final (Color bg, Color fg) = switch (booking.status) {
      'completed' => (AppColors.greenSoft, AppColors.green),
      'cancelled' || 'canceled' => (AppColors.redSoft, AppColors.red),
      'accepted' || 'on_the_way' || 'in_progress' => (AppColors.orangeSoft, AppColors.orange),
      _ => (AppColors.blueSoft, AppColors.navy),
    };
    final label = booking.isUpcoming && !booking.isActive ? 'Upcoming' : booking.statusLabel;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(6)),
      child: Text(label, style: AppText.tiny.copyWith(color: fg, fontWeight: FontWeight.w800)),
    );
  }
}

class EmptyState extends StatelessWidget {
  const EmptyState({
    super.key,
    required this.icon,
    required this.title,
    required this.message,
    this.action,
    this.onAction,
  });

  final IconData icon;
  final String title;
  final String message;
  final String? action;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 40),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: const BoxDecoration(color: AppColors.yellowSoft, shape: BoxShape.circle),
            child: Icon(icon, size: 34, color: AppColors.ink),
          ),
          const SizedBox(height: 16),
          Text(title, style: AppText.h3, textAlign: TextAlign.center),
          const SizedBox(height: 6),
          Text(message, style: AppText.body, textAlign: TextAlign.center),
          if (action != null) ...[
            const SizedBox(height: 18),
            PrimaryButton(label: action!, onPressed: onAction, expand: false),
          ],
        ],
      ),
    );
  }
}

class Sparkle extends StatelessWidget {
  const Sparkle({super.key, this.size = 22});

  final double size;

  @override
  Widget build(BuildContext context) =>
      Icon(Icons.auto_awesome, size: size, color: const Color(0xFFD4A20B));
}

/// An image from a `data:image/...;base64,` string or an http URL.
class RemotePhoto extends StatelessWidget {
  const RemotePhoto(this.source, {super.key, this.height = 160});

  final String source;
  final double height;

  static Uint8List? _bytes(String source) {
    if (!source.startsWith('data:image')) return null;
    final comma = source.indexOf(',');
    if (comma < 0) return null;
    try {
      return base64Decode(source.substring(comma + 1));
    } catch (_) {
      return null;
    }
  }

  static bool canShow(String source) => source.startsWith('http') || _bytes(source) != null;

  @override
  Widget build(BuildContext context) {
    final bytes = _bytes(source);
    final image = bytes != null
        ? Image.memory(bytes, height: height, width: double.infinity, fit: BoxFit.cover, gaplessPlayback: true)
        : Image.network(
            source,
            height: height,
            width: double.infinity,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => SizedBox(height: height),
          );
    return ClipRRect(borderRadius: BorderRadius.circular(12), child: image);
  }
}

class Photo extends StatelessWidget {
  const Photo(this.asset, {super.key, this.width, this.height, this.radius = 12});

  final String asset;
  final double? width;
  final double? height;
  final double radius;

  @override
  Widget build(BuildContext context) {
    final dpr = MediaQuery.devicePixelRatioOf(context);
    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: Image.asset(
        asset,
        width: width,
        height: height,
        fit: BoxFit.cover,
        // Decode at display size, not the full photo.
        cacheWidth: width == null || width == double.infinity ? null : (width! * dpr).round(),
      ),
    );
  }
}

/// A zero-height app bar that only paints behind the status bar, so content
/// scrolling under it stays readable.
PreferredSizeWidget statusBarBackdrop(Color color, {bool dark = false}) {
  return PreferredSize(
    preferredSize: Size.zero,
    child: AppBar(
      toolbarHeight: 0,
      backgroundColor: color,
      surfaceTintColor: Colors.transparent,
      scrolledUnderElevation: 0,
      elevation: 0,
      systemOverlayStyle: dark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark,
    ),
  );
}
