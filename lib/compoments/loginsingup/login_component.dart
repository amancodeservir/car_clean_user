import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../../authentication/otp_verificaion.dart';
import '../../config/color_veriable.dart';
import 'Password_screen.dart';

class LoginSignupCard extends StatefulWidget {
  @override
  _LoginSignupCardState createState() => _LoginSignupCardState();
}

class _LoginSignupCardState extends State<LoginSignupCard> {
  final TextEditingController _controller = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  String? _validateInput(String? value) {
    if (value == null || value.isEmpty) {
      return 'Input is required';
    }
    if (!RegExp(r'^[0-9]+$').hasMatch(value) && !RegExp(r'^[a-zA-Z0-9@.]+$').hasMatch(value)) {
      return 'Please enter a valid input (Phone or Email)';
    }
    return null;
  }
  Future<void> _handleInput() async {
    String input = _controller.text.trim();

    // Check if input is a phone number or email
    if (RegExp(r'^[0-9]+$').hasMatch(input)) {
      String phoneNumber = '+91' + input; // India code
      await FirebaseAuth.instance.verifyPhoneNumber(
        phoneNumber: phoneNumber,
        timeout: Duration(seconds: 60),
        verificationCompleted: (PhoneAuthCredential credential) async {
          await FirebaseAuth.instance.signInWithCredential(credential);
        },
        verificationFailed: (FirebaseAuthException e) {
          print("Verification failed: ${e.message}");
        },
        codeSent: (String verificationId, int? resendToken) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => OtpVerificationPage(verificationId: verificationId),
            ),
          );
        },
        codeAutoRetrievalTimeout: (String verificationId) {
          print("Code Auto Retrieval Timeout");
        },
      );
    } else if (RegExp(r'^[a-zA-Z0-9@.]+$').hasMatch(input)) {
      // If input is an email, navigate to the signup screen
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => PasswordScreen(email: input),
        ),
      );
    } else {
      // Invalid input case
      print('Invalid phone or email');
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    double screenHeight = MediaQuery.of(context).size.height;
    double screenWidth = MediaQuery.of(context).size.width;

    return Container(
      height: screenHeight * 0.8,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(30),
          topRight: Radius.circular(30),
        ),
      ),
      child: Padding(
        padding: EdgeInsets.symmetric(
            horizontal: screenWidth * 0.05,
            vertical: screenHeight * 0.05
        ),
        child: SingleChildScrollView(
          child: Column(
            children: [
              // Logo Section
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Image.asset(
                    "assets/logo.png",
                    width: screenWidth * 0.12,
                    height: screenWidth * 0.12,
                    fit: BoxFit.contain,
                  ),
                  SizedBox(width: screenWidth * 0.02),
                  Text(
                    "CAR CLEAN PLUS",
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                    ),
                  ),
                ],
              ),
              SizedBox(height: screenHeight * 0.03),

              // Phone/Email Section
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Phone Number or Email",
                    style: TextStyle(
                      color: AppColors.primary,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  SizedBox(height: 10),
                  Form(
                    key: _formKey,
                    child: TextFormField(
                      controller: _controller,
                      keyboardType: TextInputType.text,
                      decoration: InputDecoration(
                        hintText: "Enter phone number or email",
                        prefixIcon: Icon(Icons.person, color: AppColors.primary),
                        enabledBorder: OutlineInputBorder(
                          borderSide: BorderSide(color: AppColors.primary, width: 1.5),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderSide: BorderSide(color: Colors.red, width: 1.5),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        contentPadding: EdgeInsets.symmetric(vertical: 12),
                      ),
                      validator: _validateInput,
                    ),
                  ),
                ],
              ),
              SizedBox(height: screenHeight * 0.03),

              // Login/Signup Button
              SizedBox(
                width: double.infinity,
                height: screenHeight * 0.07,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 5,
                    padding: EdgeInsets.symmetric(vertical: 15),
                  ),
                  onPressed: () {
                    if (_formKey.currentState?.validate() ?? false) {
                      _handleInput();
                    }
                  },
                  child: Text(
                    "Login/Signup",
                    style: TextStyle(
                      fontSize: 20,
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              SizedBox(height: screenHeight * 0.02),
            ],
          ),
        ),
      ),
    );
  }
}
