import 'package:secretary/secretary.dart';

/// Parameters passed to `RecurringValidator` and `TaskBuilder` functions.
/// These represent the state of a `RecurringTask` at the time of execution.
class const ExecutionParams<K, T>({
  required final int maxRuns,
  required final List<SecretaryTask<K, T>> runs,
}) {
  int get numRuns => runs.length;
  int get runIndex => numRuns;
  bool get canRun => maxRuns == 0 || runs.length < maxRuns;
}
