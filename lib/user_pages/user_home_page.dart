import 'package:flutter/material.dart';

import '../compoments/homepage_components/top_cerosal_slider.dart';

class HomePage extends StatelessWidget {
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
                  value: "BIKE",
                  icon: Icon(Icons.arrow_drop_down, color: Colors.black),
                  items: ["BIKE", "CAR"].map((String value) {
                    return DropdownMenuItem<String>(
                      value: value,
                      child: Row(
                        children: [
                          Icon(Icons.directions_bike, color: Colors.black),
                          SizedBox(width: 4),
                          Text(value, style: TextStyle(color: Colors.black)),
                        ],
                      ),
                    );
                  }).toList(),
                  onChanged: (_) {},
                ),
                Icon(Icons.notifications_none, color: Colors.black),
              ],
            ),
          ],
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: EdgeInsets.all(10),
              color: Colors.yellow[700],
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "HOORA",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                  Text(
                    "Washing Centre | Daily Washer",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  Text(
                    "Know More >",
                    style: TextStyle(color: Colors.black),
                  ),
                ],
              ),
            ),
            Stack(
              children: [
                CarouselWithButtons(),
                Positioned(
                  bottom: 20,
                  right: 20,
                  child: ElevatedButton(
                    onPressed: () {},
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.yellow,
                    ),
                    child: Text(
                      "Book Now",
                      style: TextStyle(color: Colors.black),
                    ),
                  ),
                ),
              ],
            ),
            Padding(
              padding: EdgeInsets.all(10),
              child: Text(
                "Doorstep Autocare Services",
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
              ),
            ),
            GridView.count(
              shrinkWrap: true,
              crossAxisCount: 3,
              physics: NeverScrollableScrollPhysics(),
              children: [
                ServiceItem("Car Wash", Icons.car_repair),
                ServiceItem("Deep Clean", Icons.cleaning_services),
                ServiceItem("Shine and Coat", Icons.shield),
                ServiceItem("Luxury Car Care", Icons.diamond),
                ServiceItem("Special Car Care", Icons.star),
                ServiceItem("Bike and Moped", Icons.two_wheeler),
              ],
            ),
            Padding(
              padding: EdgeInsets.all(10),
              child: Text(
                "Popular Services",
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
              ),
            ),
            SizedBox(
              height: 150,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: List.generate(3, (index) {
                  return Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Container(
                      width: 120,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.grey.withOpacity(0.3),
                            blurRadius: 4,
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            height: 70,
                            decoration: BoxDecoration(
                              image: DecorationImage(
                                image: NetworkImage(
                                  'https://marvel-b1-cdn.bc0a.com/f00000000270514/s25180.pcdn.co/wp-content/uploads/2024/10/Cover-Automation-1.jpg',
                                ),
                                fit: BoxFit.cover,
                              ),
                              borderRadius: BorderRadius.only(
                                topLeft: Radius.circular(8),
                                topRight: Radius.circular(8),
                              ),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Text(
                              "Interior + Exterior",
                              style: TextStyle(fontSize: 12),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 8.0),
                            child: Text(
                              "₹959",
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }),
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
            // SizedBox(
            //   height: 250,
            // ),
            // VideoPlayerWidget(),

          ],
        ),
      ),
    );
  }
}

class ServiceItem extends StatelessWidget {
  final String title;
  final IconData icon;

  ServiceItem(this.title, this.icon);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, size: 40),
        SizedBox(height: 5),
        Text(title, textAlign: TextAlign.center),
      ],
    );
  }
}
