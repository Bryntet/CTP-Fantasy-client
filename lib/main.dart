import 'package:dynamic_color/dynamic_color.dart';
import 'package:flutter/material.dart';
import 'package:rusty_chains/home_page.dart';
import 'package:rusty_chains/tournament.dart';

import 'api.dart';
import 'logged_in.dart';

void main() {
  //setPathUrlStrategy();
  runApp(MyApp());
}

const _brandBlue = Color(0xFFFF9400);

class MyApp extends StatelessWidget {
  final _apiService = ApiService();

  MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return DynamicColorBuilder(
      builder: (ColorScheme? lightDynamic, ColorScheme? darkDynamic) {
        ColorScheme lightColorScheme;
        ColorScheme darkColorScheme;

        if (lightDynamic != null && darkDynamic != null) {
          // On Android S+ devices, use the provided dynamic color scheme.
          // (Recommended) Harmonize the dynamic color scheme' built-in semantic colors.
          lightColorScheme = lightDynamic.harmonized();
          // (Optional) Customize the scheme as desired. For example, one might
          // want to use a brand color to override the dynamic [ColorScheme.secondary].
          lightColorScheme = lightColorScheme.copyWith(secondary: _brandBlue);
          // (Optional) If applicable, harmonize custom colors.

          // Repeat for the dark color scheme.
          darkColorScheme = darkDynamic.harmonized();
          darkColorScheme = darkColorScheme.copyWith(secondary: _brandBlue);
        } else {
          // Otherwise, use fallback schemes.
          lightColorScheme = ColorScheme.fromSeed(
            seedColor: _brandBlue,
          );
          darkColorScheme = ColorScheme.fromSeed(
            seedColor: _brandBlue,
            brightness: Brightness.dark,
          );
        }

        return MaterialApp(
          title: 'Front Page',
          themeMode: ThemeMode.dark,
          theme:
              ThemeData.from(colorScheme: lightColorScheme, useMaterial3: true),
          darkTheme:
              ThemeData.from(colorScheme: darkColorScheme, useMaterial3: true),
          onGenerateRoute: (settings) {
            print('Attempting to generate route for URL: ${settings.name}');
            final Uri uri = Uri.parse(settings.name!);
            if (uri.pathSegments.length == 2 &&
                uri.pathSegments.first == 'tournament') {
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
      },
    );
  }
}
