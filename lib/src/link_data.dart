import 'dart:async';

import 'package:secretary/secretary.dart';

/// An internal data structure used to keep track of links.
class const LinkData<K, X>({
  required final Secretary<K, X> target,
  required final StreamSubscription outgoingSub,
  required final StreamSubscription disposeSub,
}) {
  Future<void> dispose() async =>
      await Future.wait([outgoingSub.cancel(), disposeSub.cancel()]);
}
