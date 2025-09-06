// ignore_for_file: unawaited_futures

import 'package:secretary/secretary.dart';
import 'package:test/test.dart';

import 'helpers.dart';

void main() {
  group('Retry Policies', () {
    test('QueuePolicy.backOfQueue', () async {
      final secretary = Secretary<int, String>(
        validator: Validators.matchSingle('ok'),
        maxAttempts: 3,
        retryPolicy: QueuePolicy.backOfQueue,
      );
      int i = 0;
      final values = ['bad', 'bad', 'ok'];
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

    test('QueuePolicy.frontOfQueue', () async {
      final secretary = Secretary<int, String>(
        validator: Validators.matchSingle('ok'),
        maxAttempts: 3,
        retryPolicy: QueuePolicy.frontOfQueue,
      );
      int i = 0;
      final values = ['bad', 'bad', 'ok'];
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
      final secretary = Secretary<int, String>(
        validator: Validators.matchSingle('ok'),
        maxAttempts: 3,
        retryPolicy: QueuePolicy.backOfQueue,
      );
      int i = 0;
      int j = 0;
      final values = ['bad', 'bad', 'ok'];
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
        overrides: TaskOverrides(retryPolicy: QueuePolicy.frontOfQueue),
      );
      secretary.add(
        2,
        () => Future.delayed(Duration(milliseconds: 100), () => 'ok'),
      );
    });
  });
}
