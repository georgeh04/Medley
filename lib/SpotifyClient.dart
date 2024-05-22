import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_web_auth/flutter_web_auth.dart';
import 'package:hive/hive.dart';

class SpotifyAuthService {
  final String clientId = '86c941a5eab047739d80c6fbfa845abe';
  final String clientSecret = '56640be9f7a945f3be57e13ec1dd2d19';
  final String redirectUri = 'medleyapp://callback';
  final FlutterSecureStorage storage = FlutterSecureStorage();

  Future<String?> requestSpotifyAuthorizationCode() async {
    final String scopes = 'user-read-currently-playing';
    final String url =
        'https://accounts.spotify.com/authorize?client_id=$clientId&response_type=code&redirect_uri=$redirectUri&scope=$scopes';

    final result = await FlutterWebAuth.authenticate(
      url: url,
      callbackUrlScheme: redirectUri.split('://')[0],
    );

    var code = Uri.parse(result).queryParameters['code'];
    return code;
  }

  Future<String?> exchangeAuthorizationCode(String code) async {
    final response = await http.post(
      Uri.parse('https://accounts.spotify.com/api/token'),
      headers: {
        'Content-Type': 'application/x-www-form-urlencoded',
        'Authorization':
            'Basic ' + base64Encode(utf8.encode('$clientId:$clientSecret')),
      },
      body: {
        'grant_type': 'authorization_code',
        'code': code,
        'redirect_uri': redirectUri,
      },
    );

    if (response.statusCode == 200) {
      final Map<String, dynamic> responseBody = json.decode(response.body);
      final String accessToken = responseBody['access_token'];
      return accessToken;
    } else {
      throw Exception('Failed to exchange authorization code for access token');
    }
  }

  Future<void> storeAccessToken(String accessToken) async {
    await storage.write(key: 'spotifyAccessToken', value: accessToken);
  }
}
