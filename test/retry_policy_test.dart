import 'package:secretary/secretary.dart';
import 'package:test/test.dart';

import 'helpers.dart';

void main() {
  group('Retry Policies', () {
    test('RetryPolicy.backOfQueue', () async {
      Secretary<int, String> secretary = Secretary(
        validator: Validators.matchSingle('ok'),
        maxAttempts: 3,
        retryPolicy: RetryPolicy.backOfQueue,
      );
      int i = 0;
      List<String> values = ['bad', 'bad', 'ok'];
      expectLater(
        secretary.stream,
        emitsInOrder([0, 1, 0, 0].map((e) => hasKey(e))),
      );
      secretary.add(
        0,
        () => Future.delayed(Duration(milliseconds: 100), () => values[i++]),
      );
      secretary.add(
        1,
        () => Future.delayed(Duration(milliseconds: 100), () => 'ok'),
      );
    });

    test('RetryPolicy.frontOfQueue', () async {
      Secretary<int, String> secretary = Secretary(
        validator: Validators.matchSingle('ok'),
        maxAttempts: 3,
        retryPolicy: RetryPolicy.frontOfQueue,
      );
      int i = 0;
      List<String> values = ['bad', 'bad', 'ok'];
      expectLater(
        secretary.stream,
        emitsInOrder([0, 0, 0, 1].map((e) => hasKey(e))),
      );
      secretary.add(
        0,
        () => Future.delayed(Duration(milliseconds: 100), () => values[i++]),
      );
      secretary.add(
        1,
        () => Future.delayed(Duration(milliseconds: 100), () => 'ok'),
      );
    });

    test('Mixed/overridden policies', () async {
      Secretary<int, String> secretary = Secretary(
        validator: Validators.matchSingle('ok'),
        maxAttempts: 3,
        retryPolicy: RetryPolicy.backOfQueue,
      );
      int i = 0;
      int j = 0;
      List<String> values = ['bad', 'bad', 'ok'];
      expectLater(
        secretary.stream,
        emitsInOrder([0, 1, 1, 1, 2, 0, 0].map((e) => hasKey(e))),
      );
      secretary.add(
        0,
        () => Future.delayed(Duration(milliseconds: 100), () => values[i++]),
      );
      secretary.add(
        1,
        () => Future.delayed(Duration(milliseconds: 100), () => values[j++]),
        retryPolicy: RetryPolicy.frontOfQueue,
      );
      secretary.add(
        2,
        () => Future.delayed(Duration(milliseconds: 100), () => 'ok'),
      );
    });
  });
}
