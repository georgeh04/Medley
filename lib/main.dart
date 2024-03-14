import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
import 'package:window_manager/window_manager.dart';
import 'package:desktop_window/desktop_window.dart';
import 'dart:io' show Platform;
import 'dart:io';

import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:url_launcher/url_launcher.dart';
import 'package:crypto/crypto.dart';
import 'dart:math';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'globalKeys.dart';
import 'package:hive/hive.dart';
import 'PlaylistsPage.dart';

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

  if (!Platform.isAndroid) {
    await windowManager.ensureInitialized();
    print('not on android or ios');
  }
  print('on android or ios');

  await initialiseLastfm();

  WindowOptions windowOptions = WindowOptions(
    size: Size(800, 600),
    center: true,
    backgroundColor: Colors.transparent,
    skipTaskbar: false,
    titleBarStyle: TitleBarStyle.normal,
  );
  windowManager.waitUntilReadyToShow(windowOptions, () async {
    await windowManager.show();
    await windowManager.focus();
  });

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

void connectToLastFm(BuildContext context) {
  DateTime now = DateTime.now();

// Convert to milliseconds since epoch, then divide by 1000 to get seconds
  int secondsSinceEpoch = now.millisecondsSinceEpoch ~/ 1000;

  Map<String, dynamic> singleTrackData = {
    'artist': 'Kanye West',
    'track': 'Stronger',
    'timestamp':
        secondsSinceEpoch.toString(), // Example UNIX timestamp (in seconds)
    // Optional parameters
    'album': 'Graduation',
    'trackNumber': '4',
    'chosenByUser': '1', // Assuming the user chose this song
  };
// Get the current date and time

  showDialog(
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(
        title: Text('Connect to Last.fm'),
        content: SingleChildScrollView(
          child: ListBody(
            children: [
              Text(
                  'To scrobble music, you need to connect your Last.fm account.'),
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
      );
    },
  );
}

String generateApiSignature(Map<String, dynamic> params, String secret) {
  var sortedKeys = params.keys.toList()..sort();
  var paramString =
      sortedKeys.fold('', (prev, key) => '$prev$key${params[key]}');
  var finalString = '$paramString$secret';
  print(finalString);
  return md5.convert(utf8.encode(finalString)).toString();
}

Future<void> scrobbleTracks(Map<String, dynamic> tracksData, String apiKey,
    String apiSecret, String sessionKey) async {
  final String apiUrl = 'https://ws.audioscrobbler.com/2.0/';
  Map<String, dynamic> params = {
    ...tracksData, // Your track data including artist[i], track[i], timestamp[i], etc.
    'api_key': apiKey,
    'method': 'track.scrobble',
    'sk': sessionKey,
  };

  // Generate the API signature
  String apiSig = generateApiSignature(params, apiSecret);
  params['api_sig'] = apiSig;
  params['format'] = 'json'; // Assuming you want the response in JSON format

  // Perform the HTTP POST request
  var response = await http.post(Uri.parse(apiUrl), body: params);

  print('Scrobble Status: $response.body');

  if (response.statusCode == 200) {
    print('Scrobble success: ${response.body}');
  } else {
    print('Scrobble failed with status code: ${response.statusCode}');
  }
}

Future<void> openBrowserPage(String url) async {
  if (!await launchUrl(Uri.parse(url))) {
    print('Could not launch $url');
  }
}

Future<String?> requestLastFmToken(String apiKey) async {
  final response = await http.get(
    Uri.parse(
        'http://ws.audioscrobbler.com/2.0/?method=auth.getToken&api_key=$apiKey&format=json'),
  );

  if (response.statusCode == 200) {
    final data = jsonDecode(response.body);
    return data['token'];
  } else {
    // Handle error or return null
    print('Failed to obtain token');
    return null;
  }
}

Future<String> authorizeLastFmUser(var token) async {
  openBrowserPage(
      'http://www.last.fm/api/auth/?api_key=cad200fbadbeb49cbd8b060607a0ccf5&token=$token');
  var apisig = await generateApiSignature({
    'api_key': 'cad200fbadbeb49cbd8b060607a0ccf5',
    'method': 'auth.getSession',
    'token': token,
  }, '83a6ae544f0729705292a12699d92c58');
  bool shouldContinue = true;
  while (shouldContinue) {
    final response = await fetchWebServiceSession(
        'cad200fbadbeb49cbd8b060607a0ccf5', token, apisig);
    if (response != null) {
      print('response here bb : $response');
      print('test print $response');
      if (true == true) {
        print('key here ${response}');
        shouldContinue = false;
        return response;
      } else {
        await Future.delayed(Duration(seconds: 5));
      }
    }
  }
  return 'Null';
}

Future<String?> fetchWebServiceSession(
    String apiKey, String token, String apiSig) async {
  final url = Uri.parse('http://ws.audioscrobbler.com/2.0/');
  final response = await http.post(url, body: {
    'method': 'auth.getSession',
    'api_key': apiKey,
    'token': token,
    'api_sig': apiSig,
    'format': 'json',
  });

  if (response.statusCode == 200) {
    final data = jsonDecode(response.body);
    return data['session']
        ['key']; // Extracting the session key from the response
  } else {
    // Error handling
    print('Failed to fetch web service session: ${response.body}');
    return null;
  }
}

void showSettingsDialog(BuildContext context, Function(String) onChanged) {
  showDialog(
    context: context,
    builder: (BuildContext context) {
      // Initialize a local state variable for the connection status

      return StatefulBuilder(
        // Use StatefulBuilder to manage dialog state
        builder: (context, setState) {
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
                          onChanged(
                              "Resync Library"); // Call the callback function
                        });
                      },
                      child: Text('Resync Library'),
                    ),
                    SizedBox(
                      height: 8,
                    ),
                    lastfmConnected // Use the local state variable
                        ? OutlinedButton(
                            onPressed: null, // Disables the button
                            style: OutlinedButton.styleFrom(
                              side: BorderSide(
                                  color: Colors.grey), // Greyed out border
                            ),
                            child: Text(
                                'Connected to Last.fm as $lastfmUsername',
                                style: TextStyle(
                                    color: Colors.grey)), // Greyed out text
                          )
                        : OutlinedButton(
                            onPressed: () {
                              requestLastFmToken(
                                      'cad200fbadbeb49cbd8b060607a0ccf5')
                                  .then((token) {
                                print(token);

                                authorizeLastFmUser(token).then((val) async {
                                  var lastfm = await Hive.openBox('lastfmData');
                                  await lastfm.put('lastfmSession', val);
                                  initialiseLastfm();
                                  ScaffoldMessenger.of(context)
                                      .showSnackBar(SnackBar(
                                    content: Text('Connected to Last.fm.'),
                                    backgroundColor: Colors.green,
                                  ));
                                  setState(() {
                                    // Update the state to rebuild the dialog with the new status
                                    lastfmConnected = true;
                                  });
                                });
                              });
                            },
                            child: Text('Connect to Last.fm'),
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
    },
  );
}

class MarqueeWidget extends StatefulWidget {
  final Widget child;
  final Axis direction;
  final Duration animationDuration, backDuration, pauseDuration;

  const MarqueeWidget({
    Key? key,
    required this.child,
    this.direction = Axis.horizontal,
    this.animationDuration = const Duration(milliseconds: 3000),
    this.backDuration = const Duration(milliseconds: 3000),
    this.pauseDuration = const Duration(milliseconds: 800),
  }) : super(key: key);

  @override
  _MarqueeWidgetState createState() => _MarqueeWidgetState();
}

class _MarqueeWidgetState extends State<MarqueeWidget> {
  late ScrollController scrollController;

  @override
  void initState() {
    scrollController = ScrollController(initialScrollOffset: 50.0);
    WidgetsBinding.instance.addPostFrameCallback(scroll);
    super.initState();
  }

  @override
  void dispose() {
    scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      physics: NeverScrollableScrollPhysics(),
      child: widget.child,
      scrollDirection: widget.direction,
      controller: scrollController,
    );
  }

  void scroll(_) async {
    await Future.delayed(Duration(milliseconds: 100)); // Small delay

    while (scrollController.hasClients && mounted) {
      // Check if the widget is still mounted
      await Future.delayed(widget.pauseDuration);
      if (scrollController.hasClients) {
        await scrollController.animateTo(
          scrollController.position.maxScrollExtent,
          duration: widget.animationDuration,
          curve: Curves.ease,
        );
      }
      await Future.delayed(widget.pauseDuration);
      if (scrollController.hasClients) {
        await scrollController.animateTo(
          0.0,
          duration: widget.backDuration,
          curve: Curves.easeOut,
        );
      }
    }
  }
}

