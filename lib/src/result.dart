import 'package:secretary/secretary.dart';

class Result<T, E> {
  final T? object;
  final E? error;

  bool get ok => error == null;
  bool get hasObject => object != null;

  const Result({this.object, this.error});
  factory Result.ok(T object) => Result(object: object);
  factory Result.error(E error) => Result(error: error);

  @override
  String toString() {
    String str = ok ? 'ok, $object' : 'error, $error';
    return 'Result($str)';
  }
}
