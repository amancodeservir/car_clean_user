import '../models/catalog.dart';

/// A time slot. [id] is exactly what the backend stores.
class Slot {
  const Slot(this.id, this.label, this.hour, this.minute);

  final String id;
  final String label;
  final int hour;
  final int minute;

  bool isPast(DateTime day) {
    final now = DateTime.now();
    final start = DateTime(day.year, day.month, day.day, hour, minute);
    // Leave an hour for the washer to reach the car.
    return now.isAfter(start.subtract(const Duration(hours: 1)));
  }
}

class CarModel {
  const CarModel(this.name, this.category);
  final String name;
  final String category;
}

/// Mirrors `backend/utils/defaultCatalog.js` and `backend/utils/cities.js`.
/// Used until the live catalog loads, or if it cannot be reached.
class Defaults {
  static const slots = [
    Slot('Slot 1 – 08:30 AM', '08:30 AM', 8, 30),
    Slot('Slot 2 – 10:00 AM', '10:00 AM', 10, 0),
    Slot('Slot 3 – 11:30 AM', '11:30 AM', 11, 30),
    Slot('Slot 4 – 01:30 PM', '01:30 PM', 13, 30),
    Slot('Slot 5 – 03:00 PM', '03:00 PM', 15, 0),
    Slot('Slot 6 – 04:30 PM', '04:30 PM', 16, 30),
  ];

  static const services = [
    ServiceInfo(
      name: 'Basic Wash',
      title: 'Smart Wash',
      tagline: 'Foam wash, rinse and dry at your door',
      description:
          'A quick doorstep wash for regular upkeep. Road dust and grime come off with a pH-neutral foam, then the car is rinsed and hand dried with microfibre.',
      durationMins: 45,
      inclusions: ['Exterior foam wash', 'Tyre and rim clean', 'Microfibre hand dry', 'Glass wipe'],
      group: 'wash',
      popular: true,
    ),
    ServiceInfo(
      name: 'Premium Wash',
      title: 'Premium Wash',
      tagline: 'Pressure wash plus interior vacuum',
      description:
          'Everything in the Smart Wash plus a high-pressure rinse, a full interior vacuum and a dashboard wipe-down so the cabin feels fresh again.',
      durationMins: 75,
      inclusions: ['High-pressure foam wash', 'Interior vacuum', 'Dashboard and console wipe', 'Tyre dressing'],
      group: 'wash',
      popular: true,
    ),
    ServiceInfo(
      name: 'Complete Clean',
      title: 'Complete Clean',
      tagline: 'Deep interior and exterior detail',
      description:
          'A deep clean inside and out. Seats, mats and door pads are cleaned, the exterior gets a foam wash and a polish for a lasting shine.',
      durationMins: 120,
      inclusions: [
        'Exterior foam wash and polish',
        'Seat and mat cleaning',
        'Door pad and roof wipe',
        'Interior vacuum',
        'Tyre dressing',
      ],
      group: 'detailing',
      popular: true,
    ),
    ServiceInfo(
      name: 'Festive Offer',
      title: 'Festive Detail',
      tagline: 'A new-car shine for the season',
      description:
          'Our festive package: a full detail with wax protection so your vehicle looks its best for the celebrations.',
      durationMins: 150,
      inclusions: ['Complete Clean included', 'Wax coat', 'Engine bay wipe', 'Fragrance'],
      group: 'detailing',
    ),
    ServiceInfo(
      name: 'Waterless Wash',
      title: 'Waterless Wash',
      tagline: 'Eco wash that uses almost no water',
      description:
          'An eco-friendly spray-and-wipe wash that cleans where the vehicle is parked, without a hose. Ideal for basements and society parking.',
      durationMins: 40,
      inclusions: ['Waterless spray wash', 'Microfibre wipe', 'Glass clean', 'Tyre shine'],
      group: 'eco',
    ),
  ];

  static const _serviceOrder = ['Basic Wash', 'Premium Wash', 'Complete Clean', 'Festive Offer', 'Waterless Wash'];

  static const _table = {
    'Compact': [299, 499, 699, 899, 349],
    'Standard': [399, 599, 799, 999, 449],
    'Large': [499, 699, 899, 1199, 549],
    'Premium Compact': [499, 699, 899, 1099, 549],
    'Premium Standard': [599, 799, 999, 1299, 649],
    'Premium Large': [699, 899, 1199, 1499, 749],
    'Premium': [699, 899, 1199, 1499, 749],
    'Bike': [149, 249, 349, 399, 199],
  };

