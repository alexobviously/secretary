import 'dart:convert';
import 'dart:io';

import 'package:colorize/colorize.dart';
import 'package:secretary/secretary.dart';

import 'agify.dart';

void main(List<String> args) async {
  final secretary = Secretary<String, AgePredictionResult>(
    maxAttempts: 20,
    validator: (res) => res.ok ? null : res.error!,
    retryIf: (error) => error != 'invalid_name',
  );
  secretary.resultStream.listen(printResult);
  secretary.errorStream.listen(printError);
  print(
    Colorize(
            'Secretary is ready\nEnter names to get predictions of their ages:')
        .magenta(),
  );

  void addName(String name) => secretary.add(name, () => getAge(name));
  void addNameMulti(String str) => str.split(', ').forEach(addName);

  readLine().listen(addNameMulti);
}

void printResult(AgePredictionResult result) {
  final object = result.object!;
  print(Colorize('${object.name} is probably about ${object.age} years old.')
      .green());
}

void printError(ErrorEvent<String, AgePredictionResult> event) {
  String message =
      '${event.isFailure ? 'Failure' : 'Error'}: ${event.error} for key ${event.key} [${event.attempts}/${event.maxAttempts}]';
  final c = Colorize(message);
  if (event.isFailure) {
    print(c.red());
  } else {
    print(c.yellow());
  }
}

Stream<String> readLine() =>
    stdin.transform(utf8.decoder).transform(const LineSplitter());
