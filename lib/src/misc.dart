import 'secretary.dart';

class RetryIf {
  static bool alwaysRetry(Object? error) => true;
  static bool neverRetry(Object? error) => false;
}
