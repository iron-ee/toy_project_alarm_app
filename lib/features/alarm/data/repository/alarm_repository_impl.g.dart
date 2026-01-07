// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'alarm_repository_impl.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(alarmRepository)
final alarmRepositoryProvider = AlarmRepositoryProvider._();

final class AlarmRepositoryProvider
    extends
        $FunctionalProvider<AlarmRepository, AlarmRepository, AlarmRepository>
    with $Provider<AlarmRepository> {
  AlarmRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'alarmRepositoryProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$alarmRepositoryHash();

  @$internal
  @override
  $ProviderElement<AlarmRepository> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  AlarmRepository create(Ref ref) {
    return alarmRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(AlarmRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<AlarmRepository>(value),
    );
  }
}

String _$alarmRepositoryHash() => r'dbc82a9722687ce1f024c041e245a8227069d9b8';
