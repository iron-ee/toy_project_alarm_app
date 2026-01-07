import 'package:alarm_app/core/service/notification_service.dart';
import 'package:alarm_app/features/alarm/domain/entity/alarm_entity.dart';
import 'package:alarm_app/features/alarm/presentation/view/alarm_list_view.dart';
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
  await Hive.openBox<AlarmEntity>(kAlarmBoxName);

  // ProviderContainer를 직접 생성해서 초기화 로직 수행
  final container = ProviderContainer();

  // Notification Service 초기화
  await container.read(notificationServiceProvider).init();

  runApp(
    // ProviderScope 필수!
    const ProviderScope(child: MyApp()),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Alarm App',
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
      ),
      home: const AlarmListScreen(),
    );
  }
}
