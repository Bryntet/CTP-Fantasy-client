import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:dio_cookie_manager/dio_cookie_manager.dart';
import 'package:cookie_jar/cookie_jar.dart';

Future<void> createUser(String username, String password) async {
  var dio = Dio();
  var cj = CookieJar();
  dio.interceptors.add(CookieManager(cj));

  final response = await dio.post(
    'http://localhost:8000/api/create-user',
    options: Options(
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
      },
    ),
    data: jsonEncode(<String, String>{
      'username': username,
      'password': password,
    }),
  );

  if (response.statusCode == 200) {
    // Cookies will be stored in the CookieJar
    // You can retrieve them with cj.loadForRequest(Uri.parse('http://localhost:8000'))
  } else {
    throw Exception('Failed to create user');
  }
}
