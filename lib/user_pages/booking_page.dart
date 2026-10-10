import 'package:car_clean_user/data/service_catalog.dart';
import 'package:car_clean_user/providers/app_provider.dart';
import 'package:car_clean_user/providers/auth_provider.dart';
import 'package:car_clean_user/services/api_service.dart';
import 'package:car_clean_user/theme/brand_theme.dart';
import 'package:car_clean_user/utils/constants.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

const _radius = BorderRadius.all(Radius.circular(16));

const _weekdays = <String>['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
const _months = <String>[
  'Jan',
  'Feb',
  'Mar',
  'Apr',
  'May',
  'Jun',
  'Jul',
  'Aug',
  'Sep',
  'Oct',
  'Nov',
  'Dec',
];

String _ymd(DateTime date) {
  final month = date.month.toString().padLeft(2, '0');
  final day = date.day.toString().padLeft(2, '0');
  return '${date.year}-$month-$day';
}

IconData _serviceIcon(String name) {
  switch (name) {
    case 'Basic Wash':
      return Icons.local_car_wash_outlined;
    case 'Premium Wash':
      return Icons.auto_awesome_outlined;
    case 'Complete Clean':
      return Icons.cleaning_services_outlined;
    case 'Festive Offer':
      return Icons.celebration_outlined;
    case 'Waterless Wash':
      return Icons.water_drop_outlined;
    default:
      return Icons.local_car_wash_outlined;
  }
}

IconData _addonIcon(String name) {
  switch (name) {
    case 'Wax':
      return Icons.auto_awesome_outlined;
    case 'Interior':
      return Icons.weekend_outlined;
    case 'Engine bay':
      return Icons.settings_outlined;
    default:
      return Icons.add_outlined;
  }
}

class BookingPage extends StatefulWidget {
  final String? initialService;
  final String vehicleType;

  const BookingPage({
    super.key,
    this.initialService,
    this.vehicleType = 'CAR',
  });

  @override
  State<BookingPage> createState() => _BookingPageState();
}

class _BookingPageState extends State<BookingPage> {
  final _addressController = TextEditingController();
  final _searchController = TextEditingController();
  final _vehicleNameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _instructionsController = TextEditingController();

  late final List<DateTime> _dates;
  late String _service;

  int _step = 0;
  CarModelOption? _model;
  bool _isOther = false;
  String _otherCategory = '';
  String? _selectedYmd;
  TimeSlot? _slot;
  List<String> _booked = const [];
  bool _slotsLoading = false;
  bool _submitting = false;
  bool _success = false;
  bool _addressSeeded = false;
  int _slotRequest = 0;

  bool get _isBike => widget.vehicleType == 'BIKE';

  String get _vehicleName {
    if (_isBike || _isOther) return _vehicleNameController.text.trim();
    return _model?.name ?? '';
  }

  String get _category {
    if (_isBike) return 'Bike';
    if (_isOther) return _otherCategory;
    return _model?.category ?? '';
  }

  int get _price {
    final category = _category;
    if (_service.isEmpty || category.isEmpty) return 0;
    if (_quoted != null) return _quoted!;
    final base = context.read<AppProvider>().priceFor(category: category, service: _service);
    var extra = 0;
    for (final name in _addons) {
      final addonPrice = context.read<AppProvider>().addonPrice(name);
      extra += addonPrice == 0 ? _addonFallback(name) : addonPrice;
    }
    return base + extra;
  }

  final Set<String> _addons = {};
  String _paymentMethod = 'Cash';
  final _promoController = TextEditingController();
  bool _usePlan = false;
  bool _useCredit = false;
  double? _latitude;
  double? _longitude;
  int? _quoted;

  int _addonFallback(String name) {
    switch (name) {
      case 'Wax':
        return 149;
      case 'Interior':
        return 199;
      case 'Engine bay':
        return 249;
      default:
        return 0;
    }
  }

  @override
  void initState() {
    super.initState();
    const names = ServiceCatalog.serviceNames;
    final initial = widget.initialService;
    if (initial != null && names.contains(initial)) {
      _service = initial;
    } else if (names.contains('Basic Wash')) {
      _service = 'Basic Wash';
    } else {
      _service = names.isEmpty ? 'Basic Wash' : names.first;
    }

    if (_isBike) _vehicleNameController.text = 'Bike';

    final today = DateTime.now();
    final start = DateTime(today.year, today.month, today.day);
    final dates = <DateTime>[];
    for (var i = 0; i < 14; i++) {
      final day = start.add(Duration(days: i));
      if (day.weekday == DateTime.sunday) continue;
      dates.add(day);
    }
    _dates = dates;
    if (_dates.isNotEmpty) {
      _selectedYmd = _ymd(_dates.first);
      _slotsLoading = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final ymd = _selectedYmd;
        if (!mounted || ymd == null) return;
        _fetchSlots(ymd);
      });
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_addressSeeded) return;
    final app = Provider.of<AppProvider>(context);
    if (!app.isReady && app.address.isEmpty) return;
    _addressSeeded = true;
    if (_addressController.text.isEmpty && app.address.isNotEmpty) {
      _addressController.text = app.address;
    }
  }

  @override
  void dispose() {
    _addressController.dispose();
    _searchController.dispose();
    _vehicleNameController.dispose();
    _phoneController.dispose();
    _instructionsController.dispose();
    _promoController.dispose();
    super.dispose();
  }

  Future<void> _fetchSlots(String ymd) async {
    final request = ++_slotRequest;
    if (!mounted) return;
    setState(() {
      _slotsLoading = true;
      _booked = const [];
    });
    try {
      final booked = await ApiService.getBookedSlots(
        ymd,
        city: context.read<AppProvider>().city,
      );
      if (!mounted || request != _slotRequest) return;
      setState(() {
        _booked = booked;
        _slotsLoading = false;
        final slot = _slot;
        if (slot != null &&
            (ServiceCatalog.isSlotPast(ymd, slot) ||
                ServiceCatalog.isSlotBooked(slot, booked))) {
          _slot = null;
        }
      });
    } catch (error) {
      if (!mounted || request != _slotRequest) return;
      setState(() {
        _booked = const [];
        _slotsLoading = false;
      });
      _showSnack(_errorMessage(error));
    }
  }

  void _selectDate(String ymd) {
    if (_selectedYmd == ymd || _submitting) return;
    setState(() {
      _selectedYmd = ymd;
      _slot = null;
    });
    _fetchSlots(ymd);
  }

  String? _validateStep(int step) {
    switch (step) {
      case 0:
        if (_service.isEmpty) return 'Select a service';
        return null;
      case 1:
        if (_vehicleName.isEmpty) return 'Enter the vehicle name';
        if (_category.isEmpty) return 'Select a vehicle category';
        return null;
      case 2:
        if (_addressController.text.trim().isEmpty) return 'Enter your address';
        if (context.read<AppProvider>().city.trim().isEmpty) {
          return 'Set your city on the home screen';
        }
        final ymd = _selectedYmd;
        final slot = _slot;
        if (ymd == null) return 'Select a date';
        if (slot == null) return 'Select a time slot';
        if (ServiceCatalog.isSlotPast(ymd, slot) ||
            ServiceCatalog.isSlotBooked(slot, _booked)) {
          return 'That time slot is no longer available';
        }
        return null;
      default:
        return null;
    }
  }

  void _goNext() {
    final message = _validateStep(_step);
    if (message != null) {
      _showSnack(message);
      return;
    }
    setState(() => _step += 1);
    if (_step == 3) _refreshQuote();
  }

  Future<void> _refreshQuote() async {
    final token = context.read<AuthProvider>().user?.token;
    try {
      final response = await ApiService.sendJson('POST', AppConstants.quote, token, {
        'category': _category,
        'service': _service,
        'addons': _addons.toList(),
        'city': context.read<AppProvider>().city,
        'promoCode': _promoController.text.trim(),
        'usePlan': _usePlan,
        'useCredit': _useCredit,
        if (_latitude != null) 'latitude': _latitude,
        if (_longitude != null) 'longitude': _longitude,
      });
      final data = response['data'];
      if (!mounted || data is! Map) return;
      final total = data['total'];
      setState(() {
        _quoted = total is num ? total.round() : int.tryParse('$total');
      });
    } catch (error) {
      if (!mounted) return;
      setState(() => _quoted = null);
      _showSnack(_errorMessage(error));
    }
  }

  Future<void> _confirm() async {
    if (_submitting) return;
    if (_price == 0) {
      _showSnack('Price is unavailable for this vehicle');
      return;
    }
    final invalid = _validateStep(2);
    if (invalid != null) {
      _showSnack(invalid);
      return;
    }

    final user = context.read<AuthProvider>().user;
    final fullName = (user?.name ?? '').trim();
    var mobile = (user?.phone ?? '').trim();
    if (mobile.isEmpty) {
      mobile = _phoneController.text.trim();
      if (mobile.isEmpty) {
        _showSnack('Enter your mobile number');
        return;
      }
    }

    final city = context.read<AppProvider>().city.trim();
    final address = _addressController.text.trim();
    final ymd = _selectedYmd!;
    final slot = _slot!;
    final price = _price;
    final vehicleName = _vehicleName;
    final category = _category;
    final instructions = _instructionsController.text.trim();

    setState(() => _submitting = true);
    try {
      final token = context.read<AuthProvider>().user?.token;
      final leadId = await ApiService.createLead(
        mobile: mobile,
        name: fullName,
        token: token,
      );
      final saved = await ApiService.finalizeBooking(
        leadId: leadId,
        service: _service,
        vehicleName: vehicleName,
        category: category,
        city: city,
        address: address,
        date: ymd,
        timeSlot: slot.id,
        fullName: fullName,
        mobile: mobile,
        instructions: instructions,
        price: price,
        token: token,
        paymentMethod: _paymentMethod,
        addons: _addons.toList(),
        promoCode: _promoController.text.trim(),
        usePlan: _usePlan,
        useCredit: _useCredit,
        latitude: _latitude,
        longitude: _longitude,
      );
      if (!mounted) return;
      final app = context.read<AppProvider>();
      await app.addOrder(saved);
      if (!mounted) return;
      await app.setAddress(address);
      await app.syncOrders(token);
      if (saved.paymentUrl.isNotEmpty) {
        final uri = Uri.tryParse(saved.paymentUrl);
        if (uri != null) {
          await launchUrl(uri, mode: LaunchMode.externalApplication);
        }
      }
      if (!mounted) return;
      setState(() => _success = true);
      await Future<void>.delayed(const Duration(milliseconds: 900));
      if (!mounted) return;
      context.pop(true);
    } catch (error) {
      if (!mounted) return;
      setState(() => _submitting = false);
      _showSnack(_errorMessage(error));
    }
  }

  Future<void> _pinAddress() async {
    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      _showSnack('Location permission is needed to check the service area');
      return;
    }
    final position = await Geolocator.getCurrentPosition();
    if (!mounted) return;
    setState(() {
      _latitude = position.latitude;
      _longitude = position.longitude;
      _quoted = null;
    });
    _showSnack('Pin saved. Travel fee is added if this spot is outside the free radius.');
  }

  void _showSnack(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: const TextStyle(color: Colors.white)),
      ),
    );
  }

  String _errorMessage(Object error) {
    var text = error.toString().trim();
    const prefix = 'Exception: ';
    if (text.startsWith(prefix)) {
      text = text.substring(prefix.length).trim();
    }
    if (text.isEmpty) return 'Something went wrong';
    return text;
  }

  @override
  Widget build(BuildContext context) {
    final city = context.watch<AppProvider>().city;
    final savedPhone = (context.watch<AuthProvider>().user?.phone ?? '').trim();
    final needsPhone = savedPhone.isEmpty;

    return PopScope(
      canPop: !_submitting && !_success,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Book a wash'),
        ),
        body: _success
            ? const _BookingSuccess()
            : Column(
                children: [
                  _stepIndicator(),
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                      keyboardDismissBehavior:
                          ScrollViewKeyboardDismissBehavior.onDrag,
                      child: _stepBody(city, needsPhone),
                    ),
                  ),
                  _bottomBar(),
                ],
              ),
      ),
    );
  }

  Widget _stepBody(String city, bool needsPhone) {
    switch (_step) {
      case 0:
        return _serviceStep();
      case 1:
        return _vehicleStep();
      case 2:
        return _scheduleStep(city);
      default:
        return _reviewStep(city, needsPhone);
    }
  }

  Widget _stepIndicator() {
    final steps = <(IconData, String)>[
      (Icons.local_car_wash_outlined, 'Service'),
      (_isBike ? Icons.two_wheeler_outlined : Icons.directions_car_outlined, 'Vehicle'),
      (Icons.calendar_today_outlined, 'Schedule'),
      (Icons.fact_check_outlined, 'Review'),
    ];
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 12, 8, 4),
      child: Row(
        children: [
          for (var i = 0; i < steps.length; i++)
            Expanded(
              child: Column(
                children: [
                  BrandIconWell(
                    icon: steps[i].$1,
                    box: 36,
                    iconSize: 20,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    steps[i].$2,
                    textAlign: TextAlign.center,
                    style: AppType.label.copyWith(
                      color: i == _step ? AppConstants.ink : AppConstants.mute,
                      fontWeight: i == _step ? FontWeight.w700 : FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _serviceStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        BrandPhoto(asset: AppConstants.photoForService(_service), height: 140),
        const SizedBox(height: 16),
        const _Heading('Choose a service'),
        for (final name in ServiceCatalog.serviceNames)
          _SelectTile(
            icon: _serviceIcon(name),
            title: name,
            selected: _service == name,
            onTap: () => setState(() => _service = name),
          ),
        if (_category.isNotEmpty) ...[
          const SizedBox(height: 8),
          _priceBanner(),
        ],
      ],
    );
  }

  Widget _vehicleStep() {
    if (_isBike) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const _Heading('Your vehicle'),
          const _FieldLabel(icon: Icons.category_outlined, text: 'Category'),
          const _ReadOnlyBox(icon: Icons.two_wheeler_outlined, text: 'Bike'),
          const SizedBox(height: 16),
          const _FieldLabel(icon: Icons.edit_outlined, text: 'Vehicle name'),
          TextField(
            controller: _vehicleNameController,
            style: const TextStyle(color: AppConstants.ink),
            textCapitalization: TextCapitalization.words,
            decoration: _fieldDecoration('Vehicle name', icon: Icons.two_wheeler_outlined),
          ),
          const SizedBox(height: 16),
          _priceBanner(),
        ],
      );
    }

    final query = _searchController.text.trim().toLowerCase();
    final models = ServiceCatalog.carModels.where((model) {
      if (query.isEmpty) return true;
      return model.name.toLowerCase().contains(query) ||
          model.category.toLowerCase().contains(query);
    }).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const _Heading('Your vehicle'),
        TextField(
          controller: _searchController,
          style: const TextStyle(color: AppConstants.ink),
          decoration: _fieldDecoration('Search car model', icon: Icons.search),
          onChanged: (_) => setState(() {}),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 280,
          child: models.isEmpty
              ? const Center(
                  child: Text(
                    'No models match',
                    style: TextStyle(color: AppConstants.mute),
                  ),
                )
              : ListView.builder(
                  itemCount: models.length,
                  itemBuilder: (context, index) {
                    final model = models[index];
                    final selected = !_isOther &&
                        _model?.name == model.name &&
                        _model?.category == model.category;
                    return _SelectTile(
                      icon: Icons.directions_car_outlined,
                      title: model.name,
                      subtitle: model.category,
                      selected: selected,
                      onTap: () => setState(() {
                        _isOther = false;
                        _model = model;
                      }),
                    );
                  },
                ),
        ),
        _SelectTile(
          icon: Icons.edit_outlined,
          title: 'Other',
          subtitle: 'Custom name and category',
          selected: _isOther,
          onTap: () {
            setState(() {
              _isOther = true;
              _model = null;
              if (_otherCategory.isEmpty &&
                  ServiceCatalog.carCategories.isNotEmpty) {
                _otherCategory = ServiceCatalog.carCategories.first;
              }
            });
          },
        ),
        if (_isOther) ...[
          const _FieldLabel(icon: Icons.edit_outlined, text: 'Vehicle name'),
          TextField(
            controller: _vehicleNameController,
            style: const TextStyle(color: AppConstants.ink),
            textCapitalization: TextCapitalization.words,
            decoration: _fieldDecoration('Vehicle name', icon: Icons.directions_car_outlined),
          ),
          const SizedBox(height: 12),
          const _FieldLabel(icon: Icons.category_outlined, text: 'Category'),
          _categoryDropdown(),
        ],
        const SizedBox(height: 8),
        _priceBanner(),
      ],
    );
  }

  Widget _categoryDropdown() {
    const categories = ServiceCatalog.carCategories;
    final value = categories.contains(_otherCategory) ? _otherCategory : null;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: _radius,
        border: Border.all(color: AppConstants.line),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          isExpanded: true,
          value: value,
          hint: const Text('Category', style: TextStyle(color: AppConstants.mute)),
          icon: const Icon(
            Icons.keyboard_arrow_down_outlined,
            color: AppConstants.signal,
            size: 22,
          ),
          items: [
            for (final category in categories)
              DropdownMenuItem<String>(
                value: category,
                child: Text(
                  category,
                  style: const TextStyle(color: AppConstants.ink),
                ),
              ),
          ],
          onChanged: (selected) {
            if (selected == null) return;
            setState(() => _otherCategory = selected);
          },
        ),
      ),
    );
  }

  Widget _scheduleStep(String city) {
    final cityText = city.trim();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const _FieldLabel(icon: Icons.location_on_outlined, text: 'Where'),
        _placeCard(cityText),
        const SizedBox(height: 18),
        const _FieldLabel(icon: Icons.calendar_today_outlined, text: 'Date'),
        SizedBox(
          height: 76,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: _dates.length,
            separatorBuilder: (context, index) => const SizedBox(width: 8),
            itemBuilder: (context, index) {
              final date = _dates[index];
              final ymd = _ymd(date);
              return _DateChip(
                date: date,
                selected: ymd == _selectedYmd,
                onTap: () => _selectDate(ymd),
              );
            },
          ),
        ),
        const SizedBox(height: 16),
        const _FieldLabel(icon: Icons.schedule_outlined, text: 'Time'),
        _timeSlots(),
        const SizedBox(height: 16),
        _priceBanner(),
      ],
    );
  }

  Widget _placeCard(String cityText) {
    final cityLabel = cityText.isEmpty ? 'Set city on home' : cityText;
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 4, 12, 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: _radius,
        border: Border.all(color: AppConstants.line),
      ),
      child: Column(
        children: [
          TextField(
            controller: _addressController,
            style: AppType.item,
            textCapitalization: TextCapitalization.sentences,
            decoration: const InputDecoration(
              hintText: 'Flat, street, or parking spot',
              prefixIcon: Icon(Icons.location_on_outlined, size: 20),
              border: InputBorder.none,
              enabledBorder: InputBorder.none,
              focusedBorder: InputBorder.none,
              contentPadding: EdgeInsets.symmetric(vertical: 12),
            ),
          ),
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Row(
              children: [
                const Icon(Icons.location_city_outlined, size: 20, color: AppConstants.signal),
                const SizedBox(width: 8),
                Text('City', style: AppType.label.copyWith(color: AppConstants.mute)),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    cityLabel,
                    textAlign: TextAlign.end,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppType.item.copyWith(
                      color: cityText.isEmpty ? AppConstants.mute : AppConstants.ink,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
              onPressed: _pinAddress,
              style: TextButton.styleFrom(
                visualDensity: VisualDensity.compact,
                padding: const EdgeInsets.symmetric(horizontal: 4),
              ),
              icon: Icon(
                _latitude == null ? Icons.pin_drop_outlined : Icons.check_circle_outline,
                size: 18,
              ),
              label: Text(
                _latitude == null ? 'Drop a pin at this parking spot' : 'Pin saved',
                style: AppType.label.copyWith(fontWeight: FontWeight.w700),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _timeSlots() {
    final ymd = _selectedYmd;
    if (ymd == null) {
      return const Text(
        'Select a date to see times',
        style: TextStyle(color: AppConstants.mute),
      );
    }
    if (_slotsLoading) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 24),
        child: Center(child: CircularProgressIndicator()),
      );
    }

    final groups = <String, List<TimeSlot>>{};
    for (final slot in ServiceCatalog.timeSlots) {
      (groups[slot.period] ??= <TimeSlot>[]).add(slot);
    }
    if (groups.isEmpty) {
      return const Text('No time slots', style: TextStyle(color: AppConstants.ink));
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final entry in groups.entries) ...[
          if (entry.key.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 4, bottom: 8),
              child: Row(
                children: [
                  Icon(
                    entry.key == 'AM' ? Icons.wb_sunny_outlined : Icons.nights_stay_outlined,
                    size: 20,
                    color: AppConstants.signal,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    entry.key,
                    style: const TextStyle(
                      color: AppConstants.ink,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          _slotGrid(ymd, entry.value),
          const SizedBox(height: 8),
        ],
      ],
    );
  }

  Widget _slotGrid(String ymd, List<TimeSlot> slots) {
    final rows = <Widget>[];
    for (var i = 0; i < slots.length; i += 3) {
      final end = i + 3 > slots.length ? slots.length : i + 3;
      final slice = slots.sublist(i, end);
      rows.add(
        Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Row(
            children: [
              for (var column = 0; column < 3; column++) ...[
                if (column > 0) const SizedBox(width: 8),
                Expanded(
                  child: column < slice.length
                      ? _slotChip(ymd, slice[column])
                      : const SizedBox.shrink(),
                ),
              ],
            ],
          ),
        ),
      );
    }
    return Column(children: rows);
  }

  Widget _slotChip(String ymd, TimeSlot slot) {
    final past = ServiceCatalog.isSlotPast(ymd, slot);
    final booked = ServiceCatalog.isSlotBooked(slot, _booked);
    final blocked = past || booked;
    final selected =
        !blocked && _slot?.id == slot.id && _slot?.timeKey == slot.timeKey;
    final status = past ? 'Past' : (booked ? 'Booked' : null);
    final foreground = selected
        ? Colors.white
        : (blocked ? AppConstants.mute : AppConstants.ink);

    return Material(
      color: selected
          ? AppConstants.signal
          : (blocked ? AppConstants.paper : Colors.white),
      shape: const StadiumBorder(),
      child: InkWell(
        onTap: blocked ? null : () => setState(() => _slot = slot),
        customBorder: const StadiumBorder(),
        child: Container(
          width: double.infinity,
          alignment: Alignment.center,
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 10),
          decoration: ShapeDecoration(
            shape: StadiumBorder(
              side: BorderSide(
                color: selected ? AppConstants.signal : AppConstants.line,
              ),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                slot.label,
                textAlign: TextAlign.center,
                style: AppType.label.copyWith(
                  color: foreground,
                  fontWeight: FontWeight.w700,
                ),
              ),
              if (status != null)
                Text(
                  status,
                  style: AppType.label.copyWith(color: foreground),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _reviewStep(String city, bool needsPhone) {
    final cityText = city.trim();
    final price = _price;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const _Heading('Review'),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BrandTheme.card,
          child: Column(
            children: [
              _SummaryRow(icon: _serviceIcon(_service), label: 'Service', value: _service),
              _SummaryRow(
                icon: _isBike ? Icons.two_wheeler_outlined : Icons.directions_car_outlined,
                label: 'Vehicle',
                value: _vehicleName,
              ),
              _SummaryRow(icon: Icons.category_outlined, label: 'Category', value: _category),
              _SummaryRow(
                icon: Icons.location_city_outlined,
                label: 'City',
                value: cityText.isEmpty ? 'Set city on home' : cityText,
              ),
              _SummaryRow(
                icon: Icons.location_on_outlined,
                label: 'Address',
                value: _addressController.text.trim(),
              ),
              _SummaryRow(icon: Icons.calendar_today_outlined, label: 'Date', value: _selectedYmd ?? ''),
              _SummaryRow(icon: Icons.schedule_outlined, label: 'Time', value: _slot?.label ?? ''),
              _SummaryRow(
                icon: Icons.currency_rupee_outlined,
                label: 'Price',
                value: price == 0 ? '₹0' : '₹$price',
              ),
              _SummaryRow(icon: Icons.payments_outlined, label: 'Payment', value: _paymentMethod),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          children: [
            for (final method in ['Cash', 'UPI', 'Online'])
              ChoiceChip(
                avatar: Icon(
                  method == 'Cash'
                      ? Icons.payments_outlined
                      : method == 'UPI'
                          ? Icons.qr_code_outlined
                          : Icons.credit_card_outlined,
                  size: 20,
                  color: AppConstants.signal,
                ),
                label: Text(method == 'Online' ? 'Card / UPI now' : method),
                selected: _paymentMethod == method,
                showCheckmark: false,
                onSelected: (_) => setState(() => _paymentMethod = method),
              ),
          ],
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          children: [
            for (final addon in context.watch<AppProvider>().addons)
              FilterChip(
                avatar: Icon(_addonIcon(addon), size: 20, color: AppConstants.signal),
                label: Text(addon),
                selected: _addons.contains(addon),
                showCheckmark: false,
                onSelected: (selected) {
                  setState(() {
                    _quoted = null;
                    if (selected) {
                      _addons.add(addon);
                    } else {
                      _addons.remove(addon);
                    }
                  });
                  _refreshQuote();
                },
              ),
          ],
        ),
        TextField(
          controller: _promoController,
          decoration: _fieldDecoration('Promo or referral code', icon: Icons.local_offer_outlined),
          onSubmitted: (_) {
            setState(() => _quoted = null);
            _refreshQuote();
          },
        ),
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          secondary: const Icon(Icons.event_repeat_outlined, size: 22, color: AppConstants.signal),
          title: const Text('Use a wash from my plan'),
          value: _usePlan,
          onChanged: (value) {
            setState(() {
              _usePlan = value;
              _quoted = null;
            });
            _refreshQuote();
          },
        ),
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          secondary: const Icon(Icons.loyalty_outlined, size: 22, color: AppConstants.signal),
          title: const Text('Use referral credit'),
          value: _useCredit,
          onChanged: (value) {
            setState(() {
              _useCredit = value;
              _quoted = null;
            });
            _refreshQuote();
          },
        ),
        const SizedBox(height: 8),
        const _FieldLabel(icon: Icons.notes_outlined, text: 'Instructions'),
        TextField(
          controller: _instructionsController,
          style: const TextStyle(color: AppConstants.ink),
          textCapitalization: TextCapitalization.sentences,
          minLines: 2,
          maxLines: 3,
          decoration: _fieldDecoration('Optional', icon: Icons.edit_outlined),
        ),
        if (needsPhone) ...[
          const SizedBox(height: 16),
          const _FieldLabel(icon: Icons.phone_outlined, text: 'Mobile'),
          TextField(
            controller: _phoneController,
            style: const TextStyle(color: AppConstants.ink),
            keyboardType: TextInputType.phone,
            decoration: _fieldDecoration('Mobile number', icon: Icons.phone_outlined),
          ),
        ],
        if (price == 0) ...[
          const SizedBox(height: 12),
          const Row(
            children: [
              Icon(Icons.info_outline, size: 20, color: AppConstants.signal),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  'This booking cannot be confirmed because the price is ₹0.',
                  style: TextStyle(color: AppConstants.ink),
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }

  Widget _priceBanner() {
    final category = _category;
    if (category.isEmpty) {
      return const Row(
        children: [
          Icon(Icons.currency_rupee_outlined, size: 20, color: AppConstants.mute),
          SizedBox(width: 8),
          Text(
            'Select a vehicle to see the price',
            style: TextStyle(color: AppConstants.mute),
          ),
        ],
      );
    }
    final price = _price;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BrandTheme.card,
      child: Row(
        children: [
          const BrandIconWell(icon: Icons.currency_rupee_outlined, box: 36, iconSize: 20),
          const SizedBox(width: 10),
          const Expanded(
            child: Text(
              'Price',
              style: TextStyle(color: AppConstants.ink, fontWeight: FontWeight.w700),
            ),
          ),
          Text(
            price == 0 ? 'Unavailable' : '₹$price',
            style: AppType.title.copyWith(
              color: AppConstants.signal,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }

  Widget _bottomBar() {
    final isReview = _step == 3;
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
        child: Row(
          children: [
            if (_step > 0) ...[
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _submitting ? null : () => setState(() => _step -= 1),
                  icon: const Icon(Icons.arrow_back_outlined, size: 20),
                  label: const Text('Back'),
                ),
              ),
              const SizedBox(width: 12),
            ],
            Expanded(
              child: FilledButton(
                onPressed: _submitting || (isReview && _price == 0)
                    ? null
                    : () {
                        if (isReview) {
                          _confirm();
                        } else {
                          _goNext();
                        }
                      },
                child: _submitting
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(isReview ? 'Confirm' : 'Next'),
                          const SizedBox(width: 8),
                          Icon(
                            isReview ? Icons.check_circle_outline : Icons.arrow_forward_outlined,
                            size: 20,
                          ),
                        ],
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  InputDecoration _fieldDecoration(String hint, {IconData? icon}) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: AppConstants.mute),
      prefixIcon: icon == null ? null : Icon(icon, size: 22, color: AppConstants.signal),
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      border: const OutlineInputBorder(
        borderRadius: _radius,
        borderSide: BorderSide(color: AppConstants.line),
      ),
      enabledBorder: const OutlineInputBorder(
        borderRadius: _radius,
        borderSide: BorderSide(color: AppConstants.line),
      ),
      focusedBorder: const OutlineInputBorder(
        borderRadius: _radius,
        borderSide: BorderSide(color: AppConstants.signal, width: 1.5),
      ),
    );
  }
}

class _BookingSuccess extends StatelessWidget {
  const _BookingSuccess();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const BrandIconWell(icon: Icons.check_circle_outline, box: 64, iconSize: 22),
            const SizedBox(height: 16),
            Text(
              'Booking confirmed',
              style: AppType.display.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 8),
            Text(
              'Your wash is booked.',
              textAlign: TextAlign.center,
              style: AppType.body.copyWith(color: AppConstants.mute),
            ),
          ],
        ),
      ),
    );
  }
}

class _Heading extends StatelessWidget {
  const _Heading(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        text,
        style: AppType.display.copyWith(fontWeight: FontWeight.w800),
      ),
    );
  }
}

class _FieldLabel extends StatelessWidget {
  const _FieldLabel({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(icon, size: 20, color: AppConstants.signal),
          const SizedBox(width: 6),
          Text(
            text,
            style: const TextStyle(
              color: AppConstants.ink,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _ReadOnlyBox extends StatelessWidget {
  const _ReadOnlyBox({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: _radius,
        border: Border.all(color: AppConstants.line),
      ),
      child: Row(
        children: [
          Icon(icon, size: 22, color: AppConstants.signal),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: AppType.item,
            ),
          ),
        ],
      ),
    );
  }
}

class _SelectTile extends StatelessWidget {
  const _SelectTile({
    required this.icon,
    required this.title,
    required this.selected,
    required this.onTap,
    this.subtitle,
  });

  final IconData icon;
  final String title;
  final String? subtitle;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: selected ? AppConstants.well : Colors.white,
        borderRadius: _radius,
        child: InkWell(
          onTap: onTap,
          borderRadius: _radius,
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            decoration: BoxDecoration(
              borderRadius: _radius,
              border: Border.all(
                color: selected ? AppConstants.signal : AppConstants.line,
              ),
            ),
            child: Row(
              children: [
                BrandIconWell(icon: icon, box: 36, iconSize: 20),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          color: AppConstants.ink,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      if (subtitle != null) ...[
                        const SizedBox(height: 2),
                        Text(
                          subtitle!,
                          style: AppType.label.copyWith(color: AppConstants.mute),
                        ),
                      ],
                    ],
                  ),
                ),
                Icon(
                  selected ? Icons.check_circle_outline : Icons.chevron_right,
                  size: 22,
                  color: selected ? AppConstants.signal : AppConstants.mute,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _DateChip extends StatelessWidget {
  const _DateChip({
    required this.date,
    required this.selected,
    required this.onTap,
  });

  final DateTime date;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = selected ? Colors.white : AppConstants.ink;
    return Material(
      color: selected ? AppConstants.signal : Colors.white,
      borderRadius: _radius,
      child: InkWell(
        onTap: onTap,
        borderRadius: _radius,
        child: Container(
          width: 68,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            borderRadius: _radius,
            border: Border.all(
              color: selected ? AppConstants.signal : AppConstants.line,
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                _weekdays[date.weekday - 1],
                style: AppType.label.copyWith(color: color),
              ),
              Text(
                '${date.day}',
                style: AppType.title.copyWith(color: color, fontWeight: FontWeight.w800),
              ),
              Text(
                _months[date.month - 1],
                style: AppType.label.copyWith(color: color),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  const _SummaryRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          BrandIconWell(icon: icon, box: 36, iconSize: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: AppType.label.copyWith(color: AppConstants.mute),
                ),
                Text(
                  value,
                  style: AppType.item,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
