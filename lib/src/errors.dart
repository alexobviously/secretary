class SecretaryError {
  const SecretaryError();
}

class TaskNotFoundError<K> extends SecretaryError {
  final K key;
  const TaskNotFoundError(this.key);
}
