import 'package:secretary/secretary.dart';
import 'package:test/test.dart';

import 'helpers.dart';

void main() {
  group('Stop Policies', () {
    test('StopPolicy.stopImmediately', () async {
      Secretary<int, int> secretary = Secretary(
        stopPolicy: StopPolicy.stopImmediately,
      );
      List<int> results = [];
      secretary.resultStream.listen(results.add);
      secretary.add(0, () => delayedValue(0, Duration(milliseconds: 500)));
      secretary.add(1, () => delayedValue(1, Duration(milliseconds: 500)));
      secretary.add(2, () => delayedValue(2, Duration(milliseconds: 500)));
      await Future.delayed(Duration(milliseconds: 600));
      await secretary.stop();
      expect(results, [0]);
    });

    test('StopPolicy.finishActive', () async {
      Secretary<int, int> secretary = Secretary(
        stopPolicy: StopPolicy.finishActive,
      );
      List<int> results = [];
      secretary.resultStream.listen(results.add);
      secretary.add(0, () => delayedValue(0, Duration(milliseconds: 500)));
      secretary.add(1, () => delayedValue(1, Duration(milliseconds: 500)));
      secretary.add(2, () => delayedValue(2, Duration(milliseconds: 500)));
      await Future.delayed(Duration(milliseconds: 600));
      await secretary.stop();
      expect(results, [0, 1]);
    });

    test('StopPolicy.finishQueue', () async {
      Secretary<int, int> secretary = Secretary(
        stopPolicy: StopPolicy.finishQueue,
      );
      List<int> results = [];
      secretary.resultStream.listen(results.add);
      secretary.add(0, () => delayedValue(0, Duration(milliseconds: 500)));
      secretary.add(1, () => delayedValue(1, Duration(milliseconds: 500)));
      secretary.add(2, () => delayedValue(2, Duration(milliseconds: 500)));
      await Future.delayed(Duration(milliseconds: 600));
      await secretary.stop();
      expect(results, [0, 1, 2]);
    });

    test('StopPolicy.finishRecurring', () async {
      Secretary<int, int> secretary = Secretary(
        stopPolicy: StopPolicy.finishRecurring,
      );
      List<int> results = [];
      secretary.resultStream.listen(results.add);
      secretary.addRecurring(
        0,
        task: () => delayedValue(0, Duration(milliseconds: 500)),
        maxRuns: 5,
      );
      await Future.delayed(Duration(milliseconds: 600));
      await secretary.stop();
      expect(results, [0, 0, 0, 0, 0]);
    });

    test('StopPolicy.finishQueue, with recurring task', () async {
      Secretary<int, int> secretary = Secretary(
        stopPolicy: StopPolicy.finishQueue,
      );
      List<int> results = [];
      secretary.resultStream.listen(results.add);
      secretary.addRecurring(
        0,
        task: () => delayedValue(0, Duration(milliseconds: 500)),
        maxRuns: 5,
      );
      await Future.delayed(Duration(milliseconds: 600));
      await secretary.stop();
      expect(results, [0, 0]);
    });
  });
}
