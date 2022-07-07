import 'package:secretary/secretary.dart';
import 'time_api.dart';

void main(List<String> args) async {
  final secretary = Secretary<String, TimeResult>();
  secretary.addRecurring(
    'Europe/Lisbon',
    task: () => getTime('Europe/Lisbon'),
    interval: Duration(seconds: 5),
    runImmediately: true,
  );
  secretary.addRecurring(
    'Asia/Saigon',
    task: () => getTime('Asia/Saigon'),
    interval: Duration(seconds: 3),
    maxRuns: 5,
    queuePolicy: QueuePolicy.frontOfQueue,
  );
  DateTime cutoffTime = DateTime.now().add(Duration(days: 4));
  secretary.addRecurring(
    'Brazil/East',
    taskBuilder: (params) => () => getTime(
          'Brazil/East',
          timeTravel: Duration(days: params.runIndex),
        ),
    interval: Duration(seconds: 5),
    validator: (params) =>
        params.runs.last.lastResult?.object?.object?.isBefore(cutoffTime) ??
        false,
  );
  secretary.stream.listen(print);
}
