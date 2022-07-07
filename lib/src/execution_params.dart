import 'package:secretary/secretary.dart';

/// Parameters passed to `RecurringValidator` and `TaskBuilder` functions.
/// These represent the state of a `RecurringTask` at the time of execution.
class ExecutionParams<K, T> {
  final int maxRuns;
  final List<SecretaryTask<K, T>> runs;

  int get numRuns => runs.length;
  int get runIndex => numRuns;
  bool get canRun => maxRuns == 0 || runs.length < maxRuns;

  const ExecutionParams({required this.maxRuns, required this.runs});
}
