import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'api.dart';
import 'logged_in.dart'; // Import the HomePage widget

class CombinedLoginScreen extends StatefulWidget {
  const CombinedLoginScreen({super.key});

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
      child: KeyboardListener(
        focusNode: FocusNode(),
        onKeyEvent: (KeyEvent event) {
          if (event.logicalKey == LogicalKeyboardKey.enter) {
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
          }
        },
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: <Widget>[
              TextFormField(
                controller: _usernameController,
                decoration: const InputDecoration(labelText: "Username"),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter your username';
                  } else if (value.trim() != value) {
                    return 'Username cannot contain whitespace';
                  }
                  return null;
                },
                autofillHints: const [AutofillHints.username],
              ),
              const SizedBox(height: 16),
              TextFormField(
                  controller: _passwordController,
                  decoration: const InputDecoration(labelText: "Password"),
                  obscureText: true,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter your password';
                    }
                    return null;
                  },
                  autofillHints: const [AutofillHints.password]),
              const SizedBox(height: 16),
              Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    buildRegisterButton(),
                    const SizedBox(width: 16),
                    buildLoginButton()
                  ]),
            ],
          ),
        ),
      ),
    );
  }

  ElevatedButton buildRegisterButton() {
    return ElevatedButton(
      /*style: ElevatedButton.styleFrom(
        minimumSize: const Size(500, 100), // Set the minimum size
      ),*/
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
      /*style: ElevatedButton.styleFrom(
        minimumSize: const Size(500, 100), // Set the minimum size
      ),*/
      child: const Text('Login', style: TextStyle(fontSize: 20)),
    );
  }

  FutureBuilder buildFutureBuilder(Future future) {
    return FutureBuilder(
      future: future,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: SizedBox(
              width: 50,
              height: 50,
              child: CircularProgressIndicator(
                strokeCap: StrokeCap.round,
              ),
            ),
          );
        } else if (snapshot.hasError) {
          Navigator.pop(context);
          String? errorMessage = (snapshot.error is DioException)
              ? (snapshot.error as DioException).response?.data
              : snapshot.error.toString();
          WidgetsBinding.instance.addPostFrameCallback((_) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  errorMessage ?? 'Unknown error occurred',
                ),
                duration: const Duration(seconds: 5),
                backgroundColor: Colors.red,
              ),
            );
          });
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
