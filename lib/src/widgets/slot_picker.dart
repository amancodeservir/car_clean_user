import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../data/defaults.dart';
import '../providers/bookings_provider.dart';
import '../theme.dart';
import 'ui.dart';

/// Booking days: the next two weeks, without Sundays (no washes on Sunday).
List<DateTime> bookingDays() {
  final now = DateTime.now();
  final start = DateTime(now.year, now.month, now.day);
  return [
    for (var i = 0; i < 15; i++) start.add(Duration(days: i)),
  ].where((day) => day.weekday != DateTime.sunday).toList();
}

/// Day chips and slot grid. Full and past slots are disabled.
class SlotPicker extends StatefulWidget {
  const SlotPicker({
    super.key,
    required this.city,
    required this.onChanged,
    this.initialDate,
    this.initialSlot,
  });

  final String city;
  final String? initialDate;
  final String? initialSlot;
  final void Function(String date, Slot? slot) onChanged;

  @override
  State<SlotPicker> createState() => _SlotPickerState();
}

class _SlotPickerState extends State<SlotPicker> {
  late final List<DateTime> _days = bookingDays();
  late DateTime _day;
  Slot? _slot;
  Set<String> _full = const {};
  bool _loading = true;
  int _request = 0;

  @override
  void initState() {
    super.initState();
    final initial = DateTime.tryParse(widget.initialDate ?? '');
    _day = _days.firstWhere(
      (day) => initial != null && ymd(day) == ymd(initial),
      orElse: () => _days.firstWhere((day) => _openSlots(day).isNotEmpty, orElse: () => _days.first),
    );
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  @override
  void didUpdateWidget(covariant SlotPicker oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.city != widget.city) _load();
  }

  List<Slot> _openSlots(DateTime day) => Defaults.slots.where((slot) => !slot.isPast(day)).toList();

  Future<void> _load() async {
    final request = ++_request;
    setState(() => _loading = true);
    final full = await context.read<BookingsProvider>().fullSlots(ymd(_day), widget.city);
    if (!mounted || request != _request) return;
    setState(() {
      _full = full;
      _loading = false;
      final keep = widget.initialSlot;
      final current = _slot ?? (keep == null ? null : Defaults.slots.where((slot) => slot.id == keep).firstOrNull);
      _slot = current != null && _available(current) ? current : null;
    });
    widget.onChanged(ymd(_day), _slot);
  }

  bool _available(Slot slot) => !slot.isPast(_day) && !_full.contains(slot.id);

  void _pickDay(DateTime day) {
    if (ymd(day) == ymd(_day)) return;
    setState(() {
      _day = day;
      _slot = null;
    });
    widget.onChanged(ymd(day), null);
    _load();
  }

  void _pickSlot(Slot slot) {
    setState(() => _slot = slot);
    widget.onChanged(ymd(_day), slot);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SizedBox(
          height: 74,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: _days.length,
            separatorBuilder: (_, __) => const SizedBox(width: 8),
            itemBuilder: (context, index) {
              final day = _days[index];
              final selected = ymd(day) == ymd(_day);
              final closed = _openSlots(day).isEmpty;
              return InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: closed ? null : () => _pickDay(day),
                child: Container(
                  width: 58,
                  decoration: BoxDecoration(
                    color: selected ? AppColors.yellow : (closed ? AppColors.paper : Colors.white),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: selected ? AppColors.yellowDeep : AppColors.line),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(weekday(day),
                          style: AppText.tiny.copyWith(color: closed ? AppColors.faint : AppColors.inkSoft)),
                      Text('${day.day}', style: AppText.h3.copyWith(color: closed ? AppColors.faint : AppColors.ink)),
                      Text(month(day),
                          style: AppText.tiny.copyWith(color: closed ? AppColors.faint : AppColors.inkSoft)),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 14),
        if (_loading)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 22),
            child: Center(child: SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2.2))),
          )
        else
          GridView.count(
            padding: EdgeInsets.zero,
            crossAxisCount: 3,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 8,
            crossAxisSpacing: 8,
            childAspectRatio: 2.3,
            children: [
              for (final slot in Defaults.slots) _slotChip(slot),
            ],
          ),
        if (!_loading && Defaults.slots.every((slot) => !_available(slot)))
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text('No slots left on this day. Pick another day.',
                style: AppText.small.copyWith(color: AppColors.red)),
          ),
      ],
    );
  }

  Widget _slotChip(Slot slot) {
    final past = slot.isPast(_day);
    final full = _full.contains(slot.id);
    final enabled = !past && !full;
    final selected = _slot?.id == slot.id;
    return InkWell(
      borderRadius: BorderRadius.circular(10),
      onTap: enabled ? () => _pickSlot(slot) : null,
      child: Container(
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: selected ? AppColors.ink : (enabled ? Colors.white : AppColors.paper),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: selected ? AppColors.ink : AppColors.line),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              slot.label,
              style: AppText.smallStrong.copyWith(
                color: selected ? Colors.white : (enabled ? AppColors.ink : AppColors.faint),
              ),
            ),
            if (!enabled)
              Text(full ? 'Full' : 'Closed', style: AppText.tiny.copyWith(color: AppColors.faint, fontSize: 10)),
          ],
        ),
      ),
    );
  }
}
