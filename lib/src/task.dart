import 'package:secretary/secretary.dart';

class SecretaryTask<K, T> {
  final K key;
  final Task<T> task;
  final Validator<T>? validator;
  final Callback<T>? onComplete;
  final Callback<ErrorEvent<K, T>>? onError;
  final RetryTest retryIf;
  final RetryPolicy retryPolicy;
  final Duration retryDelay;
  final int maxAttempts;
  final List<Result<T, Object>> results;

  List<Object> get errors =>
      results.where((e) => !e.ok).map((e) => e.error!).toList();
  int get attempts => results.length;
  bool get canRetry => attempts < maxAttempts;
  bool get succeeded => results.isNotEmpty && results.last.ok;
  bool get failed => !canRetry && !succeeded;
  bool get finished => !canRetry || succeeded;

  const SecretaryTask({
    required this.key,
    required this.task,
    this.validator,
    this.onComplete,
    this.onError,
    this.retryIf = RetryIf.alwaysRetry,
    required this.retryPolicy,
    this.retryDelay = Duration.zero,
    required this.maxAttempts,
    this.results = const [],
  });

  SecretaryTask<K, T> copyWith({
    K? key,
    Task<T>? task,
    Validator<T>? validator,
    Callback<T>? onComplete,
    Callback<ErrorEvent<K, T>>? onError,
    RetryTest? retryIf,
    RetryPolicy? retryPolicy,
    Duration? retryDelay,
    int? maxAttempts,
    List<Result<T, Object>>? results,
  }) =>
      SecretaryTask<K, T>(
        key: key ?? this.key,
        task: task ?? this.task,
        validator: validator ?? this.validator,
        onComplete: onComplete ?? this.onComplete,
        onError: onError ?? this.onError,
        retryIf: retryIf ?? this.retryIf,
        retryPolicy: retryPolicy ?? this.retryPolicy,
        retryDelay: retryDelay ?? this.retryDelay,
        maxAttempts: maxAttempts ?? this.maxAttempts,
        results: results ?? this.results,
      );

  SecretaryTask<K, T> withResult(Result<T, Object> result) =>
      copyWith(results: [...results, result]);

  SecretaryTask<K, T> withError(Object error) =>
      withResult(Result.error(error));

  SecretaryTask<K, T> withSuccess(T result) => withResult(Result.ok(result));
}
