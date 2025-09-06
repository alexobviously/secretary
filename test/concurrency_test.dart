import 'package:secretary/secretary.dart';
import 'package:test/test.dart';

import 'helpers.dart';

void main() {
  group('Concurrency', () {
    _concurrencyTest(1, 2);
    _concurrencyTest(2, 4);
    _concurrencyTest(3, 6);
    _concurrencyTest(0, 10);
  });
}

void _concurrencyTest(int concurrency, int expected) async {
  test('Concurrency: $concurrency', () async {
    final secretary = Secretary<int, int>(
      maxConcurrentTasks: concurrency,
      checkInterval: Duration(milliseconds: 5),
    );
    final values = List.generate(10, (i) => i);
    final results = <int>[];
    secretary.resultStream.listen(results.add);
    for (int i in values) {
      secretary.add(i, () => delayedValue(i, Duration(milliseconds: 100)));
    }
    await Future.delayed(Duration(milliseconds: 250));
    expect(results.length, expected);
  });
}
