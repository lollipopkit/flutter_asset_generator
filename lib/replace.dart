import 'package:flutter_asset_generator/config.dart';
import 'package:yaml/yaml.dart';

class ReplaceItem {
  const ReplaceItem({
    required this.from,
    required this.to,
  });
  final String from;
  final String to;
}

class Replacer {
  Replacer({required this.config}) {
    init();
  }

  final Config config;

  final Map<String, ReplaceItem> itemMap = <String, ReplaceItem>{};

  void init() {
    final YamlMap? options = config.configFileOptions;
    if (options != null) {
      final List<dynamic>? replace = options['replace'] as List<dynamic>?;
      if (replace != null) {
        for (final dynamic item in replace) {
          final Map<dynamic, dynamic> map = item as Map<dynamic, dynamic>;
          final String from = map['from'] as String? ?? '';
          final String to = map['to'] as String? ?? '';
          itemMap[from] = ReplaceItem(from: from, to: to);
        }
      }
    }

    itemMap.putIfAbsent('/', () => const ReplaceItem(from: '/', to: '_'));
    itemMap.putIfAbsent('.', () => const ReplaceItem(from: '.', to: '_'));
    itemMap.putIfAbsent(' ', () => const ReplaceItem(from: ' ', to: '_'));
    itemMap.putIfAbsent('-', () => const ReplaceItem(from: '-', to: '_'));
    itemMap.putIfAbsent('@', () => const ReplaceItem(from: '@', to: '_AT_'));
  }

  String replaceName(String path) {
    String result = path;
    itemMap.forEach((String key, ReplaceItem value) {
      result = result.replaceAll(value.from, value.to);
    });
    return result;
  }
}
