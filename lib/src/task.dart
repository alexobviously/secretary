import 'dart:async';

import 'package:secretary/secretary.dart';

class const SecretaryTask<K, T>({
  required final K key,
  required final Task<T> task,
  final Validator<T>? validator,
  final Callback<T>? onComplete,
  final Callback<ErrorEvent<K, T>>? onError,
  final RetryTest retryIf = RetryIf.alwaysRetry,
  required final QueuePolicy retryPolicy,
  final Duration retryDelay = .zero,
  required final int maxAttempts,
  final List<Result<T, Object>> results = const [],
  required final Completer<Result<T, Object>> completer,
  required final Completer<Result<T, Object>> finalCompleter,
}) {
  List<Object> get errors => results.errs.values.toList();
  int get attempts => results.length;
  bool get canRetry => attempts < maxAttempts;
  bool get succeeded => results.isNotEmpty && results.last is Ok;
  bool get failed => !canRetry && !succeeded;
  bool get finished => !canRetry || succeeded;
  Result<T, Object>? get lastResult => results.isNotEmpty ? results.last : null;

  SecretaryTask<K, T> copyWith({
    K? key,
    Task<T>? task,
    Validator<T>? validator,
    Callback<T>? onComplete,
    Callback<ErrorEvent<K, T>>? onError,
    RetryTest? retryIf,
    QueuePolicy? retryPolicy,
    Duration? retryDelay,
    int? maxAttempts,
    List<Result<T, Object>>? results,
    Completer<Result<T, Object>>? completer,
    Completer<Result<T, Object>>? finalCompleter,
  }) => SecretaryTask<K, T>(
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
    completer: completer ?? this.completer,
    finalCompleter: finalCompleter ?? this.finalCompleter,
  );

  SecretaryTask<K, T> withResult(Result<T, Object> result) =>
      copyWith(results: [...results, result]);

  SecretaryTask<K, T> withError(Object error) =>
      withResult(Result.error(error));

  SecretaryTask<K, T> withSuccess(T result) => withResult(Result.ok(result));
}
