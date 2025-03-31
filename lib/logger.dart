var logger = Logger._(false);

final class Logger {
  Logger._(this.isDebug);

  bool isDebug = false;

  void debug(Object msg) {
    if (isDebug) {
      print(msg);
    }
  }
}
