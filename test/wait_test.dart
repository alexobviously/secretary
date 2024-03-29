import 'package:secretary/secretary.dart';
import 'package:test/test.dart';

import 'helpers.dart';

void main() {
  group('Wait for result', () {
    test('Wait for result, basic', () async {
      Secretary<int, int> secretary = Secretary();
      secretary.add(0, () => delayedValue(0));
      final result = await secretary.waitForResult(0);
      expect(result.object, 0);
    });

    test('Wait for result, retries, waitForFinal: true', () async {
      Secretary<int, int> secretary = Secretary(
        validator: (e) => e > 0 ? null : e,
        maxAttempts: 3,
      );
      int i = 0;
      List<int> values = [-2, -4, 6];
      secretary.add(
        0,
        () => Future.delayed(Duration(milliseconds: 200), () => values[i++]),
      );
      final result = await secretary.waitForResult(0);
      expect(result.object, 6);
    });

    test('Wait for result, retries, waitForFinal: false', () async {
      Secretary<int, int> secretary = Secretary(
        validator: (e) => e > 0 ? null : InvalidValueError(e),
        maxAttempts: 3,
      );
      int i = 0;
      List<int> values = [-2, -4, 6];
      secretary.add(
        0,
        () => Future.delayed(Duration(milliseconds: 200), () => values[i++]),
      );
      final result = await secretary.waitForResult(0, waitForFinal: false);
      expect(result.error, InvalidValueError(-2));
    });

    test('Wait for empty', () async {
      Secretary<int, int> secretary = Secretary();
      for (int i in List.generate(3, (i) => i)) {
        secretary.add(
          i,
          () => Future.delayed(Duration(milliseconds: 200), () => i),
        );
      }
      expect(secretary.state.numTasks, 3);
      await secretary.waitForEmpty();
      expect(secretary.state.numTasks, 0);
    });
  });
}
