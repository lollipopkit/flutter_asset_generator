import 'package:dart_style/dart_style.dart';
import 'package:pub_semver/pub_semver.dart';

String formatFile(String source) {
  final DartFormatter df = DartFormatter(languageVersion: Version(3, 0, 0));
  return df.format(source);
}
