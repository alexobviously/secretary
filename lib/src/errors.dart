sealed class const SecretaryError();

class const TaskNotFoundError<K>(final K key) extends SecretaryError {
  @override
  bool operator ==(Object other) =>
      other is TaskNotFoundError && other.key == key;

  @override
  int get hashCode => key.hashCode;
}

class const InvalidValueError<T>(final T value) extends SecretaryError {
  @override
  bool operator ==(Object other) =>
      other is InvalidValueError && other.value == value;

  @override
  int get hashCode => value.hashCode;
}
