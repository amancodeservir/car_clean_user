import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../config.dart';
import '../../data/defaults.dart' show Slot;
import '../../models/address.dart';
import '../../models/vehicle.dart';
import '../../providers/account_provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/bookings_provider.dart';
import '../../providers/catalog_provider.dart';
import '../../services/api.dart';
import '../../theme.dart';
import '../../widgets/address_sheets.dart';
import '../../widgets/slot_picker.dart';
import '../../widgets/ui.dart';
import '../../widgets/vehicle_sheets.dart';

class BookingScreen extends StatefulWidget {
  const BookingScreen({super.key, required this.service});

  final String service;

  @override
  State<BookingScreen> createState() => _BookingScreenState();
}

class _BookingScreenState extends State<BookingScreen> {
  final _promo = TextEditingController();
  final _notes = TextEditingController();
  final _phone = TextEditingController();

  late String _service = widget.service;
  String _date = '';
  Slot? _slot;
  final Set<String> _addons = {};
  String _appliedPromo = '';
  bool _water = false;
  bool _usePlan = false;
  bool _useCredit = false;
  bool _payOnline = false;

  Quote? _quote;
  String? _quoteError;
  bool _quoting = false;
  bool _submitting = false;
  Timer? _debounce;
  int _quoteRequest = 0;

