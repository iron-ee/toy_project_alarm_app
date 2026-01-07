// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'alarm_data_source.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(alarmLocalDataSource)
final alarmLocalDataSourceProvider = AlarmLocalDataSourceProvider._();

final class AlarmLocalDataSourceProvider
    extends
        $FunctionalProvider<
          AlarmLocalDataSource,
          AlarmLocalDataSource,
          AlarmLocalDataSource
        >
    with $Provider<AlarmLocalDataSource> {
  AlarmLocalDataSourceProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'alarmLocalDataSourceProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$alarmLocalDataSourceHash();

  @$internal
  @override
  $ProviderElement<AlarmLocalDataSource> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  AlarmLocalDataSource create(Ref ref) {
    return alarmLocalDataSource(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(AlarmLocalDataSource value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<AlarmLocalDataSource>(value),
    );
  }
}

String _$alarmLocalDataSourceHash() =>
    r'67af906d7e66121a294f0089879c67f9939d7d9b';
