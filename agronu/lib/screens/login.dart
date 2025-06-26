import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'home.dart';
import 'sign_up.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({Key? key}) : super(key: key);

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController phoneController = TextEditingController();
  final TextEditingController otpController = TextEditingController();

  String? verificationId;
  bool showOtpField = false;
  bool isLoading = false;

  // ✅ Send OTP
  Future<void> sendOtp() async {
    String phone = '+91${phoneController.text.trim()}';

    if (!RegExp(r'^[6-9]\d{9}$').hasMatch(phoneController.text.trim())) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter a valid 10-digit phone number')),
      );
      return;
    }

    setState(() => isLoading = true);

    await FirebaseAuth.instance.verifyPhoneNumber(
      phoneNumber: phone,
      timeout: const Duration(seconds: 60),
      verificationCompleted: (PhoneAuthCredential credential) async {
        // For test numbers, auto-login
        await FirebaseAuth.instance.signInWithCredential(credential);
        await saveUserToFirestore(phone);
        goToHome();
      },
      verificationFailed: (FirebaseAuthException e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Verification Failed: ${e.message}')),
        );
        setState(() => isLoading = false);
      },
      codeSent: (String verId, int? resendToken) {
        setState(() {
          verificationId = verId;
          showOtpField = true;
          isLoading = false;
        });
      },
      codeAutoRetrievalTimeout: (String verId) {
        verificationId = verId;
      },
    );
  }

  // ✅ Verify OTP
  Future<void> verifyOtp() async {
    String otp = otpController.text.trim();
    String phone = '+91${phoneController.text.trim()}';

    if (otp.isEmpty || otp.length != 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid 6-digit OTP')),
      );
      return;
    }

    setState(() => isLoading = true);

    try {
      PhoneAuthCredential credential = PhoneAuthProvider.credential(
        verificationId: verificationId!,
        smsCode: otp,
      );

      UserCredential userCredential = await FirebaseAuth.instance
          .signInWithCredential(credential);

      await saveUserToFirestore(phone, userCredential.user!.uid);
      goToHome();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Invalid OTP. Please try again.')),
      );
    }

    setState(() => isLoading = false);
  }

  // ✅ Save phone number to Firestore
  Future<void> saveUserToFirestore(String phone, [String? uid]) async {
    final userId = uid ?? FirebaseAuth.instance.currentUser!.uid;

    await FirebaseFirestore.instance.collection('users').doc(userId).set({
      'uid': userId,
      'phone': phone,
      'timestamp': FieldValue.serverTimestamp(),
    });
  }

  // ✅ Navigate to Home Page
  void goToHome() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const HomePage()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFE8F5E9),
      appBar: AppBar(backgroundColor: Colors.green, title: const Text('Login')),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const SizedBox(height: 20),
            const Text(
              'agroNu',
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: Colors.green,
              ),
            ),
            const SizedBox(height: 40),
            TextField(
              controller: phoneController,
              decoration: const InputDecoration(labelText: 'Phone Number'),
              keyboardType: TextInputType.phone,
            ),
            const SizedBox(height: 16),
            if (showOtpField)
              TextField(
                controller: otpController,
                decoration: const InputDecoration(labelText: 'Enter OTP'),
                keyboardType: TextInputType.number,
              ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: isLoading
                  ? null
                  : () {
                      if (showOtpField) {
                        verifyOtp();
                      } else {
                        sendOtp();
                      }
                    },
              child: Text(
                isLoading
                    ? 'Please wait...'
                    : showOtpField
                    ? 'Verify OTP'
                    : 'Send OTP',
              ),
            ),
            const SizedBox(height: 16),
            TextButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const SignupScreen()),
                );
              },
              child: const Text("Don't have an account? Sign Up"),
            ),
          ],
        ),
      ),
    );
  }
}
