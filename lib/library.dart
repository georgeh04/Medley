import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:Medley/AlbumPage.dart';
import 'package:Medley/db.dart';
import 'ArtistPage.dart';
import 'package:sqflite/sqflite.dart';
import 'audiomanager.dart';
import 'dart:io';
import 'PlaylistPage.dart';
import 'main.dart';
import 'globals.dart';
import 'package:path_provider/path_provider.dart';
import 'package:http/http.dart' as http;
import 'package:file_picker/file_picker.dart';

class MusicLibraryPage extends StatefulWidget {
  @override
  _MusicLibraryPageState createState() => _MusicLibraryPageState();
}

class _MusicLibraryPageState extends State<MusicLibraryPage>
    with SingleTickerProviderStateMixin, AutomaticKeepAliveClientMixin {
  TabController? _tabController;
  TextEditingController _searchController = TextEditingController();
  List<Album> _allAlbums = [];
  List<Album> _filteredAlbums = [];
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadAlbums();
    _searchController.addListener(_filterAlbums);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _tabController?.dispose();
    super.dispose();
  }

  Future<void> _loadAlbums() async {
    _allAlbums = await fetchAlbums();
    _filterAlbums();
  }

  void _filterAlbums() {
    setState(() {
      if (_searchController.text.isEmpty) {
        _filteredAlbums = List.from(_allAlbums);
      } else {
        _filteredAlbums = _allAlbums
            .where((album) =>
                album.title.toLowerCase().contains(_searchController.text.toLowerCase()) ||
                album.artistName.toLowerCase().contains(_searchController.text.toLowerCase()))
            .toList();
      }
    });
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
    super.build(context);

    return Scaffold(
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: <Widget>[
            UserAccountsDrawerHeader(
              accountName: Text(userData.displayName),
              accountEmail: Text(userData.username),
              currentAccountPicture: CircleAvatar(
                backgroundImage: NetworkImage(userData.profilePictureUrl),
              ),
            ),
            ListTile(
              leading: Icon(Icons.reviews),
              title: Text('Reviews'),
            ),
            ListTile(
              leading: Icon(Icons.settings),
              title: Text('Settings'),
              onTap: () {
                showSettingsDialog(context, (String val) {});
              },
            ),
          ],
        ),
      ),
      appBar: !Platform.isAndroid
          ? PreferredSize(
              preferredSize: Size.fromHeight(kToolbarHeight),
              child: TabBar(
                controller: _tabController,
                tabs: [
                  Tab(text: 'Albums'),
                  Tab(text: 'Songs'),
                ],
              ))
          : AppBar(
              leading: Builder(
                builder: (BuildContext context) {
                  return InkWell(
                    onTap: () {
                      Scaffold.of(context).openDrawer();
                    },
                    child: Container(
                      margin: EdgeInsets.all(8),
                      child: CircleAvatar(
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
                  Tab(text: 'Albums'),
                  Tab(text: 'Songs'),
                ],
              ),
            ),
      body: TabBarView(
        controller: _tabController,
        children: [
          Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    labelText: 'Search Albums',
                    prefixIcon: Icon(Icons.search),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
              ),
              Expanded(
                child: _filteredAlbums.isEmpty
                    ? Center(child: CircularProgressIndicator())
                    : _buildAlbumList(_filteredAlbums),
              ),
            ],
          ),
          FutureBuilder<List<Song>>(
            future: fetchSongs(),
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
                            song.coverUrl ?? 'https://placehold.jp/78/ffffff/000000/150x150.png?text=%E2%99%AA',
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return Image.network(
                                'https://placehold.jp/78/ffffff/000000/150x150.png?text=%E2%99%AA',
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
        ],
      ),
    );
  }

  Widget _buildAlbumList(List<Album> albums) {
    Map<String, List<Album>> albumsByArtist = {};
    for (var album in albums) {
      if (!albumsByArtist.containsKey(album.artistName)) {
        albumsByArtist[album.artistName] = [];
      }
      albumsByArtist[album.artistName]!.add(album);
    }

    var sortedEntries = albumsByArtist.entries.toList()
      ..sort((a, b) => a.key.compareTo(b.key));

    return ListView.builder(
      itemCount: sortedEntries.length,
      itemBuilder: (context, artistIndex) {
        var artistName = sortedEntries[artistIndex].key;
        var artistAlbums = sortedEntries[artistIndex].value;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text(
                artistName,
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
            ListView.builder(
              shrinkWrap: true,
              physics: NeverScrollableScrollPhysics(),
              itemCount: artistAlbums.length,
              itemBuilder: (context, albumIndex) {
                Album album = artistAlbums[albumIndex];
                return GestureDetector(
  onSecondaryTapDown: (TapDownDetails details) => _showAlbumContextMenu(context, album, details),
  child: ListTile(
    leading: _buildAlbumCover(album),
    title: Text(album.title),
    subtitle: Text(album.artistName),
    onTap: () {
      Navigator.of(context).push(MaterialPageRoute(
        builder: ((context) => AlbumPage(albumId: album.id))
      ));
    },
  ),
);
              },
            ),
            Divider(),
          ],
        );
      },
    );
  }

  void _showAlbumContextMenu(BuildContext context, Album album, TapDownDetails details) {
  final RenderBox overlay = Overlay.of(context).context.findRenderObject() as RenderBox;
  final RelativeRect position = RelativeRect.fromLTRB(
    details.globalPosition.dx,
    details.globalPosition.dy,
    overlay.size.width - details.globalPosition.dx,
    overlay.size.height - details.globalPosition.dy,
  );

  showMenu(
    context: context,
    position: position,
    items: [
      if (album.localCoverPath == null || album.localCoverPath!.isEmpty)
        PopupMenuItem(
          child: Text('Add Custom Artwork'),
          value: 'add_custom_artwork',
        )
      else ...[
        PopupMenuItem(
          child: Text('Change Custom Artwork'),
          value: 'change_custom_artwork',
        ),
        PopupMenuItem(
          child: Text('Remove Custom Artwork'),
          value: 'remove_custom_artwork',
        ),
      ],
    ],
  ).then((value) {
    if (value == 'add_custom_artwork' || value == 'change_custom_artwork') {
      _addCustomArtwork(album);
    } else if (value == 'remove_custom_artwork') {
      _removeCustomArtwork(album);
    }
  });
}

