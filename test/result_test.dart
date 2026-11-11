import 'dart:async';

import 'package:secretary/secretary.dart';
import 'package:test/test.dart';

void main() {
  group('Result integration', () {
    test('resultOk validates both Result variants', () {
      const ok = Result<int, String>.ok(42);
      const error = Result<int, String>.error('failed');

      expect(Validators.resultOk(ok), isNull);
      expect(Validators.resultOk(error), 'failed');
    });

    test('TaskState derives status and errors from Result variants', () {
      const state = TaskState<String, int>(
        key: 'task',
        maxAttempts: 2,
        results: [
          Result<int, Object>.error('first'),
          Result<int, Object>.error('second'),
        ],
      );

      expect(state.errors, ['first', 'second']);
      expect(state.succeeded, isFalse);
      expect(state.failed, isTrue);
      expect(state.finished, isTrue);
      expect(state.lastResult, isA<Err<int, Object>>());
    });

    test('SecretaryTask recognizes a final Ok after an Err', () {
      final task = SecretaryTask<String, int>(
        key: 'task',
        task: () async => 42,
        retryPolicy: QueuePolicy.backOfQueue,
        maxAttempts: 2,
        results: const [
          Result<int, Object>.error('first'),
          Result<int, Object>.ok(42),
        ],
        completer: Completer(),
        finalCompleter: Completer(),
      );

      expect(task.errors, ['first']);
      expect(task.succeeded, isTrue);
      expect(task.failed, isFalse);
      expect(task.finished, isTrue);
      expect(task.lastResult, isA<Ok<int, Object>>());
    });
  });
}
