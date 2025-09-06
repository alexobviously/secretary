import 'package:secretary/secretary.dart';
import 'package:test/test.dart';

import 'helpers.dart';

void main() {
  group('Basic Tests', () {
    test('Single limited recurring test', () {
      final secretary = Secretary<int, String>();
      expectLater(
        secretary.resultStream,
        emitsInOrder(
          List.generate(5, (_) => 'hello'),
        ),
      );
      secretary.addRecurring(
        0,
        task: () => Future.delayed(Duration(milliseconds: 100), () => 'hello'),
        maxRuns: 5,
      );
    });

    test('Recurring with taskBuilder', () {
      final secretary = Secretary<int, String>();
      final values = ['foo', 'baz', 'bar'];
      expectLater(secretary.resultStream, emitsInOrder(values));
      secretary.addRecurring(
        0,
        maxRuns: values.length,
        taskBuilder: TaskBuilders.fromRunIndex(
          (i) => Future.delayed(Duration(milliseconds: 100), () => values[i]),
        ),
      );
    });

    test('Recurring with validator', () async {
      final secretary = Secretary<int, String>(
        validator: Validators.matchSingle('ok'),
        recurringValidator: RecurringValidators.lastRunSucceeded,
      );
      final values = ['ok', 'ok', 'fail', 'ok'];
      final events = <SecretaryEvent>[];
      secretary.stream.listen(events.add);
      secretary.addRecurring(
        0,
        maxRuns: values.length,
        taskBuilder: TaskBuilders.fromRunIndex(
          (i) => Future.delayed(Duration(milliseconds: 100), () => values[i]),
        ),
      );
      await Future.delayed(Duration(seconds: 1));
      expect(events, [
        successPredicate,
        successPredicate,
        failurePredicate,
        recurringFinishedPredicate,
      ]);
    });
  });
}
