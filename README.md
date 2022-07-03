# Secretary
#### A sophisticated task manager.

Secretary is a tool for keeping your futures in check. It's useful for managing queues of asynchronous tasks, where not all tasks should be executed simultaneously, or where some tasks might fail. 

### Features
- Reliable task queue
- Result validation
- Retry handling: limits, policies, conditions
- Type constraints for keys and results
- Event stream, and convenience methods for splitting it into result and error streams

### Upcoming features
- Concurrency

### Simple use case
Imagine a situation where you want to manage the uploading of a number of files to some server, and you want to queue them so it doesn't all happen at once and kill whatever fragile networking protocol is the weakest link. You don't necessarily care about collecting any results from this process, but you do want to check if the HTTP status code was 200 (successful), and retry some number of times if it wasn't.
You could do something like this:

```dart
Future<int> uploadFile(String path) async {
    // ... upload logic
    // maybe it returns 4xx or 5xx sometimes
    return 200;
}


final secretary = Secretary<String, int>(
    validator: (code) => code == 200 ? null : code, // returning null means no error, otherwise pass the code
    maxAttempts: 5, // retry up to 5 times
);

final paths = ['0001.mov', '0002.mov', '0003.mov']; // and so on and so on
for (String p in paths) {
    secretary.add(
        p,
        () => uploadFile(p),
    );
}
```

### What about errors?
Let's say you have the above use case, but you want to make a record of files that fail to upload?
Well you can simply add this line:

```dart
secretary.failureStream.listen((event) => recordFailure(event.key, event.error));
```

Note that there is also `secretary.errorStream`, but this also includes errors which resulted in a retry, alongside ones that resulted in failure. You can also sort these yourself if you want to log them by checking `event.isFailure`.

### Retry conditions
Following on from the example above, what if you want to retry in general, but not for every error? For example, perhaps you get error [415 Unsupported Media Type](https://developer.mozilla.org/en-US/docs/Web/HTTP/Status/415) when uploading a file. This is an error which won't change however many times you retry it, so there's no point.
Simply add a `retryIf` condition:

```dart
final secretary = Secretary<String, int>(
    validator: (code) => code == 200 ? null : code,
    maxAttempts: 5,
    retryIf: (error) => error != 415,
);
```