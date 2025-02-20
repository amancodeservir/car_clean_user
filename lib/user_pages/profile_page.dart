import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../authentication/singin_singup.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({Key? key}) : super(key: key);

  // Function to get user data using the email
  Future<Map<String, dynamic>> getUserDataByEmail(String email) async {
    try {
      // Query Firestore to find the document where 'email' matches
      QuerySnapshot userSnapshot = await FirebaseFirestore.instance
          .collection('user_carclean_USERS')
          .where('email', isEqualTo: email)
          .get();

      if (userSnapshot.docs.isNotEmpty) {
        return userSnapshot.docs.first.data() as Map<String, dynamic>;
      } else {
        throw Exception("User data not found");
      }
    } catch (e) {
      print("Error fetching user data: $e");
      throw e;
    }
  }

  // Logout Function
  Future<void> logout(BuildContext context) async {
    try {

      await FirebaseAuth.instance.signOut();
      Navigator.pushReplacement(context,
        MaterialPageRoute(builder: (context) => LoginSignupScreen()),
      );
    } catch (e) {
      print("Error during logout: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    final String userEmail = FirebaseAuth.instance.currentUser?.email ?? '';

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Center(child: const Text("Profile")),
        backgroundColor: Colors.white,
        elevation: 0,
        automaticallyImplyLeading: false,
      ),
      body: FutureBuilder<Map<String, dynamic>>(
        future: getUserDataByEmail(userEmail), // Fetch user data by email
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text("Error: ${snapshot.error}"));
          }

          if (snapshot.hasData) {
            var userData = snapshot.data!;
            return SingleChildScrollView(
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
                              subtitle: userData['name'] ?? 'N/A',
                            ),
                            const Divider(),
                            ProfileTile(
                              icon: Icons.email,
                              title: "Email",
                              subtitle: userData['email'] ?? 'N/A',
                            ),
                            const Divider(),
                            ProfileTile(
                              icon: Icons.phone,
                              title: "Mobile",
                              subtitle: userData['mobile'] ?? 'N/A',
                            ),
                            const Divider(),
                            ProfileTile(
                              icon: Icons.location_on,
                              title: "Address",
                              subtitle: userData['address'] ?? 'N/A',
                            ),
                            const Divider(),
                            ProfileTile(
                              icon: Icons.directions_car,
                              title: "Vehicle",
                              subtitle: userData['vehicle'] ?? 'N/A',
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  Center(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        logout(context);
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
            );
          }

          return const Center(child: Text("No user data found"));
        },
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
