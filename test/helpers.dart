import 'package:test/test.dart';
import 'package:secretary/secretary.dart';

final retryPredicate = predicate<SecretaryEvent>((e) => e.isRetry);
final failurePredicate = predicate<SecretaryEvent>((e) => e.isFailure);
final successPredicate = predicate<SecretaryEvent>((e) => e.isSuccess);

Matcher hasKey<K, T>(K key) =>
    predicate<SecretaryEvent<K, T>>((e) => e.key == key);
