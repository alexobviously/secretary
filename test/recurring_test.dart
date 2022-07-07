import 'package:secretary/secretary.dart';
import 'package:test/test.dart';

import 'helpers.dart';

void main() {
  group('Basic Tests', () {
    test('Single limited recurring test', () {
      Secretary<int, String> secretary = Secretary();
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
      Secretary<int, String> secretary = Secretary();
      List<String> values = ['foo', 'baz', 'bar'];
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
      Secretary<int, String> secretary = Secretary(
        validator: Validators.matchSingle('ok'),
        recurringValidator: RecurringValidators.lastRunSucceeded,
      );
      List<String> values = ['ok', 'ok', 'fail', 'ok'];
      List<SecretaryEvent> events = [];
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
      ]);
    });
  });
}
