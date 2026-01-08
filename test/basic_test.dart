// ignore_for_file: unawaited_futures

import 'dart:async';

import 'package:secretary/secretary.dart';
import 'package:test/test.dart';

import 'helpers.dart';

void main() {
  group('Basic Tests', () {
    test('Basic results in order', () async {
      final secretary = Secretary<int, String>();
      int i = 0;
      final values = ['foo', 'baz', 'bar'];
      expectLater(secretary.resultStream, emitsInOrder(values));
      for (String v in values) {
        secretary.add(
          i++,
          () => Future.delayed(Duration(milliseconds: 100), () => v),
        );
      }
    });

    test(
      'Failure after retries',
      () async {
        final secretary = Secretary<int, String>(
          maxAttempts: 3,
          validator: Validators.matchSingle('ok'),
        );
        expectLater(
          secretary.errorStream,
          emitsInOrder([
            retryPredicate,
            retryPredicate,
            failurePredicate,
          ]),
        );
        secretary.add(
          0,
          () => .delayed(Duration(milliseconds: 100), () => 'bad'),
        );
      },
    );

    test('Success after retries', () async {
      final results = ['bad', 'bad', 'ok'];
      final secretary = Secretary<int, String>(
        maxAttempts: 3,
        validator: Validators.matchSingle('ok'),
      );
      expectLater(
        secretary.stream,
        emitsInOrder([
          retryPredicate,
          retryPredicate,
          successPredicate,
        ]),
      );
      int i = 0;
      secretary.add(
        0,
        () => .delayed(Duration(milliseconds: 100), () => results[i++]),
      );
    });

    test('Success with retryIf', () async {
      final results = ['retry', 'retry', 'ok'];
      final secretary = Secretary<int, String>(
        maxAttempts: 3,
        validator: Validators.matchSingle('ok'),
        retryIf: RetryIf.notSingle('fail'),
      );
      expectLater(
        secretary.stream,
        emitsInOrder([
          retryPredicate,
          retryPredicate,
          successPredicate,
        ]),
      );
      int i = 0;
      secretary.add(
        0,
        () => .delayed(Duration(milliseconds: 100), () => results[i++]),
      );
    });

    test('Failure with retryIf', () async {
      final results = ['retry', 'fail', 'ok'];
      final secretary = Secretary<int, String>(
        maxAttempts: 3,
        validator: (val) => val == 'ok' ? null : val,
        retryIf: RetryIf.notSingle('fail'),
      );
      expectLater(
        secretary.stream,
        emitsInOrder([
          retryPredicate,
          failurePredicate,
        ]),
      );
      int i = 0;
      secretary.add(
        0,
        () => .delayed(Duration(milliseconds: 100), () => results[i++]),
      );
    });

    test('with taskBuilder and addKey', () async {
      Future<String> hello(String key) async {
        await Future.delayed(Duration(milliseconds: 100));
        return 'hello $key';
      }

      final secretary = Secretary<String, String>(
        taskBuilder: (key) => hello(key),
      );
      expectLater(
        secretary.resultStream,
        emitsInOrder(['hello alex', 'hello callum', 'hello steve']),
      );
      secretary.addKey('alex');
      secretary.addKey('callum');
      secretary.addKey('steve');
    });
  });

  test('addKey throws if no taskBuilder', () {
    final secretary = Secretary<int, String>();
    expect(() => secretary.addKey(0), throwsArgumentError);
  });
}
