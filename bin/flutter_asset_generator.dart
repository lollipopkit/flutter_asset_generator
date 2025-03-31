import 'package:args/args.dart';
import 'package:flutter_asset_generator/builder.dart';
import 'package:flutter_asset_generator/config.dart';
import 'package:flutter_asset_generator/logger.dart';

void main(List<String> args) {
  final ArgParser parser = ArgParser();
  parser.addOption(
    'output',
    abbr: 'o',
    help: 'Output resource file path',
  );
  parser.addOption(
    'src',
    abbr: 's',
    defaultsTo: '.',
    help: 'Flutter project root path',
  );
  parser.addOption(
    'name',
    abbr: 'n',
    help: 'The generated class name',
  );
  parser.addFlag(
    'watch',
    abbr: 'w',
    defaultsTo: false,
    help: 'Monitor changes after execution of orders.',
  );
  parser.addFlag(
    'preview',
    abbr: 'p',
    help: 'Enable preview comments',
    defaultsTo: false,
    negatable: false,
  );
  parser.addFlag(
    'replace_strings',
    abbr: 'r',
    help: 'Enable replace strings',
    defaultsTo: null,
    negatable: false,
  );
  parser.addFlag(
    'debug',
    abbr: 'd',
    help: 'debug mode',
    defaultsTo: false,
    negatable: false,
  );
  parser.addFlag(
    'help',
    abbr: 'h',
    help: 'Print this usage information.',
    defaultsTo: false,
    negatable: false,
  );

  final ArgResults results = parser.parse(args);

  logger.isDebug = results['debug'] as bool;

  if (results.wasParsed('help')) {
    print(parser.usage);
    return;
  }

  final Config config = Config.fromArgResults(results);

  logger.debug('The config is: $config');

  final ResourceDartBuilder builder = ResourceDartBuilder(config);
  builder.generateResourceDartFile();
}
