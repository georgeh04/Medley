import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:sqflite/sqflite.dart';
import 'package:sqflite_common/sqlite_api.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:path/path.dart';
import 'package:audio_metadata_reader/audio_metadata_reader.dart';
import 'library.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';

Future<Database> openDb() async {
  // Check if the platform is Windows
  if (Platform.isWindows) {
    // Initialize sqflite FFI
    sqfliteFfiInit();
    // Use the database factory for FFI
    final databaseFactory = databaseFactoryFfi;
    var databasesPath = await getApplicationDocumentsDirectory();
    String path = join(databasesPath.path, 'medleyLibrary.db');
    return databaseFactory.openDatabase(path,
        options: OpenDatabaseOptions(
          version: 1,
          onCreate: (Database db, int version) async {
            await _createDb(db);
          },
        ));
  } else {
    // For non-Windows platforms, continue using the existing path
    final databasePath = await getDatabasesPath();
    final path = join(databasePath, 'medleyLibrary.db');
    return openDatabase(path, version: 1,
        onCreate: (Database db, int version) async {
      await _createDb(db);
    });
  }
}

// Refactored the DB creation logic to a separate function for clarity
Future<void> _createDb(Database db) async {
  await db.execute('''
    CREATE TABLE Artists (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      name TEXT NOT NULL
    )
  ''');

  await db.execute('''
    CREATE TABLE Albums (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      artistId INTEGER NOT NULL,
      name TEXT NOT NULL,
      coverUrl TEXT NOT NULL,
      FOREIGN KEY (artistId) REFERENCES Artists(id)
    )
  ''');

  await db.execute('''
    CREATE TABLE Songs (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      albumId INTEGER NOT NULL,
      artistId INTEGER NOT NULL,
      title TEXT NOT NULL,
      trackNumber INTEGER,
      duration INTEGER,
      filePath TEXT NOT NULL,
      FOREIGN KEY (albumId) REFERENCES Albums(id)
    )
  ''');
}

Future<void> findMusicFiles(Directory directory,
    {String? artistName, String? albumName}) async {
  final db = await openDb();

  await for (FileSystemEntity entity
      in directory.list(recursive: false, followLinks: false)) {
    if (entity is Directory) {
      final newArtistName =
          artistName ?? entity.path.split(Platform.pathSeparator).last;
      final newAlbumName = artistName != null
          ? entity.path.split(Platform.pathSeparator).last
          : albumName;

      await findMusicFiles(Directory(entity.path),
          artistName: newArtistName, albumName: newAlbumName);
    } else if (entity is File && isMusicFile(entity)) {
      // Use audio_metadata_reader to read metadata

      var file = File(entity.path);
      final metadata = await readMetadata(file);

      // Fallback to filename if metadata is not available
      final songTitle =
          metadata?.title ?? entity.path.split(Platform.pathSeparator).last;
      final trackArtist = metadata?.artist ?? artistName ?? 'Unknown Artist';
      final trackAlbum = metadata?.album ?? albumName ?? 'Unknown Album';
      final trackNumber = metadata?.trackNumber ?? 1;
      final duration = metadata?.duration!.inSeconds ??
          240; // Duration in milliseconds, converted to seconds if available

      await insertMusicInfoIntoDb(db, trackArtist, trackAlbum, songTitle,
          trackNumber, duration, entity.path);
    }
  }

  await db.close();
}

Future<void> insertMusicInfoIntoDb(
    Database db,
    String artistName,
    String albumName,
    String songTitle,
    int trackNumber,
    int duration,
    String filePath) async {
  int artistId = await _insertArtist(db, artistName);
  int albumId = await _insertAlbum(db, artistId, albumName, artistName);

  await db.insert(
      'Songs',
      {
        'albumId': albumId,
        'artistId': artistId,
        'title': songTitle,
        'trackNumber': trackNumber,
        'duration': duration,
        'filePath': filePath
      },
      conflictAlgorithm: ConflictAlgorithm.ignore);
}