  @override
  void initState() {
    super.initState();
    final catalog = context.read<CatalogProvider>();
    if (catalog.service(_service) == null) _service = 'Basic Wash';
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AccountProvider>().refreshPlan();
      _requote();
    });
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _promo.dispose();
    _notes.dispose();
    _phone.dispose();
    super.dispose();
  }

  Vehicle? get _vehicle => context.read<AccountProvider>().vehicle;
  SavedAddress? get _address => context.read<AccountProvider>().defaultAddress;
  String get _city => _address?.city ?? context.read<CatalogProvider>().city;

  NewBooking _draft() {
    final user = context.read<AuthProvider>().user!;
    final vehicle = _vehicle!;
    final address = _address;
    final phone = user.phone.replaceAll(RegExp(r'\D'), '');
    return NewBooking(
      service: _service,
      vehicleName: vehicle.plate.isEmpty ? vehicle.name : '${vehicle.name} (${vehicle.plate})',
      category: vehicle.category,
      city: _city,
      address: address?.address ?? '',
      latitude: address?.latitude,
      longitude: address?.longitude,
      date: _date,
      slotId: _slot?.id ?? '',
      name: user.name,
      mobile: phone.length >= 10 ? phone.substring(phone.length - 10) : _phone.text.trim(),
      instructions: _notes.text.trim(),
      addons: _addons.toList(),
      promoCode: _appliedPromo,
      usePlan: _usePlan,
      useCredit: _useCredit,
      providesWaterElectricity: _water,
      payOnline: _payOnline,
    );
  }

  void _requote() {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 350), _fetchQuote);
  }

  Future<void> _fetchQuote() async {
    if (!mounted || _vehicle == null) return;
    final request = ++_quoteRequest;
    setState(() => _quoting = true);
    try {
      final quote = await context.read<BookingsProvider>().quote(_draft());
      if (!mounted || request != _quoteRequest) return;
      setState(() {
        _quote = quote;
        _quoteError = null;
      });
    } catch (error) {
      if (!mounted || request != _quoteRequest) return;
      final text = errorText(error);
      setState(() {
        _quote = null;
        _quoteError = text;
      });
      if (_appliedPromo.isNotEmpty && text.toLowerCase().contains('promo')) {
        showMessage(context, text);
        setState(() => _appliedPromo = '');
        _requote();
      } else if (_usePlan && text.toLowerCase().contains('plan')) {
        showMessage(context, text);
        setState(() => _usePlan = false);
        _requote();
      }
    } finally {
      if (mounted && request == _quoteRequest) setState(() => _quoting = false);
    }
  }

  String? _problem() {
    if (_vehicle == null) return 'Add your vehicle';
    if (_address == null) return 'Add the address where the vehicle is parked';
    if (_date.isEmpty || _slot == null) return 'Pick a date and time slot';
    final user = context.read<AuthProvider>().user;
    final saved = (user?.phone ?? '').replaceAll(RegExp(r'\D'), '');
    if (saved.length < 10 && _phone.text.trim().length != 10) return 'Enter your 10 digit mobile number';
    if (_quoteError != null) return _quoteError;
    if (_quote == null) return 'Getting the price…';
    return null;
  }

  Future<void> _confirm() async {
    final problem = _problem();
    if (problem != null) {
      showMessage(context, problem);
      return;
    }
    setState(() => _submitting = true);
    final auth = context.read<AuthProvider>();
    final bookings = context.read<BookingsProvider>();
    final account = context.read<AccountProvider>();
    try {
      final user = auth.user!;
      if (user.phone.replaceAll(RegExp(r'\D'), '').length < 10) {
        await auth.updateProfile(name: user.name, phone: _phone.text.trim());
      }
      final saved = await bookings.create(_draft());
      account.refreshPlan();
      if (!mounted) return;
      // The confirmed screen opens the payment page for an online booking.
      context.pushReplacement('/booking/${saved.id}/confirmed${_payOnline ? '?pay=1' : ''}');
    } catch (error) {
      if (!mounted) return;
      showMessage(context, errorText(error));
      setState(() => _submitting = false);
      _requote();
    }
  }

  @override
  Widget build(BuildContext context) {
    final catalog = context.watch<CatalogProvider>();
    final account = context.watch<AccountProvider>();
    final user = context.watch<AuthProvider>().user;
    final info = catalog.service(_service);
    final vehicle = account.vehicle;
    final address = account.defaultAddress;
    final plan = account.plan;
    final planCovers = plan.isActive &&
        catalog.plans.any((row) => row.name == plan.planName && (row.service.isEmpty || row.service == _service));
    final needsPhone = (user?.phone ?? '').replaceAll(RegExp(r'\D'), '').length < 10;

    return PopScope(
      canPop: !_submitting,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Checkout'),
          // Opened straight after sign-in there is nothing to pop back to.
          leading: context.canPop()
              ? null
              : IconButton(onPressed: () => context.go('/home'), icon: const Icon(Icons.arrow_back_rounded)),
        ),
        body: ListView(
          padding: const EdgeInsets.fromLTRB(16, 6, 16, 24),
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          children: [
            // Service
            AppCard(
              child: Row(
                children: [
                  Photo(Photos.forService(_service), width: 64, height: 64),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(info?.title ?? _service, style: AppText.h3),
                        if (info != null && info.durationLabel.isNotEmpty)
                          Text('About ${info.durationLabel}', style: AppText.small),
                        const SizedBox(height: 4),
                        if (vehicle != null) PriceLine(catalog.price(_service, vehicle.category)),
                      ],
                    ),
                  ),
                  TextButton(onPressed: _changeService, child: const Text('Change')),
                ],
              ),
            ),
            const SizedBox(height: 18),
            const _Step('1', 'Vehicle'),
            _PickRow(
              icon: vehicleIcon(vehicle),
              title: vehicle?.name ?? 'Add your vehicle',
              subtitle: vehicle == null
                  ? 'Price depends on the size'
                  : [vehicle.sizeLabel, if (vehicle.plate.isNotEmpty) vehicle.plate].join(' · '),
              missing: vehicle == null,
              onTap: () async {
                final Vehicle? picked;
                if (vehicle == null) {
                  picked = await addVehicle(context);
                } else {
                  picked = await pickVehicle(context);
                }
                if (picked != null) _requote();
              },
            ),
            const SizedBox(height: 18),
            const _Step('2', 'Address'),
            _PickRow(
              icon: addressIcon(address?.label ?? ''),
              title: address == null ? 'Add the parking address' : address.label,
              subtitle: address == null ? 'Home, office or society parking' : '${address.address}, ${address.city}',
              missing: address == null,
              onTap: () async {
                final SavedAddress? picked;
                if (address == null) {
                  picked = await addAddress(context);
                } else {
                  picked = await pickAddress(context);
                }
                if (picked != null) _requote();
              },
            ),
            const SizedBox(height: 18),
            const _Step('3', 'Date and time'),
            SlotPicker(
              city: _city,
              onChanged: (date, slot) {
                setState(() {
                  _date = date;
                  _slot = slot;
                });
              },
            ),
            const SizedBox(height: 20),
            if (catalog.addons.isNotEmpty) ...[
              Text('Add-ons', style: AppText.h3),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final addon in catalog.addons)
                    FilterChip(
                      label: Text('${addon.name}  +${rupees(addon.amount)}'),
                      selected: _addons.contains(addon.name),
                      selectedColor: AppColors.yellowSoft,
                      avatar: Icon(_addons.contains(addon.name) ? Icons.check_rounded : Icons.add_rounded, size: 16),
                      onSelected: (selected) {
                        setState(() => selected ? _addons.add(addon.name) : _addons.remove(addon.name));
                        _requote();
                      },
                    ),
                ],
              ),
              const SizedBox(height: 18),
            ],
            Text('Offers and savings', style: AppText.h3),
            const SizedBox(height: 8),
            _PromoField(
              controller: _promo,
              applied: _appliedPromo,
              onApply: () {
                final code = _promo.text.trim().toUpperCase();
                if (code.isEmpty) return;
                setState(() => _appliedPromo = code);
                _requote();
              },
              onRemove: () {
                setState(() {
                  _appliedPromo = '';
                  _promo.clear();
                });
                _requote();
              },
            ),
            const SizedBox(height: 8),
            _ToggleTile(
              icon: Icons.water_drop_outlined,
              title: 'I will provide water and power',
              subtitle: 'Save ₹100 when the washer can use your tap and socket',
              value: _water,
              onChanged: (value) {
                setState(() => _water = value);
                _requote();
              },
            ),
            if (planCovers)
              _ToggleTile(
                icon: Icons.workspace_premium_outlined,
                title: 'Use a plan wash',
                subtitle: '${plan.washesLeft} left on ${plan.planName}',
                value: _usePlan,
                onChanged: (value) {
                  setState(() => _usePlan = value);
                  _requote();
                },
              ),
            if (plan.credit > 0)
              _ToggleTile(
                icon: Icons.card_giftcard_outlined,
                title: 'Use referral credit',
                subtitle: '${rupees(plan.credit)} available',
                value: _useCredit,
                onChanged: (value) {
                  setState(() => _useCredit = value);
                  _requote();
                },
              ),
            const SizedBox(height: 18),
            Text('Payment', style: AppText.h3),
            const SizedBox(height: 8),
            _PayOption(
              icon: Icons.payments_outlined,
              title: 'Pay after service',
              subtitle: 'Cash or UPI to the washer',
              selected: !_payOnline,
              onTap: () => setState(() => _payOnline = false),
            ),
            const SizedBox(height: 8),
            _PayOption(
              icon: Icons.credit_card_rounded,
              title: 'Pay online now',
              subtitle: 'UPI, card or net banking on a secure page',
              selected: _payOnline,
              onTap: () => setState(() => _payOnline = true),
            ),
            const SizedBox(height: 18),
            if (needsPhone) ...[
              TextField(
                controller: _phone,
                keyboardType: TextInputType.phone,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(10)],
                decoration: const InputDecoration(
                  labelText: 'Mobile number for the washer',
                  prefixIcon: Icon(Icons.phone_outlined, size: 20),
                ),
              ),
              const SizedBox(height: 12),
            ],
            TextField(
              controller: _notes,
              minLines: 2,
              maxLines: 3,
              maxLength: 300,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(
                labelText: 'Notes for the washer (optional)',
                hintText: 'Parking spot, gate code, car colour…',
                alignLabelWithHint: true,
              ),
            ),
            const SizedBox(height: 8),
            _Bill(quote: _quote, error: _quoteError, loading: _quoting, hasVehicle: vehicle != null),
          ],
        ),
        bottomNavigationBar: DecoratedBox(
          decoration: const BoxDecoration(
            color: Colors.white,
            border: Border(top: BorderSide(color: AppColors.line)),
          ),
          child: SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(18, 10, 16, 10),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('To pay', style: AppText.small),
                        Text(_quote == null ? '—' : rupees(_quote!.total), style: AppText.h2),
                      ],
                    ),
                  ),
                  SizedBox(
                    width: 190,
                    child: PrimaryButton(
                      label: _payOnline ? 'Book & pay' : 'Confirm booking',
                      loading: _submitting,
                      onPressed: _quoting ? null : _confirm,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _changeService() async {
    final catalog = context.read<CatalogProvider>();
    final vehicle = _vehicle;
    final picked = await showModalBottomSheet<String>(
      context: context,
      builder: (context) => SafeArea(
        child: ListView(
          shrinkWrap: true,
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
          children: [
            Text('Choose a service', style: AppText.h2),
            const SizedBox(height: 8),
            for (final service in catalog.services)
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Photo(Photos.forService(service.name), width: 48, height: 48, radius: 10),
                title: Text(service.title, style: AppText.title),
                subtitle: Text(service.tagline, style: AppText.small),
                trailing: Text(
                  rupees((vehicle == null ? catalog.startingPrice(service.name) : catalog.price(service.name, vehicle.category)).amount),
                  style: AppText.bodyStrong,
                ),
                selected: service.name == _service,
                onTap: () => Navigator.pop(context, service.name),
              ),
          ],
        ),
      ),
    );
    if (picked == null || picked == _service) return;
    setState(() {
      _service = picked;
      _usePlan = false;
    });
    _requote();
  }
}

