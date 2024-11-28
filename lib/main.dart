import 'package:eisenhower_matrix/screens/authentication/login_screen.dart';
import 'package:eisenhower_matrix/screens/authentication/sign_up_page.dart';
import 'package:eisenhower_matrix/screens/note/create_note_screen.dart';
import 'package:eisenhower_matrix/screens/note/home_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

Future<void> main() async {
  await dotenv.load();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(

        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const LoginScreen(),
    );
  }
}

