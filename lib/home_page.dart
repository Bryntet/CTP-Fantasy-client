
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
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
      appBar: AppBar(
        title: const Text('Register/Login'),
      ),
      body: Column(
        children: <Widget>[
          Form(
            key: _sharedFormKey,
            child: Column(
              children: <Widget>[
                TextFormField(
                  controller: _usernameController,
                  decoration: const InputDecoration(labelText: 'Username'),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter your username';
                    }
                    return null;
                  },
                ),
                TextFormField(
                  controller: _passwordController,
                  decoration: const InputDecoration(labelText: 'Password'),
                  obscureText: true,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter your password';
                    }
                    return null;
                  },
                ),
                ElevatedButton(
                  onPressed: () async {
                    if (_sharedFormKey.currentState?.validate() == true) {
                      try {
                        await ApiService().createUser(
                            _usernameController.text, _passwordController.text);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('User created successfully'),
                            backgroundColor: Colors.green, // success color
                          ),
                        );
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const HomePage()),
                        );
                      } catch (e) {
                        if (e is DioError) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(e.response?.data),
                              backgroundColor: Colors.red, // error color
                            ),
                          );
                        }
                      }
                    }
                  },
                  child: const Text('Register'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    if (_sharedFormKey.currentState?.validate() == true) {
                      try {
                        await ApiService().loginUser(
                            _usernameController.text, _passwordController.text);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('User logged in successfully'),
                            backgroundColor: Colors.green, // success color
                          ),
                        );
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const HomePage()),
                        );
                      } catch (e) {
                        if (e is DioError) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(e.response?.data ??
                                  'An error occurred'), // Use a default string if e.response?.data is null
                              backgroundColor: Colors.red, // error color
                            ),
                          );
                        }
                      }
                    }
                  },
                  child: const Text('Login'),
                )
              ],
            ),
          ),
        ],
      ),
    );
  }
}
