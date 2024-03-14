import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:hive/hive.dart';
import 'package:path_provider/path_provider.dart';

// medley login



// Last.fm Section

String? lastfmSession = '';
bool lastfmConnected = false;
String? lastfmUsername = '';



Future initialiseLastfm() async {
  final appDocumentDirectory = await getApplicationDocumentsDirectory();
  Hive.init(appDocumentDirectory.path);
  lastfmConnected = await Hive.boxExists('lastfmData');
  print('last fm connected? $lastfmConnected');
  if (lastfmConnected == false) {
    return null;
  } else {
    var lastfm = await Hive.openBox('lastfmData');
    lastfmSession = await lastfm.get('lastfmSession');
    var info =
        await getUserInfo('cad200fbadbeb49cbd8b060607a0ccf5', lastfmSession!);
    print('user info here ${info}');
    lastfmUsername = info!['name'];
  }
}

Future<Map<String, dynamic>?> getUserInfo(
    String apiKey, String sessionKey) async {
  final String apiUrl = 'https://ws.audioscrobbler.com/2.0/';
  final Map<String, String> params = {
    'method': 'user.getinfo',
    'api_key': apiKey,
    'sk': sessionKey,
    'format': 'json',
  };

  try {
    // Build the URL with query parameters
    final uri = Uri.parse(apiUrl).replace(queryParameters: params);
    // Make the HTTP GET request
    final response = await http.get(uri);

    if (response.statusCode == 200) {
      // Parse the JSON response
      final Map<String, dynamic> jsonResponse = json.decode(response.body);
      // Extract and return user information
      return jsonResponse['user'];
    } else {
      // Handle errors or unexpected responses
      print(
          'Failed to load user info with status code: ${response.statusCode}');
      return null;
    }
  } catch (e) {
    // Handle any exceptions
    print('Exception occurred: $e');
    return null;
  }
}
