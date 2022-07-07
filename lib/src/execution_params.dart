import 'package:secretary/secretary.dart';

class ExecutionParams<K, T> {
  final int maxRuns;
  final List<SecretaryTask<K, T>> runs;

  int get numRuns => runs.length;
  int get runIndex => numRuns;
  bool get canRun => maxRuns == 0 || runs.length < maxRuns;

  const ExecutionParams({required this.maxRuns, required this.runs});
}
