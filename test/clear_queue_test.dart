import 'package:test/test.dart';
import 'package:secretary/secretary.dart';

void main() {
  group('clearQueue', () {
    test('clears empty queue', () {
      final secretary = Secretary<String, int>();
      final removed = secretary.clearQueue();

      expect(removed, isEmpty);
      expect(secretary.queue, isEmpty);
      expect(secretary.tasks, isEmpty);
    });

    test('clears queue with multiple tasks', () async {
      final secretary = Secretary<String, int>();

      secretary.add('task1', () async => 1);
      secretary.add('task2', () async => 2);
      secretary.add('task3', () async => 3);

      expect(secretary.queue.length, equals(3));
      expect(secretary.tasks.length, equals(3));

      final removed = secretary.clearQueue();

      expect(removed, equals(['task1', 'task2', 'task3']));
      expect(secretary.queue, isEmpty);
      expect(secretary.tasks, isEmpty);
    });

    test('does not affect active tasks', () async {
      final secretary = Secretary<String, int>();

      secretary.add('slow_task', () async {
        await Future.delayed(Duration(milliseconds: 300));
        return 42;
      });

      secretary.add('task1', () async => 1);
      secretary.add('task2', () async => 2);
      secretary.start();

      await Future.delayed(Duration(milliseconds: 100));

      expect(secretary.active, contains('slow_task'));
      expect(secretary.queue.length, equals(2));

      final removed = secretary.clearQueue();

      expect(removed, equals(['task1', 'task2']));
      expect(secretary.queue, isEmpty);
      expect(secretary.active, contains('slow_task'));
      expect(secretary.tasks.containsKey('slow_task'), isTrue);
    });

    test('emits state change', () async {
      final secretary = Secretary<String, int>();

      secretary.add('task1', () async => 1);
      secretary.add('task2', () async => 2);

      final states = <SecretaryState<String, int>>[];
      final subscription = secretary.stateStream.listen(states.add);

      secretary.clearQueue();

      await Future.delayed(Duration(milliseconds: 10));

      expect(states.length, greaterThan(0));
      expect(states.last.queue, isEmpty);

      subscription.cancel();
    });

    test('returns empty list when queue is already empty', () {
      final secretary = Secretary<String, int>();

      final removed1 = secretary.clearQueue();
      expect(removed1, isEmpty);

      // Clear again to make sure it handles empty queue gracefully
      final removed2 = secretary.clearQueue();
      expect(removed2, isEmpty);
    });
  });
}
