import 'package:flutter/material.dart';
import 'package:sqflite/sqflite.dart';
import 'db.dart'; // Make sure this path is correct
import 'main.dart';
import 'audiomanager.dart';

import 'library.dart';

Future createPlaylist(String name) async {
  var db = await openDb();
  await db.insert('Playlists', {
    'name': name,
  });
}

Future<String> showCreatePlaylistDialog(BuildContext context) async {
  final TextEditingController _playlistNameController = TextEditingController();
  String returnValue = 'not'; // Default return value

  // Await the showDialog's Future to complete and return its result.
  final result = await showDialog<String>(
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(
        title: Text('Create New Playlist'),
        content: TextField(
          controller: _playlistNameController,
          decoration: InputDecoration(hintText: "Playlist Name"),
        ),
        actions: <Widget>[
          TextButton(
            child: Text('Cancel'),
            onPressed: () {
              Navigator.of(context).pop('cancel'); // Explicitly pass 'cancel'
            },
          ),
          TextButton(
            child: Text('Create'),
            onPressed: () async {
              if (_playlistNameController.text.isNotEmpty) {
                // Assuming createPlaylist is an asynchronous function
                await createPlaylist(_playlistNameController.text);
                Navigator.of(context).pop('finish'); // Explicitly pass 'finish'
              } else {
                // Close the dialog without creating a playlist.
                Navigator.of(context).pop('empty'); // For empty input
              }
            },
          ),
        ],
      );
    },
  );

  // Assign the result to returnValue only if it's not null
  if (result != null) {
    returnValue = result;
  }

  return returnValue;
}

void showAddToPlaylistDialog(
    BuildContext context, int songId, String title) async {
  final playlists = await fetchPlaylists(); // Fetch playlists from the database
  showDialog(
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(
        title: Text('Add $title to Playlist'),
        content: Container(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: playlists.length,
            itemBuilder: (BuildContext context, int index) {
              return ListTile(
                title: Text(playlists[index]['name']),
                onTap: () async {
                  // Add song to the selected playlist
                  await addSongToPlaylist(playlists[index]['id'], songId);
                  Navigator.of(context).pop(); // Close the dialog
                  // Optionally, show a confirmation message or refresh the UI
                },
              );
            },
          ),
        ),
        actions: <Widget>[
          TextButton(
            child: Text('Cancel'),
            onPressed: () {
              Navigator.of(context).pop();
            },
          ),
        ],
      );
    },
  );
}

Future<List<Map<String, dynamic>>> fetchPlaylists() async {
  final db = await openDb();
  final List<Map<String, dynamic>> playlists = await db.query('Playlists');
  return playlists;
}

Future<void> addSongToPlaylist(int playlistId, int songId) async {
  final db = await openDb();
  await db.insert(
    'PlaylistSongs',
    {'playlistId': playlistId, 'songId': songId},
    conflictAlgorithm: ConflictAlgorithm.ignore, // Prevent duplicate entries
  );
}

class PlaylistPage extends StatefulWidget {
  final int playlistId;

  const PlaylistPage({Key? key, required this.playlistId}) : super(key: key);

  @override
  _PlaylistPageState createState() => _PlaylistPageState();
}

class _PlaylistPageState extends State<PlaylistPage> {
  late Future<List<Song>> _playlistSongsFuture;

  @override
  void initState() {
    super.initState();
    _playlistSongsFuture = _loadPlaylistSongs();
  }

  Future<String> _loadPlaylistName() async {
    final db = await openDb();
    final playlist = await db
        .query('Playlists', where: 'id = ?', whereArgs: [widget.playlistId]);
    if (playlist.isNotEmpty) {
      return playlist.first['name'] as String; // Ensure name is cast to String
    }
    return 'Playlist';
  }

  Future<List<Song>> _loadPlaylistSongs() async {
    final db = await openDb();
    final maps = await db.rawQuery('''
    SELECT 
      Songs.*, 
      Artists.name AS artistName, 
      Albums.name AS albumName, 
      Albums.coverUrl AS coverUrl
    FROM 
      Songs
    INNER JOIN 
      PlaylistSongs ON Songs.id = PlaylistSongs.songId
    INNER JOIN 
      Artists ON Songs.artistId = Artists.id
    INNER JOIN 
      Albums ON Songs.albumId = Albums.id
    WHERE 
      PlaylistSongs.playlistId = ?
  ''', [widget.playlistId]);
    return List.generate(maps.length, (i) {
      return Song.fromMap(maps[i]);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: FutureBuilder<String>(
          future: _loadPlaylistName(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.done &&
                snapshot.hasData) {
              return Text(snapshot.data!); // Use Text widget here for the title
            } else {
              return Text('Loading...');
            }
          },
        ),
      ),
      body: FutureBuilder<List<Song>>(
        future: _playlistSongsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error loading songs'));
          } else if (snapshot.hasData) {
            final songs = snapshot.data!;
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
                              showAddToPlaylistDialog(
                                  context, song.id, song.title);
                            },
                          ),
                          PopupMenuItem(
                            value: 'edit',
                            child: Text('Remove from Playlist'),
                            onTap: () {
                              confirmRemoval(
                                  widget.playlistId, song.id, context);
                            },
                          ),
                        ],
                      );
                    },
                    child: ListTile(
                      leading: Container(
                        child: Image.network(song.coverUrl!),
                      ),
                      title: Text(song.title),
                      subtitle: Text(song
                          .artistName), // Assuming Song has an artistName field
                      onTap: () {
                        PlaybackManager().playAlbumFromTrack(songs, index);
                      },
                    ));
              },
            );
          } else {
            return Center(child: Text('No songs found'));
          }
        },
      ),
    );
  }
}

// Assuming you're within a widget that has access to a BuildContext
void confirmRemoval(int playlistId, int songId, BuildContext context) {
  showDialog(
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(
        title: Text('Confirm Removal'),
        content: Text(
            'Are you sure you want to remove this song from the playlist?'),
        actions: <Widget>[
          TextButton(
            child: Text('Cancel'),
            onPressed: () => Navigator.of(context).pop(),
          ),
          TextButton(
            child: Text('Remove'),
            onPressed: () async {
              await removeSongFromPlaylist(playlistId, songId);
              Navigator.of(context).pop();
              // Optionally, refresh your list or show a snackbar confirmation
            },
          ),
        ],
      );
    },
  );
}

Future<void> removeSongFromPlaylist(int playlistId, int songId) async {
  final db = await openDb();
  await db.delete(
    'PlaylistSongs',
    where: 'playlistId = ? AND songId = ?',
    whereArgs: [playlistId, songId],
  );
}
