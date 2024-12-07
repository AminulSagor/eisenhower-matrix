import 'package:eisenhower_matrix/screens/authentication/login_screen.dart';
import 'package:eisenhower_matrix/screens/note/home_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load();

  MobileAds.instance.initialize();

  final SharedPreferences prefs = await SharedPreferences.getInstance();
  final token = prefs.getString('accessToken');

  runApp(MyApp(initialScreen: token != null ? const HomePage() : const LoginScreen()));
}

class MyApp extends StatelessWidget {
  final Widget initialScreen;

  const MyApp({super.key, required this.initialScreen});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Eisenhower Matrix',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: initialScreen,
    );
  }
}
