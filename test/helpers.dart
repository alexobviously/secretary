import 'package:test/test.dart';
import 'package:secretary/secretary.dart';

final retryPredicate = predicate<SecretaryEvent>((e) => e.isRetry);
final failurePredicate = predicate<SecretaryEvent>((e) => e.isFailure);
final successPredicate = predicate<SecretaryEvent>((e) => e.isSuccess);
final recurringFinishedPredicate = predicate<SecretaryEvent>(
  (e) => e is RecurringTaskFinishedEvent,
);

Matcher hasKey<K, T>(K key) =>
    predicate<SecretaryEvent<K, T>>((e) => e.key == key);

Future<T> delayedValue<T>(
  T value, [
  Duration delay = const Duration(milliseconds: 500),
]) => .delayed(delay, () => value);
