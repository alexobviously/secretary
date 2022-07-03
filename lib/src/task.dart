import 'package:secretary/secretary.dart';

class SecretaryTask<K, T> {
  final K key;
  final FutureFunction<T> task;
  final Validator<T>? validator;
  final Callback<T>? onComplete;
  final RetryPolicy retryPolicy;
  final int maxAttempts;
  final List<Object> errors;

  int get attempts => errors.length;
  bool get canRetry => attempts < maxAttempts;

  const SecretaryTask({
    required this.key,
    required this.task,
    this.validator,
    this.onComplete,
    required this.retryPolicy,
    required this.maxAttempts,
    this.errors = const [],
  });

  SecretaryTask<K, T> copyWith({
    K? key,
    FutureFunction<T>? task,
    Validator<T>? validator,
    Callback<T>? onComplete,
    RetryPolicy? retryPolicy,
    int? maxAttempts,
    List<Object>? errors,
  }) =>
      SecretaryTask<K, T>(
        key: key ?? this.key,
        task: task ?? this.task,
        validator: validator ?? this.validator,
        onComplete: onComplete ?? this.onComplete,
        retryPolicy: retryPolicy ?? this.retryPolicy,
        maxAttempts: maxAttempts ?? this.maxAttempts,
        errors: errors ?? this.errors,
      );

  SecretaryTask<K, T> withError(Object error) =>
      copyWith(errors: [...errors, error]);
}
