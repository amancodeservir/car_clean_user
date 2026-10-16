import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../data/defaults.dart';
import '../models/vehicle.dart';
import '../providers/account_provider.dart';
import '../services/api.dart';
import '../theme.dart';
import 'ui.dart';

/// Pick one of the saved vehicles, or add a new one. Returns the choice.
Future<Vehicle?> pickVehicle(BuildContext context) {
  return showModalBottomSheet<Vehicle>(
    context: context,
    isScrollControlled: true,
    builder: (_) => const _PickVehicleSheet(),
  );
}

/// Add a vehicle. Returns it once saved.
Future<Vehicle?> addVehicle(BuildContext context) {
  return showModalBottomSheet<Vehicle>(
    context: context,
    isScrollControlled: true,
    builder: (_) => const _AddVehicleSheet(),
  );
}

IconData vehicleIcon(Vehicle? vehicle) =>
    vehicle?.isBike == true ? Icons.two_wheeler_rounded : Icons.directions_car_filled_rounded;

class _PickVehicleSheet extends StatelessWidget {
  const _PickVehicleSheet();

  @override
  Widget build(BuildContext context) {
    final account = context.watch<AccountProvider>();
    final current = account.vehicle;
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Select your vehicle', style: AppText.h2),
            const SizedBox(height: 4),
            Text('Prices follow the size of the vehicle.', style: AppText.small),
            const SizedBox(height: 14),
            Flexible(
              child: ListView(
                shrinkWrap: true,
                children: [
                  for (final vehicle in account.vehicles)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: AppCard(
                        color: vehicle == current ? AppColors.yellowWash : null,
                        onTap: () async {
                          await account.selectVehicle(vehicle);
                          if (context.mounted) Navigator.pop(context, vehicle);
                        },
                        child: Row(
                          children: [
                            _VehicleBadge(vehicle),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(vehicle.name, style: AppText.title),
                                  Text(
                                    [vehicle.sizeLabel, if (vehicle.plate.isNotEmpty) vehicle.plate].join(' · '),
                                    style: AppText.small,
                                  ),
                                ],
                              ),
                            ),
                            Icon(
                              vehicle == current ? Icons.radio_button_checked_rounded : Icons.radio_button_off_rounded,
                              color: vehicle == current ? AppColors.ink : AppColors.faint,
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 6),
            OutlinedButton.icon(
              onPressed: () async {
                final added = await addVehicle(context);
                if (added != null && context.mounted) Navigator.pop(context, added);
              },
              icon: const Icon(Icons.add_rounded),
              label: const Text('Add a vehicle'),
            ),
          ],
        ),
      ),
    );
  }
}

class _VehicleBadge extends StatelessWidget {
  const _VehicleBadge(this.vehicle);

  final Vehicle vehicle;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(color: AppColors.yellowSoft, borderRadius: BorderRadius.circular(12)),
      child: Icon(vehicleIcon(vehicle), color: AppColors.ink),
    );
  }
}

class _AddVehicleSheet extends StatefulWidget {
  const _AddVehicleSheet();

  @override
  State<_AddVehicleSheet> createState() => _AddVehicleSheetState();
}

class _AddVehicleSheetState extends State<_AddVehicleSheet> {
  final _search = TextEditingController();
  final _custom = TextEditingController();
  final _plate = TextEditingController();
  bool _bike = false;
  CarModel? _model;
  bool _other = false;
  String _size = 'Compact';
  bool _saving = false;

  @override
  void dispose() {
    _search.dispose();
    _custom.dispose();
    _plate.dispose();
    super.dispose();
  }

  String get _name => _bike || _other ? _custom.text.trim() : (_model?.name ?? '');
  String get _category => _bike ? 'Bike' : (_other ? _size : (_model?.category ?? ''));

