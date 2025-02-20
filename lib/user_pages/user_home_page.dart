import 'package:flutter/material.dart';
import '../compoments/homepage_components/doorstepAutocareServices.dart';
import '../compoments/homepage_components/top_cerosal_slider.dart';

class HomePage extends StatefulWidget {
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  String selectedVehicle = "BIKE"; // Default value for the dropdown

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 1,
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Icon(Icons.location_on, color: Colors.black),
                SizedBox(width: 5),
                Text(
                  "Add Address",
                  style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            Row(
              children: [
                DropdownButton<String>(
                  value: selectedVehicle,
                  icon: Icon(Icons.arrow_drop_down, color: Colors.black),
                  items: ["BIKE", "CAR"].map((String value) {
                    return DropdownMenuItem<String>(
                      value: value,
                      child: Row(
                        children: [
                          Icon(
                            value == "BIKE" ? Icons.directions_bike : Icons.directions_car,
                            color: Colors.black,
                          ),
                          SizedBox(width: 4),
                          Text(value, style: TextStyle(color: Colors.black)),
                        ],
                      ),
                    );
                  }).toList(),
                  onChanged: (String? newValue) {
                    setState(() {
                      selectedVehicle = newValue!;
                    });
                  },
                ),
                Icon(Icons.notifications_none, color: Colors.black),
              ],
            ),
          ],
        ),
        automaticallyImplyLeading: false,
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: EdgeInsets.symmetric(horizontal: 10),
              color: Colors.yellow[700],
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "CAR CLEAN PLUSH",
                    style: TextStyle(
                      fontSize:12,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                  Text(
                    "Washing Centre | Daily Washer",
                    style: TextStyle(
                      fontSize:12,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  Text(
                    "Know More >",
                    style: TextStyle(
                        fontSize:12,
                        color: Colors.black,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              height: MediaQuery.of(context).size.height * 0.715,
              child: Stack(
                children: [
                  CarouselWithButtons(),
                  Positioned(
                    top: 200,
                    left: 0,
                    right: 0,
                    child: DoorstepAutocareServices(), // Widget to overlap the carousel
                  ),
                ],
              ),
            ),
            Image.network(
              "https://marvel-b1-cdn.bc0a.com/f00000000270514/s25180.pcdn.co/wp-content/uploads/2024/10/Cover-Automation-1.jpg",
              width: double.infinity,
              fit: BoxFit.cover,
            ),
            Padding(
              padding: EdgeInsets.all(10),
              child: Text(
                "Why Hoora",
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
              ),
            ),
            Image.network(
              "https://marvel-b1-cdn.bc0a.com/f00000000270514/s25180.pcdn.co/wp-content/uploads/2024/10/Cover-Automation-1.jpg",
              width: double.infinity,
              fit: BoxFit.cover,
            ),
          ],
        ),
      ),
    );
  }
}