class _Step extends StatelessWidget {
  const _Step(this.number, this.title);

  final String number;
  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Container(
            width: 22,
            height: 22,
            alignment: Alignment.center,
            decoration: const BoxDecoration(color: AppColors.ink, shape: BoxShape.circle),
            child: Text(number, style: AppText.tiny.copyWith(color: Colors.white)),
          ),
          const SizedBox(width: 8),
          Text(title, style: AppText.h3),
        ],
      ),
    );
  }
}

class _PickRow extends StatelessWidget {
  const _PickRow({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.missing = false,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final bool missing;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      onTap: onTap,
      color: missing ? AppColors.yellowWash : null,
      child: Row(
        children: [
          Icon(icon, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: AppText.title),
                const SizedBox(height: 2),
                Text(subtitle, style: AppText.small, maxLines: 2, overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
          Text(missing ? 'Add' : 'Change', style: AppText.smallStrong.copyWith(color: AppColors.navy)),
        ],
      ),
    );
  }
}

class _PromoField extends StatelessWidget {
  const _PromoField({required this.controller, required this.applied, required this.onApply, required this.onRemove});

  final TextEditingController controller;
  final String applied;
  final VoidCallback onApply;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    if (applied.isNotEmpty) {
      return AppCard(
        color: AppColors.greenSoft,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        child: Row(
          children: [
            const Icon(Icons.local_offer_rounded, color: AppColors.green, size: 20),
            const SizedBox(width: 10),
            Expanded(child: Text('$applied applied', style: AppText.smallStrong.copyWith(color: AppColors.green))),
            TextButton(onPressed: onRemove, child: const Text('Remove')),
          ],
        ),
      );
    }
    return Row(
      children: [
        Expanded(
          child: TextField(
            controller: controller,
            textCapitalization: TextCapitalization.characters,
            onSubmitted: (_) => onApply(),
            decoration: const InputDecoration(
              hintText: 'Coupon code',
              prefixIcon: Icon(Icons.local_offer_outlined, size: 20),
            ),
          ),
        ),
        const SizedBox(width: 8),
        OutlinedButton(onPressed: onApply, child: const Text('Apply')),
      ],
    );
  }
}

