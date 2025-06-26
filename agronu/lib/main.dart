import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart'; // 👈 Add this
import 'screens/login.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions
        .currentPlatform, // 👈 Required for Firebase to work
  );
  runApp(const Agronu());
}

class Agronu extends StatelessWidget {
  const Agronu({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Agronu',
      theme: ThemeData(
        primarySwatch: Colors.green,
        scaffoldBackgroundColor: const Color.fromRGBO(19, 167, 76, 1),
      ),
      debugShowCheckedModeBanner: false,
      home:
          const LoginScreen(), // 👈 Make sure this is a `const` if defined that way
    );
  }
}