Future<void> _addCustomArtwork(Album album) async {
  FilePickerResult? result = await FilePicker.platform.pickFiles(
    type: FileType.image,
    allowMultiple: false,
  );

  if (result != null) {
    File file = File(result.files.single.path!);
    final appDir = await getApplicationDocumentsDirectory();
    final localPath = '${appDir.path}/album_covers/${album.id}_custom.jpg';
    
    await file.copy(localPath);

    // Update the database
    final db = await openDb();
    await db.update(
      'Albums',
      {'localCoverPath': localPath},
      where: 'id = ?',
      whereArgs: [album.id],
    );

    // Update the UI
    setState(() {
      int index = _allAlbums.indexWhere((a) => a.id == album.id);
      if (index != -1) {
        _allAlbums[index] = Album(
          id: album.id,
          title: album.title,
          artistId: album.artistId,
          artistName: album.artistName,
          coverUrl: album.coverUrl,
          localCoverPath: localPath,
          year: album.year,
        );
      }
      _filterAlbums();
    });
  }
}

Future<void> _removeCustomArtwork(Album album) async {
  if (album.localCoverPath != null && album.localCoverPath!.isNotEmpty) {
    // Delete the file
    final file = File(album.localCoverPath!);
    if (await file.exists()) {
      await file.delete();
    }

    // Update the database
    final db = await openDb();
    await db.update(
      'Albums',
      {'localCoverPath': null},
      where: 'id = ?',
      whereArgs: [album.id],
    );

    // Update the UI
    setState(() {
      int index = _allAlbums.indexWhere((a) => a.id == album.id);
      if (index != -1) {
        _allAlbums[index] = Album(
          id: album.id,
          title: album.title,
          artistId: album.artistId,
          artistName: album.artistName,
          coverUrl: album.coverUrl,
          localCoverPath: null,
          year: album.year,
        );
      }
      _filterAlbums();
    });
  }
}

  Widget _buildAlbumCover(Album album) {
    if (album.localCoverPath != null) {
      return Image.file(
        File(album.localCoverPath!),
        fit: BoxFit.cover,
        width: 50,
        height: 50,
        errorBuilder: (context, error, stackTrace) => _buildDefaultCover(),
      );
    } else if (album.coverUrl != null) {
      return Image.network(
        album.coverUrl,
        fit: BoxFit.cover,
        width: 50,
        height: 50,
        errorBuilder: (context, error, stackTrace) => _buildDefaultCover(),
      );
    } else {
      return _buildDefaultCover();
    }
  }

  Widget _buildDefaultCover() {
    return Image.asset(
      'assets/default_album_cover.png',
      fit: BoxFit.cover,
      width: 50,
      height: 50,
    );
  }
}

