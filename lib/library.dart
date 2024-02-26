import 'package:flutter/material.dart';

class MusicLibraryPage extends StatefulWidget {
  @override
  _MusicLibraryPageState createState() => _MusicLibraryPageState();
}

class _MusicLibraryPageState extends State<MusicLibraryPage>
    with SingleTickerProviderStateMixin {
  // Define a TabController to control the selected tab.
  TabController? _tabController;

  @override
  void initState() {
    super.initState();
    // Initialize the TabController with 3 tabs.
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: TabBar(
        controller: _tabController,
        tabs: [
          Tab(text: 'Artists'),
          Tab(text: 'Songs'),
          Tab(text: 'Albums'),
        ],
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          ArtistsView(),
          SongsView(),
          AlbumsView(),
        ],
      ),
    );
  }
}

class ArtistsView extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    // Example list of artists. Replace with your dynamic data source.
    final artists = ['Artist 1', 'Artist 2', 'Artist 3', 'Artist 4'];

    return ListView.builder(
      itemCount: artists.length,
      itemBuilder: (context, index) {
        return ListTile(
          leading: Icon(Icons.person), // Placeholder for artist images
          title: Text(artists[index]),
          onTap: () {
            // TODO: Implement navigation to artist detail
            print('Tapped on ${artists[index]}');
          },
        );
      },
    );
  }
}

class SongsView extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    // Example list of songs. Replace with your dynamic data source.
    final songs = ['Song 1', 'Song 2', 'Song 3', 'Song 4'];

    return ListView.builder(
      itemCount: songs.length,
      itemBuilder: (context, index) {
        return ListTile(
          leading: Icon(Icons.music_note), // Placeholder for song thumbnails
          title: Text(songs[index]),
          subtitle: Text('Artist for ${songs[index]}'), // Example artist name
          onTap: () {
            // TODO: Implement navigation to song detail
            print('Tapped on ${songs[index]}');
          },
        );
      },
    );
  }
}

class AlbumsView extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    // Example list of albums. Replace with your dynamic data source.
    final albums = ['Album 1', 'Album 2', 'Album 3', 'Album 4'];

    return ListView.builder(
      itemCount: albums.length,
      itemBuilder: (context, index) {
        return ListTile(
          leading: Icon(Icons.album), // Placeholder for album covers
          title: Text(albums[index]),
          subtitle: Text('Artist for ${albums[index]}'), // Example artist name
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => AlbumPage(
                  album: Album(
                    title: albums[index],
                    artist: 'Artist for ${albums[index]}',
                    coverImageUrl:
                        'https://via.placeholder.com/150', // Example album cover image
                    releaseYear: 2021, // Example release year
                    songs: [
                      Song(
                          title: 'Song 1',
                          duration: Duration(minutes: 3, seconds: 30)),
                      Song(
                          title: 'Song 2',
                          duration: Duration(minutes: 4, seconds: 15)),
                      Song(
                          title: 'Song 3',
                          duration: Duration(minutes: 5, seconds: 0)),
                    ],
                  ),
                ),
              ),
            );
            print('Tapped on ${albums[index]}');
          },
        );
      },
    );
  }
}

class Album {
  final String title;
  final String artist;
  final String coverImageUrl;
  final int releaseYear;
  final List<Song> songs;

  Album(
      {required this.title,
      required this.artist,
      required this.coverImageUrl,
      required this.releaseYear,
      required this.songs});
}

class Song {
  final String title;
  final Duration duration;

  Song({required this.title, required this.duration});
}

class AlbumPage extends StatelessWidget {
  final Album album;

  AlbumPage({required this.album});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(album.title),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Image.network(album.coverImageUrl,
                fit: BoxFit.cover), // Display the album cover
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text(
                album.title,
                style: Theme.of(context).textTheme.headline6,
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text(
                '${album.artist} • ${album.releaseYear}',
                style: Theme.of(context).textTheme.subtitle1,
              ),
            ),
            ListView.builder(
              physics:
                  NeverScrollableScrollPhysics(), // to prevent scrolling within the ListView
              shrinkWrap: true, // necessary to display inside a Column
              itemCount: album.songs.length,
              itemBuilder: (context, index) {
                Song song = album.songs[index];
                return ListTile(
                  leading: Icon(Icons.music_note),
                  title: Text(song.title),
                  subtitle: Text(_formatDuration(song.duration)),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, "0");
    String twoDigitMinutes = twoDigits(duration.inMinutes.remainder(60));
    String twoDigitSeconds = twoDigits(duration.inSeconds.remainder(60));
    return "$twoDigitMinutes:$twoDigitSeconds";
  }
}
