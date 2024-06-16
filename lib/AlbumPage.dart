import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:Medley/ArtistPage.dart';
import 'package:Medley/db.dart'; // Ensure this file has the necessary functions to interact with the database
import 'package:Medley/main.dart';
import 'library.dart';
import 'dart:io';

import 'audiomanager.dart';

Future<List<Song>> fetchSongsForAlbum(int albumId) async {
  final db = await openDb();
  final List<Map<String, dynamic>> maps = await db.rawQuery('''
    SELECT Songs.*, Artists.name AS artistName, Albums.name AS albumName, Albums.coverUrl AS coverUrl
    FROM Songs
    JOIN Artists ON Songs.artistId = Artists.id
    JOIN Albums ON Songs.albumId = Albums.id
    WHERE Songs.albumId = ?
    ORDER BY Songs.trackNumber ASC
  ''', [albumId]);

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
  late Future<Album> _albumFuture;
  late Future<List<Song>> _songsFuture;

  @override
  void initState() {
    super.initState();
    _albumFuture = fetchAlbum();
    _songsFuture = fetchSongsForAlbum(widget.albumId);
  }

  Future<Album> fetchAlbum() async {
    var albumId = widget.albumId;
    final db = await openDb();
    final List<Map<String, dynamic>> maps = await db.rawQuery('''
    SELECT Albums.*, Artists.name AS artistName, Albums.coverUrl AS coverUrl
    FROM Albums
    INNER JOIN Artists ON Albums.artistId = Artists.id
    WHERE Albums.id = ?
  ''', [albumId]);
    if (maps.isNotEmpty) {
      return Album.fromMap(maps.first);
    } else {
      throw Exception('Album not found');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Album Details"),
      ),
      body: FutureBuilder<Album>(
        future: _albumFuture,
        builder: (context, albumSnapshot) {
          if (albumSnapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          } else if (albumSnapshot.hasError) {
            return Text("Error: ${albumSnapshot.error}");
          } else if (albumSnapshot.hasData) {
            return SingleChildScrollView(
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Platform.isAndroid
                        ? Column(
                            children: [
                              Image.network(
                                albumSnapshot.data!.coverUrl,
                                height: 200,
                                errorBuilder: (context, error, stackTrace) {
                                  return Image.network(
                                    'https://placehold.jp/78/ffffff/000000/150x150.png?text=%E2%99%AA',
                                    height: 200,
                                  );
                                },
                              ),
                              SizedBox(height: 16),
                              Text(
                                albumSnapshot.data!.title,
                                style: Theme.of(context).textTheme.headlineLarge,
                              ),
                              SizedBox(height: 16),
                              FutureBuilder<List<Song>>(
                                future: _songsFuture,
                                builder: (context, songsSnapshot) {
                                  if (songsSnapshot.connectionState == ConnectionState.waiting) {
                                    return CircularProgressIndicator();
                                  } else if (songsSnapshot.hasError) {
                                    return Text("Error: ${songsSnapshot.error}");
                                  } else if (songsSnapshot.hasData) {
                                    final trackCount = songsSnapshot.data!.length;
                                    return Row(
                                      children: [
                                        TextButton(
                                          child: Text(
                                            albumSnapshot.data!.artistName,
                                            style: Theme.of(context).textTheme.titleSmall,
                                          ),
                                          onPressed: () {
                                            navigatorKey.currentState!.push(
                                              MaterialPageRoute(
                                                builder: (context) => ArtistPage(
                                                  artistId: albumSnapshot.data!.artistId,
                                                  artistName: albumSnapshot.data!.artistName,
                                                ),
                                              ),
                                            );
                                          },
                                        ),
                                        Text('|   $trackCount Tracks  ' + (albumSnapshot.data!.year != 'null' ? '| ${albumSnapshot.data!.year}' : '')),

                                      ],
                                    );
                                  } else {
                                    return Text("No songs found");
                                  }
                                },
                              ),
                            ],
                          )
                        : Row(
                            children: [
                              Image.network(
                                albumSnapshot.data!.coverUrl,
                                height: 200,
                                errorBuilder: (context, error, stackTrace) {
                                  return Image.network(
                                    'https://placehold.jp/78/ffffff/000000/150x150.png?text=%E2%99%AA',
                                    height: 200,
                                  );
                                },
                              ),
                              SizedBox(width: 16),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    ' ${albumSnapshot.data!.title}',
                                    style: Theme.of(context).textTheme.headlineLarge,
                                  ),
                                  SizedBox(height: 16),
                                  FutureBuilder<List<Song>>(
                                    future: _songsFuture,
                                    builder: (context, songsSnapshot) {
                                      if (songsSnapshot.connectionState == ConnectionState.waiting) {
                                        return CircularProgressIndicator();
                                      } else if (songsSnapshot.hasError) {
                                        return Text("Error: ${songsSnapshot.error}");
                                      } else if (songsSnapshot.hasData) {
                                        final trackCount = songsSnapshot.data!.length;
                                        return Row(
                                          children: [
                                            TextButton(
                                              child: Text(
                                                albumSnapshot.data!.artistName,
                                                style: Theme.of(context).textTheme.titleSmall,
                                              ),
                                              onPressed: () {
                                                navigatorKey.currentState!.push(
                                                  MaterialPageRoute(
                                                    builder: (context) => ArtistPage(
                                                      artistId: albumSnapshot.data!.artistId,
                                                      artistName: albumSnapshot.data!.artistName,
                                                    ),
                                                  ),
                                                );
                                              },
                                            ),
                                            Text(' |   $trackCount Tracks  ' + (albumSnapshot.data!.year != 'null' ? '|  ${albumSnapshot.data!.year}' : '')),

                                          ],
                                        );
                                      } else {
                                        return Text("No songs found");
                                      }
                                    },
                                  ),
                                  SizedBox(height: 16),
                                  ElevatedButton(
                                    onPressed: () async {
                                      List<Song> songs = await fetchSongsForAlbum(widget.albumId);
                                      if (songs.isNotEmpty) {
                                        PlaybackManager().playAlbumFromTrack(songs, 0);
                                      }
                                    },
                                    child: Icon(Icons.play_arrow, color: Colors.white),
                                    style: ElevatedButton.styleFrom(
                                      shape: CircleBorder(),
                                      padding: EdgeInsets.all(20),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                  ),
                  Divider(),
                  FutureBuilder<List<Song>>(
                    future: _songsFuture,
                    builder: (context, songsSnapshot) {
                      if (songsSnapshot.connectionState == ConnectionState.waiting) {
                        return CircularProgressIndicator();
                      } else if (songsSnapshot.hasError) {
                        return Text("Error: ${songsSnapshot.error}");
                      } else if (songsSnapshot.hasData) {
                        return ListView.builder(
                          physics: NeverScrollableScrollPhysics(),
                          shrinkWrap: true,
                          itemCount: songsSnapshot.data!.length,
                          itemBuilder: (context, index) {
                            Song song = songsSnapshot.data![index];
                            return ListTile(
                              leading: Text(song.trackNumber.toString()),
                              title: Text(song.title),
                              onTap: () {
                                PlaybackManager().playAlbumFromTrack(songsSnapshot.data!, index);
                              },
                            );
                          },
                        );
                      } else {
                        return Text("No songs found");
                      }
                    },
                  ),
                ],
              ),
            );
          } else {
            return Text("No album found");
          }
        },
      ),
    );
  }
}
