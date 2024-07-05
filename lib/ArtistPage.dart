import 'package:flutter/material.dart';
import 'package:Medley/db.dart'; // Ensure this file has necessary database functions
import 'library.dart';
import 'AlbumPage.dart';
import 'audiomanager.dart';

class ArtistPage extends StatefulWidget {
  final int artistId;
  final String artistName;

  const ArtistPage({Key? key, required this.artistId, required this.artistName})
      : super(key: key);

  @override
  _ArtistPageState createState() => _ArtistPageState();
}

class _ArtistPageState extends State<ArtistPage>
    with SingleTickerProviderStateMixin {
  TabController? _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.artistName),
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
          AlbumsTab(artistId: widget.artistId),
          SongsTab(artistId: widget.artistId),
        ],
      ),
    );
  }
}

class AlbumsTab extends StatelessWidget {
  final int artistId;

  const AlbumsTab({Key? key, required this.artistId}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Album>>(
      future: fetchAlbumsByArtistId(artistId), // Implement this method
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
                leading: Container(
                  child: Image.network(album.coverUrl!),
                ),
                title: Text(album.title),
                subtitle: Text(album.artistName),
                onTap: () {
                  Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => AlbumPage(albumId: album.id)));
                },
              );
            },
          );
        } else {
          return Text("No albums found");
        }
      },
    );
  }
}

class SongsTab extends StatelessWidget {
  final int artistId;

  const SongsTab({Key? key, required this.artistId}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Song>>(
      future: fetchSongsByArtistId(artistId), // Implement this method
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
              return ListTile(
                leading: Container(
                  child: Image.network(song.coverUrl!),
                ),
                title: Text(song.title),
                subtitle: Text(
                    song.artistName), // Assuming Song has an artistName field
                onTap: () {
                  PlaybackManager().playSongObject(song);
                },
              );
            },
          );
        } else {
          return Text("No songs found");
        }
      },
    );
  }
}

Future<List<Album>> fetchAlbumsByArtistId(int artistId) async {
  final db =
      await openDb(); // Assuming openDb returns an instance of `Database`
  // Perform a JOIN operation to fetch the artist's name along with album details
  final List<Map<String, dynamic>> maps = await db.rawQuery('''
    SELECT Albums.*, Artists.name AS artistName, Albums.coverUrl AS coverUrl
    FROM Albums
    INNER JOIN Artists ON Albums.artistId = Artists.id
    WHERE Albums.artistId = ?
  ''', [artistId]);

  return List.generate(maps.length, (i) {
    // Assuming Album model is adjusted to include artistName
    return Album.fromMap(maps[i]);
  });
}

Future<List<Song>> fetchSongsByArtistId(int artistId) async {
  final db =
      await openDb(); // Assuming openDb returns an instance of `Database`

  // Adjust the query to include a join with the Albums table as well
  final List<Map<String, dynamic>> maps = await db.rawQuery('''
    SELECT Songs.*, Artists.name AS artistName, Albums.name AS albumName, Albums.coverUrl AS coverUrl
    FROM Songs
    JOIN Artists ON Songs.artistId = Artists.id
    JOIN Albums ON Songs.albumId = Albums.id
    WHERE Songs.artistId = ?
  ''', [artistId]); // Use the artistId to filter the songs

  return List.generate(maps.length, (i) {
    // Ensure the Song model includes a constructor that can handle both artistName and albumName
    return Song.fromMap(maps[i]);
  });
}
