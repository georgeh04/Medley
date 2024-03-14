import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:media_kit/media_kit.dart';
import 'package:medleylibrary/main.dart';
import 'library.dart';
import 'globalKeys.dart';

class PlaybackManager {
  ValueNotifier<Song?> currentSongNotifier = ValueNotifier(null);
  static final PlaybackManager _instance = PlaybackManager._internal();
  factory PlaybackManager() => _instance;
  int currentTrackIndex = 0;

  final Player _player = Player();
  List<Song> queue = [];
  ValueNotifier<bool> isPlaying = ValueNotifier(false);
  ValueNotifier<Duration> currentPositionNotifier =
      ValueNotifier(Duration.zero);

  Stream<Duration> get positionStream => _player.stream.position;
  Stream<Duration> get durationStream => _player.stream.duration;

  PlaybackManager._internal() {
    _player.stream.completed.listen((event) {
      print('changing song: $event');
      if (event == true) {
        currentTrackIndex++;
        currentSongNotifier.value = queue[currentTrackIndex];
        if (lastfmConnected == true) {
          scrobbleFromSong(currentSongNotifier.value!);
        }
      }
    });
    _player.stream.playing.listen((_isPlaying) => isPlaying.value = _isPlaying);
    _player.stream.position
        .listen((position) => currentPositionNotifier.value = position);
    // Additional player stream subscriptions as needed
  }

  Future<void> setVolume(double volume) async {
    await _player.setVolume(volume);
  }

  Future<void> seek(Duration position) async {
    await _player.seek(position);
  }

  Future<void> playSongObject(Song song) async {
    if (lastfmConnected == true) {
      scrobbleFromSong(song);
    }
    Media media = Media(song.path);
    await _player.open(media);
    currentSongNotifier.value = song;
    await _player.play();
  }

  Future<void> playAlbumFromTrack(List<Song> albumSongs, int trackIndex) async {
    if (albumSongs.isEmpty || trackIndex >= albumSongs.length) {
      return;
    }

    print('playing index: $trackIndex, length: ${albumSongs.length}');

    // Update the queue with the album songs
    queue.clear(); // Clear the current queue
    queue.addAll(albumSongs); // Add the new songs to the queue

    // Update the current track index
    currentTrackIndex = trackIndex;

    // Create a playlist from the album songs and open it
    Playlist playlist =
        Playlist(albumSongs.map((song) => Media(song.path)).toList());
    await _player.open(playlist);
    await _player
        .jump(trackIndex); // Jump to the specific track in the playlist

    // Update the current song notifier to reflect the current song
    currentSongNotifier.value = queue[currentTrackIndex];
    if (lastfmConnected == true) {
      scrobbleFromSong(currentSongNotifier.value!);
    }
    // Start playback
    await _player.play();
  }

  Future<void> play() async {
    if (!isPlaying.value) {
      await _player.play();
    }
  }

  Future<void> pause() async {
    await _player.pause();
  }

  Future<void> next() async {
    await _player.next();
    currentTrackIndex++;
    currentSongNotifier.value = queue[currentTrackIndex];
  }

  Future<void> previous() async {
    await _player.previous();
    currentTrackIndex--;
    currentSongNotifier.value = queue[currentTrackIndex];
  }

  Future<void> stop() async {
    await _player.dispose();
    currentSongNotifier.value = null;
  }

  Song? getCurrentSong() {
    return currentSongNotifier.value;
  }
}

void scrobbleFromSong(Song song) {
  DateTime now = DateTime.now();

// Convert to milliseconds since epoch, then divide by 1000 to get seconds
  int secondsSinceEpoch = now.millisecondsSinceEpoch ~/ 1000;

  Map<String, dynamic> tracksData = {
    'artist': song.artistName,
    'track': song.title,
    'timestamp':
        secondsSinceEpoch.toString(), // Example UNIX timestamp (in seconds)
    // Optional parameters
    'album': song.albumName,
    'trackNumber': song.trackNumber.toString(),
    'chosenByUser': '1', // Assuming the user chose this song
  };
  scrobbleTracks(tracksData, 'cad200fbadbeb49cbd8b060607a0ccf5',
      '83a6ae544f0729705292a12699d92c58', lastfmSession!);
}
