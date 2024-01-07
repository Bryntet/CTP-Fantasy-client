import 'package:flutter/material.dart';
import 'package:rusty_chains/home_page.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Front Page',
      themeMode: ThemeMode.dark, // Set the theme mode to dark
      darkTheme: ThemeData(
        brightness: Brightness.dark,
        // Add any other theme customization you want
      ),
      home: CombinedLoginScreen(),
    );
  }
}
