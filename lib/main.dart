import 'package:flutter/material.dart';
import 'package:medleylibrary/AlbumPage.dart';
import 'package:medleylibrary/PlaylistPage.dart';
import 'library.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:io';
import 'db.dart';
import 'audiomanager.dart';
import 'package:media_kit/media_kit.dart';
import 'ArtistPage.dart';
import 'package:audio_service/audio_service.dart';
import 'package:desktop_window/desktop_window.dart';
import 'package:sqflite/sqflite.dart';
import 'package:sqflite_common/sqlite_api.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:peerdart/peerdart.dart';
import 'p2p.dart';
import 'SearchPage.dart';
import 'package:sidebarx/sidebarx.dart';
import 'Store.dart';

import 'dart:io' show Platform;

import 'package:permission_handler/permission_handler.dart';

Future<void> requestPermissions() async {
  var status = await Permission.storage.status;
  if (!status.isGranted) {
    await Permission.audio.request();
    await Permission.storage.request();
  }
}

void main() async {
  MediaKit.ensureInitialized();
  final audioHandler = await AudioService.init(
    builder: () => MyAudioHandler(),
    config: AudioServiceConfig(
      androidNotificationChannelId: 'com.yourapp.music.channel.audio',
      androidNotificationChannelName: 'Music playback',
      androidNotificationIcon:
          'mipmap/ic_launcher', // Update with your app icon
      androidShowNotificationBadge: true,
      androidStopForegroundOnPause: true,
    ),
  );
  WidgetsFlutterBinding.ensureInitialized();

  if (Platform.isMacOS || Platform.isWindows) {
    await DesktopWindow.setMinWindowSize(Size(800, 600));
  }

  runApp(MusicPlayerApp());
}

class MyAudioHandler extends BaseAudioHandler {
  final PlaybackManager _playbackManager = PlaybackManager();

  MyAudioHandler() {
    // Listen to playback manager changes and update audio_service state accordingly
    _playbackManager.currentSongNotifier.addListener(_updateCurrentMediaItem);
    _playbackManager.isPlaying.addListener(_updatePlaybackState);
    // Add more listeners as needed for position, queue, etc.
  }

  void _updateCurrentMediaItem() {
    final Song? currentSong = _playbackManager.getCurrentSong();
    if (currentSong != null) {
      // Update the media item for the currently playing song
      mediaItem.add(MediaItem(
        artUri: Uri.parse(currentSong.coverUrl),
        id: currentSong.path,
        album: currentSong.albumName,
        title: currentSong.title,
        artist: currentSong.artistName,
        // Add more properties as needed, like duration, artUri, etc.
      ));
    }
  }

  void _updatePlaybackState() {
    // Update the playback state (e.g., playing, paused)
    final isPlaying = _playbackManager.isPlaying.value;
    playbackState.add(playbackState.value.copyWith(
      controls: [
        MediaControl.skipToPrevious,
        if (isPlaying) MediaControl.pause else MediaControl.play,
        MediaControl.skipToNext,
        // Add more controls as needed
      ],
      systemActions: const {
        MediaAction.seek,
        // Add more system actions as needed
      },
      playing: isPlaying,
      // Update other state properties as needed, like current position
    ));
  }

  @override
  Future<void> play() async {
    await _playbackManager.play();
  }

  @override
  Future<void> pause() async {
    await _playbackManager.pause();
  }

  @override
  Future<void> skipToNext() async {
    await _playbackManager.next();
  }

  @override
  Future<void> skipToPrevious() async {
    await _playbackManager.previous();
  }

  // Implement other methods like stop, seek, setQueue, addQueueItem, etc., as needed
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
        appBarTheme: AppBarTheme(backgroundColor: Color(0xFF2A2730)),
        scaffoldBackgroundColor: Color(0xFF2A2730),
        primaryColorDark: Color(0xFF2A2730),
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

class DataSearch extends SearchDelegate<String> {
  late Database db;
  DataSearch() {
    openDb().then((database) {
      db = database;
    });
  }
  @override
  List<Widget> buildActions(BuildContext context) {
    return [
      IconButton(
        icon: Icon(Icons.clear),
        onPressed: () {
          query = '';
        },
      )
    ];
  }

  @override
  Widget buildLeading(BuildContext context) {
    return IconButton(
      icon: AnimatedIcon(
        icon: AnimatedIcons.menu_arrow,
        progress: transitionAnimation,
      ),
      onPressed: () {
        close(context, 'null');
      },
    );
  }

  @override
  Widget buildResults(BuildContext context) {
    return Text('data');
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    // Optionally, you can also implement search suggestions here
    return Container();
  }
}

const canvasColor = Color(0xFF2A2730);
const scaffoldBackgroundColor = Color(0xFF464667);
const accentCanvasColor = Color.fromARGB(255, 32, 32, 52);
const white = Colors.white;
final actionColor = const Color(0xFF2E2E48).withOpacity(0.6);
final divider = Divider(color: white.withOpacity(0.3), height: 1);

class ExampleSidebarX extends StatelessWidget {
  const ExampleSidebarX({
    Key? key,
    required SidebarXController controller,
  })  : _controller = controller,
        super(key: key);

