import 'dart:convert';
import 'dart:io';

import 'package:colorize/colorize.dart';
import 'package:secretary/secretary.dart';

import 'agify.dart';

void main(List<String> args) async {
  final secretary = Secretary<String, AgePredictionResult>(
    maxAttempts: 20,
    validator: Validators.resultOk,
    retryIf: RetryIf.notSingle('invalid_name'),
    stopPolicy: StopPolicy.finishQueue,
    autostart: true,
  );
  secretary.resultStream.listen(printResult);
  secretary.errorStream.listen(printError);
  secretary.statusStream.listen(printState);
  printState(secretary.status);
  print(
    Colorize(
            'Enter names to get predictions of their ages\nOther commands: start, stop')
        .magenta(),
  );

  void addName(String name) => secretary.add(name, () => getAge(name));
  void addNameMulti(String str) => str.split(', ').forEach(addName);

  void handleInput(String input) {
    if (input == 'stop') {
      secretary.stop();
    } else if (input == 'start') {
      secretary.start();
    } else {
      addNameMulti(input);
    }
  }

  readLine().listen(handleInput);
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

void printState(SecretaryStatus state) =>
    print(Colorize('Secretary state: ${state.name}').italic().cyan());

Stream<String> readLine() =>
    stdin.transform(utf8.decoder).transform(const LineSplitter());
