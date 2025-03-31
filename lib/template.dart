import 'package:flutter_asset_generator/config.dart';
import 'package:path/path.dart' as path_library;

import 'replace.dart';

class Template {
  Template(
    this.className,
    this.config,
  );

  final String className;
  final Config config;

  late final Replacer replacer = Replacer(config: config);

  static const String license = '''
/// Generate by [asset_generator](https://github.com/lollipopkit/flutter_asset_generator) library.
/// PLEASE DO NOT EDIT MANUALLY.
// ignore_for_file: constant_identifier_names\n''';

  String get classDeclare => '''
abstract final class $className {\n
  const $className._();\n''';

  static const String classDeclareFooter = '}\n';

  String formatOnePath(String path, String projectPath, bool addPreview) {
    if (addPreview) {
      return '''
  /// ![preview](file://$projectPath${path_library.separator}${_formatPreviewName(path)})
  static const String ${_formatFiledName(path)} = '$path';\n''';
    }
    return '''
  static const String ${_formatFiledName(path)} = '$path';\n''';
  }

  String _formatPreviewName(String path) {
    path = path.replaceAll(' ', '%20').replaceAll('/', path_library.separator);
    return path;
  }

  String _formatFiledName(String path) {
    return replacer.replaceName(path).toUpperCase();
  }

  String toUppercaseFirstLetter(String str) {
    return '${str[0].toUpperCase()}${str.substring(1)}';
  }
}