  final SidebarXController _controller;

  @override
  Widget build(BuildContext context) {
    return SidebarX(
      controller: _controller,
      theme: SidebarXTheme(
        margin: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: canvasColor,
          borderRadius: BorderRadius.circular(20),
        ),
        hoverColor: scaffoldBackgroundColor,
        textStyle: TextStyle(color: Colors.white.withOpacity(0.7)),
        selectedTextStyle: const TextStyle(color: Colors.white),
        itemTextPadding: const EdgeInsets.only(left: 30),
        selectedItemTextPadding: const EdgeInsets.only(left: 30),
        itemDecoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: canvasColor),
        ),
        selectedItemDecoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: actionColor.withOpacity(0.37),
          ),
          gradient: const LinearGradient(
            colors: [accentCanvasColor, canvasColor],
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.28),
              blurRadius: 30,
            )
          ],
        ),
        iconTheme: IconThemeData(
          color: Colors.white.withOpacity(0.7),
          size: 20,
        ),
        selectedIconTheme: const IconThemeData(
          color: Colors.white,
          size: 20,
        ),
      ),
      extendedTheme: const SidebarXTheme(
        width: 200,
        decoration: BoxDecoration(
          color: canvasColor,
        ),
      ),
      footerDivider: divider,
      items: [
        SidebarXItem(
          icon: Icons.home,
          label: 'Home',
          onTap: () {
            debugPrint('Home');
          },
        ),
        const SidebarXItem(
          icon: Icons.search,
          label: 'Search',
        ),
        const SidebarXItem(
          icon: Icons.my_library_music,
          label: 'Library',
        ),
        const SidebarXItem(
          icon: Icons.reviews,
          label: 'Reviews',
        ),
        const SidebarXItem(
          icon: Icons.shop,
          label: 'Store',
        ),
        const SidebarXItem(
          icon: Icons.settings,
          label: 'Settings',
        ),
      ],
    );
  }
}

