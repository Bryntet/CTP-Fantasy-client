import 'package:flutter/material.dart';
import 'package:rusty_chains/register.dart';

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
      home: Scaffold(
        appBar: AppBar(
          title: Text('Front Page'),
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              ElevatedButton(
                onPressed: () {
                  // Navigate to Login Page
                },
                child: Text('Login'),
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => RegisterScreen()),
                  );
                },
                child: Text('Register'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
