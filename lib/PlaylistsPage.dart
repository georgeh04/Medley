import 'package:flutter/material.dart';
import 'package:sqflite/sqflite.dart';
import 'db.dart'; // Make sure this path is correct
import 'PlaylistPage.dart'; // Make sure this path is correct

class PlaylistsPage extends StatefulWidget {
  @override
  _PlaylistsPageState createState() => _PlaylistsPageState();
}

class _PlaylistsPageState extends State<PlaylistsPage> {
  late Database db;
  List<Map<String, dynamic>> playlists = [];

  @override
  void initState() {
    super.initState();
    _loadPlaylists();
  }

  Future<void> _loadPlaylists() async {
    db = await openDb();
    var fetchedPlaylists = await db.query('Playlists');
    setState(() {
      playlists = fetchedPlaylists;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Playlists"),
      ),
      body: ListView.separated(
        itemCount: playlists.length + 1, // +1 for the Add Playlist tile
        itemBuilder: (context, index) {
          // Special case for the first item
          if (index == 0) {
            return ListTile(
              leading: Icon(Icons.add),
              title: Text('Add Playlist'),
              onTap: () {
                // Function to show a dialog or another screen to add a new playlist
                showCreatePlaylistDialog(context).then((value) {
                  if (value == 'finish') {
                    // Perform actions after the playlist is successfully created
                    setState(() {
                      _loadPlaylists();
                    });
                  } else {
                    print('Dialog result: $value');
                  }
                });
              },
            );
          }
          // Adjust the index for accessing playlists since the first item is the Add button
          final adjustedIndex = index - 1;
          return GestureDetector(onSecondaryTap: (){
            showMenu(
                          context: context,
                          position: RelativeRect.fill,
                          items: [
                            PopupMenuItem(
                              value: 'edit',
                              child: Text('Delete Playlist'),
                              onTap: () {
                                deletePlaylist(playlists[adjustedIndex]['id']);
                                setState(() {
                                  
                                });
                              },
                            ),
                            
                          ],
                        );
            },child: ListTile(
            title: Text(playlists[adjustedIndex]['name']),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) =>
                      PlaylistPage(playlistId: playlists[adjustedIndex]['id']),
                ),
              );
            },
          ));
        },
        separatorBuilder: (context, index) => Divider(),
      ),
    );
  }

  @override
  void dispose() {
    db.close();
    super.dispose();
  }
}
