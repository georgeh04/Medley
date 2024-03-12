import 'package:flutter/material.dart';
import 'package:medleylibrary/main.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'db.dart';

class PlaylistPage extends StatefulWidget {
  @override
  _PlaylistPageState createState() => _PlaylistPageState();
}

class _PlaylistPageState extends State {
  late Future _database;

  @override
  void initState() {
    super.initState();
    _database = openDb();
  }

  Future _getPlaylists(Database db) async {
    return await db.query('Playlists');
  }

  Future printPlaylists() async {
    final path = await getDatabasesPath();
    final dbPath = join(path, 'medleyLibrary.db');
    final db = await openDatabase(dbPath);

    final result = await db.query('Playlists');

    for (final row in result) {
      print(row['name']);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Playlists'),
      ),
      body: FutureBuilder(
        future: _database,
        builder: (context, snapshot) {
          if (snapshot.hasData) {
            return FutureBuilder(
              future: _getPlaylists(snapshot.data),
              builder: (context, snapshot) {
                print('give data here: ${snapshot.data}');
                if (snapshot.hasData) {
                  return ListView.builder(
                    itemCount: snapshot.data.length,
                    itemBuilder: (context, index) {
                      final playlist = snapshot.data[index];
                      return ListTile(
                        title: Text(playlist['name']),
                        onTap: () {
                          navigatorKey.currentState!.push(MaterialPageRoute(
                              builder: (context) => PlaylistsPage(
                                    playlistId: playlist['id'],
                                  )));
                          printPlaylists();
                        },
                      );
                    },
                  );
                } else {
                  return Center(child: CircularProgressIndicator());
                }
              },
            );
          } else {
            return Center(child: CircularProgressIndicator());
          }
        },
      ),
    );
  }
}

class PlaylistsPage extends StatefulWidget {
  final int playlistId;

  PlaylistsPage({required this.playlistId});

  @override
  _PlaylistsPageState createState() => _PlaylistsPageState();
}

class _PlaylistsPageState extends State<PlaylistsPage> {
  late Database _db;
  late List _songs;
  final GlobalKey _scaffoldKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    _initDatabase();
  }

  _initDatabase() async {
    _db = await openDb(); // replace with your database initialisation function
    _songs = await getSongsForPlaylist(widget.playlistId);
    setState(() {});
  }

  Future getSongsForPlaylist(int playlistId) async {
    final db = await _db;
    final res = await db.query(
      'PlaylistSongs',
      where: 'playlistId = ?',
      whereArgs: [playlistId],
      columns: ['songId'],
    );
    final songIds = res.map((e) => e['songId']).toList();
    final songs = await Future.wait(
      songIds.map((songId) async {
        final res = await db.query(
          'Songs',
          where: 'id = ?',
          whereArgs: [songId],
        );
        return res.first;
      }),
    );
    return songs;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      appBar: AppBar(
        title: Text('Playlist Songs'),
      ),
      body: _songs != null
          ? ListView.builder(
              itemCount: _songs.length,
              itemBuilder: (context, index) {
                final song = _songs[index];
                return ListTile(
                  title: Text(song['title']),
                );
              },
            )
          : Center(
              child: CircularProgressIndicator(),
            ),
    );
  }

  @override
  void dispose() {
    super.dispose();
  }
}
