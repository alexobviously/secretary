import 'dart:async';

import 'package:secretary/secretary.dart';

/// An internal data structure used to keep track of links.
class LinkData<K, X> {
  final Secretary<K, X> target;
  final StreamSubscription outgoingSub;
  final StreamSubscription disposeSub;

  const LinkData({
    required this.target,
    required this.outgoingSub,
    required this.disposeSub,
  });

  Future<void> dispose() async =>
      await Future.wait([outgoingSub.cancel(), disposeSub.cancel()]);
}
