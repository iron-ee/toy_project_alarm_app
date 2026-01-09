import 'package:alarm_app/core/constants/app_constants.dart';
import 'package:alarm_app/core/service/alarm_service.dart';
import 'package:alarm_app/features/alarm/domain/entity/alarm_entity.dart';
import 'package:alarm_app/features/alarm/presentation/provider/ringing_state_provider.dart';
import 'package:alarm_app/features/alarm/presentation/view/alarm_list_view.dart';
import 'package:alarm_app/features/alarm/presentation/view/alarm_ring_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_ce_flutter/adapters.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 1) Hive 초기화
  await Hive.initFlutter();

  // 2) Adapter 등록 (Build Runner 실행 후 생성된 어댑터)
  Hive.registerAdapter(AlarmEntityAdapter());

  // 3) Box 열기
  await Hive.openBox<AlarmEntity>(AppConstants.alarmBoxName);

  // 1. 단일 컨테이너 생성 ProviderContainer를 직접 생성해서 초기화 로직 수행
  final container = ProviderContainer();

  // 2. 알림 서비스 초기화 (이제 해당 컨테이너는 앱이 꺼질 때까지 유지됨)
  await container.read(alarmServiceProvider).init();

  runApp(
    // 3. 위 컨테이너 주입
    UncontrolledProviderScope(container: container, child: MyApp()),
  );
}

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 알림 울림 상태 감시
    final ringingAlarm = ref.watch(ringingStateProvider);
    return MaterialApp(
      title: '알림딩동',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
      ),
      home: ringingAlarm != null
          ? const AlarmRingView()
          : const AlarmListScreen(),
    );
  }
}
