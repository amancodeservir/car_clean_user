import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../config/color_veriable.dart';
import '../../user_footer/footer.dart';

class PasswordScreen extends StatefulWidget {
  final String email;

  PasswordScreen({required this.email});

  @override
  _PasswordScreenState createState() => _PasswordScreenState();
}

class _PasswordScreenState extends State<PasswordScreen> {
  final TextEditingController _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  Future<void> _signUpWithPassword() async {
    String password = _passwordController.text.trim();

    try {
      List<String> signInMethods = await FirebaseAuth.instance.fetchSignInMethodsForEmail(widget.email);

      if (signInMethods.isEmpty) {
        // User does not exist, so we can sign them up
        UserCredential userCredential = await FirebaseAuth.instance.createUserWithEmailAndPassword(
          email: widget.email,
          password: password,
        );
        print("User signed up as: ${userCredential.user?.email}");

        // Send user data to Firestore
        await _sendDataToFirestore(userCredential.user,password);

        // Navigate to CarCleaningBottomNav screen after signup
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => CarCleaningBottomNav()),
        );
      } else {
        // If user exists, sign them in instead of sign up
        _signInWithPassword();
      }
    } catch (e) {
      // Catch the error and show the message accordingly
      if (e.toString().contains("email-already-in-use")) {
        // If email is already in use, sign in the user instead of signing up
        _signInWithPassword();
      } else {
        print("Error during sign up: $e");
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Failed to sign up or login. Please check your credentials.")),
        );
      }
    }
  }


  Future<void> _signInWithPassword() async {
    String password = _passwordController.text.trim();

    try {
      UserCredential userCredential = await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: widget.email,
        password: password,
      );
      print("Signed in as: ${userCredential.user?.email}");

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => CarCleaningBottomNav()),
      );
    } catch (e) {
      // Handle error if login fails
      if (e.toString().contains("user-not-found")) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("User not found. Please sign up.")),
        );
      } else if (e.toString().contains("wrong-password")) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Incorrect password. Please try again.")),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Failed to login. Please check your credentials.")),
        );
      }
    }
  }


  Future<void> _sendDataToFirestore(User? user, String password) async {
    if (user == null) return;

    try {
      await FirebaseFirestore.instance.collection('user_carclean_USERS').doc(user.uid).set({
        'email': user.email,
        'lastLogin': FieldValue.serverTimestamp(),
        'password': password,
      });
      print("User data saved to Firestore in user_carclean_USERS");
    } catch (e) {
      print("Error saving data to Firestore: $e");
    }
  }

  @override
  void dispose() {
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    double screenHeight = MediaQuery.of(context).size.height;
    double screenWidth = MediaQuery.of(context).size.width;
    return Scaffold(
      appBar: AppBar(
        title: Text("Login / Sign Up",
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: AppColors.primary,
          ),
        ),
        automaticallyImplyLeading: false,
      ),
      body: Center(  // Center the content of the screen
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: screenWidth * 0.05,
            vertical: screenHeight * 0.05,
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,

              children: [
                TextFormField(
                  initialValue: widget.email,
                  readOnly: true,
                  decoration: InputDecoration(
                    prefixIcon: Icon(Icons.email, color: AppColors.primary),
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
                ),
                SizedBox(height: screenHeight * 0.03),

                // Password input field
                Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      TextFormField(
                        controller: _passwordController,
                        obscureText: true,
                        decoration: InputDecoration(
                          hintText: "Enter password",
                          prefixIcon: Icon(Icons.lock, color: AppColors.primary),
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
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Password is required';
                          }
                          return null;
                        },
                      ),
                      SizedBox(height: screenHeight * 0.05),

                      // Login/Sign Up button
                      ElevatedButton(
                        onPressed: () {
                          if (_formKey.currentState?.validate() ?? false) {
                            // First check if user already exists or not
                            FirebaseAuth.instance.fetchSignInMethodsForEmail(widget.email).then((methods) {
                              if (methods.isEmpty) {
                                // If no user found, Sign Up
                                _signUpWithPassword();
                              } else {
                                // If user found, Sign In
                                _signInWithPassword();
                              }
                            }).catchError((e) {
                              print("Error checking user existence: $e");
                            });
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          padding: EdgeInsets.symmetric(vertical: 15, horizontal: 55),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30),
                          ),
                        ),
                        child: Text(
                          "Login / Sign Up",
                          style: TextStyle(fontSize: 18, color: Colors.white),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
