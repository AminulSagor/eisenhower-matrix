import 'dart:async';
import 'package:eisenhower_matrix/screens/note/home_screen.dart';
import 'package:flutter/material.dart';

import '../../service/auth_service.dart';

class OtpScreen extends StatefulWidget {
  final String email;
  const OtpScreen({super.key, required this.email});

  @override
  OtpScreenState createState() => OtpScreenState();
}

class OtpScreenState extends State<OtpScreen> {
  final List<TextEditingController> _controllers =
  List.generate(6, (index) => TextEditingController());
  bool isResendEnabled = false;
  int countdown = 30; // Resend timer duration
  late Timer _timer;
  final AuthService _authService = AuthService(); // Initialize AuthService

  @override
  void initState() {
    super.initState();
    _startCountdown();
  }

  @override
  void dispose() {
    for (var controller in _controllers) {
      controller.dispose();
    }
    _timer.cancel();
    super.dispose();
  }

  void _startCountdown() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        if (countdown > 0) {
          countdown--;
        } else {
          isResendEnabled = true;
          timer.cancel();
        }
      });
    });
  }

  Future<void> _verifyOtp() async {
    final otp = _controllers.map((controller) => controller.text).join();
    if (otp.length == 6) {
      try {
        await _authService.verifyOtp(email: widget.email, otp: otp);

        if (!mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('OTP Verified Successfully!')),
        );
        Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const HomePage(),
            ));
      } catch (e) {
        if (!mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to verify OTP: $e')),
        );
      }
    } else {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid 6-digit OTP.')),
      );
    }
  }

  Future<void> _resendOtp() async {
    if (isResendEnabled) {
      setState(() {
        countdown = 30;
        isResendEnabled = false;
      });
      _startCountdown();
      try {
        await _authService.resendOtp(email: widget.email);

        if (!mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('OTP resent successfully.')),
        );
      } catch (e) {
        if (!mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to resend OTP: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Verify OTP'),
      ),
      body: Padding(
        padding: const EdgeInsets.only(left: 16.0, right: 16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Image.asset(
              'assets/app_icon.png',
              width: 500,
              height: 300,
            ),
            const Text(
              'Enter the 6-digit OTP sent to your email',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 18),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(6, (index) {
                return SizedBox(
                  width: 40,
                  height: 50,
                  child: TextField(
                    controller: _controllers[index],
                    keyboardType: TextInputType.number,
                    maxLength: 1,
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    decoration: const InputDecoration(
                      counterText: '',
                      border: OutlineInputBorder(),
                    ),
                    onChanged: (value) {
                      if (value.isNotEmpty && index < 5) {
                        FocusScope.of(context).nextFocus();
                      } else if (value.isEmpty && index > 0) {
                        FocusScope.of(context).previousFocus();
                      }
                    },
                  ),
                );
              }),
            ),
            const SizedBox(height: 30),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _verifyOtp,
                child: const Text('Verify OTP'),
              ),
            ),
            const SizedBox(height: 20),
            TextButton(
              onPressed: isResendEnabled ? _resendOtp : null,
              child: Text(
                isResendEnabled ? 'Resend OTP' : 'Resend OTP in $countdown sec',
                style: TextStyle(
                  color: isResendEnabled ? Colors.blue : Colors.grey,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