  Future<void> _save() async {
    if (_name.isEmpty || _category.isEmpty) {
      showMessage(context, _bike ? 'Enter the bike name' : 'Pick your car model');
      return;
    }
    setState(() => _saving = true);
    try {
      final vehicle = await context.read<AccountProvider>().addVehicle(_name, _category, plate: _plate.text);
      if (mounted) Navigator.pop(context, vehicle);
    } catch (error) {
      if (mounted) showMessage(context, errorText(error));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final query = _search.text.trim().toLowerCase();
    final models = Defaults.carModels.where((model) => query.isEmpty || model.name.toLowerCase().contains(query)).toList();
    final bottom = MediaQuery.viewInsetsOf(context).bottom;
    return Padding(
      padding: EdgeInsets.only(bottom: bottom),
      child: SafeArea(
        child: SizedBox(
          height: MediaQuery.sizeOf(context).height * 0.78,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Add your vehicle', style: AppText.h2),
                    const SizedBox(height: 12),
                    SegmentedButton<bool>(
                      showSelectedIcon: false,
                      style: SegmentedButton.styleFrom(
                        selectedBackgroundColor: AppColors.yellow,
                        selectedForegroundColor: AppColors.ink,
                      ),
                      segments: const [
                        ButtonSegment(value: false, icon: Icon(Icons.directions_car_filled_rounded), label: Text('Car')),
                        ButtonSegment(value: true, icon: Icon(Icons.two_wheeler_rounded), label: Text('Bike')),
                      ],
                      selected: {_bike},
                      onSelectionChanged: (value) => setState(() {
                        _bike = value.first;
                        _custom.clear();
                      }),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  children: _bike ? _bikeFields() : _carFields(models),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
                child: Column(
                  children: [
                    TextField(
                      controller: _plate,
                      textCapitalization: TextCapitalization.characters,
                      decoration: const InputDecoration(
                        labelText: 'Number plate (optional)',
                        hintText: 'UP32 AB 1234',
                        prefixIcon: Icon(Icons.pin_outlined, size: 20),
                      ),
                    ),
                    const SizedBox(height: 10),
                    PrimaryButton(label: 'Save vehicle', loading: _saving, onPressed: _save),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  List<Widget> _bikeFields() {
    return [
      TextField(
        controller: _custom,
        textCapitalization: TextCapitalization.words,
        onChanged: (_) => setState(() {}),
        decoration: const InputDecoration(labelText: 'Bike or scooter name', prefixIcon: Icon(Icons.two_wheeler_rounded, size: 20)),
      ),
      const SizedBox(height: 12),
      Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          for (final name in Defaults.bikeModels)
            ChoiceChip(
              label: Text(name),
              selected: _custom.text == name,
              onSelected: (_) => setState(() => _custom.text = name),
            ),
        ],
      ),
    ];
  }

  List<Widget> _carFields(List<CarModel> models) {
    return [
      if (!_other) ...[
        TextField(
          controller: _search,
          onChanged: (_) => setState(() {}),
          decoration: const InputDecoration(hintText: 'Search model, e.g. Creta', prefixIcon: Icon(Icons.search_rounded, size: 20)),
        ),
        const SizedBox(height: 8),
        for (final model in models)
          ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 4),
            dense: true,
            title: Text(model.name, style: AppText.title),
            subtitle: Text(Vehicle(name: model.name, category: model.category).sizeLabel, style: AppText.small),
            trailing: Icon(
              _model == model ? Icons.check_circle_rounded : Icons.circle_outlined,
              color: _model == model ? AppColors.green : AppColors.line,
            ),
            onTap: () => setState(() => _model = model),
          ),
        if (models.isEmpty) Padding(padding: const EdgeInsets.all(12), child: Text('No model matches', style: AppText.small)),
        TextButton.icon(
          onPressed: () => setState(() {
            _other = true;
            _custom.text = _search.text.trim();
          }),
          icon: const Icon(Icons.edit_outlined, size: 18),
          label: const Text("Can't find your car? Enter it"),
        ),
      ] else ...[
        TextField(
          controller: _custom,
          textCapitalization: TextCapitalization.words,
          decoration: const InputDecoration(labelText: 'Car make and model', prefixIcon: Icon(Icons.directions_car_rounded, size: 20)),
        ),
        const SizedBox(height: 14),
        Text('Size', style: AppText.title),
        const SizedBox(height: 8),
        for (final size in Defaults.carCategories)
          ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 4),
            dense: true,
            onTap: () => setState(() => _size = size),
            leading: Icon(
              _size == size ? Icons.radio_button_checked_rounded : Icons.radio_button_off_rounded,
              color: _size == size ? AppColors.ink : AppColors.faint,
            ),
            title: Text(Vehicle(name: '', category: size).sizeLabel, style: AppText.title),
          ),
        TextButton(onPressed: () => setState(() => _other = false), child: const Text('Back to the model list')),
      ],
    ];
  }
}
