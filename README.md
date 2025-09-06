# Secretary
#### A sophisticated task manager.

Secretary is a tool for keeping your futures in check. It's useful for managing queues of asynchronous tasks, where not all tasks should be executed simultaneously, or where some tasks might fail. 

## Features
- Reliable task queue.
- Result validation.
- Retry handling: limits, policies, conditions.
- Type constraints for keys and results.
- Event stream, and convenience methods for splitting it into result and error streams.
- Concurrent tasks.
- Recurring tasks.
- Easy linking of two or more Secretaries together, so tasks finishing on one can trigger tasks on another.

## Upcoming Features
- Scheduled tasks (i.e. set a datetime for execution).
- Better state tracking (stream updates with a more descriptive state of the Secretary, e.g. number of tasks running).
- Event stream improvements, especially for incorporating recurring task events.

## Simple use case
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

### Alternative, simplified approach
In this case, all of the tasks we are adding to this secretary behave the same, with the only parameter being the key. There is a simplified API for use cases where this is true:

```dart
final secretary = Secretary<String, int>(
    taskBuilder: (key) => uploadFile(p),
);

final paths = ['0001.mov', '0002.mov', '0003.mov'];
for (String p in paths) {
    secretary.addKey(p);
}
```


## What about errors?
Let's say you have the above use case, but you want to make a record of files that fail to upload?
Well you can simply add this line:

```dart
secretary.failureStream.listen((event) => recordFailure(event.key, event.error));
```

Note that there is also `secretary.errorStream`, but this also includes errors which resulted in a retry, alongside ones that resulted in failure. You can also sort these yourself if you want to log them by checking `event.isFailure`.

Also note that all `SecretaryEvent` objects, including successful ones, include a list of all errors they've encountered over all their attempts. In most cases, these will all be roughly the same as the final error, but you can access them with `event.errors`.

## Retry conditions
Following on from the example above, what if you want to retry in general, but not for every error? For example, perhaps you get error [415 Unsupported Media Type](https://developer.mozilla.org/en-US/docs/Web/HTTP/Status/415) when uploading a file. This is an error which won't change however many times you retry it, so there's no point.
Simply add a `retryIf` condition:

```dart
final secretary = Secretary<String, int>(
    validator: (code) => code == 200 ? null : code,
    maxAttempts: 5,
    retryIf: (error) => error != 415,
);
```

In this case, tasks that result in a 415 error will be declared failures, and you'll be able to see their events in the stream and log them as above.

## Waiting for results
If you want to get the value of a specific task asynchronously, you can use `Secretary.waitForResult(key)`, for example:

```dart
Future<Result<Something, Error>> getValue(int thingId) async {
    if(results.containsKey(thingId)) {
        // Checking some local map of results first.
        return results[thingId];
    }
    // Tell the secretary to get the thing from some service.
    // Note that if the key is already in the task list, it won't be added again.
    secretary.add(thingId, () => thingService.getThing(thingId));
    final result = await secretary.waitForResult(thingId);
    // You could add [result] to [results] here, but it's better practice to use
    // secretary.listen when you create it instead.
    return result;
}
```

## Linking
Linking solves the problem of related dependent tasks that should happen in series across multiple Secretaries. For example, one task might be to upload a file (Secretary A), and another might be to update a database record with the URL of the uploaded file (Secretary B). The second task obviously depends on the first.

This sort of behaviour can be accomplished with the `link` function:
```dart
final secA = Secretary<String, Foo>();
final secB = Secretary<String, Bar>();
secA.link(secB, (Foo e) => barFromFoo(e));
// This will add a task to secB, to create a Bar object from a Foo object,
// where the Foo object is the successful result of a task in secA.
```

See [this example](https://github.com/alexobviously/secretary/blob/main/example/links.dart) for more details.