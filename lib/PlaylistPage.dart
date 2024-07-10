import 'package:flutter/material.dart';
import 'package:sqflite/sqflite.dart';
import 'db.dart'; // Make sure this path is correct
import 'main.dart';
import 'audiomanager.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

import 'library.dart';

Future createPlaylist(name, description, filePath) async {
  var db = await openDb();
  await db.insert('Playlists',
      {'name': name, 'description': description, 'imagePath': description});
}

Future<String?> pickAndCopyImage() async {
  try {
    // Pick an image file using image_picker
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);

    if (image == null) {
      return null; // User canceled the picker
    }

    // Get the app's document directory
    final Directory appDocDir = await getApplicationDocumentsDirectory();

    // Create the PlaylistImages folder if it doesn't exist
    final String playlistImagesPath =
        path.join(appDocDir.path, 'PlaylistImages');
    final Directory playlistImagesDir = Directory(playlistImagesPath);
    if (!await playlistImagesDir.exists()) {
      await playlistImagesDir.create(recursive: true);
    }

    // Generate a unique file name for the copied image
    final String fileName =
        'playlist_image_${DateTime.now().millisecondsSinceEpoch}${path.extension(image.path)}';
    final String destinationPath = path.join(playlistImagesPath, fileName);

    // Copy the picked image to the PlaylistImages folder
    final File sourceFile = File(image.path);
    await sourceFile.copy(destinationPath);

    // Return the new file path
    print('Path to add: $destinationPath');
    return destinationPath;
  } catch (e) {
    print('Error picking and copying image: $e');
    return null;
  }
}

Future<String> showCreatePlaylistDialog(BuildContext context) async {
  final TextEditingController _playlistNameController = TextEditingController();
  final TextEditingController _playlistDescriptionController =
      TextEditingController();
  String? playlistImagePath;
  String returnValue = 'not'; // Default return value

  // Await the showDialog's Future to complete and return its result.
  final result = await showDialog<String>(
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(
        title: Text('Create New Playlist'),
        content: Column(children: [
          TextField(
            controller: _playlistNameController,
            decoration: InputDecoration(hintText: "Name"),
          ),
          SizedBox(
            height: 5,
          ),
          TextField(
            controller: _playlistDescriptionController,
            decoration: InputDecoration(hintText: "Description"),
          ),
          SizedBox(
            height: 5,
          ),
          TextButton(
              onPressed: () async {
                playlistImagePath = await pickAndCopyImage();
              },
              child: Text('Add Cover Image')),
        ]),
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
                await createPlaylist(_playlistNameController.text, playlistImagePath,  _playlistDescriptionController.text, );
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

Future<void> deletePlaylist(int playlistId) async {
  final db = await openDb();
  
  // Start a transaction to ensure all operations are performed or none
  await db.transaction((txn) async {
    // First, delete all songs associated with this playlist from PlaylistSongs table
    await txn.delete(
      'PlaylistSongs',
      where: 'playlistId = ?',
      whereArgs: [playlistId],
    );

    // Then, delete the playlist itself from Playlists table
    await txn.delete(
      'Playlists',
      where: 'id = ?',
      whereArgs: [playlistId],
    );
  });

  // Optionally, delete the playlist image file if it exists
  final playlistInfo = await _loadPlaylistInfo(playlistId);
  final imagePath = playlistInfo['imagePath'];
  if (imagePath != null && imagePath.isNotEmpty) {
    final imageFile = File(imagePath);
    if (await imageFile.exists()) {
      await imageFile.delete();
    }
  }
}

// Helper function to load playlist info (reused from your existing code)
Future<Map<String, String>> _loadPlaylistInfo(int playlistId) async {
  final db = await openDb();
  final playlist = await db.query(
    'Playlists',
    columns: ['name', 'description', 'imagePath'],
    where: 'id = ?',
    whereArgs: [playlistId],
  );

  if (playlist.isNotEmpty) {
    return {
      'name': playlist.first['name'] as String? ?? 'Playlist',
      'imagePath': playlist.first['imagePath'] as String? ?? '',
      'description': playlist.first['description'] as String? ?? ''
    };
  }

  return {
    'name': 'Playlist',
    'imagePath': '',
    'description': ''
  };
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

  Future<Map<String, String>> _loadPlaylistInfo() async {
    final db = await openDb();
    final playlist = await db.query(
      'Playlists',
      columns: ['name', 'description', 'imagePath'], // Specify the columns we want
      where: 'id = ?',
      whereArgs: [widget.playlistId],
    );

    if (playlist.isNotEmpty) {

      print('path for the image is ${playlist.first['imagePath']}');

      return {
        'name': playlist.first['name'] as String? ?? 'Playlist',
        'imagePath': playlist.first['imagePath'] as String? ?? '',
        'description' : playlist.first['description'] as String? ?? ''
      };
    }

    return {
      'name': 'Playlist',
      'imagePath': '',
      'description' : ''
    };
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
    appBar: AppBar(),
    body: Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: FutureBuilder<Map<String, String>>(
            future: _loadPlaylistInfo(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.done &&
                  snapshot.hasData) {
                return Row(
                  children: [
                    Image.file(File(snapshot.data!['imagePath']!), height: 100),
                    SizedBox(width: 15),
                    Expanded(
                      child: Text(
                        snapshot.data!['name']!,
                        style: Theme.of(context).textTheme.headlineMedium,
                      ),
                    ),
                  ],
                );
              } else {
                return Text('Loading...');
              }
            },
          ),
        ),
        Divider(),
        Expanded(
          child: FutureBuilder<List<Song>>(
            future: _playlistSongsFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return Center(child: CircularProgressIndicator());
              } else if (snapshot.hasError) {
                return Center(child: Text('Error loading songs'));
              } else if (snapshot.hasData) {
                final songs = snapshot.data!;
                return ListView.builder(
                  itemCount: songs.length,
                  itemBuilder: (context, index) {
                    Song song = songs[index];
                    return GestureDetector(
                      onSecondaryTap: () {
                        showMenu(
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
                            PopupMenuItem(
                              value: 'edit',
                              child: Text('Remove from Playlist'),
                              onTap: () {
                                confirmRemoval(widget.playlistId, song.id, context);
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
                        subtitle: Text(song.artistName),
                        onTap: () {
                          PlaybackManager().playAlbumFromTrack(songs, index);
                        },
                      ),
                    );
                  },
                );
              } else {
                return Center(child: Text('No songs found'));
              }
            },
          ),
        ),
      ],
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