class _ToggleTile extends StatelessWidget {
  const _ToggleTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: AppCard(
        padding: const EdgeInsets.fromLTRB(14, 6, 6, 6),
        onTap: () => onChanged(!value),
        child: Row(
          children: [
            Icon(icon, size: 22),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: AppText.title),
                  Text(subtitle, style: AppText.small),
                ],
              ),
            ),
            Switch(value: value, onChanged: onChanged),
          ],
        ),
      ),
    );
  }
}

class _PayOption extends StatelessWidget {
  const _PayOption({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      onTap: onTap,
      color: selected ? AppColors.yellowWash : null,
      child: Row(
        children: [
          Icon(icon, size: 22),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: AppText.title),
                Text(subtitle, style: AppText.small),
              ],
            ),
          ),
          Icon(
            selected ? Icons.radio_button_checked_rounded : Icons.radio_button_off_rounded,
            color: selected ? AppColors.ink : AppColors.faint,
          ),
        ],
      ),
    );
  }
}

class _Bill extends StatelessWidget {
  const _Bill({required this.quote, required this.error, required this.loading, required this.hasVehicle});

  final Quote? quote;
  final String? error;
  final bool loading;
  final bool hasVehicle;

  @override
  Widget build(BuildContext context) {
    final current = quote;
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Text('Bill details', style: AppText.h3),
              const Spacer(),
              if (loading) const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)),
            ],
          ),
          const SizedBox(height: 12),
          if (!hasVehicle)
            Text('Add your vehicle to see the price.', style: AppText.small)
          else if (error != null)
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.info_outline_rounded, color: AppColors.red, size: 18),
                const SizedBox(width: 8),
                Expanded(child: Text(error!, style: AppText.small.copyWith(color: AppColors.red))),
              ],
            )
          else if (current == null)
            Text('Working out the price…', style: AppText.small)
          else ...[
            _line('Service', rupees(current.base)),
            for (final addon in current.addons) _line(addon.name, rupees(addon.price)),
            if (current.waterDiscount > 0) _line('Water and power discount', '-${rupees(current.waterDiscount)}', green: true),
            if (current.discount - current.waterDiscount > 0)
              _line(current.planUsed ? 'Plan wash and coupon' : 'Coupon discount', '-${rupees(current.discount - current.waterDiscount)}', green: true),
            if (current.travelFee > 0) _line('Travel fee', rupees(current.travelFee)),
            if (current.creditUsed > 0) _line('Referral credit', '-${rupees(current.creditUsed)}', green: true),
            const Padding(padding: EdgeInsets.symmetric(vertical: 8), child: Divider()),
            _line('To pay', rupees(current.total), strong: true),
            const SizedBox(height: 4),
            Text('Prices include GST.', style: AppText.tiny),
          ],
        ],
      ),
    );
  }

  Widget _line(String label, String value, {bool strong = false, bool green = false}) {
    final style = strong ? AppText.h3 : AppText.body;
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          Expanded(child: Text(label, style: style)),
          Text(value, style: style.copyWith(color: green ? AppColors.green : null, fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }
}
