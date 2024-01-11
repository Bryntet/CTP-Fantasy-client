import 'dart:convert';
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:dio_cookie_manager/dio_cookie_manager.dart';
import 'package:cookie_jar/cookie_jar.dart';
import 'api-classes.dart';

class ApiService {
  static final ApiService _instance = ApiService._internal();
  final Dio _dio;
  final url = "http://127.0.0.1:8000/api";

  List<Cookie> cookies = [];

  factory ApiService() {
    return _instance;
  }

  ApiService._internal()
      : _dio = Dio()..interceptors.add(CookieManager(PersistCookieJar())) {
    _loadCookies();
  }

  Future<void> _loadCookies() async {
    var cookieJar = PersistCookieJar();
    var uri = Uri.parse(url);
    cookies = await cookieJar.loadForRequest(uri);
    print('Cookies: $cookies');
  }

  Future<String?> createUser(String username, String password) async {
    final response = await _dio.post(
      '$url/create-user',
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
    return response.statusMessage;
  }

  Future<String?> loginUser(String username, String password) async {
    final response = await _dio.post(
      '$url/login',
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
    return response.statusMessage;
  }

  Future<List<FantasyTournament>> getFantasyTournaments() async {
    final response = await _dio.get(
      '$url/my-tournaments',
    );

    List<FantasyTournament> tournaments = (response.data as List<dynamic>)
        .map((item) => FantasyTournament.fromJson(item as Map<String, dynamic>))
        .toList();

    return tournaments;
  }

  Future<void> createFantasyTournament(
      FantasyTournamentInput tournament) async {
    await _dio.post(
      '$url/create-fantasy-tournament',
      options: Options(
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
        },
      ),
      data: jsonEncode(tournament.toJson()),
    );
  }

  Future<List<Participant>> getFantasyTournamentParticipants(int id) async {
    final response = await _dio.get(
      '$url/fantasy-tournament/$id/participants',
    );

    List<Participant> participants = (response.data as List<dynamic>)
        .map((item) => Participant.fromJson(item as Map<String, dynamic>))
        .toList();

    return participants;
  }

  Future<String?> inviteUser(int tournamentId, String username) async {
    final response = await _dio.post(
      '$url/fantasy-tournament/$tournamentId/invite/$username',
    );
    return response.statusMessage;
  }

  Future<void> answerInvitation(int tournamentId, bool response) async {
    await _dio.post(
      '$url/fantasy-tournament/$tournamentId/answer-invite/$response',
    );
  }

  Future<void> pickPlayer(int tournamentId, int slot, int pdgaNumber) async {
    await _dio.put(
      '$url/fantasy-tournament/$tournamentId/pick/$slot/player/$pdgaNumber',
    );
  }

  Future<SimpleFantasyPicks> getUserPicks(int tournamentId, int userId) async {
    final response = await _dio.get(
      '$url/fantasy-tournament/$tournamentId/user_picks/$userId',
    );

    return SimpleFantasyPicks.fromJson(response.data as Map<String, dynamic>);
  }

  Future<bool> checkCookie() async {
    try {
      final response = await _dio.get('$url/check-cookie');
      return response.statusCode == 200;
    } catch (e) {
      print(e);
      return false;
    }
  }

  Future<void> logout() async {
    await _dio.post(
      '$url/logout',
    );
  }

  Future<void> logoutAll() async {
    await _dio.post(
      '$url/logout-all',
    );
  }
}
