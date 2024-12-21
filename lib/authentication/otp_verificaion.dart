import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:async';

import '../location/user_city_location.dart';
import '../user_footer/footer.dart';


class OtpVerificationPage extends StatefulWidget {
  @override
  _OtpVerificationPageState createState() => _OtpVerificationPageState();
}

class _OtpVerificationPageState extends State<OtpVerificationPage> {
  final TextEditingController _otpController = TextEditingController();
  int _counter = 10;
  late final Timer _timer;

  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_counter > 0) {
        setState(() {
          _counter--;
        });
      } else {
        timer.cancel();
      }
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    _otpController.dispose();
    super.dispose();
  }

  Widget _buildOtpBox({required bool isFocused}) {
    return Container(
      width: 50,
      height: 50,
      decoration: BoxDecoration(
        border: Border.all(
          color: isFocused ? Colors.black : Colors.grey,
          width: 2,
        ),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Center(
        child: TextField(
          controller: _otpController,
          keyboardType: TextInputType.number,
          textAlign: TextAlign.center,
          inputFormatters: [LengthLimitingTextInputFormatter(1)],
          style: const TextStyle(fontSize: 20),
          decoration: const InputDecoration(border: InputBorder.none),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        title: const Text("OTP", style: TextStyle(color: Colors.black)),
      ),
      body: Center(  // Center the entire body content
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisAlignment: MainAxisAlignment.center,  // Vertically center the content
            children: [
              const SizedBox(height: 30),
              const Text(
                "Enter Verification Code",
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 10),
              const Text(
                "We have sent you a 6 digit verification code on",
                style: TextStyle(color: Colors.grey),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    "+91-94543-10605",
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  IconButton(
                    icon: const Icon(Icons.edit, size: 16, color: Colors.grey),
                    onPressed: () {
                      // Handle edit phone number
                    },
                  ),
                ],
              ),
              const Text(
                "via SMS",
                style: TextStyle(color: Colors.grey),
              ),
              const SizedBox(height: 30),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: List.generate(
                  6,
                      (index) => _buildOtpBox(isFocused: index == 0),
                ),
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    "Didn't receive the code?",
                    style: TextStyle(color: Colors.grey),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    _counter > 0 ? "Wait | $_counter" : "Resend",
                    style: TextStyle(
                      color: _counter > 0 ? Colors.black : Colors.blue,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                  onPressed: (){
                    Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => SelectCityPage()
                        )
                    );
                  },
                  child: Text('next 1')
              ),
              ElevatedButton(
                  onPressed: (){
                    Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => CarCleaningBottomNav()
                        )
                    );
                  },
                  child: Text('next 2')
              ),
              const Spacer(),
              const Padding(
                padding: EdgeInsets.only(bottom: 16.0),
                child: Text(
                  "HOORA",
                  style: TextStyle(
                    color: Colors.grey,
                    fontSize: 16,
                    letterSpacing: 2,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );

  }
}
