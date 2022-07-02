typedef FutureFunction<T> = Future<T> Function();
typedef ValidatorFunction<T> = bool Function(T);
typedef Callback<T> = T Function(T);

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