  static Map<String, int> get prices {
    final out = <String, int>{};
    _table.forEach((category, amounts) {
      for (var i = 0; i < _serviceOrder.length; i++) {
        out['$category|${_serviceOrder[i]}'] = amounts[i];
      }
    });
    return out;
  }

  static const addons = [Addon('Wax', 149), Addon('Interior', 199), Addon('Engine bay', 249)];

  static const plans = [
    WashPlan(name: 'City 4', washes: 4, amount: 999, service: 'Basic Wash'),
    WashPlan(name: 'City 8', washes: 8, amount: 1799, service: 'Basic Wash'),
  ];

  static const cities = [
    City('Ahmedabad', 23.0225, 72.5714),
    City('Bengaluru', 12.9716, 77.5946),
    City('Chennai', 13.0827, 80.2707),
    City('Hyderabad', 17.385, 78.4867),
    City('Lucknow', 26.8467, 80.9462),
    City('Mumbai', 19.076, 72.8777),
    City('Nagpur', 21.1458, 79.0882),
    City('New Delhi', 28.6139, 77.209),
    City('Pune', 18.5204, 73.8567),
  ];

  static const zoneKm = 25.0;

  static const carCategories = [
    'Compact',
    'Standard',
    'Large',
    'Premium Compact',
    'Premium Standard',
    'Premium Large',
    'Premium',
  ];

  static const carModels = [
    CarModel('Maruti Suzuki Alto', 'Compact'),
    CarModel('Maruti Suzuki WagonR', 'Compact'),
    CarModel('Maruti Suzuki Swift', 'Compact'),
    CarModel('Maruti Suzuki Celerio', 'Compact'),
    CarModel('Maruti Suzuki Ignis', 'Compact'),
    CarModel('Hyundai Grand i10 Nios', 'Compact'),
    CarModel('Tata Tiago', 'Compact'),
    CarModel('Tata Punch', 'Compact'),
    CarModel('Renault Kwid', 'Compact'),
    CarModel('Maruti Suzuki Baleno', 'Standard'),
    CarModel('Maruti Suzuki Dzire', 'Standard'),
    CarModel('Maruti Suzuki Brezza', 'Standard'),
    CarModel('Maruti Suzuki Fronx', 'Standard'),
    CarModel('Hyundai i20', 'Standard'),
    CarModel('Hyundai Aura', 'Standard'),
    CarModel('Hyundai Venue', 'Standard'),
    CarModel('Hyundai Verna', 'Standard'),
    CarModel('Honda Amaze', 'Standard'),
    CarModel('Honda City', 'Standard'),
    CarModel('Tata Altroz', 'Standard'),
    CarModel('Tata Nexon', 'Standard'),
    CarModel('Kia Sonet', 'Standard'),
    CarModel('Skoda Slavia', 'Standard'),
    CarModel('Volkswagen Virtus', 'Standard'),
    CarModel('Hyundai Creta', 'Large'),
    CarModel('Kia Seltos', 'Large'),
    CarModel('Maruti Suzuki Grand Vitara', 'Large'),
    CarModel('Maruti Suzuki Ertiga', 'Large'),
    CarModel('Toyota Innova Crysta', 'Large'),
    CarModel('Toyota Innova Hycross', 'Large'),
    CarModel('Toyota Fortuner', 'Large'),
    CarModel('Mahindra XUV700', 'Large'),
    CarModel('Mahindra Scorpio N', 'Large'),
    CarModel('Mahindra Thar', 'Large'),
    CarModel('Tata Harrier', 'Large'),
    CarModel('Tata Safari', 'Large'),
    CarModel('MG Hector', 'Large'),
    CarModel('Mercedes-Benz A-Class', 'Premium Compact'),
    CarModel('BMW 2 Series', 'Premium Compact'),
    CarModel('Mini Cooper', 'Premium Compact'),
    CarModel('Mercedes-Benz C-Class', 'Premium Standard'),
    CarModel('BMW 3 Series', 'Premium Standard'),
    CarModel('Audi A4', 'Premium Standard'),
    CarModel('Mercedes-Benz GLE', 'Premium Large'),
    CarModel('BMW X5', 'Premium Large'),
    CarModel('Audi Q7', 'Premium Large'),
    CarModel('Volvo XC90', 'Premium Large'),
    CarModel('Mercedes-Benz S-Class', 'Premium'),
    CarModel('BMW 7 Series', 'Premium'),
  ];

  static const bikeModels = [
    'Hero Splendor Plus',
    'Honda Activa',
    'Honda Shine',
    'TVS Jupiter',
    'TVS Apache',
    'Bajaj Pulsar',
    'Royal Enfield Classic 350',
    'Suzuki Access',
    'Yamaha FZ',
    'KTM Duke',
  ];
}
