import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

var userData = User();
var backlogIds = [];
var listenedIds = [];
var notReviewedIds = [];
var reviewedIds = [];
var userTags = [];

class Globals extends ChangeNotifier {
  String mode = 'games';

  void updateMode(String newMode) {
    mode = newMode;
    notifyListeners();
  }
}

class User {
  static final User _instance = User._internal();

  // Factory constructor
  factory User() {
    return _instance;
  }

  // Internal constructor
  User._internal();

  // Properties
  String username = '';
  String userId = '';
  String accesstoken = '';
  String profilePictureUrl = '';
  String displayName = '';

  // Methods to update the properties if needed
  void setUsername(String newUsername) {
    username = newUsername;
  }

  void setUserId(String newUserId) {
    userId = newUserId;
  }

  void setAccessToken(String newSessionId) {
    accesstoken = newSessionId;
  }
}

void addToLibrary(String userId, String accessToken, String albumId) async {
  final response = await http.post(
    Uri.parse('https://app.medleyapp.co.uk/library_add_album.php'),
    body: {
      'userid': userData.userId,
      'access_token': userData.accesstoken,
      'album_id': albumId,
      'type': 'Add to Library',
    },
  );

  if (response.statusCode == 200) {
    print('Added to library successfully');
  } else {
    print('Error adding to library: ${response.body}');
  }
}

void removeFromLibrary(String userId, String accessToken, String albumId) async {
  final response = await http.post(
    Uri.parse('https://app.medleyapp.co.uk/library_remove_album.php'),
    body: {
      'userid': userData.userId,
      'access_token': userData.accesstoken,
      'album_id': albumId,
    },
  );

  if (response.statusCode == 200) {
    print('response is ${response.body}');
  } else {
    print('Error removing from library: ${response.body}');
  }
}

void moveToListened(String userId, String accessToken, String albumId) async {
  final response = await http.post(
    Uri.parse('https://app.medleyapp.co.uk/library_add_album.php'),
    body: {
      'userid': userData.userId,
      'access_token': userData.accesstoken,
      'album_id': albumId,
      'type': 'Move to Listened',
    },
  );

  if (response.statusCode == 200) {
    print('${response.body}');
  } else {
    print('Error moving to listened: ${response.body}');
  }
}

void moveToBacklog(String userId, String accessToken, String albumId) async {
  final response = await http.post(
    Uri.parse('https://app.medleyapp.co.uk/library_add_album.php'),
    body: {
      'userid': userData.userId,
      'access_token': userData.accesstoken,
      'album_id': albumId,
      'type': 'Move to Backlog',
    },
  );

  if (response.statusCode == 200) {
    print('Moved to backlog successfully');
  } else {
    print('Error moving to backlog: ${response.body}');
  }
}

// Add similar functions for 'Info' and 'Remove from List' options
