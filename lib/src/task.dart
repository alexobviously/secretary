import 'package:secretary/secretary.dart';

class SecretaryTask<K, T> {
  final K key;
  final Task<T> task;
  final Validator<T>? validator;
  final Callback<T>? onComplete;
  final RetryTest retryIf;
  final RetryPolicy retryPolicy;
  final Duration retryDelay;
  final int maxAttempts;
  final List<Object> errors;

  int get attempts => errors.length;
  bool get canRetry => attempts < maxAttempts;

  const SecretaryTask({
    required this.key,
    required this.task,
    this.validator,
    this.onComplete,
    this.retryIf = RetryIf.alwaysRetry,
    required this.retryPolicy,
    this.retryDelay = Duration.zero,
    required this.maxAttempts,
    this.errors = const [],
  });

  SecretaryTask<K, T> copyWith({
    K? key,
    Task<T>? task,
    Validator<T>? validator,
    Callback<T>? onComplete,
    RetryTest? retryIf,
    RetryPolicy? retryPolicy,
    Duration? retryDelay,
    int? maxAttempts,
    List<Object>? errors,
  }) =>
      SecretaryTask<K, T>(
        key: key ?? this.key,
        task: task ?? this.task,
        validator: validator ?? this.validator,
        onComplete: onComplete ?? this.onComplete,
        retryIf: retryIf ?? this.retryIf,
        retryPolicy: retryPolicy ?? this.retryPolicy,
        retryDelay: retryDelay ?? this.retryDelay,
        maxAttempts: maxAttempts ?? this.maxAttempts,
        errors: errors ?? this.errors,
      );

  SecretaryTask<K, T> withError(Object error) =>
      copyWith(errors: [...errors, error]);
}
