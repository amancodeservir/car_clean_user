import 'package:car_clean_user/location/Location_permission.dart';
import 'package:car_clean_user/theme/brand_theme.dart';
import 'package:car_clean_user/utils/constants.dart';
import 'package:flutter/material.dart';

class SelectCityPage extends StatefulWidget {
  const SelectCityPage({super.key});

  @override
  State<SelectCityPage> createState() => _SelectCityPageState();
}

class _SelectCityPageState extends State<SelectCityPage> {
  final List<String> _cities = [
    "Agartala",
    "Agra",
    "Ahmedabad",
    "Ahmednagar",
    "Ajmer",
    "Bengaluru",
    "Chennai",
    "Delhi",
    "Hyderabad",
    "Jaipur",
    "Kolkata",
    "Mumbai",
    "Nagpur",
    "Pune",
    "Surat",
    "Visakhapatnam"
  ];

  String _query = '';

  List<String> get _filteredCities {
    final query = _query.trim().toLowerCase();
    if (query.isEmpty) return _cities;
    return _cities.where((city) => city.toLowerCase().contains(query)).toList();
  }

  @override
  Widget build(BuildContext context) {
    final cities = _filteredCities;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Select your City'),
        centerTitle: true,
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              onChanged: (value) {
                setState(() => _query = value);
              },
              decoration: const InputDecoration(
                prefixIcon: Icon(Icons.search, size: 22),
                hintText: 'Search for your city',
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Material(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              child: InkWell(
                borderRadius: BorderRadius.circular(16),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const LocationPermission(),
                    ),
                  );
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppConstants.line),
                  ),
                  child: Row(
                    children: [
                      const BrandIconWell(icon: Icons.my_location_outlined, box: 36, iconSize: 20),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Use Current Location',
                          style: AppType.title.copyWith(color: AppConstants.signal),
                        ),
                      ),
                      const Icon(Icons.chevron_right, size: 22, color: AppConstants.signal),
                    ],
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Row(
              children: [
                const Icon(Icons.location_city_outlined, size: 20, color: AppConstants.signal),
                const SizedBox(width: 6),
                Text('Popular Cities', style: AppType.title),
              ],
            ),
          ),
          const SizedBox(height: 10),
          GridView(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 16),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 4,
              mainAxisSpacing: 12,
              crossAxisSpacing: 10,
              mainAxisExtent: 96,
            ),
            children: [
              _buildCityCard(context, 'Mumbai', 'assets/mumbai.png'),
              _buildCityCard(context, 'Ahmedabad', 'assets/ahmedabad.png'),
              _buildCityCard(context, 'Hyderabad', 'assets/hyderabad.png'),
              _buildCityCard(context, 'Pune', 'assets/pune.png'),
              _buildCityCard(context, 'Chennai', 'assets/chennai.png'),
              _buildCityCard(context, 'Bengaluru', 'assets/bengaluru.png'),
              _buildCityCard(context, 'Nagpur', 'assets/nagpur.png'),
              _buildCityCard(context, 'New Delhi', 'assets/newdelhi.png'),
            ],
          ),
          const Divider(),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('All Cities (A-Z)', style: AppType.title),
                TextButton.icon(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Tell us your city from the list'),
                      ),
                    );
                  },
                  icon: const Icon(Icons.info_outline, size: 20),
                  label: const Text('City missing?'),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: cities.length,
              itemBuilder: (context, index) {
                return ListTile(
                  leading: const BrandIconWell(
                    icon: Icons.location_on_outlined,
                    box: 36,
                    iconSize: 20,
                  ),
                  title: Text(cities[index], style: AppType.item),
                  trailing: const Icon(Icons.chevron_right, size: 22, color: AppConstants.mute),
                  onTap: () {
                    Navigator.pop(context, cities[index]);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCityCard(
      BuildContext context, String cityName, String assetPath) {
    return GestureDetector(
      onTap: () => Navigator.pop(context, cityName),
      child: Column(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Image.asset(
              assetPath,
              height: 64,
              width: double.infinity,
              fit: BoxFit.cover,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            cityName,
            style: AppType.label.copyWith(fontWeight: FontWeight.w700),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
