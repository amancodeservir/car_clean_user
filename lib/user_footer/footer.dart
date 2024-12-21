import 'package:flutter/material.dart';

import '../user_pages/profile_page.dart';
import '../user_pages/user_home_page.dart';

class CarCleaningBottomNav extends StatefulWidget {
  const CarCleaningBottomNav({super.key});

  @override
  _CarCleaningBottomNavState createState() => _CarCleaningBottomNavState();
}

class _CarCleaningBottomNavState extends State<CarCleaningBottomNav> {
  int _selectedIndex = 0;
  // int _cartItemCount = 3; // Example cart count (services added to the cart)

  final List<Widget> _screens = [
    HomePage(),  // Home Screen
    CarCleaningServices(), // Car cleaning services screen
    WaterService(),  // Water-related services screen
    ProfilePage(),  // User profile screen
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: _screens[_selectedIndex],  // Navigate to the selected screen
      bottomNavigationBar: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            margin: const EdgeInsets.only(bottom: 0),
            padding: const EdgeInsets.only(top: 5.0),
            decoration: const BoxDecoration(
              // Styling the footer (bottom navigation bar)
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
              child: BottomNavigationBar(
                backgroundColor: Colors.white,
                items: <BottomNavigationBarItem>[
                  BottomNavigationBarItem(
                    icon: Icon(Icons.home, size: 30),
                    label: 'Home',
                  ),
                  BottomNavigationBarItem(
                    icon: Icon(Icons.cleaning_services, size: 30),
                    label: 'My Order',
                  ),
                  BottomNavigationBarItem(
                    icon: Icon(Icons.local_drink, size: 30),
                    label: 'Water',
                  ),
                  // BottomNavigationBarItem(
                  //   icon: _buildCartIcon(),
                  //   label: 'Cart',  // Cart screen
                  // ),
                  BottomNavigationBarItem(
                    icon: Icon(Icons.person, size: 30),
                    label: 'Profile',
                  ),
                ],
                currentIndex: _selectedIndex,
                onTap: _onItemTapped,
                type: BottomNavigationBarType.fixed,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Cart icon with a badge showing the cart item count
  // Widget _buildCartIcon() {
  //   return Stack(
  //     children: [
  //       IconButton(
  //         onPressed: () {
  //           // Navigate to cart page (or any other action)
  //           Navigator.push(
  //             context,
  //             MaterialPageRoute(builder: (context) => CartPage()),
  //           );
  //         },
  //         icon: const Icon(Icons.shopping_cart, color: Colors.black),
  //       ),
  //       if (_cartItemCount > 0) // Show badge only if cart has items
  //         Positioned(
  //           right: 0,
  //           child: Container(
  //             padding: const EdgeInsets.all(2.0),
  //             decoration: BoxDecoration(
  //               color: Colors.red, // Badge color (red)
  //               borderRadius: BorderRadius.circular(10),
  //             ),
  //             constraints: const BoxConstraints(
  //               minWidth: 16,
  //               minHeight: 16,
  //             ),
  //             child: Text(
  //               '$_cartItemCount', // Show the cart item count
  //               style: const TextStyle(
  //                 color: Colors.white,
  //                 fontSize: 12,
  //                 fontWeight: FontWeight.bold,
  //               ),
  //               textAlign: TextAlign.center,
  //             ),
  //           ),
  //         ),
  //     ],
  //   );
  // }
}


class CarCleaningServices extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(child: Text("Car Cleaning Services"));
  }
}

class WaterService extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(child: Text("Water Services"));
  }
}

// class UserProfile extends StatelessWidget {
//   @override
//   Widget build(BuildContext context) {
//     return Center(child: Text("User Profile"));
//   }
// }

// Cart page where the user can see their cart items
// class CartPage extends StatelessWidget {
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: Text("Your Cart"),
//       ),
//       body: Center(
//         child: Text("This is your cart, review your car cleaning services."),
//       ),
//     );
//   }
// }
