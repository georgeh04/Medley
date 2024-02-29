import 'package:flutter/material.dart';
import 'package:medleylibrary/AlbumPage.dart';
import 'library.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:io';
import 'db.dart';
import 'audiomanager.dart';
import 'package:media_kit/media_kit.dart';
import 'ArtistPage.dart';

void main() {
  MediaKit.ensureInitialized();
  runApp(MusicPlayerApp());
}

bool isMusicFile(File file) {
  // Check the file extension to determine if it's a music file
  return file.path.endsWith('.mp3') ||
      file.path.endsWith('.wav') ||
      file.path.endsWith('.flac') ||
      file.path.endsWith('.aac');
}

void printMusicFileInformation(File file) {
  // Print the file path. You can extend this to print more info if needed
  print(file.path);
}

Future<void> pickAndScanMusicFolder(BuildContext context) async {
  // Use FilePicker to let the user pick a directory
  String? selectedDirectory = await FilePicker.platform
      .getDirectoryPath(dialogTitle: 'Choose your music folder');

  // Show loading dialog
  showDialog(
    context: context,
    barrierDismissible:
        false, // Prevents the dialog from closing before the task is done
    builder: (BuildContext context) {
      return Dialog(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(),
              SizedBox(width: 20),
              Text("Scanning music files..."),
            ],
          ),
        ),
      );
    },
  );

  if (selectedDirectory != null) {
    // If the user selected a directory, scan it for music files
    await findMusicFiles(Directory(selectedDirectory));
  } else {
    print("No directory selected");
  }

  // Dismiss the loading dialog
  Navigator.of(context, rootNavigator: true).pop();
}

class MusicPlayerApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      darkTheme: ThemeData(
        brightness: Brightness.dark,
      ),
      themeMode: ThemeMode.dark,
      home: MainScreen(),
    );
  }
}

class ClickableAlbumCover extends StatefulWidget {
  final Song? currentSong;

  const ClickableAlbumCover({Key? key, required this.currentSong})
      : super(key: key);

  @override
  _ClickableAlbumCoverState createState() => _ClickableAlbumCoverState();
}

class _ClickableAlbumCoverState extends State<ClickableAlbumCover> {
  bool _isHovering = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _isHovering = true),
      onExit: (_) => setState(() => _isHovering = false),
      child: GestureDetector(
        onTap: () {
          if (widget.currentSong != null) {
            navigatorKey.currentState!.push(
              MaterialPageRoute(
                builder: (context) =>
                    AlbumPage(albumId: widget.currentSong!.albumId),
              ),
            );
          }
        },
        child: Container(
          // Apply a hover effect, for example, a shadow
          decoration: _isHovering
              ? BoxDecoration(
                  color: Colors.black.withOpacity(0.2),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.1),
                      spreadRadius: 5,
                      blurRadius: 7,
                      offset: Offset(0, 3),
                    ),
                  ],
                )
              : null,
          child: Image.network(
            widget.currentSong?.coverUrl ??
                'https://placehold.jp/78/ffffff/000000/150x150.png?text=%E2%99%AA',
            // You can add error handling for loading the image
            errorBuilder: (context, error, stackTrace) => Icon(Icons.error),
          ),
        ),
      ),
    );
  }
}

class VolumeControl extends StatefulWidget {
  final PlaybackManager playbackManager;

  const VolumeControl({Key? key, required this.playbackManager})
      : super(key: key);

  @override
  _VolumeControlState createState() => _VolumeControlState();
}

class _VolumeControlState extends State<VolumeControl> {
  double _currentVolume = 100; // Initialize with the default volume

  @override
  Widget build(BuildContext context) {
    return SliderTheme(
        data: SliderTheme.of(context).copyWith(
          trackHeight: 2.0, // Adjust the track height
        ),
        child: Slider(
          min: 0,
          max: 100,
          value: _currentVolume,
          onChanged: (value) async {
            // Update the local state of the volume slider only
            setState(() {
              _currentVolume = value;
            });
            // Convert the slider value (0 to 100) to the player's volume range (e.g., 0.0 to 1.0)
            await widget.playbackManager.setVolume(value);
          },
        ));
  }
}

