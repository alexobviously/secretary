import 'package:secretary/secretary.dart';

class SecretaryTask<K, T> {
  final K key;
  final FutureFunction<T> task;
  final ValidatorFunction<T>? validator;
  final Callback<T>? onComplete;
  final RetryPolicy retryPolicy;
  final int maxRetries;

  const SecretaryTask({
    required this.key,
    required this.task,
    this.validator,
    this.onComplete,
    required this.retryPolicy,
    required this.maxRetries,
  });

  SecretaryTask copyWith({
    K? key,
    FutureFunction<T>? task,
    ValidatorFunction<T>? validator,
    Callback<T>? onComplete,
    RetryPolicy? retryPolicy,
    int? maxRetries,
  }) =>
      SecretaryTask<K, T>(
        key: key ?? this.key,
        task: task ?? this.task,
        validator: validator ?? this.validator,
        onComplete: onComplete ?? this.onComplete,
        retryPolicy: retryPolicy ?? this.retryPolicy,
        maxRetries: maxRetries ?? this.maxRetries,
      );
}
