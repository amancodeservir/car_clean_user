import 'package:car_clean_user/config/color_veriable.dart';
// import 'package:car_clean_user/home/home_page.dart'; // Import HomePage
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../compoments/loginsingup/login_component.dart';
import '../user_pages/user_home_page.dart';

class LoginSignupScreen extends StatefulWidget {
  @override
  _LoginSignupScreenState createState() => _LoginSignupScreenState();
}

class _LoginSignupScreenState extends State<LoginSignupScreen> {
  final TextEditingController _phoneController = TextEditingController();
  final FocusNode _phoneFocusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    Future.delayed(Duration(milliseconds: 200), () {
      FocusScope.of(context).requestFocus(_phoneFocusNode);
    });
    _checkUserLoggedIn(); // Check if the user is already logged in
  }

  @override
  void dispose() {
    _phoneController.dispose();
    _phoneFocusNode.dispose();
    super.dispose();
  }

  // Function to check if the user is logged in
  _checkUserLoggedIn() async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      // If the user is logged in, navigate to HomePage
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => HomePage()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Stack(
              children: [
                Container(
                  height: 500,
                  width: double.infinity,
                  child: Image.asset(
                    "assets/car_wash.jpg",
                    fit: BoxFit.cover,
                  ),
                ),
                Positioned(
                  top: 90,
                  right: 20,
                  child: Text(
                    "Premium Car & Bike Care",
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      backgroundColor: AppColors.primary.withOpacity(0.5),
                    ),
                  ),
                ),
                Positioned(
                  top: 120,
                  right: 20,
                  child: Text(
                    "at your Door-step!",
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      backgroundColor: AppColors.primary.withOpacity(0.5),
                    ),
                  ),
                ),
              ],
            ),
            Transform.translate(
              offset: Offset(0, -120), // Adjust the overlap distance here
              child: LoginSignupCard(),
            ),
          ],
        ),
      ),
    );
  }
}
