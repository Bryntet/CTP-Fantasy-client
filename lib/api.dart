import 'dart:convert';

import 'package:cookie_jar/cookie_jar.dart';
import 'package:dio/dio.dart';
import 'package:dio_cookie_manager/dio_cookie_manager.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_prefs_cookie_store/shared_prefs_cookie_store.dart';

import 'api_classes.dart';

class ApiService {
  static final ApiService _instance = ApiService._internal();
  final Dio _dio;
  final url = {
    kDebugMode ? 'http://localhost:8000/api' : 'https://rustlingchains.com/api'
  }.first;
  final SharedPrefCookieStore _cookieStore = SharedPrefCookieStore();

  List<Cookie> cookies = [];

  factory ApiService() {
    return _instance;
  }

  void init() {
    _dio.interceptors.add(CookieManager(kIsWeb ? CookieJar() : _cookieStore));
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          if (kDebugMode) {
            print('Sending request to ${options.uri}');
          }
          return handler.next(options);
        },
        onResponse: (response, handler) {
          if (kDebugMode) {
            print('Received response: $response');
          }
          return handler.next(response);
        },
        onError: (DioException error, handler) {
          if (kDebugMode) {
            print(
                'Error occurred: ${error.response?.statusCode}: ${error.response?.data}');
          }
          return handler.next(error);
        },
      ),
    );
  }

  ApiService._internal() : _dio = Dio() {
    init();
  }

  Future<void> _loadCookies() async {
    if (!kIsWeb) {
      //await requestStoragePermission();
      var cookieJar = _cookieStore;
      var uri = Uri.parse(url);
      cookies = await cookieJar.loadForRequest(uri);
      print('Cookies: $cookies');
    }
  }

  Future<String?> createUser(String username, String password) async {
    final response = await _dio.post(
      '$url/create-user',
      options: Options(
        contentType: Headers.jsonContentType,
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
        contentType: Headers.jsonContentType,
      ),
      data: jsonEncode(<String, String>{
        'username': username,
        'password': password,
      }),
    );
    return response.statusMessage;
  }

  Future<FantasyTournament> getFantasyTournament(int id) async {
    final response = await _dio.get(
      '$url/fantasy-tournament/$id',
    );
    return FantasyTournament.fromJson(response.data as Map<String, dynamic>);
  }

  Future<List<FantasyTournament>> getFantasyTournaments() async {
    _loadCookies();
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
      '$url/fantasy-tournament',
      options: Options(contentType: Headers.jsonContentType),
      data: jsonEncode(tournament.toJson()),
    );
  }

  Future<List<Participant>> getFantasyTournamentParticipants(int id) async {
    final response = await _dio.get(
      '$url/fantasy-tournament/$id/users',
    );

    List<Participant> participants = (response.data as List<dynamic>)
        .map((item) => Participant.fromJson(item as Map<String, dynamic>))
        .toList();

    return participants;
  }

  Future<int> getUserId() async {
    final response = await _dio.get('$url/my-id');
    return response.data;
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

  Future<void> pickPlayer(
      int tournamentId, int slot, int pdgaNumber, Division div) async {
    await _dio.put(
        '$url/fantasy-tournament/$tournamentId/user/${await getUserId()}/picks/div/${div.toString().split(".").last}/$slot/$pdgaNumber');
  }

  Future<Pick> getPick(
      int tournamentId, int slot, int userId, Division div) async {
    final response = await _dio.get(
      '$url/fantasy-tournament/$tournamentId/user/$userId/picks/div/${div.name}/slot/$slot',
    );

    return Pick.fromJson(response.data as Map<String, dynamic>);
  }

  Future<Picks> getUserPicks(int tournamentId, int userId, Division div) async {
    final response = await _dio.get(
      '$url/fantasy-tournament/$tournamentId/user/$userId/picks/div/${div.name}',
    );

    return Picks.fromJson(response.data as Map<String, dynamic>);
  }

  Future<bool> checkCookie() async {
    try {
      final response = await _dio.get('$url/check-cookie');
      return response.statusCode == 200;
    } catch (e) {
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

  Future<void> addPicks(
      int tournamentId, List<Pick> picks, Division div) async {
    await _dio.post(
      '$url/fantasy-tournament/$tournamentId/user/${await getUserId()}/picks/div/${div.name}',
      options: Options(contentType: Headers.jsonContentType),
      data: jsonEncode(picks),
    );
  }

  Future<int> maxPicks(int tournamentId) async {
    final response = await _dio.get(
      '$url/fantasy-tournament/$tournamentId/max-picks',
    );
    return response.data;
  }

  Future<List<Division>> getFantasyTournamentDivisions(int id) async {
    final response = await _dio.get('$url/fantasy-tournament/$id/divisions');

    List<Division> divisions = (response.data as List<dynamic>)
        .map((item) => DivisionExtension.fromJson(item as String))
        .toList();
    return divisions;
  }

  Future<String?> addCompetitionToFantasyTournament(
      int fantasyTournamentId, AddCompetition comp) async {
    var res = await _dio.post(
      '$url/fantasy-tournament/$fantasyTournamentId/competition/add',
      options: Options(
          contentType: Headers.jsonContentType,
          responseType: ResponseType.json),
      data: comp.toJson(),
    );
    return res.statusMessage;
  }

  Future<List<Competition>> getCompetitionsFromFantasyTournament(
      int fantasyTournamentId) async {
    final response = await _dio.get(
      '$url/fantasy-tournament/$fantasyTournamentId/competitions',
    );

    List<Competition> competitions = (response.data as List<dynamic>)
        .map((item) => Competition.fromJson(item as Map<String, dynamic>))
        .toList();

    return competitions;
  }
}
