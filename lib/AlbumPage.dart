import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:medleylibrary/ArtistPage.dart';
import 'package:medleylibrary/db.dart'; // Ensure this file has the necessary functions to interact with the database
import 'package:medleylibrary/main.dart';
import 'library.dart';

import 'audiomanager.dart';

Future<List<Song>> fetchSongsForAlbum(int albumId) async {
  final db = await openDb();
  // Adjust this rawQuery to match your actual table structure and relationships
  final List<Map<String, dynamic>> maps = await db.rawQuery('''
    SELECT Songs.*, Artists.name AS artistName, Albums.name AS albumName, Albums.coverUrl AS coverUrl
    FROM Songs
    JOIN Artists ON Songs.artistId = Artists.id
    JOIN Albums ON Songs.albumId = Albums.id
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
    SELECT Albums.*, Artists.name AS artistName, Albums.coverUrl AS coverUrl
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
    return Scaffold(
      appBar: AppBar(
        title: Text("Album Details"), // Providing context for the page
      ),
      body: FutureBuilder<Album>(
        future: fetchAlbum(),
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
                    child: Row(
                      children: [
                        Image.network(albumSnapshot.data!.coverUrl,
                            height: 200), // Adjusted size for better layout
                        SizedBox(
                          height: 16,
                          width: 16,
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(albumSnapshot.data!.title,
                                style:
                                    Theme.of(context).textTheme.headlineLarge),
                            SizedBox(
                              height: 16,
                            ),
                            Row(
                              children: [
                                TextButton(
                                  child: Text(
                                    albumSnapshot.data!.artistName,
                                    style:
                                        Theme.of(context).textTheme.titleSmall,
                                  ),
                                  onPressed: () {
                                    navigatorKey.currentState!.push(
                                        MaterialPageRoute(
                                            builder: (context) => ArtistPage(
                                                artistId: albumSnapshot
                                                    .data!.artistId,
                                                artistName: albumSnapshot
                                                    .data!.artistName)));
                                  },
                                ),
                                Text('|   21 Tracks  |  2004')
                              ],
                            )

                            // Additional album details (release year, genre, etc.) can be added here],)
                          ],
                        ),
                      ],
                      mainAxisAlignment: MainAxisAlignment.start,
                      mainAxisSize: MainAxisSize.max,
                    ),
                  ),
                  Divider(),
                  FutureBuilder<List<Song>>(
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
                              NeverScrollableScrollPhysics(), // Keep disabled scrolling
                          shrinkWrap:
                              true, // Ensure proper sizing within a Column
                          itemCount: songsSnapshot.data!.length,
                          itemBuilder: (context, index) {
                            Song song = songsSnapshot.data![index];
                            return ListTile(
                              leading: Text(song.trackNumber.toString()),
                              title: Text(song.title),
                              onTap: () {
                                // Assuming PlaybackManager() has a method to play a specific song
                                PlaybackManager().playAlbumFromTrack(
                                    songsSnapshot.data!, index);
                              },
                            );
                          },
                        );
                      } else {
                        return Text("No songs found");
                      }
                    },
                  ),
                  // Here you would add components for rating, reviews, and related albums
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
