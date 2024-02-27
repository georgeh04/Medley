import 'package:flutter/cupertino.dart';
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

Future<List<Song>> fetchSongsForAlbum(int albumId) async {
  final db = await openDb();
  // Adjust this rawQuery to match your actual table structure and relationships
  final List<Map<String, dynamic>> maps = await db.rawQuery('''
    SELECT Songs.*, Artists.name AS artistName
    FROM Songs
    JOIN Artists ON Songs.artistId = Artists.id
    WHERE Songs.albumId = ?
    ORDER BY Songs.trackNumber ASC
  ''', [albumId]);

  print('test here $maps');

  return List.generate(maps.length, (i) {
    return Song.fromMap(maps[i]);
  });
}

class AlbumPage extends StatefulWidget {
  final int albumId;

  const AlbumPage({Key? key, required this.albumId}) : super(key: key);

  @override
  _AlbumPageState createState() => _AlbumPageState();
}

class _AlbumPageState extends State<AlbumPage> {
  Future<Album> fetchAlbum() async {
    var albumId = widget.albumId;
    final db = await openDb();

    // Assuming there's an `artistId` column in `Albums` that references an `id` in `Artists`
    final List<Map<String, dynamic>> maps = await db.rawQuery('''
    SELECT Albums.*, Artists.name AS artistName
    FROM Albums
    INNER JOIN Artists ON Albums.artistId = Artists.id
    WHERE Albums.id = ?
  ''', [albumId]);
    if (maps.isNotEmpty) {
      // Ensure Album.fromMap can handle the artistName included in the map
      return Album.fromMap(maps.first);
    } else {
      throw Exception('Album not found');
    }
  }

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<PlaybackState>(
      builder: (context, playbackState, child) => Scaffold(
        body: FutureBuilder<Album>(
          future: fetchAlbum(),
          builder: (context, albumSnapshot) {
            if (albumSnapshot.connectionState == ConnectionState.waiting) {
              return Center(child: CircularProgressIndicator());
            } else if (albumSnapshot.hasError) {
              return Text("Error: ${albumSnapshot.error}");
            } else if (albumSnapshot.hasData) {
              return Row(
                children: [
                  Container(
                    width: 300,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Image.network('https://placehold.jp/150x150.png'),
                        SizedBox(height: 16),
                        Text(albumSnapshot.data!.title,
                            style: Theme.of(context).textTheme.headline5),
                        Text('By ${albumSnapshot.data!.artistName}',
                            style: Theme.of(context).textTheme.subtitle1),
                      ],
                    ),
                  ),
                  Expanded(
                    child: SingleChildScrollView(
                      child: FutureBuilder<List<Song>>(
                        future: fetchSongsForAlbum(widget.albumId),
                        builder: (context, songsSnapshot) {
                          if (songsSnapshot.connectionState ==
                              ConnectionState.waiting) {
                            return CircularProgressIndicator();
                          } else if (songsSnapshot.hasError) {
                            return Text("Error: ${songsSnapshot.error}");
                          } else if (songsSnapshot.hasData) {
                            return ListView.builder(
                              physics:
                                  NeverScrollableScrollPhysics(), // Disable scrolling within the ListView
                              shrinkWrap:
                                  true, // Allow ListView to size itself properly within the Column
                              itemCount: songsSnapshot.data!.length,
                              itemBuilder: (context, index) {
                                Song song = songsSnapshot.data![index];
                                return ListTile(
                                  leading: Text(song.trackNumber.toString()),
                                  title: Text(song.title),
                                  onTap: () {
                                    playbackState.playSong(
                                        song.path, song.title);
                                  },
                                );
                              },
                            );
                          } else {
                            return Text("No songs found");
                          }
                        },
                      ),
                    ),
                  ),
                ],
              );
            } else {
              return Text("No album found");
            }
          },
        ),
      ),
    );
  }
}
