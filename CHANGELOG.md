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