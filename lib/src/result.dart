/// An object that can contain either a successful result (of type T), or
/// an  error (of type E).
/// Use the `Result.ok` and `Result.error` constructors to create these.
class Result<T, E> {
  final T? object;
  final E? error;

  bool get ok => error == null;
  bool get hasObject => object != null;

  const Result({this.object, this.error});

  /// A successful result.
  factory Result.ok(T object) => Result(object: object);

  /// A failed result.
  factory Result.error(E error) => Result(error: error);

  /// Transforms a Result<T, E> into a Result<X, E> through [transformer].
  /// If the Result this is called on has an error, it will be passed on, and
  /// if it is ok then the [transformer] will be applied.
  Result<X, E> transform<X>(Result<X, E> Function(T e) transformer) =>
      // ignore: null_check_on_nullable_type_parameter
      ok ? transformer(object!) : Result<X, E>.error(error!);

  @override
  String toString() {
    String str = ok ? 'ok, $object' : 'error, $error';
    return 'Result($str)';
  }
}
