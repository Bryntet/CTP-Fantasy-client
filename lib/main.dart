import 'package:flutter/material.dart';
import 'package:rusty_chains/home_page.dart';

import 'api.dart';
import 'logged_in.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  final _apiService = ApiService();

  MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<bool>(
      future: _apiService.checkCookie(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const CircularProgressIndicator();
        } else {
          if (snapshot.data == true) {
            return MaterialApp(
              title: 'Front Page',
              themeMode: ThemeMode.dark,
              darkTheme: ThemeData(
                brightness: Brightness.dark,
              ),
              home: const HomePage(),
            );
          } else {
            return MaterialApp(
              title: 'Front Page',
              themeMode: ThemeMode.dark,
              darkTheme: ThemeData(
                brightness: Brightness.dark,
              ),
              home: const CombinedLoginScreen(),
            );
          }
        }
      },
    );
  }
}
