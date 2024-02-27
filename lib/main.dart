import 'package:flutter/material.dart';
import 'package:sqflite/sqlite_api.dart';
import 'library.dart';
import 'package:provider/provider.dart';
import 'package:just_audio/just_audio.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:io';
import 'db.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

void main() {
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

Future<void> pickAndScanMusicFolder() async {
  // Use FilePicker to let the user pick a directory
  String? selectedDirectory = await FilePicker.platform
      .getDirectoryPath(dialogTitle: 'Choose your music folder');

  if (selectedDirectory != null) {
    // If the user selected a directory, scan it for music files
    await findMusicFiles(Directory(selectedDirectory));
  } else {
    print("No directory selected");
  }
}

class MusicPlayerApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
        create: (_) => PlaybackState(),
        child: MaterialApp(
          theme: ThemeData(
            primarySwatch: Colors.blue,
            visualDensity: VisualDensity.adaptivePlatformDensity,
          ),
          darkTheme: ThemeData(
            brightness: Brightness.dark,
          ),
          themeMode: ThemeMode.dark,
          home: MainScreen(),
        ));
  }
}

class PlaybackState with ChangeNotifier {
  String _currentSong = "No song playing";
  bool _isPlaying = false;
  final AudioPlayer _audioPlayer = AudioPlayer();

  String get currentSong => _currentSong;
  bool get isPlaying => _isPlaying;

  void playSong(String song, String name) async {
    _currentSong = name;
    await _audioPlayer.setFilePath(song);
    await _audioPlayer.play();
    _isPlaying = true;
    print('playing');
    notifyListeners();
  }

  void pause() async {
    _isPlaying = false;
    await _audioPlayer.pause();

    print('paused');
    notifyListeners();
  }

  void play() async {
    _isPlaying = true;
    await _audioPlayer.play();

    print('playing');
    notifyListeners();
  }

  // Add methods as needed for your app's functionality

  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }
}

class MainScreen extends StatefulWidget {
  @override
  _MainScreenState createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;

  void onTabTapped(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  @override
  void initState() {
    pickAndScanMusicFolder();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<PlaybackState>(
      builder: (context, playbackState, child) => Scaffold(
        body: Navigator(
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
          actions: [
            IconButton(
              icon: Icon(Icons.folder_open),
              onPressed: () async {
                FilePickerResult? result = await FilePicker.platform.pickFiles(
                  type: FileType.custom,
                  allowedExtensions: ['mp3', 'wav', 'flac', 'aac'],
                );

                if (result != null) {
                  String path = result.files.single.path!;
                  String Title = result.files.single.name;
                  setState(() {
                    playbackState.playSong(path, Title);
                  });
                }
              },
            ),
          ],
        ),
        bottomNavigationBar: BottomAppBar(
          child: Container(
            height: 70,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                IconButton(
                  icon: Icon(
                      playbackState.isPlaying ? Icons.pause : Icons.play_arrow),
                  onPressed: () {
                    // Play or pause the song based on current state
                    if (playbackState.isPlaying) {
                      setState(() {
                        playbackState.pause();
                      });
                    } else {
                      setState(() {
                        playbackState.play();
                      });
                    }
                  },
                ),
                Container(
                  width: 300,
                  child: Text(
                    playbackState.currentSong,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                // Add more controls as needed
              ],
            ),
          ),
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
