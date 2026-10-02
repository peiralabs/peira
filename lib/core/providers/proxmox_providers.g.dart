// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'proxmox_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(proxmoxApi)
final proxmoxApiProvider = ProxmoxApiProvider._();

final class ProxmoxApiProvider
    extends
        $FunctionalProvider<
          AsyncValue<ProxmoxApi>,
          ProxmoxApi,
          FutureOr<ProxmoxApi>
        >
    with $FutureModifier<ProxmoxApi>, $FutureProvider<ProxmoxApi> {
  ProxmoxApiProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'proxmoxApiProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$proxmoxApiHash();

  @$internal
  @override
  $FutureProviderElement<ProxmoxApi> $createElement($ProviderPointer pointer) =>
      $FutureProviderElement(pointer);

  @override
  FutureOr<ProxmoxApi> create(Ref ref) {
    return proxmoxApi(ref);
  }
}

String _$proxmoxApiHash() => r'a22ebf6c17cfc77a880f38f38dd7780fdf94742e';

@ProviderFor(nodes)
final nodesProvider = NodesProvider._();

final class NodesProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<ProxmoxNode>>,
          List<ProxmoxNode>,
          FutureOr<List<ProxmoxNode>>
        >
    with
        $FutureModifier<List<ProxmoxNode>>,
        $FutureProvider<List<ProxmoxNode>> {
  NodesProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'nodesProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$nodesHash();

  @$internal
  @override
  $FutureProviderElement<List<ProxmoxNode>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<List<ProxmoxNode>> create(Ref ref) {
    return nodes(ref);
  }
}

String _$nodesHash() => r'b87bfd5912321e4366a0de5598ebbd8d35d4ca2b';

@ProviderFor(containers)
final containersProvider = ContainersFamily._();

