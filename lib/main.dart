import 'package:flutter/material.dart';
import 'screens/home_screen.dart';

void main() {
  runApp(const Pr10App());
}

class Pr10App extends StatelessWidget {
  const Pr10App({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ПР-10 СМО',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(useMaterial3: true, colorSchemeSeed: Colors.blue),
      home: const HomeScreen(),
    );
  }
}
