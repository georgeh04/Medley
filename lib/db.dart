import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:audio_metadata_reader/audio_metadata_reader.dart';
import 'library.dart';

// Define your database opening function if not already done
Future<Database> openDb() async {
  final databasePath = await getDatabasesPath();
  final path = join(databasePath, 'medleyLibrary.db');

  return openDatabase(path, version: 1,
      onCreate: (Database db, int version) async {
    // Create the Artists table
    await db.execute('''
      CREATE TABLE Artists (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL
      )
    ''');

    // Create the Albums table
    await db.execute('''
      CREATE TABLE Albums (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        artistId INTEGER NOT NULL,
        name TEXT NOT NULL,
        FOREIGN KEY (artistId) REFERENCES Artists(id)
      )
    ''');

    // Create the Songs table
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
  });
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
  int albumId = await _insertAlbum(db, artistId, albumName);

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

Future<int> _insertAlbum(Database db, int artistId, String albumName) async {
  // First, check if the album already exists for the artist.
  final List<Map<String, dynamic>> albums = await db.query(
    'Albums',
    columns: ['id'],
    where: 'name = ? AND artistId = ?',
    whereArgs: [albumName, artistId],
  );

  // If the album exists, return the existing ID.
  if (albums.isNotEmpty) {
    return albums.first['id'];
  }

  // If the album doesn't exist, insert a new record.
  return await db.insert(
    'Albums',
    {'artistId': artistId, 'name': albumName},
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
        'Album ID: ${album['id']}, Artist ID: ${album['artistId']}, Name: ${album['name']}');
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
