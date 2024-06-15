import 'package:flutter/material.dart';
import 'package:sqflite/sqflite.dart';
import 'db.dart'; // Adjust this import to where your db.dart file is located
import 'library.dart'; // Adjust this import to where your library.dart file is located
import 'audiomanager.dart';
import 'ArtistPage.dart';
import 'AlbumPage.dart';
// Import other necessary files, e.g., ArtistPage, AlbumPage, and AudioManager

class SearchTab extends StatefulWidget {
  @override
  _SearchTabState createState() => _SearchTabState();
}

class _SearchTabState extends State<SearchTab>
    with AutomaticKeepAliveClientMixin {
  bool get wantKeepAlive => true; // Indicates you want to keep the state alive

  @override
  Widget build(BuildContext context) {
    super.build(
        context); // This is required when using AutomaticKeepAliveClientMixin

    return Scaffold(
      body: SearchPage(),
    );
  }
}

class SearchPage extends StatefulWidget {
  @override
  _SearchPageState createState() => _SearchPageState();
}

Future<List<Artist>> searchArtists({required String query}) async {
  var db = await openDb();
  final List<Map<String, dynamic>> maps = await db.query(
    'Artists',
    where: 'name LIKE ?',
    whereArgs: ['%$query%'],
  );

  return List.generate(maps.length, (i) {
    return Artist.fromMap(maps[i]);
  });
}

Future<List<Song>> searchSongs({required String query}) async {
  var db = await openDb();
  // Adjusted to perform a search across songs, including joining with the Artists and Albums tables if necessary
  final List<Map<String, dynamic>> maps = await db.rawQuery('''
    SELECT Songs.*, Artists.name AS artistName, Albums.name AS albumName, Albums.coverUrl AS coverUrl
    FROM Songs
    JOIN Artists ON Songs.artistId = Artists.id
    JOIN Albums ON Songs.albumId = Albums.id
    WHERE Songs.title LIKE ? OR Artists.name LIKE ? OR Albums.name LIKE ?
  ''', ['%$query%', '%$query%', '%$query%']);

  return List.generate(maps.length, (i) {
    return Song.fromMap(maps[i]);
  });
}

Future<List<Album>> searchAlbums({required String query}) async {
  var db = await openDb();
  final List<Map<String, dynamic>> maps = await db.rawQuery('''
    SELECT Albums.*, Artists.name AS artistName
    FROM Albums
    JOIN Artists ON Albums.artistId = Artists.id
    WHERE Albums.name LIKE ? OR Artists.name LIKE ?
  ''', ['%$query%', '%$query%']);

  return List.generate(maps.length, (i) {
    return Album.fromMap(maps[i]);
  });
}

class _SearchPageState extends State<SearchPage>
    with SingleTickerProviderStateMixin, AutomaticKeepAliveClientMixin {
  final TextEditingController _searchController = TextEditingController();
  List<Artist> _artistResults = [];
  List<Song> _songResults = [];
  List<Album> _albumResults = [];

  bool get wantKeepAlive => true; // Indicates you want to keep the state alive

  Future<void> _search() async {
    final query = _searchController.text;
    if (query.isEmpty) {
      setState(() {
        _artistResults = [];
        _songResults = [];
        _albumResults = [];
      });
      return;
    }

    final artists = await searchArtists(query: query);
    final songs = await searchSongs(query: query);
    final albums = await searchAlbums(query: query);

    setState(() {
      _artistResults = artists;
      _songResults = songs;
      _albumResults = albums;
    });
  }

  @override
  Widget build(BuildContext context) {
    super.build(
        context); // This is required when using AutomaticKeepAliveClientMixin

    return Scaffold(
      appBar: AppBar(
        title: Text('Search Music Library'),
        actions: [
          IconButton(
            icon: Icon(Icons.clear),
            onPressed: () {
              _searchController.clear();
              _search();
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search artists, songs, albums...',
                suffixIcon: IconButton(
                  icon: Icon(Icons.search),
                  onPressed: _search,
                ),
              ),
              onSubmitted: (value) => _search(),
            ),
          ),
          Expanded(
            child: ListView(children: [
              if (_artistResults.isNotEmpty) ...[
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Text('Artists',
                      style: Theme.of(context).textTheme.headlineLarge),
                ),
                ..._artistResults.map((artist) => ListTile(
                      title: Text(artist.name),
                      onTap: () {
                        Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (context) => ArtistPage(
                                    artistId: artist.id,
                                    artistName: artist.name)));
                      },
                    )),
              ],
              if (_albumResults.isNotEmpty) ...[
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Text('Albums',
                      style: Theme.of(context).textTheme.headlineLarge),
                ),
                ..._albumResults.map((album) => ListTile(
                      leading: Image.network(album.coverUrl,
                          errorBuilder: (context, error, stackTrace) =>
                              Icon(Icons.album)),
                      title: Text(album.title),
                      subtitle: Text(album.artistName),
                      onTap: () {
                        Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (context) =>
                                    AlbumPage(albumId: album.id)));
                      },
                    )),
              ],
              if (_songResults.isNotEmpty) ...[
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Text('Songs',
                      style: Theme.of(context).textTheme.headlineLarge),
                ),
                ..._songResults.map((song) => ListTile(
                      leading: Image.network(song.coverUrl,
                          errorBuilder: (context, error, stackTrace) =>
                              Icon(Icons.music_note)),
                      title: Text(song.title),
                      subtitle: Text(song.artistName),
                      onTap: () {
                        PlaybackManager().playSongObject(song);
                      },
                    )),
              ],
            ]),
          ),
        ],
      ),
    );
  }
}