void showQueueDialog(BuildContext context, PlaybackManager playbackManager) {
  showModalBottomSheet(
    context: context,
    builder: (BuildContext bc) {
      return ListView.builder(
        itemCount: playbackManager.queue.length,
        itemBuilder: (BuildContext context, int index) {
          Song song = playbackManager.queue[index];
          bool isCurrentSong = index ==
              playbackManager
                  .currentTrackIndex; // Check if the song is currently playing

          return ListTile(
            leading: Image.network(song.coverUrl),
            title: Text(song.title),
            subtitle: Text(song.artistName),
            trailing: isCurrentSong
                ? Icon(Icons.play_circle_fill, color: Colors.blue)
                : null, // Highlight the current song
            tileColor: isCurrentSong
                ? Colors.blue.withOpacity(0.2)
                : Colors.transparent, // Optionally change background color
            onTap: () {
              // Logic to play the selected song from the queue
              playbackManager.playAlbumFromTrack(playbackManager.queue, index);
            },
          );
        },
      );
    },
  );
}

class SongProgressWidget extends StatefulWidget {
  final PlaybackManager playbackManager;

  SongProgressWidget({Key? key, required this.playbackManager})
      : super(key: key);

  @override
  _SongProgressWidgetState createState() => _SongProgressWidgetState();
}

class _SongProgressWidgetState extends State<SongProgressWidget> {
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<Duration>(
      stream: widget.playbackManager.positionStream,
      builder: (context, positionSnapshot) {
        return StreamBuilder<Duration>(
          stream: widget.playbackManager.durationStream,
          builder: (context, durationSnapshot) {
            Duration currentPosition = positionSnapshot.data ?? Duration.zero;
            Duration totalDuration = durationSnapshot.data ?? Duration.zero;

            String currentPositionFormatted = _formatDuration(currentPosition);
            String totalDurationFormatted = _formatDuration(totalDuration);

            return Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(currentPositionFormatted),
                Expanded(
                  child: Slider(
                    min: 0,
                    max: totalDuration.inSeconds.toDouble(),
                    value: currentPosition.inSeconds
                        .toDouble()
                        .clamp(0, totalDuration.inSeconds.toDouble()),
                    onChanged: (value) {
                      widget.playbackManager
                          .seek(Duration(seconds: value.toInt()));
                    },
                  ),
                ),
                Text(totalDurationFormatted),
              ],
            );
          },
        );
      },
    );
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, "0");
    String twoDigitMinutes = twoDigits(duration.inMinutes.remainder(60));
    String twoDigitSeconds = twoDigits(duration.inSeconds.remainder(60));
    return duration.inHours > 0
        ? "${twoDigits(duration.inHours)}:$twoDigitMinutes:$twoDigitSeconds"
        : "$twoDigitMinutes:$twoDigitSeconds";
  }
}

// Define a global key for the navigator
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

class MainScreen extends StatefulWidget {
  @override
  _MainScreenState createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  var _playbackManager = PlaybackManager();

