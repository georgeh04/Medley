import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;

Future<List<File>> findMusicFiles() async {
  List<File> musicFiles = [];

  // Get the user's music directory
  Directory musicDirectory = await getMusicDirectory();

  print('Music directory: ${musicDirectory.path}');

  // List all files recursively
  await for (var entity
      in musicDirectory.list(recursive: true, followLinks: false)) {
    String extension = path.extension(entity.path).toLowerCase();
    if (entity is File &&
        ['.mp3', '.wav', '.flac', '.aac'].contains(extension)) {
      musicFiles.add(entity);
    }
  }

  return musicFiles;
}

Future<Directory> getMusicDirectory() async {
  Directory homeDirectory = await getApplicationDocumentsDirectory();
  Directory musicDirectory;

  if (Platform.isMacOS) {
    musicDirectory = Directory(path.join(homeDirectory.path, 'Music'));
  } else if (Platform.isWindows) {
    musicDirectory = Directory(path.join(homeDirectory.path, 'My Music'));
  } else if (Platform.isLinux) {
    musicDirectory = Directory(path.join(homeDirectory.path, 'Music'));
  } else {
    throw UnsupportedError('This platform is not supported');
  }

  return musicDirectory;
}
