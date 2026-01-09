// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'ringing_state_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(RingingState)
final ringingStateProvider = RingingStateProvider._();

final class RingingStateProvider
    extends $NotifierProvider<RingingState, AlarmSettings?> {
  RingingStateProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'ringingStateProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$ringingStateHash();

  @$internal
  @override
  RingingState create() => RingingState();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(AlarmSettings? value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<AlarmSettings?>(value),
    );
  }
}

String _$ringingStateHash() => r'97b7c3adf1ea69a688fbd62453a4ca42fa796a81';

abstract class _$RingingState extends $Notifier<AlarmSettings?> {
  AlarmSettings? build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<AlarmSettings?, AlarmSettings?>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AlarmSettings?, AlarmSettings?>,
              AlarmSettings?,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}
