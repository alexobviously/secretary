import 'package:secretary/secretary.dart';
import 'time_api.dart';

void main(List<String> args) async {
  final secretary = Secretary<String, TimeResult>();
  secretary.addRecurring(
    'Europe/Lisbon',
    task: () => getTime('Europe/Lisbon'),
    interval: Duration(seconds: 5),
    runImmediately: true,
    onComplete: (result) {
      switch (result) {
        case Ok(:final value):
          print('In Lisbon it is $value');
        case Err(:final error):
          print('Failed to get the time in Lisbon: $error');
      }
    },
  );
  secretary.addRecurring(
    'Asia/Saigon',
    task: () => getTime('Asia/Saigon'),
    interval: Duration(seconds: 3),
    maxRuns: 5,
    queuePolicy: .frontOfQueue,
  );
  final cutoffTime = DateTime.now().add(Duration(days: 4));
  secretary.addRecurring(
    'Brazil/East',
    taskBuilder: (params) =>
        () =>
            getTime('Brazil/East', timeTravel: Duration(days: params.runIndex)),
    interval: Duration(seconds: 5),
    validator: (params) => switch (params.runs.last.lastResult) {
      Ok(value: Ok(:final value)) => value.isBefore(cutoffTime),
      _ => false,
    },
  );
  secretary.stream.listen(print);
}