Future<int> _insertArtist(Database db, String artistName) async {
  // First, check if the artist already exists.
  final List<Map<String, dynamic>> artists = await db.query(
    'Artists',
    columns: ['id'],
    where: 'name = ?',
    whereArgs: [artistName],
  );

  // If the artist exists, return the existing ID.
  if (artists.isNotEmpty) {
    return artists.first['id'];
  }

  // If the artist doesn't exist, insert a new record.
  return await db.insert(
    'Artists',
    {'name': artistName},
    conflictAlgorithm: ConflictAlgorithm.ignore,
  );
}

Future<String?> fetchAlbumCoverArt(String artistName, String albumName) async {
  const String apiKey =
      '47eae4afc5dc8f374fc3047348bf979d'; // Replace with your Last.fm API key
  final String apiUrl =
      'http://ws.audioscrobbler.com/2.0/?method=album.getinfo&api_key=$apiKey&artist=${Uri.encodeComponent(artistName)}&album=${Uri.encodeComponent(albumName)}&format=json';

  try {
    final response = await http.get(Uri.parse(apiUrl));
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      // Navigate the JSON response to find the image URL
      var albumData = data['album'];
      if (albumData != null) {
        var images = albumData['image'];
        if (images != null && images.isNotEmpty) {
          // Last.fm provides multiple sizes, this example grabs the last one (largest)
          String imageUrl = images.last['#text'];
          return imageUrl.isNotEmpty ? imageUrl : null;
        }
      }
    } else {
      print('Failed to load album cover art');
    }
  } catch (e) {
    print('Error fetching album cover art: $e');
  }
  return null; // Return null if there was an error or if the cover art was not found
}

Future<int> _insertAlbum(
    Database db, int artistId, String albumName, String artistName) async {
  // First, check if the album already exists for the artist.
  final List<Map<String, dynamic>> albums = await db.query(
    'Albums',
    columns: ['id'],
    where: 'name = ? AND artistId = ?',
    whereArgs: [albumName, artistId],
  );

  var coverArt = await fetchAlbumCoverArt(artistName, albumName);

  // If the album exists, return the existing ID.
  if (albums.isNotEmpty) {
    return albums.first['id'];
  }

  // If the album doesn't exist, insert a new record.
  return await db.insert(
    'Albums',
    {'artistId': artistId, 'name': albumName, 'coverUrl': coverArt ?? ''},
    conflictAlgorithm: ConflictAlgorithm.ignore,
  );
}

bool isMusicFile(File file) {
  return file.path.endsWith('.mp3') ||
      file.path.endsWith('.flac') ||
      file.path.endsWith('.wav') ||
      file.path.endsWith('.aac');
}

Future<void> printMusicLibrary(Database db) async {
  print("Music Library:");

  List<Map<String, dynamic>> artists = await db.query('Artists');
  for (var artist in artists) {
    print('Artist: ${artist['name']}');

    List<Map<String, dynamic>> albums = await db
        .query('Albums', where: 'artistId = ?', whereArgs: [artist['id']]);
    for (var album in albums) {
      print('  Album: ${album['name']}');

      List<Map<String, dynamic>> songs = await db
          .query('Songs', where: 'albumId = ?', whereArgs: [album['id']]);
      for (var song in songs) {
        print(
            '    Song: ${song['title']} (Track: ${song['trackNumber']}, Duration: ${song['duration']} seconds)');
      }
    }
  }
}

Future<void> printArtists() async {
  var db = await openDb();
  print("Artists in the Library:");
  List<Map<String, dynamic>> artists = await db.query('Artists');
  for (var artist in artists) {
    print('Artist ID: ${artist['id']}, Name: ${artist['name']}');
  }
}

Future<void> printAlbums() async {
  var db = await openDb();
  print("Albums in the Library:");
  List<Map<String, dynamic>> albums = await db.query('Albums');
  for (var album in albums) {
    print(
        'Album ID: ${album['id']}, Artist ID: ${album['artistId']}, Name: ${album['name']}, Cover URL: ${album['coverUrl']}');
  }
}

Future<void> printSongs() async {
  var db = await openDb();
  print("Songs in the Library:");
  List<Map<String, dynamic>> songs = await db.query('Songs');
  for (var song in songs) {
    print(
        'Song ID: ${song['id']}, Album ID: ${song['albumId']}, Title: ${song['title']}, Track Number: ${song['trackNumber']}, Duration: ${song['duration']} seconds, File Path: ${song['filePath']}');
  }
}
