## 1.0.0
- Upgraded SDK constraint to Dart 3.
- `Secretary.waitForEmpty()`: wait for the task list to be empty. Useful for cases where a fixed number of tasks is added at once, and you just want to wait for all of them to finish.

## 0.4.1
- `Secretary.link()`: connects a Secretary to another, so that whenever a task successfully completes in the first, one is added to the second.

## 0.4.0
- What used to be `SecretaryState` is now `SecretaryStatus`, `Secretary.state` is now `Secretary.status`, etc.
- Added `SecretaryState` (`Secretary.state` and `Secretary.stateStream`), which contains information about the queue and recurring tasks.

## 0.3.2
- Tests for `waitForResult()`.
- More `Validator` helper functions, and match validators now return `InvalidValueError`.

## 0.3.1
- `Secretary.waitForResult()`: use this to wait for a result for a specific event.

## 0.3.0
- Added concurrency: `Secretary.maxConcurrentTasks`.

## 0.2.2
- Added `StopPolicy.finishRecurring`.
- Stop policy tests.

## 0.2.1
- Added `onComplete` and `onError` callbacks to recurring tasks.

## 0.2.0
- Recurring tasks.
- `TaskOverrides` data class instead of tons of parameters in `Secretary.add()`.
- `RetryPolicy` is now `QueuePolicy`.

## 0.1.2
- More tests.
- More documentation.
- More Validator and RetryTest helpers.

## 0.1.1
- More documentation.
- `failureStream` and `retryStream` helpers.
- Fixed a bug with cleaning up failed tasks.

## 0.1.0
- Initial release.