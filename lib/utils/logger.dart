// ignore_for_file: avoid_print

List<Log> logs = [];

void log(var message, [LogLevel logLevel = LogLevel.info]) {
  print(message.toString());
  logs.add(Log(message.toString(), logLevel));
}

class Log {
  DateTime time = DateTime.now().toUtc();
  String message = "";
  LogLevel level = LogLevel.info;
  Log(this.message, this.level);
}

enum LogLevel {
  info,
  warn,
  error
}