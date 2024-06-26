import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:Medley/AlbumPage.dart';
import 'package:Medley/db.dart'; // Ensure this file has the necessary functions to interact with the database
import 'ArtistPage.dart';
import 'package:sqflite/sqflite.dart';
import 'audiomanager.dart';
import 'dart:io';
import 'PlaylistPage.dart';
import 'main.dart';
import 'globals.dart';

class MusicLibraryPage extends StatefulWidget {
  @override
  _MusicLibraryPageState createState() => _MusicLibraryPageState();
}

class _MusicLibraryPageState extends State<MusicLibraryPage>
    with SingleTickerProviderStateMixin, AutomaticKeepAliveClientMixin {
  TabController? _tabController;
  bool get wantKeepAlive => true; // Indicates you want to keep the state alive

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

  Future addSongToPlaylist(int playlistId, int songId) async {
    final path = await getDatabasesPath();
    final db = await openDb();

    await db.insert('PlaylistSongs', {
      'playlistId': playlistId,
      'songId': songId,
    });

    final result = await db.query('PlaylistSongs');

    for (final row in result) {
      print('PlaylistId: ${result}');
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(
        context); // This is required when using AutomaticKeepAliveClientMixin

    return Scaffold(
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: <Widget>[
            UserAccountsDrawerHeader(
              accountName:
                  Text(userData.displayName), // Replace with actual user name
              accountEmail:
                  Text(userData.username), // Replace with actual user email
              currentAccountPicture: CircleAvatar(
                backgroundImage: NetworkImage(userData
                    .profilePictureUrl), // Replace with actual user profile picture URL
              ),
            ),
            ListTile(
              leading: Icon(Icons.reviews),
              title: Text('Reviews'),
              // No onTap action provided for "Reviews"
            ),
            ListTile(
              leading: Icon(Icons.settings),
              title: Text('Settings'),
              onTap: () {
                // Assuming showSettingsDialog is correctly implemented elsewhere
                showSettingsDialog(context, (String val) {
                  // Place to call setState or any other callback
                });
              },
            ),
          ],
        ),
      ),
      appBar: !Platform.isAndroid
          ? PreferredSize(
              preferredSize:
                  Size.fromHeight(kToolbarHeight), // Standard toolbar height
              child: TabBar(
                controller: _tabController,
                tabs: [
                  Tab(text: 'Artists'),
                  Tab(text: 'Songs'),
                  Tab(text: 'Albums'),
                ],
              ))
          : AppBar(
              leading: Builder(
                builder: (BuildContext context) {
                  return InkWell(
                    onTap: () {
                      Scaffold.of(context).openDrawer();
                    },
                    // Wrap CircleAvatar in a Container or Padding
                    child: Container(
                      margin: EdgeInsets.all(8), // Adjust the value as needed
                      child: CircleAvatar(
                        // The backgroundImage should remain unchanged
                        backgroundImage: NetworkImage(
                          userData.profilePictureUrl,
                        ),
                      ),
                    ),
                  );
                },
              ),
              title: Text(''),
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
                        navigatorKey.currentState!
                            .push(MaterialPageRoute(builder: (context) {
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
  future: fetchSongs(), // Assuming this function is defined in db.dart
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
          return GestureDetector(
            onSecondaryTap: () {
              showMenu(
                color: Colors.grey,
                context: context,
                position: RelativeRect.fill,
                items: [
                  PopupMenuItem(
                    value: 'edit',
                    child: Text('Add to Playlist'),
                    onTap: () {
                      showAddToPlaylistDialog(context, song.id, song.title);
                    },
                  ),
                ],
              );
            },
            child: ListTile(
              leading: Container(
                child: Image.network(
                  song.coverUrl == null ? 'https://placehold.jp/78/ffffff/000000/150x150.png?text=%E2%99%AA' : song.coverUrl!,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Image.network(
                      'https://placehold.jp/78/ffffff/000000/150x150.png?text=%E2%99%AA', // Placeholder image URL
                      fit: BoxFit.cover,
                    );
                  },
                ),
              ),
              title: Text(song.title),
              subtitle: Text(song.artistName),
              onTap: () {
                PlaybackManager().playSongObject(song);
              },
            ),
          );
        },
      );
    } else {
      return Text("No songs found");
    }
  },
),

          FutureBuilder<List<Album>>(
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
            leading: Image.network(
              album.coverUrl == null ? 'https://placehold.jp/78/ffffff/000000/150x150.png?text=%E2%99%AA' : album.coverUrl!,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                return Image.network(
                  'https://placehold.jp/78/ffffff/000000/150x150.png?text=%E2%99%AA', // Placeholder image URL
                  fit: BoxFit.cover,
                );
              },
            ),
            title: Text(album.title),
            subtitle: Text(album.artistName),
            onTap: () {
              Navigator.of(context).push(MaterialPageRoute(
                  builder: ((context) => AlbumPage(albumId: album.id))));
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
  final String year;

  Album({
    required this.id,
    required this.title,
    required this.artistId,
    required this.artistName,
    required this.coverUrl,
    required this.year,
  });

  factory Album.fromMap(Map<String, dynamic> map) {
    return Album(
      id: map['id'],
      title: map['name'],
      artistId: map['artistId'],
      artistName: map['artistName'],
      coverUrl: map['coverUrl'],
      year: map['year']
    );
  }
}

Future getDatabaseSchema(Database database) async {
  // Get the database info
  var info = await database.rawQuery('PRAGMA database_list');
  var dbName = info.first['name'];

  // Get the table names
  var tableNames = await database
      .rawQuery('SELECT name FROM sqlite_master WHERE type="table"');

  // For each table, get the schema
  for (var table in tableNames) {
    var tableName = table['name'];

    // Get the table schema
    var schema = await database.rawQuery('PRAGMA table_info($tableName)');

    // Print the table name and schema
    print('Table: $tableName');
    print('Schema:');
    for (var row in schema) {
      print('  - ${row['name']}: ${row['type']}');
    }
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
