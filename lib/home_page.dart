import 'package:flutter/material.dart';

import 'api.dart';
import 'logged_in.dart'; // Import the HomePage widget

class CombinedLoginScreen extends StatefulWidget {
  const CombinedLoginScreen({Key? key}) : super(key: key);

  @override
  _CombinedLoginScreenState createState() => _CombinedLoginScreenState();
}

class _CombinedLoginScreenState extends State<CombinedLoginScreen> {
  final _sharedFormKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: const Key('login_screen'),
      appBar: AppBar(
        title: const Text('Register/Login'),
      ),
      body: buildLoginForm(),
    );
  }

  Form buildLoginForm() {
    return Form(
      key: _sharedFormKey,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: <Widget>[
            buildTextField(_usernameController, 'Username'),
            const SizedBox(height: 16),
            buildTextField(_passwordController, 'Password', obscureText: true),
            const SizedBox(height: 16),
            buildRegisterButton(),
            const SizedBox(height: 16),
            buildLoginButton(),
          ],
        ),
      ),
    );
  }

  TextFormField buildTextField(TextEditingController controller, String label,
      {bool obscureText = false}) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(labelText: label),
      obscureText: obscureText,
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Please enter your $label';
        }
        return null;
      },
    );
  }

  ElevatedButton buildRegisterButton() {
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        minimumSize: Size(200, 100), // Set the minimum size
      ),
      onPressed: () {
        if (_sharedFormKey.currentState?.validate() == true) {
          showDialog(
            context: context,
            barrierDismissible: false,
            builder: (BuildContext context) {
              return Container(
                child: buildFutureBuilder(ApiService().createUser(
                    _usernameController.text, _passwordController.text)),
              );
            },
          );
        }
      },
      child: const Text(
        'Register',
        style: TextStyle(fontSize: 20),
      ),
    );
  }

  ElevatedButton buildLoginButton() {
    return ElevatedButton(
      onPressed: () {
        if (_sharedFormKey.currentState?.validate() == true) {
          showDialog(
            context: context,
            barrierDismissible: false,
            builder: (BuildContext context) {
              return Container(
                child: buildFutureBuilder(ApiService().loginUser(
                    _usernameController.text, _passwordController.text)),
              );
            },
          );
        }
      },
      style: ElevatedButton.styleFrom(
        minimumSize: const Size(200, 200), // Set the minimum size
      ),
      child: const Text('Login', style: TextStyle(fontSize: 20)),
    );
  }

  FutureBuilder buildFutureBuilder(Future future) {
    return FutureBuilder(
      future: future,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const CircularProgressIndicator();
        } else if (snapshot.hasError) {
          try {
            throw Exception(snapshot.error);
          } catch (e) {
            //print(e);
          }
          return Container();
        } else if (snapshot.data != null) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                  builder: (context) => const TournamentsPage(),
                  settings: const RouteSettings(name: '/tournaments')),
            );
          });
        }
        return Container();
      },
    );
  }
}
