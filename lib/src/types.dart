typedef Task<T> = Future<T> Function();
typedef Validator<T> = Object? Function(T);
typedef Callback<T> = T Function(T);
typedef RetryTest = bool Function(Object?);

enum SecretaryState {
  idle,
  active,
  stopping,
  stopped,
  disposed,
}

enum RetryPolicy {
  backOfQueue,
  frontOfQueue,
}

enum StopPolicy {
  stopImmediately,
  finishActive,
  finishQueue,
}

class RetryIf {
  static bool alwaysRetry(Object? error) => true;
  static bool neverRetry(Object? error) => false;
}