final class ContainersProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<ProxmoxContainer>>,
          List<ProxmoxContainer>,
          FutureOr<List<ProxmoxContainer>>
        >
    with
        $FutureModifier<List<ProxmoxContainer>>,
        $FutureProvider<List<ProxmoxContainer>> {
  ContainersProvider._({
    required ContainersFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'containersProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$containersHash();

  @override
  String toString() {
    return r'containersProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<List<ProxmoxContainer>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<List<ProxmoxContainer>> create(Ref ref) {
    final argument = this.argument as String;
    return containers(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is ContainersProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$containersHash() => r'c7033006ddd28497fe9f4e70e01c99887b0851fe';

final class ContainersFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<List<ProxmoxContainer>>, String> {
  ContainersFamily._()
    : super(
        retry: null,
        name: r'containersProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  ContainersProvider call(String node) =>
      ContainersProvider._(argument: node, from: this);

  @override
  String toString() => r'containersProvider';
}

@ProviderFor(allContainers)
final allContainersProvider = AllContainersProvider._();

final class AllContainersProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<ProxmoxContainer>>,
          List<ProxmoxContainer>,
          FutureOr<List<ProxmoxContainer>>
        >
    with
        $FutureModifier<List<ProxmoxContainer>>,
        $FutureProvider<List<ProxmoxContainer>> {
  AllContainersProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'allContainersProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$allContainersHash();

  @$internal
  @override
  $FutureProviderElement<List<ProxmoxContainer>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<List<ProxmoxContainer>> create(Ref ref) {
    return allContainers(ref);
  }
}

String _$allContainersHash() => r'0baf6ecd98ff0c7d1b5375fdccfebcb09edab75e';

@ProviderFor(vms)
final vmsProvider = VmsFamily._();

final class VmsProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<ProxmoxVm>>,
          List<ProxmoxVm>,
          FutureOr<List<ProxmoxVm>>
        >
    with $FutureModifier<List<ProxmoxVm>>, $FutureProvider<List<ProxmoxVm>> {
  VmsProvider._({required VmsFamily super.from, required String super.argument})
    : super(
        retry: null,
        name: r'vmsProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$vmsHash();

  @override
  String toString() {
    return r'vmsProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<List<ProxmoxVm>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<List<ProxmoxVm>> create(Ref ref) {
    final argument = this.argument as String;
    return vms(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is VmsProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$vmsHash() => r'd869bbe75d9531eafe2f7b03a22a777c6288f164';

final class VmsFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<List<ProxmoxVm>>, String> {
  VmsFamily._()
    : super(
        retry: null,
        name: r'vmsProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  VmsProvider call(String node) => VmsProvider._(argument: node, from: this);

  @override
  String toString() => r'vmsProvider';
}

@ProviderFor(allVms)
final allVmsProvider = AllVmsProvider._();

final class AllVmsProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<ProxmoxVm>>,
          List<ProxmoxVm>,
          FutureOr<List<ProxmoxVm>>
        >
    with $FutureModifier<List<ProxmoxVm>>, $FutureProvider<List<ProxmoxVm>> {
  AllVmsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'allVmsProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$allVmsHash();

  @$internal
  @override
  $FutureProviderElement<List<ProxmoxVm>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<List<ProxmoxVm>> create(Ref ref) {
    return allVms(ref);
  }
}

String _$allVmsHash() => r'd5b69e95728e94f92e6fec5615e82e81efc3f0b9';

@ProviderFor(backupStorages)
final backupStoragesProvider = BackupStoragesFamily._();

final class BackupStoragesProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<Map<String, dynamic>>>,
          List<Map<String, dynamic>>,
          FutureOr<List<Map<String, dynamic>>>
        >
    with
        $FutureModifier<List<Map<String, dynamic>>>,
        $FutureProvider<List<Map<String, dynamic>>> {
  BackupStoragesProvider._({
    required BackupStoragesFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'backupStoragesProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$backupStoragesHash();

  @override
  String toString() {
    return r'backupStoragesProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<List<Map<String, dynamic>>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<List<Map<String, dynamic>>> create(Ref ref) {
    final argument = this.argument as String;
    return backupStorages(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is BackupStoragesProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$backupStoragesHash() => r'7a681855bbd68d2cf8a718526f138a19d55c2919';

final class BackupStoragesFamily extends $Family
    with
        $FunctionalFamilyOverride<
          FutureOr<List<Map<String, dynamic>>>,
          String
        > {
  BackupStoragesFamily._()
    : super(
        retry: null,
        name: r'backupStoragesProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  BackupStoragesProvider call(String node) =>
      BackupStoragesProvider._(argument: node, from: this);

  @override
  String toString() => r'backupStoragesProvider';
}

@ProviderFor(backups)
final backupsProvider = BackupsFamily._();

final class BackupsProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<Map<String, dynamic>>>,
          List<Map<String, dynamic>>,
          FutureOr<List<Map<String, dynamic>>>
        >
    with
        $FutureModifier<List<Map<String, dynamic>>>,
        $FutureProvider<List<Map<String, dynamic>>> {
  BackupsProvider._({
    required BackupsFamily super.from,
    required (String, String) super.argument,
  }) : super(
         retry: null,
         name: r'backupsProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$backupsHash();

  @override
  String toString() {
    return r'backupsProvider'
        ''
        '$argument';
  }

  @$internal
  @override
  $FutureProviderElement<List<Map<String, dynamic>>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<List<Map<String, dynamic>>> create(Ref ref) {
    final argument = this.argument as (String, String);
    return backups(ref, argument.$1, argument.$2);
  }

  @override
  bool operator ==(Object other) {
    return other is BackupsProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$backupsHash() => r'2b71d2ef0e800b0e661067b07840ad3303d50766';

final class BackupsFamily extends $Family
    with
        $FunctionalFamilyOverride<
          FutureOr<List<Map<String, dynamic>>>,
          (String, String)
        > {
  BackupsFamily._()
    : super(
        retry: null,
        name: r'backupsProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  BackupsProvider call(String node, String storage) =>
      BackupsProvider._(argument: (node, storage), from: this);

  @override
  String toString() => r'backupsProvider';
}

@ProviderFor(backupJobs)
final backupJobsProvider = BackupJobsProvider._();

final class BackupJobsProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<Map<String, dynamic>>>,
          List<Map<String, dynamic>>,
          FutureOr<List<Map<String, dynamic>>>
        >
    with
        $FutureModifier<List<Map<String, dynamic>>>,
        $FutureProvider<List<Map<String, dynamic>>> {
  BackupJobsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'backupJobsProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$backupJobsHash();

  @$internal
  @override
  $FutureProviderElement<List<Map<String, dynamic>>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<List<Map<String, dynamic>>> create(Ref ref) {
    return backupJobs(ref);
  }
}

String _$backupJobsHash() => r'4791d505e651892d0fade0f5374129b55038a114';

@ProviderFor(recentTasks)
final recentTasksProvider = RecentTasksProvider._();

final class RecentTasksProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<ProxmoxTask>>,
          List<ProxmoxTask>,
          FutureOr<List<ProxmoxTask>>
        >
    with
        $FutureModifier<List<ProxmoxTask>>,
        $FutureProvider<List<ProxmoxTask>> {
  RecentTasksProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'recentTasksProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$recentTasksHash();

  @$internal
  @override
  $FutureProviderElement<List<ProxmoxTask>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<List<ProxmoxTask>> create(Ref ref) {
    return recentTasks(ref);
  }
}

String _$recentTasksHash() => r'a21506a7d4c90450d326df43753b9fbe0c755f71';
