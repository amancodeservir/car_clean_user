import 'package:flutter/material.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,

      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        title: const Text("Profile"),
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Card(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                color: Colors.white,
                elevation: 4,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      const Text(
                        "YOUR PROFILE DETAILS",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey,
                        ),
                      ),
                      const SizedBox(height: 16),
                      ProfileTile(
                        icon: Icons.person,
                        title: "Name",
                        subtitle: null,
                      ),
                      const Divider(),
                      ProfileTile(
                        icon: Icons.email,
                        title: "Email",
                        subtitle: null,
                      ),
                      const Divider(),
                      ProfileTile(
                        icon: Icons.phone,
                        title: "Mobile",
                        subtitle: "+919454310605",
                      ),
                      const Divider(),
                      ProfileTile(
                        icon: Icons.location_on,
                        title: "Address",
                        subtitle: "Other - Add Address",
                      ),
                      const Divider(),
                      ProfileTile(
                        icon: Icons.directions_car,
                        title: "Vehicle",
                        subtitle: "2-Wheeler BIKE",
                      ),
                    ],
                  ),
                ),
              ),
            ),
            Center(
              child: ElevatedButton.icon(
                onPressed: () {
                  // Handle log out
                },
                icon: const Icon(Icons.logout, color: Colors.red),
                label: const Text(
                  "Log Out",
                  style: TextStyle(color: Colors.red),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  side: const BorderSide(color: Colors.red),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class ProfileTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;

  const ProfileTile({
    Key? key,
    required this.icon,
    required this.title,
    this.subtitle,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: Colors.black),
      title: Text(
        title,
        style: const TextStyle(fontWeight: FontWeight.bold),
      ),
      subtitle: subtitle != null ? Text(subtitle!) : null,
      trailing: const Icon(Icons.arrow_forward_ios, size: 16),
    );
  }
}
