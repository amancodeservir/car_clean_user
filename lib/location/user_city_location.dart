import 'package:car_clean_user/location/Location_permission.dart';
import 'package:flutter/material.dart';

class SelectCityPage extends StatelessWidget {
  final List<String> cities = [
    "Agartala", "Agra", "Ahmedabad", "Ahmednagar", "Ajmer",
    "Bengaluru", "Chennai", "Delhi", "Hyderabad", "Jaipur",
    "Kolkata", "Mumbai", "Nagpur", "Pune", "Surat", "Visakhapatnam"
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(
          'Select your City',
          style: TextStyle(color: Colors.black, fontSize: 18),
        ),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              decoration: InputDecoration(
                prefixIcon: const Icon(Icons.search, color: Colors.grey),
                hintText: 'Search for your city',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: Colors.grey[200],
              ),
            ),
          ),
          // Use Current Location
          ListTile(
            leading: const Icon(Icons.my_location, color: Colors.blue),
            title: const Text(
              'Use Current Location',
              style: TextStyle(color: Colors.blue, fontSize: 16),
            ),
            trailing: const Icon(Icons.arrow_forward_ios, color: Colors.blue),
            onTap: () {
             Navigator.push(context,
                 MaterialPageRoute(
                     builder: (context) => LocationPermission(),
                 )
             );
            },
          ),
          const SizedBox(height: 10),
          // Popular Cities Grid
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: const Text(
              "Popular Cities",
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            height: 200, // Set fixed height for the grid
            child: GridView.count(
              crossAxisCount: 4,
              mainAxisSpacing: 10,
              crossAxisSpacing: 10,
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              physics: const NeverScrollableScrollPhysics(), // Disable scrolling
              children: [
                _buildCityCard('Mumbai', 'assets/mumbai.png'),
                _buildCityCard('Ahmedabad', 'assets/ahmedabad.png'),
                _buildCityCard('Hyderabad', 'assets/hyderabad.png'),
                _buildCityCard('Pune', 'assets/pune.png'),
                _buildCityCard('Chennai', 'assets/chennai.png'),
                _buildCityCard('Bengaluru', 'assets/bengaluru.png'),
                _buildCityCard('Nagpur', 'assets/nagpur.png'),
                _buildCityCard('New Delhi', 'assets/newdelhi.png'),
              ],
            ),
          ),
          const Divider(),
          // All Cities (A-Z)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'All Cities (A-Z)',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                TextButton(
                  onPressed: () {
                    // Handle "City Missing?" action
                  },
                  child: const Text(
                    "City missing?",
                    style: TextStyle(color: Colors.blue, fontSize: 14),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: cities.length,
              itemBuilder: (context, index) {
                return ListTile(
                  title: Text(cities[index]),
                  onTap: () {
                    // Handle city selection
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

  // Helper Widget for City Card
  Widget _buildCityCard(String cityName, String assetPath) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Expanded(
          child: Image.asset(
            assetPath,
            height: 60,
            width: 60,
          ),
        ),
        const SizedBox(height: 5),
        Text(
          cityName,
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}
