import 'package:medleylibrary/db.dart';

import 'library.dart'; // Ensure this is the correct path to your Song class
import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';

typedef void OnSongChangeCallback(Song currentSong);

class PlaybackManager {
  ValueNotifier<Song?> currentSongNotifier = ValueNotifier(null);
  late ConcatenatingAudioSource _playlist;
  static final PlaybackManager _instance = PlaybackManager._internal();
  factory PlaybackManager() => _instance;

  final AudioPlayer _audioPlayer = AudioPlayer();
  List<Song> _queue = [];
  int _currentIndex = -1;
  bool _isPlaying = false;

  PlaybackManager._internal() {
    _playlist = ConcatenatingAudioSource(
      // Start loading next item just before reaching it
      // Customise the shuffle algorithm
      shuffleOrder: DefaultShuffleOrder(),
      // Initially, the playlist is empty
      children: [],
    );
    _audioPlayer.setAudioSource(_playlist,
        initialIndex: _currentIndex, initialPosition: Duration.zero);
    _audioPlayer.playerStateStream.listen((state) {
      if (state.processingState == ProcessingState.completed) {
        next();
      } else if (state.processingState == ProcessingState.ready) {
        // Update current song notifier
        currentSongNotifier.value =
            _currentIndex >= 0 && _currentIndex < _queue.length
                ? _queue[_currentIndex]
                : null;
      }
    });
  }

  void playSongObject(Song song) async {
    print('playing song: ${song.path}');
    // Clear the current playlist and queue
    await _playlist.clear(); // Clear existing songs in the playlist
    _queue
        .clear(); // Clear the queue to ensure only the selected song is in the playback queue

    // Reset the current index
    _currentIndex = 0;

    // Create an AudioSource for the selected song
    AudioSource audioSource = AudioSource.file(song.path, tag: song);

    // Add the AudioSource to the playlist
    _playlist.add(audioSource);

    // Add the song to the queue for managing playback state
    _queue.add(song);

    // Ensure the notifier is updated with the current song
    currentSongNotifier.value = song;

    // Play the song
    await _audioPlayer.setAudioSource(_playlist, initialIndex: _currentIndex);
    await _audioPlayer.play();
    _isPlaying = true;
  }

  // Adds an album to the queue. An album is represented as a list of songs.
  void playAlbumFromTrack(List<Song> albumSongs, int trackIndex) async {
    if (albumSongs.isEmpty || trackIndex >= albumSongs.length) {
      print("Invalid track index or empty album.");
      return;
    }

    print('playing song: ${albumSongs[trackIndex].title}');

    // Clear the current playlist and queue
    await _playlist.clear();
    _queue.clear();

    // Reset the current index to the selected track index
    _currentIndex = 0; // Will be set properly when playing the song

    // Add tracks from the selected index to the end of the album to the playlist and queue
    List<AudioSource> sources = [];
    for (var i = trackIndex; i < albumSongs.length; i++) {
      Song song = albumSongs[i];
      AudioSource audioSource = AudioSource.file(song.path, tag: song);
      sources.add(audioSource);
      _queue.add(song);
    }

    // Add the sources to the playlist
    await _playlist.addAll(sources);

    // Play the first song from the selected tracks
    currentSongNotifier.value = albumSongs[trackIndex];
    await _audioPlayer.setAudioSource(_playlist,
        initialIndex:
            0); // Starting from the first song in the modified playlist
    await _audioPlayer.play();
    _isPlaying = true;
  }

  void play() async {
    if (_currentIndex != -1 && !_isPlaying) {
      await _audioPlayer.seek(Duration.zero, index: _currentIndex);
      await _audioPlayer.play();
      _isPlaying = true;
    }
  }

  // Play the next song in the queue
  void next() {
    if (_currentIndex < _queue.length - 1) {
      _currentIndex++;
      play();
    } else {
      print("Reached the end of the queue.");
    }
  }

  // Play the previous song in the queue
  void previous() {
    if (_currentIndex > 0) {
      _currentIndex--;
      play();
    } else {
      print("Already at the beginning of the queue.");
    }
  }

  // Pause the current song.
  void pause() async {
    await _audioPlayer.pause();
    _isPlaying = false;
  }

  // Stop the playback and release resources
  void stop() async {
    await _audioPlayer.stop();
    _currentIndex = -1;
    _isPlaying = false;
    _queue.clear();
    _playlist.clear();
  }

  // Get the current song being played
  Song? getCurrentSong() {
    if (_currentIndex != -1) {
      return _queue[_currentIndex];
    }
    return null;
  }

  bool get isPlaying => _isPlaying;
}
