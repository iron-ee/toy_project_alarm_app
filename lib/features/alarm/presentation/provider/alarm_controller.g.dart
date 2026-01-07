// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'alarm_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(AlarmController)
final alarmControllerProvider = AlarmControllerProvider._();

final class AlarmControllerProvider
    extends $AsyncNotifierProvider<AlarmController, List<AlarmModel>> {
  AlarmControllerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'alarmControllerProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$alarmControllerHash();

  @$internal
  @override
  AlarmController create() => AlarmController();
}

String _$alarmControllerHash() => r'07e6439b09f3c8bc91331132beb5899f128f336c';

abstract class _$AlarmController extends $AsyncNotifier<List<AlarmModel>> {
  FutureOr<List<AlarmModel>> build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref =
        this.ref as $Ref<AsyncValue<List<AlarmModel>>, List<AlarmModel>>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<List<AlarmModel>>, List<AlarmModel>>,
              AsyncValue<List<AlarmModel>>,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}
