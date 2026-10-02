import 'package:flutter_test/flutter_test.dart';
import 'package:peira/core/models/docker_container.dart';
import 'package:peira/core/models/docker_image.dart';
import 'package:peira/core/models/grafana_alert.dart';
import 'package:peira/core/models/prowlarr_indexer.dart';
import 'package:peira/core/models/prowlarr_release.dart';
import 'package:peira/core/models/proxmox_vm.dart';
import 'package:peira/core/models/qbittorrent_torrent.dart';
import 'package:peira/core/models/radarr_movie.dart';
import 'package:peira/core/models/servarr_queue_item.dart';
import 'package:peira/core/models/sonarr_series.dart';
import 'package:peira/core/models/vm_status.dart';

void main() {
  group('DockerContainer.fromJson', () {
    test('maps the first Docker name and strips its leading slash', () {
      final container = DockerContainer.fromJson(const <String, dynamic>{
        'Id': 'abc123',
        'Names': <String>['/web', '/alias'],
        'Image': 'nginx:latest',
        'State': 'running',
        'Status': 'Up 2 hours',
        'Ports': <Map<String, dynamic>>[
          <String, dynamic>{
            'PrivatePort': 80,
            'PublicPort': 8080,
            'Type': 'tcp',
          },
        ],
      });

      expect(container.id, 'abc123');
      expect(container.name, 'web');
      expect(container.image, 'nginx:latest');
      expect(container.state, 'running');
      expect(container.ports.single['PublicPort'], 8080);
    });

    test('defaults missing Docker container fields', () {
      final container = DockerContainer.fromJson(const <String, dynamic>{});

      expect(container.id, isEmpty);
      expect(container.name, isEmpty);
      expect(container.ports, isEmpty);
    });
  });

  group('DockerImage.fromJson', () {
    test('parses tags and size from the Docker image payload', () {
      final image = DockerImage.fromJson(const <String, dynamic>{
        'Id': 'sha256:def456',
        'RepoTags': <String>['nginx:latest'],
        'Size': 187432960,
      });

      expect(image.id, 'sha256:def456');
      expect(image.repoTags, ['nginx:latest']);
      expect(image.size, 187432960);
    });

    test('defaults nullable RepoTags returned by Docker', () {
      final image = DockerImage.fromJson(const <String, dynamic>{
        'RepoTags': null,
      });

      expect(image.repoTags, isEmpty);
      expect(image.size, 0);
    });
  });

  group('GrafanaAlert.fromJson', () {
    test('parses an Alertmanager alert', () {
      final alert = GrafanaAlert.fromJson(const <String, dynamic>{
        'labels': <String, dynamic>{
          'alertname': 'HighCpuUsage',
          'severity': 'warning',
        },
        'annotations': <String, dynamic>{
          'summary': 'CPU usage is above 90%',
          'runbook_url': 'https://wiki.example/runbooks/high-cpu',
        },
        'startsAt': '2026-08-25T14:30:00Z',
        'fingerprint': 'abc123',
        'status': <String, dynamic>{'state': 'suppressed'},
        'generatorURL': 'https://grafana.example/alerting/rules/cpu',
      });

      expect(alert.name, 'HighCpuUsage');
      expect(alert.severity, 'warning');
      expect(alert.startsAt, DateTime.utc(2026, 8, 25, 14, 30));
      expect(alert.fingerprint, 'abc123');
      expect(alert.isSuppressed, isTrue);
      expect(alert.generatorUrl, 'https://grafana.example/alerting/rules/cpu');
    });

    test('defaults missing optional maps and generator URL', () {
      final alert = GrafanaAlert.fromJson(const <String, dynamic>{
        'startsAt': '2026-08-25T14:30:00Z',
      });

      expect(alert.labels, isEmpty);
      expect(alert.annotations, isEmpty);
      expect(alert.generatorUrl, isEmpty);
      expect(alert.fingerprint, isNull);
    });
  });

  group('ProwlarrIndexer.fromJson', () {
    test('parses a configured indexer', () {
      final indexer = ProwlarrIndexer.fromJson(const <String, dynamic>{
        'id': 7,
        'name': 'Example Indexer',
        'enable': true,
        'protocol': 'torrent',
        'priority': 25,
      });

      expect(indexer.id, 7);
      expect(indexer.name, 'Example Indexer');
      expect(indexer.enable, isTrue);
      expect(indexer.protocol, 'torrent');
      expect(indexer.priority, 25);
    });

    test('coerces numeric values and defaults missing keys', () {
      final indexer = ProwlarrIndexer.fromJson(const <String, dynamic>{
        'id': 8.0,
        'priority': 10.0,
      });

      expect(indexer.id, 8);
      expect(indexer.priority, 10);
      expect(indexer.name, isEmpty);
      expect(indexer.enable, isFalse);
    });
  });

  group('ProwlarrRelease.fromJson', () {
    test('parses a search result', () {
      final release = ProwlarrRelease.fromJson(const <String, dynamic>{
        'title': 'Example.Release.2026.1080p',
        'indexer': 'Example Indexer',
        'size': 4294967296,
        'seeders': 42,
        'leechers': 3,
        'protocol': 'torrent',
        'guid': 'urn:example:release:123',
      });

      expect(release.title, 'Example.Release.2026.1080p');
      expect(release.indexer, 'Example Indexer');
      expect(release.size, 4294967296);
      expect(release.seeders, 42);
      expect(release.leechers, 3);
      expect(release.protocol, 'torrent');
    });

    test('accepts floating-point numbers and defaults missing keys', () {
      final release = ProwlarrRelease.fromJson(const <String, dynamic>{
        'size': 1024.5,
        'seeders': 4.0,
        'leechers': 1.0,
      });

      expect(release.size, 1024.5);
      expect(release.seeders, 4);
      expect(release.leechers, 1);
      expect(release.title, isEmpty);
      expect(release.guid, isNull);
    });
  });

  group('ProxmoxVm.fromJson', () {
    test('parses a QEMU VM payload', () {
      final vm = ProxmoxVm.fromJson(const <String, dynamic>{
        'vmid': 101,
        'status': 'running',
        'name': 'app-server',
        'node': 'node1',
        'template': 0,
        'cpu': 0.125,
        'cpus': 4,
        'mem': 2147483648,
        'maxmem': 4294967296,
        'uptime': 86400,
        'netin': 123456,
        'netout': 654321,
      });

      expect(vm.vmid, 101);
      expect(vm.status, 'running');
      expect(vm.name, 'app-server');
      expect(vm.node, 'node1');
      expect(vm.cpu, 0.125);
      expect(vm.cpus, 4);
      expect(vm.mem, 2147483648);
      expect(vm.uptime, 86400);
    });

    test('accepts int CPU and omits optional metrics', () {
      final vm = ProxmoxVm.fromJson(const <String, dynamic>{
        'vmid': 9000.0,
        'status': 'stopped',
        'cpu': 0,
      });

      expect(vm.vmid, 9000);
      expect(vm.cpu, 0.0);
      expect(vm.cpu, isA<double>());
      expect(vm.name, isNull);
      expect(vm.maxmem, isNull);
    });
  });

  group('QbittorrentTorrent.fromJson', () {
    test('parses a torrent payload and snake_case fields', () {
      final torrent = QbittorrentTorrent.fromJson(const <String, dynamic>{
        'hash': '0123456789abcdef',
        'name': 'Example Linux ISO',
        'state': 'downloading',
        'progress': 0.625,
        'dlspeed': 1048576,
        'upspeed': 65536,
        'size': 4294967296,
        'eta': 1800,
        'category': 'iso',
        'num_seeds': 18,
        'num_leechs': 2,
        'ratio': 1.25,
      });

      expect(torrent.hash, '0123456789abcdef');
      expect(torrent.name, 'Example Linux ISO');
      expect(torrent.state, 'downloading');
      expect(torrent.progress, 0.625);
      expect(torrent.dlspeed, 1048576);
      expect(torrent.numSeeds, 18);
      expect(torrent.numLeechs, 2);
      expect(torrent.ratio, 1.25);
    });

    test('accepts int-valued doubles and defaults missing keys', () {
      final torrent = QbittorrentTorrent.fromJson(const <String, dynamic>{
        'progress': 1,
        'ratio': 2,
        'dlspeed': 0.0,
      });

      expect(torrent.progress, 1.0);
      expect(torrent.ratio, 2.0);
      expect(torrent.dlspeed, 0);
      expect(torrent.name, isEmpty);
      expect(torrent.numSeeds, 0);
    });
  });

  group('RadarrMovie.fromJson', () {
    test('parses a movie payload', () {
      final movie = RadarrMovie.fromJson(const <String, dynamic>{
        'id': 42,
        'title': 'Example Movie',
        'year': 2026,
        'monitored': true,
        'hasFile': true,
        'sizeOnDisk': 8589934592,
        'status': 'released',
        'tmdbId': 123456,
        'overview': 'A representative movie payload.',
      });

      expect(movie.id, 42);
      expect(movie.title, 'Example Movie');
      expect(movie.year, 2026);
      expect(movie.monitored, isTrue);
      expect(movie.hasFile, isTrue);
      expect(movie.sizeOnDisk, 8589934592);
      expect(movie.tmdbId, 123456);
    });

    test('coerces numeric values and defaults a lookup result', () {
      final movie = RadarrMovie.fromJson(const <String, dynamic>{
        'year': 2025.0,
        'tmdbId': 654321.0,
      });

      expect(movie.id, 0);
      expect(movie.title, isEmpty);
      expect(movie.year, 2025);
      expect(movie.tmdbId, 654321);
      expect(movie.monitored, isFalse);
      expect(movie.hasFile, isFalse);
    });
  });

  group('ServarrQueueItem.fromJson', () {
    test('parses a queue item', () {
      final item = ServarrQueueItem.fromJson(const <String, dynamic>{
        'id': 12,
        'title': 'Example.Show.S01E01',
        'status': 'downloading',
        'trackedDownloadState': 'downloading',
        'trackedDownloadStatus': 'ok',
        'size': 2000,
        'sizeleft': 500,
        'timeleft': '00:10:00',
        'indexer': 'Example Indexer',
      });

      expect(item.id, 12);
      expect(item.title, 'Example.Show.S01E01');
      expect(item.trackedDownloadState, 'downloading');
      expect(item.trackedDownloadStatus, 'ok');
      expect(item.size, 2000);
      expect(item.sizeleft, 500);
      expect(item.progress, 0.75);
      expect(item.timeleft, '00:10:00');
    });

    test('accepts floating-point sizes and defaults missing keys', () {
      final item = ServarrQueueItem.fromJson(const <String, dynamic>{
        'id': 13.0,
        'size': 10.5,
        'sizeleft': 2.5,
      });

      expect(item.id, 13);
      expect(item.size, 10.5);
      expect(item.sizeleft, 2.5);
      expect(item.progress, closeTo(8 / 10.5, 0.000001));
      expect(item.title, isEmpty);
      expect(item.status, isNull);
    });
  });

  group('SonarrSeries.fromJson', () {
    test('parses a series with nested statistics', () {
      final series = SonarrSeries.fromJson(const <String, dynamic>{
        'id': 31,
        'title': 'Example Series',
        'year': 2024,
        'monitored': true,
        'status': 'continuing',
        'network': 'Example Network',
        'seriesType': 'standard',
        'tvdbId': 987654,
        'overview': 'A representative series payload.',
        'statistics': <String, dynamic>{
          'episodeCount': 20,
          'episodeFileCount': 18,
          'totalEpisodeCount': 24,
          'sizeOnDisk': 32212254720,
        },
      });

      expect(series.id, 31);
      expect(series.title, 'Example Series');
      expect(series.monitored, isTrue);
      expect(series.seriesType, 'standard');
      expect(series.tvdbId, 987654);
      expect(series.statistics?.episodeCount, 20);
      expect(series.statistics?.episodeFileCount, 18);
      expect(series.statistics?.sizeOnDisk, 32212254720);
    });

    test('coerces numeric values and permits missing statistics', () {
      final series = SonarrSeries.fromJson(const <String, dynamic>{
        'id': 0.0,
        'year': 2026.0,
        'tvdbId': 1234.0,
      });

      expect(series.id, 0);
      expect(series.year, 2026);
      expect(series.tvdbId, 1234);
      expect(series.title, isEmpty);
      expect(series.monitored, isFalse);
      expect(series.statistics, isNull);
    });
  });

  group('VmStatus.fromJson', () {
    test('parses current QEMU status', () {
      final status = VmStatus.fromJson(const <String, dynamic>{
        'status': 'running',
        'vmid': 101,
        'name': 'app-server',
        'qmpstatus': 'running',
        'cpu': 0.375,
        'cpus': 4,
        'mem': 3221225472,
        'maxmem': 4294967296,
        'disk': 10737418240,
        'maxdisk': 53687091200,
        'uptime': 7200,
        'netin': 1234567,
        'netout': 7654321,
        'diskread': 111111,
        'diskwrite': 222222,
      });

      expect(status.status, 'running');
      expect(status.vmid, 101);
      expect(status.name, 'app-server');
      expect(status.qmpstatus, 'running');
      expect(status.cpu, 0.375);
      expect(status.cpus, 4);
      expect(status.maxdisk, 53687091200);
      expect(status.diskwrite, 222222);
    });

    test('accepts int CPU and omits optional metrics', () {
      final status = VmStatus.fromJson(const <String, dynamic>{
        'status': 'stopped',
        'vmid': 101.0,
        'cpu': 0,
      });

      expect(status.status, 'stopped');
      expect(status.vmid, 101);
      expect(status.cpu, 0.0);
      expect(status.cpu, isA<double>());
      expect(status.name, isNull);
      expect(status.mem, isNull);
    });
  });
}