void showSettingsDialog(BuildContext context, Function(String) onChanged) {
  showDialog(
    context: context,
    builder: (BuildContext context) {
      return SizedBox(
        width: 600,
        height: 400,
        child: AlertDialog(
          title: Text('Settings'),
          content: SingleChildScrollView(
            child: ListBody(
              children: [
                OutlinedButton(
                  onPressed: () {
                    pickAndScanMusicFolder(context).then((_) {
                      // If you're directly updating data that MusicLibraryPage reads,
                      // simply calling setState here will refresh the data.
                      onChanged("Resync Library"); // Call the callback function
                    });
                  },
                  child: Text('Resync Library'),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text('Close'),
            ),
          ],
        ),
      );
    },
  );
}

// Define a global key for the navigator
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

class MainScreen extends StatefulWidget {
  @override
  _MainScreenState createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen>
    with SingleTickerProviderStateMixin {
  var _playbackManager = PlaybackManager();
  var sidebarController = SidebarXController(selectedIndex: 0);
  int _selectedIndex = 0; // Default index
  late TabController _tabController;

  void _onSidebarItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  void initState() {
// Call this function before invoking the FilePicker
    requestPermissions().then((_) {
      pickAndScanMusicFolder(context).then((_) {
        // If you're directly updating data that MusicLibraryPage reads,
        // simply calling setState here will refresh the data.
        setState(() {
          // This empty setState call triggers a rebuild of MainScreen,
          // which in turn will recreate MusicLibraryPage with potentially new data.
        });
      });
    });
    _tabController = TabController(
        length: 4, vsync: this); // Adjust length based on the number of tabs

    super.initState();
  }

  @override
  void dispose() {
    _tabController.dispose();

    super.dispose();
  }

  Future createPlaylist(String name, int userId) async {
    var db = await openDb();
    await db.insert('Playlists', {
      'name': name,
      'userId': userId,
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFF1c1a1e),
      body: Row(
        children: [
          SidebarX(
            controller: sidebarController,
            theme: SidebarXTheme(
              margin: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: canvasColor,
                borderRadius: BorderRadius.circular(20),
              ),
              hoverColor: scaffoldBackgroundColor,
              textStyle: TextStyle(color: Colors.white.withOpacity(0.7)),
              selectedTextStyle: const TextStyle(color: Colors.white),
              itemTextPadding: const EdgeInsets.only(left: 30),
              selectedItemTextPadding: const EdgeInsets.only(left: 30),
              itemDecoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: canvasColor),
              ),
              selectedItemDecoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: actionColor.withOpacity(0.37),
                ),
                gradient: const LinearGradient(
                  colors: [accentCanvasColor, canvasColor],
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.28),
                    blurRadius: 30,
                  )
                ],
              ),
              iconTheme: IconThemeData(
                color: Colors.white.withOpacity(0.7),
                size: 20,
              ),
              selectedIconTheme: const IconThemeData(
                color: Colors.white,
                size: 20,
              ),
            ),
            extendedTheme: const SidebarXTheme(
              width: 200,
              decoration: BoxDecoration(
                color: canvasColor,
              ),
            ),
            footerDivider: divider,
            items: [
              SidebarXItem(
                icon: Icons.home,
                label: 'Home',
                onTap: () {
                  debugPrint('Home');
                },
              ),
              SidebarXItem(
                  icon: Icons.search,
                  label: 'Search',
                  onTap: () async {
                    navigatorKey.currentState!.pushNamed(
                      '/search',
                    );
                  }),
              SidebarXItem(
                  icon: Icons.my_library_music,
                  label: 'Library',
                  onTap: () async {
                    navigatorKey.currentState!.pushNamed(
                      '/',
                    );
                  }),
              SidebarXItem(
                  icon: Icons.playlist_play,
                  label: 'Playlists',
                  onTap: () async {
                    navigatorKey.currentState!.pushNamed(
                      '/playlist',
                    );
                  }),
              const SidebarXItem(
                icon: Icons.reviews,
                label: 'Reviews',
              ),
              SidebarXItem(
                  icon: Icons.plus_one,
                  label: 'Playlistadd',
                  onTap: () async {
                    createPlaylist('Test Playlist', 9);
                  }),
              SidebarXItem(
                  icon: Icons.settings,
                  label: 'Settings',
                  onTap: () {
                    showSettingsDialog(context, (String val) {
                      setState(() {});
                    });
                  }),
            ],
          ),
          Expanded(
            child: Center(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(
                    10), // Adjust the radius for more or less rounded corners
                child: Container(
                  // Adds space around the container, preventing it from touching the window edges
                  child: Padding(
                    padding: const EdgeInsets.all(
                        8.0), // Adjust the padding as needed
                    child: ClipRRect(
                        borderRadius: BorderRadius.circular(
                            18), // Slightly smaller radius for the Navigator to ensure the Container's border is visible
                        child: Navigator(
                          key: navigatorKey,
                          initialRoute: '/',
                          onGenerateRoute: (RouteSettings settings) {
                            switch (settings.name) {
                              case '/':
                                return MaterialPageRoute(
                                  builder: (context) => MusicLibraryPage(),
                                );
                              case '/album':
                                final Object? arguments = settings.arguments;
                                if (arguments is int) {
                                  return MaterialPageRoute(
                                    builder: (context) => AlbumPage(
                                      albumId: arguments,
                                    ),
                                  );
                                }
                                ;
                              case '/search':
                                return MaterialPageRoute(
                                    builder: ((context) => SearchPage()));
                              case '/artist':
                                return MaterialPageRoute(
                                  builder: (context) => MusicLibraryPage(),
                                );
                              case '/playlist':
                                return MaterialPageRoute(
                                    builder: ((context) => PlaylistPage()));
                            }
                          },
                        )),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: BottomAppBar(
        height: 104,
        child: ValueListenableBuilder(
          valueListenable: _playbackManager.currentSongNotifier,
          builder: (context, currentSong, child) {
            return Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8.0),
                    child: Row(children: [
                      ClickableAlbumCover(currentSong: currentSong),
                      SizedBox(width: 16),
                      if (currentSong != null)
                        Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              width: 150, // Set the width of the TextButton
                              alignment: Alignment
                                  .centerLeft, // Align the text to the left
                              child: TextButton(
                                onPressed: () {
                                  navigatorKey.currentState!.push(
                                    MaterialPageRoute(
                                      builder: (context) => AlbumPage(
                                        albumId: currentSong.albumId,
                                      ),
                                    ),
                                  );
                                },
                                child: Text(
                                  currentSong.title,
                                  overflow: TextOverflow.ellipsis,
                                  maxLines: 1,
                                  softWrap: true,
                                ),
                              ),
                            ),
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
                              ),
                            )
                          ],
                        ),
                    ]),
                  ),
                ),
                Container(
                  child: Row(
                    children: [
                      Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Row(
                            mainAxisSize: MainAxisSize
                                .min, // Use minimal space for the row
                            children: [
                              IconButton(
                                icon: Icon(Icons.skip_previous),
                                onPressed: () => _playbackManager.previous(),
                              ),
                              ValueListenableBuilder(
                                valueListenable: _playbackManager.isPlaying,
                                builder: (context, isPlaying, child) {
                                  return IconButton(
                                    icon: Icon(isPlaying
                                        ? Icons.pause
                                        : Icons.play_arrow),
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
                        ],
                      )
                    ],
                  ),
                ),
                Container(
                  child: Row(
                    children: [
                      VolumeControl(playbackManager: _playbackManager),
                      IconButton(
                          onPressed: () {
                            showQueueDialog(context, _playbackManager);
                          },
                          icon: Icon(Icons.queue_music)),
                    ],
                  ),
                )
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildContentBasedOnIndex(int index) {
    // Switch case to determine which widget to display
    switch (index) {
      case 0:
        return MusicLibraryPage(); // Replace with your actual widget
      case 1:
        return MusicLibraryPage(); // Replace with other pages for different indexes
      // Add more cases for additional indexes
      default:
        return Placeholder(); // Fallback widget
    }
  }
}