class Artist {
  final int id;
  final String name;

  Artist({required this.id, required this.name});

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
  final String artistName;
  final String path;
  final int trackNumber;
  final int duration;
  final String albumName;
  final String coverUrl;
  final String? localCoverPath;

  Song({
    required this.id,
    required this.title,
    required this.artistId,
    required this.albumId,
    required this.artistName,
    required this.path,
    required this.trackNumber,
    required this.duration,
    required this.albumName,
    required this.coverUrl,
    this.localCoverPath,
  });

  factory Song.fromMap(Map<String, dynamic> map) {
    return Song(
      id: map['id'],
      title: map['title'],
      artistId: map['artistId'],
      albumId: map['albumId'],
      artistName: map['artistName'],
      path: map['filePath'],
      trackNumber: map['trackNumber'],
      duration: map['duration'],
      albumName: map['albumName'],
      coverUrl: map['coverUrl'],
      localCoverPath: map['localCoverPath'],
    );
  }
}

class Album {
  final int id;
  final String title;
  final int artistId;
  final String artistName;
  final String coverUrl;
  final String? localCoverPath;
  final String year;

  Album({
    required this.id,
    required this.title,
    required this.artistId,
    required this.artistName,
    required this.coverUrl,
    this.localCoverPath,
    required this.year,
  });

  factory Album.fromMap(Map<String, dynamic> map) {
    return Album(
      id: map['id'],
      title: map['name'],
      artistId: map['artistId'],
      artistName: map['artistName'],
      coverUrl: map['coverUrl'],
      localCoverPath: map['localCoverPath'],
      year: map['year'] ?? '',
    );
  }
}

Future<List<Artist>> fetchArtists() async {
  var db = await openDb();
  final List<Map<String, dynamic>> maps = await db.query('artists');

  return List.generate(maps.length, (i) {
    return Artist.fromMap(maps[i]);
  });
}

Future<List<Song>> fetchSongs() async {
  var db = await openDb();
  final List<Map<String, dynamic>> maps = await db.rawQuery('''
    SELECT Songs.*, Artists.name AS artistName, Albums.name AS albumName, Albums.coverUrl AS coverUrl, Albums.localCoverPath AS localCoverPath
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
  final List<Map<String, dynamic>> maps = await db.rawQuery('''
    SELECT Albums.*, Artists.name AS artistName, Albums.coverUrl AS coverUrl, Albums.localCoverPath AS localCoverPath
    FROM Albums
    JOIN Artists ON Albums.artistId = Artists.id
    ORDER BY Artists.name, Albums.name
  ''');

  return List.generate(maps.length, (i) {
    return Album.fromMap(maps[i]);
  });
}

Future<String?> downloadAndSaveAlbumCover(int albumId, String coverUrl) async {
  try {
    final response = await http.get(Uri.parse(coverUrl));
    if (response.statusCode == 200) {
      final appDir = await getApplicationDocumentsDirectory();
      final localPath = '${appDir.path}/album_covers/$albumId.jpg';
      final imageFile = File(localPath);
      await imageFile.create(recursive: true);
      await imageFile.writeAsBytes(response.bodyBytes);
      return localPath;
    }
  } catch (e) {
    print('Error downloading album cover: $e');
  }
  return null;
}