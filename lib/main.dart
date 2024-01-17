import 'package:flutter/material.dart';
import 'package:rusty_chains/home_page.dart';
import 'package:rusty_chains/tournament.dart';
import 'package:url_strategy/url_strategy.dart';

import 'api.dart';
import 'logged_in.dart';

void main() {
  setPathUrlStrategy();
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  final _apiService = ApiService();

  MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Front Page',
      themeMode: ThemeMode.dark,
      darkTheme: ThemeData(
        brightness: Brightness.dark,
      ),
      onGenerateRoute: (settings) {
        print('Attempting to generate route for URL: ${settings.name}');
        final Uri uri = Uri.parse(settings.name!);
        if (uri.pathSegments.length == 2 &&
            uri.pathSegments.first == 'tournaments') {
          final id = int.parse(uri.pathSegments[1]);
          print('Generating route for tournament with ID: $id');
          return MaterialPageRoute(
            builder: (context) => FutureBuilder<bool>(
              future: _apiService.checkCookie(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const CircularProgressIndicator();
                } else {
                  if (snapshot.data == true) {
                    return TournamentDetailsPage(id: id);
                  } else {
                    return const CombinedLoginScreen();
                  }
                }
              },
            ),
          );
        }
        print('Generating default route');
        return MaterialPageRoute(
          builder: (context) => FutureBuilder<bool>(
            future: _apiService.checkCookie(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const CircularProgressIndicator();
              } else {
                if (snapshot.data == true) {
                  return const TournamentsPage();
                } else {
                  return const CombinedLoginScreen();
                }
              }
            },
          ),
        );
      },
      initialRoute: '/',
    );
  }
}
