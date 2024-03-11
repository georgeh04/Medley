import 'dart:convert';
import 'package:http/http.dart' as http;

class Album {
  final int id;
  final String title;
  final String imageUrl;

  Album({required this.id, required this.title, required this.imageUrl});

  factory Album.fromJson(Map<String, dynamic> json) {
    return Album(
      id: json['id'],
      title: json['title'],
      imageUrl: json['image'], // Adjust based on actual API response
    );
  }
}

class MusicStoreService {
  final String apiKey = 'YOUR_API_KEY_HERE';

  Future<List<Album>> fetchAlbums() async {
    final response = await http.get(Uri.parse(
        'https://api.7digital.com/1.2/album/search?q=test&oauth_consumer_key=$apiKey'));

    if (response.statusCode == 200) {
      List<dynamic> albumsJson = json.decode(response.body)['results'];
      return albumsJson.map((json) => Album.fromJson(json)).toList();
    } else {
      throw Exception('Failed to load albums');
    }
  }
}
