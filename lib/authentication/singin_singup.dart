import 'package:flutter/material.dart';

import '../compoments/loginsingup/login_component.dart';

class LoginSignupScreen extends StatelessWidget {
  const LoginSignupScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: Colors.white,
      body: LoginSignupCard(),
    );
  }
}
