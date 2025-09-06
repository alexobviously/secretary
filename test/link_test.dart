// ignore_for_file: unawaited_futures

import 'package:secretary/secretary.dart';
import 'package:test/test.dart';

void main() {
  group('Linking', () {
    test('Simple', () async {
      final secA = Secretary<int, int>();
      final secB = Secretary<int, int>();
      final values = [1, 3, 5];
      final expected = [4, 16, 36];
      expectLater(secB.resultStream, emitsInOrder(expected));
      secA.link(secB, (e) => Future.value(e * e));
      for (int x in values) {
        secA.add(x, () => Future.value(x + 1));
      }
      // todo: test unlink - it does work but hard to test
    });
  });
}
