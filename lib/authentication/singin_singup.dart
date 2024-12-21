import 'package:flutter/material.dart';

import '../compoments/loginsingup/login_component.dart';

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
  }

  @override
  void dispose() {
    _phoneController.dispose();
    _phoneFocusNode.dispose();
    super.dispose();
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
                  top: 60,
                  right: 20,
                  child: Text(
                    "Premium Car & Bike Care",
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      backgroundColor: Colors.black54,
                    ),
                  ),
                ),
                Positioned(
                  top: 93,
                  right: 20,
                  child: Text(
                    "at your Door-step!",
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      backgroundColor: Colors.black54,
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
