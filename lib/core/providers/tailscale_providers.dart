import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../api/tailscale_cli.dart';
import '../models/tailscale_status.dart';
import 'refresh.dart';

part 'tailscale_providers.g.dart';

@Riverpod(keepAlive: true)
TailscaleCli tailscaleCli(Ref ref) => const TailscaleCli();

@riverpod
Future<TailscaleStatus> tailscaleStatus(Ref ref) async {
  final cli = ref.watch(tailscaleCliProvider);
  autoRefresh(ref);
  return cli.status();
}
