class SecretaryError {
  const SecretaryError();
}

class TaskNotFoundError<K> extends SecretaryError {
  final K key;
  const TaskNotFoundError(this.key);

  @override
  operator ==(Object other) => other is TaskNotFoundError && other.key == key;

  @override
  int get hashCode => key.hashCode;
}

class InvalidValueError<T> extends SecretaryError {
  final T value;
  const InvalidValueError(this.value);

  @override
  operator ==(Object other) =>
      other is InvalidValueError && other.value == value;

  @override
  int get hashCode => value.hashCode;
}