class MusicControllerBottomSheet extends StatelessWidget {
  final PlaybackManager playbackManager;

  MusicControllerBottomSheet({Key? key, required this.playbackManager})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 1,
      minChildSize: 1,
      builder: (_, controller) {
        return Container(
          padding: EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  IconButton(
                    icon: Icon(Icons.arrow_downward),
                    onPressed: () => Navigator.pop(context),
                  ),
                  Text(
                      'From Album: ${playbackManager.currentSongNotifier.value!.albumName}'),
                  SizedBox
                      .shrink(), // Add an empty space at the end to push the text to the middle
                ],
              ),
              Spacer(),
              Center(
                child: ValueListenableBuilder<Song?>(
                  valueListenable: playbackManager.currentSongNotifier,
                  builder: (context, currentSong, child) {
                    return Column(
                      children: [
                        GestureDetector(
                            onTap: () {
                              var currentRoute =
                                  ModalRoute.of(context)?.settings.name;
                              var newRoute = '/album/${currentSong!.albumId}';

                              if (currentRoute != newRoute) {
                                navigatorKey.currentState!
                                    .push(MaterialPageRoute(
                                  builder: (context) => AlbumPage(
                                    albumId: currentSong.albumId,
                                  ),
                                  settings: RouteSettings(name: newRoute),
                                ));
                              }
                            },
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(8.0),
                              child: Image.network(
                                currentSong?.coverUrl ??
                                    'default_album_cover_url',
                                width: 300, // Adjust the size as needed
                                height: 300,
                                fit: BoxFit.cover,
                              ),
                            )),
                        SizedBox(height: 20),
                        Text(
                          currentSong?.title ?? 'No Song Playing',
                          style: TextStyle(
                              fontSize: 24, fontWeight: FontWeight.bold),
                        ),
                        SizedBox(height: 10),
                        Text(
                          currentSong?.artistName ?? 'Unknown Artist',
                          style: TextStyle(fontSize: 18),
                        ),
                        SizedBox(height: 30),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            IconButton(
                              icon: Icon(Icons.skip_previous),
                              onPressed: playbackManager.previous,
                            ),
                            ValueListenableBuilder<bool>(
                              valueListenable: playbackManager.isPlaying,
                              builder: (context, isPlaying, child) {
                                return IconButton(
                                  icon: Icon(isPlaying
                                      ? Icons.pause
                                      : Icons.play_arrow),
                                  onPressed: () {
                                    if (isPlaying) {
                                      playbackManager.pause();
                                    } else {
                                      playbackManager.play();
                                    }
                                  },
                                );
                              },
                            ),
                            IconButton(
                              icon: Icon(Icons.skip_next),
                              onPressed: playbackManager.next,
                            ),
                          ],
                        ),
                      ],
                    );
                  },
                ),
              ),
              Spacer(),
            ],
          ),
        );
      },
    );
  }
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
  final FocusNode _focusNode = FocusNode();
  bool isFullScreen = false;

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

  void _toggleFullScreen() async {
    await WindowManager.instance.setFullScreen(!isFullScreen);
    isFullScreen = !isFullScreen;
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
        child: Scaffold(
      bottomSheet: Platform.isAndroid
          ? BottomAppBar(
              height: 60,
              child: ValueListenableBuilder<Song?>(
                valueListenable: _playbackManager.currentSongNotifier,
                builder: (context, currentSong, child) {
                  return InkWell(
                    onTap: () {
                      if (_playbackManager.currentSongNotifier.value != null)
                        showModalBottomSheet(
                          context: context,
                          useSafeArea: true,
                          isScrollControlled: true,
                          builder: (context) => MusicControllerBottomSheet(
                            playbackManager: _playbackManager,
                          ),
                        );
                    },
                    child: Container(
                      padding: EdgeInsets.symmetric(horizontal: 8.0),
                      child: Row(
                        children: [
                          if (currentSong != null)
                            ClickableAlbumCover(
                              currentSong: currentSong,
                            ),
                          SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  currentSong?.title ?? 'No Song Playing',
                                  style: TextStyle(fontSize: 14),
                                  overflow: TextOverflow.ellipsis,
                                  maxLines: 1,
                                ),
                                Text(
                                  currentSong?.artistName ?? 'No Artist',
                                  style: TextStyle(
                                      fontSize: 12, color: Colors.grey),
                                  overflow: TextOverflow.ellipsis,
                                  maxLines: 1,
                                ),
                              ],
                            ),
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
                        ],
                      ),
                    ),
                  );
                },
              ),
            )
          : null,
      backgroundColor: Color(0xFF1c1a1e),
      body: KeyboardListener(
        focusNode: _focusNode,
        onKeyEvent: (KeyEvent event) {
          if (event is KeyDownEvent) {
            if ((event.logicalKey == LogicalKeyboardKey.enter &&
                    event.logicalKey == LogicalKeyboardKey.alt) ||
                event.logicalKey == LogicalKeyboardKey.f11) {
              _toggleFullScreen();
            }
          }
        },
        child: Row(
          children: [
            !Platform.isAndroid
                ? SidebarX(
                    controller: sidebarController,
                    theme: SidebarXTheme(
                      margin: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: canvasColor,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      hoverColor: scaffoldBackgroundColor,
                      textStyle:
                          TextStyle(color: Colors.white.withOpacity(0.7)),
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
                          onTap: () async {
                            navigatorKey.currentState!.pushReplacementNamed(
                              '/',
                            );
                          }),
                      SidebarXItem(
                          icon: Icons.search,
                          label: 'Search',
                          onTap: () async {
                            navigatorKey.currentState!.pushReplacementNamed(
                              '/search',
                            );
                          }),
                      SidebarXItem(
                          icon: Icons.playlist_play,
                          label: 'Playlists',
                          onTap: () async {
                            navigatorKey.currentState!.pushReplacementNamed(
                              '/playlist',
                            );
                          }),
                      const SidebarXItem(
                        icon: Icons.reviews,
                        label: 'Reviews',
                      ),
                      SidebarXItem(
                          icon: Icons.settings,
                          label: 'Settings',
                          onTap: () {
                            showSettingsDialog(context, (String val) {
                              setState(() {});
                            });
                          }),
                    ],
                  )
                : SizedBox(),
            !Platform.isAndroid
                ? Expanded(
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
                                          builder: (context) =>
                                              MusicLibraryPage(),
                                        );
                                      case '/album':
                                        final Object? arguments =
                                            settings.arguments;
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
                                            builder: ((context) =>
                                                SearchPage()));
                                      case '/artist':
                                        return MaterialPageRoute(
                                          builder: (context) =>
                                              MusicLibraryPage(),
                                        );
                                      case '/playlist':
                                        final Object? arguments =
                                            settings.arguments;
                                        return MaterialPageRoute(
                                            builder: ((context) =>
                                                PlaylistsPage()));
                                    }
                                  },
                                )),
                          ),
                        ),
                      ),
                    ),
                  )
                : Expanded(
                    child: Center(
                        child: // Adjust the radius for more or less rounded corners
                            Navigator(
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
                            final Object? arguments = settings.arguments;
                            return MaterialPageRoute(
                                builder: ((context) => PlaylistsPage()));
                        }
                      },
                    )),
                  ),
          ],
        ),
      ),
      bottomNavigationBar: !Platform.isAndroid
          ? BottomAppBar(
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
                                    width:
                                        150, // Set the width of the TextButton
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
                                      child: MarqueeWidget(
                                        child: Text(currentSong.title),
                                      ),
                                    ),
                                  ),
                                  Flexible(
                                    child: TextButton(
                                      onPressed: () {
                                        navigatorKey.currentState!.push(
                                            MaterialPageRoute(
                                                builder: (context) =>
                                                    ArtistPage(
                                                      artistId:
                                                          currentSong.albumId,
                                                      artistName: currentSong
                                                          .artistName,
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
                                      onPressed: () =>
                                          _playbackManager.previous(),
                                    ),
                                    ValueListenableBuilder(
                                      valueListenable:
                                          _playbackManager.isPlaying,
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
            )
          : BottomNavigationBar(
              items: [
                BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
                BottomNavigationBarItem(
                    icon: Icon(Icons.search), label: 'Search'),
              ],
              currentIndex: _tabController.index,
              onTap: (index) {
                _tabController.animateTo(index);
              },
            ),
    ));
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
