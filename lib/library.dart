import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:medleylibrary/AlbumPage.dart';
import 'package:medleylibrary/db.dart'; // Ensure this file has the necessary functions to interact with the database
import 'package:flutter/material.dart';
import 'package:sqflite/sqlite_api.dart';
import 'library.dart';
import 'package:provider/provider.dart';
import 'package:just_audio/just_audio.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:io';
import 'db.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'main.dart';
import 'ArtistPage.dart';
import 'audiomanager.dart';

class MusicLibraryPage extends StatefulWidget {
  @override
  _MusicLibraryPageState createState() => _MusicLibraryPageState();
}

class _MusicLibraryPageState extends State<MusicLibraryPage>
    with SingleTickerProviderStateMixin {
  TabController? _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: TabBar(
        controller: _tabController,
        tabs: [
          Tab(text: 'Artists'),
          Tab(text: 'Songs'),
          Tab(text: 'Albums'),
        ],
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          FutureBuilder<List<Artist>>(
            future:
                fetchArtists(), // Assuming this function is defined in db.dart
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return Center(child: CircularProgressIndicator());
              } else if (snapshot.hasError) {
                return Text("Error: ${snapshot.error}");
              } else if (snapshot.hasData) {
                return ListView.builder(
                  itemCount: snapshot.data!.length,
                  itemBuilder: (context, index) {
                    Artist artist = snapshot.data![index];
                    return ListTile(
                      leading: Icon(Icons.person),
                      title: Text(artist.name),
                      onTap: () {
                        Navigator.push(context,
                            MaterialPageRoute(builder: (context) {
                          return ArtistPage(
                              artistId: artist.id, artistName: artist.name);
                        }));
                      },
                    );
                  },
                );
              } else {
                return Text("No artists found");
              }
            },
          ),
          FutureBuilder<List<Song>>(
            future:
                fetchSongs(), // Assuming this function is defined in db.dart
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return Center(child: CircularProgressIndicator());
              } else if (snapshot.hasError) {
                return Text("Error: ${snapshot.error}");
              } else if (snapshot.hasData) {
                return ListView.builder(
                  itemCount: snapshot.data!.length,
                  itemBuilder: (context, index) {
                    Song song = snapshot.data![index];
                    return ListTile(
                      leading: Container(
                        child: Image.network(song.coverUrl),
                      ),
                      title: Text(song.title),
                      subtitle: Text(song
                          .artistName), // Assuming Song has an artistName field
                      onTap: () {
                        PlaybackManager().playSongObject(song);
                      },
                    );
                  },
                );
              } else {
                return Text("No songs found");
              }
            },
          ),
          FutureBuilder<List<Album>>(
            future:
                fetchAlbums(), // Assuming this function is defined in db.dart
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return Center(child: CircularProgressIndicator());
              } else if (snapshot.hasError) {
                return Text("Error: ${snapshot.error}");
              } else if (snapshot.hasData) {
                return ListView.builder(
                  itemCount: snapshot.data!.length,
                  itemBuilder: (context, index) {
                    Album album = snapshot.data![index];
                    return ListTile(
                      leading: Image.network(album.coverUrl),
                      title: Text(album.title),
                      subtitle: Text(album
                          .artistName), // Assuming Album has an artistName field
                      onTap: () {
                        Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (context) =>
                                    AlbumPage(albumId: album.id)));
                      },
                    );
                  },
                );
              } else {
                return Text("No albums found");
              }
            },
          ),
        ],
      ),
    );
  }
}

// You'll need to define these classes based on your actual database schema
class Artist {
  final int id;
  final String name;

  Artist({required this.id, required this.name});

  // Method to create an Artist from a map (for example, from a database row)
  factory Artist.fromMap(Map<String, dynamic> map) {
    return Artist(
      id: map['id'],
      name: map['name'],
    );
  }
}

class Song {
  final int id;
  final String title;
  final int artistId;
  final int albumId;
  final String artistName; // Add artist name
  final String path;
  final int trackNumber;
  final int duration;
  final String albumName; // Add album name
  final String coverUrl;

  Song(
      {required this.id,
      required this.title,
      required this.artistId,
      required this.albumId,
      required this.artistName,
      required this.path,
      required this.trackNumber,
      required this.duration,
      required this.albumName,
      required this.coverUrl});

  factory Song.fromMap(Map<String, dynamic> map) {
    return Song(
        id: map['id'],
        title: map['title'],
        artistId: map['artistId'],
        albumId: map['albumId'],
        artistName: map['artistName'], // Map this from the query result
        path: map['filePath'],
        trackNumber: map['trackNumber'],
        duration: map['duration'],
        albumName: map['albumName'],
        coverUrl: map['coverUrl']); // Map this from the query result
  }
}

class Album {
  final int id;
  final String title;
  final int artistId;
  final String artistName; // Add artist name
  final String coverUrl;

  Album({
    required this.id,
    required this.title,
    required this.artistId,
    required this.artistName,
    required this.coverUrl,
  });

  factory Album.fromMap(Map<String, dynamic> map) {
    return Album(
      id: map['id'],
      title: map['name'],
      artistId: map['artistId'],
      artistName: map['artistName'],
      coverUrl: map['coverUrl'],
    );
  }
}

Future<List<Artist>> fetchArtists() async {
  // Placeholder for database fetch logic
  // Let's assume you're using SQLite and have a dbHelper instance
  var db = await openDb();
  final List<Map<String, dynamic>> maps = await db.query('artists');

  return List.generate(maps.length, (i) {
    return Artist.fromMap(maps[i]);
  });
}

Future<List<Song>> fetchSongs() async {
  var db = await openDb();
  // Perform a join to get the artist's name along with the song's details
  final List<Map<String, dynamic>> maps = await db.rawQuery('''
    SELECT Songs.*, Artists.name AS artistName, Albums.name AS albumName, Albums.coverUrl AS coverUrl
    FROM Songs
    JOIN Artists ON Songs.artistId = Artists.id
    JOIN Albums ON Songs.albumId = Albums.id

  ''');

  return List.generate(maps.length, (i) {
    return Song.fromMap(maps[i]);
  });
}

Future<List<Album>> fetchAlbums() async {
  final db = await openDb();
  // Include coverUrl in the SELECT clause
  final List<Map<String, dynamic>> maps = await db.rawQuery('''
    SELECT Albums.*, Artists.name AS artistName, Albums.coverUrl AS coverUrl
    FROM Albums
    JOIN Artists ON Albums.artistId = Artists.id
  ''');

  print('Albums: $maps');

  return List.generate(maps.length, (i) {
    // Ensure the Album.fromMap constructor correctly handles the coverUrl
    return Album.fromMap(maps[i]);
  });
}
