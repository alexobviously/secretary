import 'package:secretary/secretary.dart';
import 'package:test/test.dart';

import 'helpers.dart';

void main() {
  group('Basic Tests', () {
    test(
      'Basic results in order',
      () async {
        Secretary<int, String> secretary = Secretary();
        int i = 0;
        List<String> values = ['foo', 'baz', 'bar'];
        expectLater(secretary.resultStream, emitsInOrder(values));
        for (String v in values) {
          secretary.add(
            i++,
            () => Future.delayed(Duration(milliseconds: 100), () => v),
          );
        }
      },
    );

    test(
      'Failure after retries',
      () async {
        Secretary<int, String> secretary = Secretary(
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
          () => Future.delayed(Duration(milliseconds: 100), () => 'bad'),
        );
      },
    );

    test(
      'Success after retries',
      () async {
        final results = ['bad', 'bad', 'ok'];
        Secretary<int, String> secretary = Secretary(
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
          () => Future.delayed(Duration(milliseconds: 100), () => results[i++]),
        );
      },
    );

    test(
      'Success with retryIf',
      () async {
        final results = ['retry', 'retry', 'ok'];
        Secretary<int, String> secretary = Secretary(
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
          () => Future.delayed(Duration(milliseconds: 100), () => results[i++]),
        );
      },
    );

    test(
      'Failure with retryIf',
      () async {
        final results = ['retry', 'fail', 'ok'];
        Secretary<int, String> secretary = Secretary(
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
          () => Future.delayed(Duration(milliseconds: 100), () => results[i++]),
        );
      },
    );

    test('with taskBuilder and addKey', () async {
      Future<String> hello(String key) async {
        await Future.delayed(Duration(milliseconds: 100));
        return 'hello $key';
      }

      Secretary<String, String> secretary = Secretary(
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
    Secretary<int, String> secretary = Secretary();
    expect(() => secretary.addKey(0), throwsArgumentError);
  });
}
