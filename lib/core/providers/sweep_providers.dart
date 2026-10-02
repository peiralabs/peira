import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Bumped whenever the instrument gauges should re-run their sweep-in
/// animation — on boot after the splash clears, and on a manual reconnect
/// from the rail footer. Gauges key their sweep tween on this value.
class SweepEpoch extends Notifier<int> {
  @override
  int build() => 0;

  void bump() => state++;
}

final sweepEpochProvider = NotifierProvider<SweepEpoch, int>(SweepEpoch.new);
