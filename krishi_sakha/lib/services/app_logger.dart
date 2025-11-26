import 'package:logger/logger.dart';

class AppLogger {
  // Private constructor to prevent instantiation
  AppLogger._();

  // Static logger instance
  static final Logger _logger = Logger(
    printer: PrettyPrinter(
      methodCount: 2, // Number of method calls to be displayed
      errorMethodCount: 8, // Number of method calls if stacktrace is provided
      lineLength: 120, // Width of the output
      colors: true, // Colorful log messages
      printEmojis: true, // Print an emoji for each log message
      printTime: false, // Should each log print contain a timestamp
    ),
    level: Level.debug, // Set default log level
  );

  /// Log a debug message
  /// Use this for detailed information useful during development
  static void debug(String message, [dynamic error, StackTrace? stackTrace]) {
    _logger.d(message, error: error, stackTrace: stackTrace);
  }

  /// Log an info message
  /// Use this for general information about application operation
  static void info(String message, [dynamic error, StackTrace? stackTrace]) {
    _logger.i(message, error: error, stackTrace: stackTrace);
  }

  /// Log a warning message
  /// Use this for potentially harmful situations that don't prevent operation
  static void warning(String message, [dynamic error, StackTrace? stackTrace]) {
    _logger.w(message, error: error, stackTrace: stackTrace);
  }

  /// Log an error message
  /// Use this for error conditions that might still allow the application to continue running
  static void error(String message, [dynamic error, StackTrace? stackTrace]) {
    _logger.e(message, error: error, stackTrace: stackTrace);
  }

  /// Log a fatal error message
  /// Use this for severe error conditions that will likely cause the application to terminate
  static void fatal(String message, [dynamic error, StackTrace? stackTrace]) {
    _logger.f(message, error: error, stackTrace: stackTrace);
  }

  /// Log a verbose message
  /// Use this for very detailed information, typically more than debug level
  static void verbose(String message, [dynamic error, StackTrace? stackTrace]) {
    _logger.v(message, error: error, stackTrace: stackTrace);
  }

  /// Log a WTF (What a Terrible Failure) message
  /// Use this for unexpected severe error conditions
  static void wtf(String message, [dynamic error, StackTrace? stackTrace]) {
    _logger.wtf(message, error: error, stackTrace: stackTrace);
  }

  /// Log network request information
  static void logNetworkRequest(String method, String url, [int? statusCode]) {
    final status = statusCode != null ? ' ($statusCode)' : '';
    info('🌐 $method $url$status');
  }

}