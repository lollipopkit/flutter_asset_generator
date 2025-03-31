import 'dart:async';
import 'dart:io';

import 'package:path/path.dart';
import 'package:yaml/yaml.dart';

import 'config.dart';
import 'filter.dart';
import 'format.dart';
import 'logger.dart';
import 'template.dart';

const String _generateLogPrefix = 'Generating resource records';

const List<String> platformExcludeFiles = <String>[
  // For MacOS
  '.DS_Store',
  // For Windows
  'thumbs.db',
  'desktop.ini',
];
const int serverPort = 31313;

class ResourceDartBuilder {
  // ResourceDartBuilder(String projectRootPath, this.outputPath) {
  ResourceDartBuilder(this.config);

  final Config config;
  Filter? get filter => config.filter;
  bool get isWatch => config.isWatch;
  bool _watching = false;
  bool get isPreview => config.preview;

  void generateResourceDartFile() {
    final String className = config.className;
    print('$_generateLogPrefix for project: $projectRootPath');
    stopWatch();
    final String pubYamlPath = '$projectRootPath${separator}pubspec.yaml';
    try {
      final List<String> assetPathList = _getAssetPath(pubYamlPath);
      logger.debug('The asset path list is: $assetPathList');
      generateImageFiles(assetPathList);
      logger.debug('the image is $allImageList');
      generateCode(className);
    } catch (e) {
      if (e is StackOverflowError && e.stackTrace != null) {
        logger.debug(e.stackTrace!);
      } else {
        logger.debug(e);
      }
    }
    print('$_generateLogPrefix finish.');
    startWatch(className);
  }

  File get logFile => File('.dart_tool${separator}fgen_log.txt');

  String get projectRootPath => config.src;
  String get outputPath => config.output;

  /// Get asset paths from [yamlPath].
  List<String> _getAssetPath(String yamlPath) {
    final YamlMap map = loadYaml(File(yamlPath).readAsStringSync()) as YamlMap;
    final dynamic flutterMap = map['flutter'];
    if (flutterMap is YamlMap) {
      final dynamic assetMap = flutterMap['assets'];
      if (assetMap is YamlList) {
        return getListFromYamlList(assetMap);
      }
    }
    return <String>[];
  }

  /// Get the asset from yaml list
  List<String> getListFromYamlList(YamlList yamlList) {
    final List<String> list = <String>[];
    final List<String> r = yamlList.map((dynamic f) => f.toString()).toList();
    list.addAll(r);
    return list;
  }

  /// Convert the set to the list
  List<String> get allImageList => imageSet.toList()..sort();

  /// The set is all file path，not exists directory.
  final Set<String> imageSet = <String>{};

  /// All of the directory with yaml.
  final List<Directory> dirList = <Directory>[];

  /// Scan the with path list
  void generateImageFiles(List<String> paths) {
    imageSet.clear();
    dirList.clear();

    for (final String path in paths) {
      generateImageFileWithPath(path, imageSet, dirList, true);
    }

    // Do filter
    if (filter != null) {
      final Iterable<String> result = filter!.filter(imageSet);
      imageSet.clear();
      imageSet.addAll(result);
    }
  }

  /// If path is a directory, add the directory to [dirList].
  /// If not, add it to [imageSet].
  void generateImageFileWithPath(
    String path,
    Set<String> imageSet,
    List<Directory> dirList,
    bool rootPath,
  ) {
    final String fullPath = _getAbsolutePath(path);
    if (FileSystemEntity.isDirectorySync(fullPath)) {
      if (!rootPath) {
        return;
      }
      final Directory directory = Directory(fullPath);
      dirList.add(directory);
      final List<FileSystemEntity> entries = directory.listSync(
        recursive: false,
      );
      for (final FileSystemEntity entity in entries) {
        generateImageFileWithPath(entity.path, imageSet, dirList, false);
      }
    } else if (FileSystemEntity.isFileSync(fullPath)) {
      if (platformExcludeFiles.contains(basename(fullPath))) {
        return;
      }
      final String relativePath = path
          .replaceAll('$projectRootPath$separator', '')
          .replaceAll('$projectRootPath/', '');
      if (!imageSet.contains(path)) {
        imageSet.add(relativePath);
      }
    }
  }

  String _getAbsolutePath(String path) {
    final File f = File(path);
    if (f.isAbsolute) {
      return path;
    }
    return '$projectRootPath/$path';
  }

  final bool isWriting = false;

  File get resourceFile {
    File res;
    if (File(outputPath).isAbsolute) {
      res = File(outputPath);
    } else {
      res = File('$projectRootPath/$outputPath');
    }

    res.createSync(recursive: true);
    return res;
  }

