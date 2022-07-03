import 'package:secretary/secretary.dart';
import 'package:test/test.dart';

void main() {
  final basicTests = [
    BasicTest(
      tasks: [
        () => Future.delayed(Duration(seconds: 1), () => 'foo'),
        () => Future.delayed(Duration(seconds: 1), () => 'baz'),
        () => Future.delayed(Duration(seconds: 1), () => 'bar'),
      ],
      expected: ['foo', 'baz', 'bar'],
    ),
  ];
  group('Queueing', () {
    for (final t in basicTests) {
      test(
        'Basic test ${t.expected}',
        () async {
          Secretary<int, String> secretary = Secretary();
          int i = 0;
          for (final task in t.tasks) {
            secretary.add(i++, task);
          }
          expect(secretary.resultStream, emitsInOrder(t.expected));
        },
      );
    }
  });
}

class BasicTest<T> {
  final List<FutureFunction<T>> tasks;
  final List<T> expected;

  Type get type => T;

  const BasicTest({
    required this.tasks,
    required this.expected,
  });
}
