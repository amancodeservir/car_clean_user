class Vehicle {
  const Vehicle({
    required this.name,
    required this.category,
    this.id = '',
    this.plate = '',
    this.isDefault = false,
  });

  /// Empty for a vehicle that only lives on this phone (guest).
  final String id;
  final String name;
  final String category;
  final String plate;
  final bool isDefault;

  bool get isBike => category == 'Bike';
  bool get isSaved => id.isNotEmpty;

  /// A short label for the size, as the customer thinks of it.
  String get sizeLabel {
    switch (category) {
      case 'Compact':
        return 'Hatchback';
      case 'Standard':
        return 'Sedan / compact SUV';
      case 'Large':
        return 'SUV / MUV';
      case 'Premium Compact':
        return 'Luxury hatchback';
      case 'Premium Standard':
        return 'Luxury sedan';
      case 'Premium Large':
        return 'Luxury SUV';
      case 'Premium':
        return 'Flagship luxury';
      case 'Bike':
        return 'Two wheeler';
      default:
        return category;
    }
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'category': category,
        'plate': plate,
        'isDefault': isDefault,
      };

  factory Vehicle.fromJson(Map<String, dynamic> json) {
    return Vehicle(
      id: '${json['_id'] ?? json['id'] ?? ''}',
      name: '${json['name'] ?? ''}',
      category: '${json['category'] ?? ''}',
      plate: '${json['plate'] ?? ''}',
      isDefault: json['isDefault'] == true,
    );
  }
}