  static final _findConstStrReg =
      RegExp(r"([a-zA-Z0-9_]+)\s+=\s+\'([^\']*)\'");

  /// Generate the dart code
  Future<void> generateCode(String className) async {
    stopWatch();
    logger.debug('Start writing records');
    await resourceFile.delete(recursive: true);
    await resourceFile.create(recursive: true);

    final StringBuffer sb = StringBuffer();
    final Template template = Template(className, config);
    sb.write(Template.license);
    sb.write(template.classDeclare);

    final replaceMap = <String, String>{};

    for (final String path in allImageList) {
      sb.write(template.formatOnePath(path, projectRootPath, isPreview));

      if (config.replaceStrings) {
        final String replacePath =
            template.replacer.replaceName(path).toUpperCase();
        replaceMap[path] = replacePath;
      }
    }
    sb.write(Template.classDeclareFooter);

    if (config.replaceStrings && replaceMap.isNotEmpty) {
      logger.debug('Start replacing strings');
      logger.debug('Replace map: $replaceMap');

      /// Replace the strings in the dart files
      final files = await Directory(join(projectRootPath, 'lib'))
          .list(recursive: true)
          .toList();
      for (final FileSystemEntity file in files) {
        if (file is File && file.path.endsWith('.dart')) {
          // If the file is the resource file, skip it.
          if (file.path == resourceFile.path) {
            continue;
          }

          final content = await file.readAsString();
          final replacedContent = content.replaceAllMapped(
            _findConstStrReg,
            (Match match) {
              final String? name = match.group(2);
              final group0 = match.group(0)!;
              logger.debug(group0);
              if (name == null) {
                return group0;
              }
              final String? replaceName = replaceMap[name];
              logger.debug('Replace $name to $replaceName');
              if (replaceName == null) {
                return group0;
              }
              final replaced = '${match.group(1)} = ${config.className}.$replaceName';
              logger.debug(
                'Replace $name to $replaceName in ${file.path}',
              );
              return replaced;
            },
          );
          await file.writeAsString(replacedContent);
        }
      }
    } else {
      logger.debug('Not replacing strings');
    }

    final Stopwatch sw = Stopwatch();
    sw.start();
    final String formattedCode = formatFile(sb.toString());
    sw.stop();
    print('Formatted records in ${sw.elapsedMilliseconds}ms');
    sw.reset();
    resourceFile.writeAsString(formattedCode);
    sw.stop();
    logger.debug('End writing records ${sw.elapsedMilliseconds}');
  }

  /// Watch all paths
  Future<void> startWatch(String className) async {
    if (!isWatch) {
      return;
    }
    if (_watching) {
      return;
    }
    _watching = true;
    for (final Directory dir in dirList) {
      final StreamSubscription<FileSystemEvent>? sub = _watch(dir);
      if (sub != null) {
        sub.onDone(sub.cancel);
      }
      watchMap[dir] = sub;
    }
    final File pubspec = File('$projectRootPath${separator}pubspec.yaml');
    // ignore: cancel_subscriptions
    final StreamSubscription<FileSystemEvent>? sub = _watch(pubspec);
    if (sub != null) {
      watchMap[pubspec] = sub;
    }

    final File configFile = File('$projectRootPath${separator}fgen.yaml');
    if (configFile.existsSync()) {
      // ignore: cancel_subscriptions
      final StreamSubscription<FileSystemEvent>? configFileSub =
          _watch(configFile);
      if (sub != null) {
        watchMap[configFile] = configFileSub;
      }
    }

    print('Watching all resources file.');
  }

  void stopWatch() {
    _watching = false;
    for (final StreamSubscription<FileSystemEvent>? v in watchMap.values) {
      v?.cancel();
    }
    watchMap.clear();
  }

  /// When the directory is change, refresh records.
  StreamSubscription<FileSystemEvent>? _watch(
    FileSystemEntity file,
  ) {
    if (FileSystemEntity.isWatchSupported) {
      return file.watch().listen((FileSystemEvent data) {
        print('${data.path} has changed.');
        config.refresh();
        generateResourceDartFile();
      });
    }
    return null;
  }

  final Map<FileSystemEntity, StreamSubscription<FileSystemEvent>?> watchMap =
      <FileSystemEntity, StreamSubscription<FileSystemEvent>?>{};

  void removeAllWatches() {
    for (final StreamSubscription<FileSystemEvent>? sub in watchMap.values) {
      sub?.cancel();
    }
  }
}
