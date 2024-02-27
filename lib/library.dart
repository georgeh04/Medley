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
    return Consumer<PlaybackState>(
        builder: (context, playbackState, child) => Scaffold(
              appBar: AppBar(
                bottom: TabBar(
                  controller: _tabController,
                  tabs: [
                    Tab(text: 'Artists'),
                    Tab(text: 'Songs'),
                    Tab(text: 'Albums'),
                  ],
                ),
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
                                // Implement navigation or action when tapping on an artist
                                print('Tapped on ${artist.name}');
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
                              leading: Icon(Icons.music_note),
                              title: Text(song.title),
                              subtitle: Text(song
                                  .artistName), // Assuming Song has an artistName field
                              onTap: () {
                                setState(() {
                                  playbackState.playSong(song.path, song.title);
                                });
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
                              leading: Container(
                                child: Image.network(
                                    'https://placehold.jp/150x150.png'),
                              ),
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
            ));
  }
}

class ArtistsView extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Artist>>(
      future: fetchArtists(), // Assuming this function is defined in db.dart
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
                  // Implement navigation or action when tapping on an artist
                  print('Tapped on ${artist.name}');
                },
              );
            },
          );
        } else {
          return Text("No artists found");
        }
      },
    );
  }
}

class AlbumsView extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Album>>(
      future: fetchAlbums(), // Assuming this function is defined in db.dart
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
                leading: Icon(Icons.album),
                title: Text(album.title),
                subtitle: Text(
                    album.artistName), // Assuming Album has an artistName field
                onTap: () {
                  // Implement navigation or action when tapping on an album
                  print('Tapped on ${album.title}');
                },
              );
            },
          );
        } else {
          return Text("No albums found");
        }
      },
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

  Song(
      {required this.id,
      required this.title,
      required this.artistId,
      required this.albumId,
      required this.artistName,
      required this.path,
      required this.trackNumber,
      required this.duration});

  factory Song.fromMap(Map<String, dynamic> map) {
    return Song(
        id: map['id'],
        title: map['title'],
        artistId: map['artistId'],
        albumId: map['albumId'],
        artistName: map['artistName'], // Map this from the query result
        path: map['filePath'],
        trackNumber: map['trackNumber'],
        duration: map['duration']);
  }
}

class Album {
  final int id;
  final String title;
  final int artistId;
  final String artistName; // Add artist name

  Album({
    required this.id,
    required this.title,
    required this.artistId,
    required this.artistName,
  });

  factory Album.fromMap(Map<String, dynamic> map) {
    return Album(
      id: map['id'],
      title: map['name'],
      artistId: map['artistId'],
      artistName: map['artistName'], // Map this from the query result
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
    SELECT Songs.*, Artists.name AS artistName 
    FROM Songs
    JOIN Artists ON Songs.artistId = Artists.id
  ''');

  return List.generate(maps.length, (i) {
    return Song.fromMap(maps[i]);
  });
}

Future<List<Album>> fetchAlbums() async {
  var db = await openDb();
  // Perform a join to get the artist's name along with the album's details
  final List<Map<String, dynamic>> maps = await db.rawQuery('''
    SELECT Albums.*, Artists.name AS artistName 
    FROM Albums
    JOIN Artists ON Albums.artistId = Artists.id
  ''');

  print('Albums: $maps');

  return List.generate(maps.length, (i) {
    return Album.fromMap(maps[i]);
  });
}