  @override
  void initState() {
    pickAndScanMusicFolder(context).then((_) {
      // If you're directly updating data that MusicLibraryPage reads,
      // simply calling setState here will refresh the data.
      setState(() {
        // This empty setState call triggers a rebuild of MainScreen,
        // which in turn will recreate MusicLibraryPage with potentially new data.
      });
    });
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Navigator(
        key: navigatorKey,
        onGenerateRoute: (RouteSettings settings) {
          WidgetBuilder builder;
          switch (settings.name) {
            case '/':
              builder = (BuildContext context) => MusicLibraryPage();
              break;
            default:
              throw Exception('Invalid route: ${settings.name}');
          }
          return MaterialPageRoute(builder: builder, settings: settings);
        },
      ),
      drawer: Drawer(
        child: ListView(
          children: [
            ListTile(
              title: Text('Print Artists'),
              onTap: () {
                printArtists();
              },
            ),
            ListTile(
              title: Text('Print Albums'),
              onTap: () {
                printAlbums();
              },
            ),
            ListTile(
              title: Text('Print Songs'),
              onTap: () {
                printSongs();
              },
            ),
          ],
        ),
      ),
      appBar: AppBar(
        title: Text('Music Player'),
      ),
      bottomNavigationBar: BottomAppBar(
        child: ValueListenableBuilder<Song?>(
          valueListenable: _playbackManager.currentSongNotifier,
          builder: (context, currentSong, child) {
            return Container(
                height: 78,
                child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Left side: Album/Song info
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8.0),
                        child: Row(children: [
                          ClickableAlbumCover(currentSong: currentSong),
                          SizedBox(width: 16),
                          if (currentSong != null)
                            Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Flexible(
                                    child: TextButton(
                                  onPressed: () {
                                    navigatorKey.currentState!.push(
                                        MaterialPageRoute(
                                            builder: (context) => AlbumPage(
                                                albumId: currentSong.albumId)));
                                  },
                                  child: Text(currentSong.title,
                                      overflow: TextOverflow.ellipsis),
                                )),
                                Flexible(
                                    child: TextButton(
                                  onPressed: () {
                                    navigatorKey.currentState!
                                        .push(MaterialPageRoute(
                                            builder: (context) => ArtistPage(
                                                  artistId: currentSong.albumId,
                                                  artistName:
                                                      currentSong.artistName,
                                                )));
                                  },
                                  child: Text(
                                    currentSong.artistName,
                                    style: TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w300,
                                        color: Colors.grey),
                                  ),
                                ))
                              ],
                            ),
                        ]),
                      ),
                      Spacer(), // Pushes controls towards the center
                      Row(
                        mainAxisSize:
                            MainAxisSize.min, // Use minimal space for the row
                        children: [
                          IconButton(
                            icon: Icon(Icons.skip_previous),
                            onPressed: () => _playbackManager.previous(),
                          ),
                          ValueListenableBuilder<bool>(
                            valueListenable: _playbackManager.isPlaying,
                            builder: (context, isPlaying, child) {
                              return IconButton(
                                icon: Icon(
                                    isPlaying ? Icons.pause : Icons.play_arrow),
                                onPressed: () {
                                  if (isPlaying) {
                                    _playbackManager.pause();
                                  } else {
                                    _playbackManager.play();
                                  }
                                },
                              );
                            },
                          ),
                          IconButton(
                            icon: Icon(Icons.skip_next),
                            onPressed: () => _playbackManager.next(),
                          ),
                        ],
                      ),
                      Spacer(), // This ensures the controls are centered
                      // Right side: Placeholder or additional controls (invisible to keep balance)
                      VolumeControl(playbackManager: _playbackManager),
                      IconButton(
                          onPressed: () {
                            showQueueDialog(context, _playbackManager);
                          },
                          icon: Icon(Icons.queue_music)),
                    ]));
          },
        ),
      ),
    );
  }
}

class MusicPlayerScreen extends StatefulWidget {
  @override
  _MusicPlayerScreenState createState() => _MusicPlayerScreenState();
}

class _MusicPlayerScreenState extends State<MusicPlayerScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Now Playing',
              style: TextStyle(fontSize: 20),
            ),
            SizedBox(height: 16),
            Image.asset(
              'assets/album_cover.png',
              width: 200,
              height: 200,
            ),
            SizedBox(height: 16),
            Text(
              'Song Title',
              style: TextStyle(fontSize: 16),
            ),
            SizedBox(height: 8),
            Text(
              'Artist Name',
              style: TextStyle(fontSize: 14),
            ),
            SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    super.dispose();
  }
}
