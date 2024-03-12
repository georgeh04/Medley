import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

Future _saveLastFmDetails() async {
  final storage = new FlutterSecureStorage();

  // Save the token
  await storage.write(key: 'lastFmToken', value: '');

  // Save the API key
  await storage.write(key: 'lastFmApiKey', value: '');
}

class LastFMLoginPage extends StatefulWidget {
  @override
  _LastFMLoginPageState createState() => _LastFMLoginPageState();
}

class _LastFMLoginPageState extends State {
  String _token = '';
  String _apiKey = '';

  Future _loginToLastFm() async {
    // Step 1: Redirect the user to the Last.fm login page
    final redirectUri = Uri.parse('https://last.fm/api/auth');
    final response = await http.get(redirectUri);

    // Step 2: User authenticates and authorizes your app
    // This step is handled by Last.fm and will redirect the user back to your app

    // Step 3: Redirect the user back to your app
    var token = response.request?.url.queryParameters['token'];

    setState(() {
      _token = token!;
    });

    // Step 4: Use the authorization token to get an API key
    if (_token.isNotEmpty) {
      final apiKeyResponse = await http.post(
          Uri.parse('https://last.fm/api/auth/getSession'),
          headers: {
            'Content-Type': 'application/x-www-form-urlencoded',
          },
          body:
              'token=$_token&api_key=your_api_key&api_sig=your_api_signature');

      final apiKeyJson = jsonDecode(apiKeyResponse.body);
      setState(() {
        _apiKey = apiKeyJson['session']['key'];
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Last.fm Login'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _token.isNotEmpty ? Text('Token: $_token') : Text('Not logged in'),
            _apiKey.isNotEmpty
                ? Text('API Key: $_apiKey')
                : Text('Not logged in'),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: _loginToLastFm,
              child: Text('Login to Last.fm'),
            ),
          ],
        ),
      ),
    );
  }
}
