import 'dart:developer';

import 'package:alarm_app/features/alarm/presentation/provider/alarm_controller.dart';
import 'package:alarm_app/features/alarm/presentation/view/add_edit_alarm_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class AlarmListScreen extends ConsumerWidget {
  const AlarmListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Controller의 상태를 구독 (Loading / Error / Data)
    final alarmListState = ref.watch(alarmControllerProvider);

    return Scaffold(
      appBar: AppBar(title: const Text("TTS 알람")),

      // AsyncValue를 사용하면 로딩/에러 처리가 매우 깔끔해집니다.
      body: alarmListState.when(
        data: (alarms) {
          if (alarms.isEmpty) {
            return const Center(child: Text("등록된 알람이 없습니다."));
          }
          return ListView.builder(
            itemCount: alarms.length,
            itemBuilder: (context, index) {
              final alarm = alarms[index];
              String daysText = "한 번 실행";
              if (alarm.activeDays != null && alarm.activeDays!.isNotEmpty) {
                final days = ["월", "화", "수", "목", "금", "토", "일"];
                // 정렬 후 텍스트로 변환
                final sortedDays = List.from(alarm.activeDays!)..sort();
                daysText = sortedDays.map((d) => days[d - 1]).join(", ");
              }

              return ListTile(
                title: Text(
                  // 시간 포맷팅 (intl 패키지 쓰면 좋지만 간단하게)
                  "${alarm.time.hour}:${alarm.time.minute.toString().padLeft(2, '0')}",
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      daysText,
                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                    Text("TTS: ${alarm.ttsMessage}"),
                  ],
                ),
                trailing: Switch(
                  value: alarm.isEnabled,
                  onChanged: (val) {
                    // TODO: 알람 켜기/끄기 로직 연결
                  },
                ),
              );
            },
          );
        },
        error: (err, stack) {
          log('err: $err');
          return Center(child: Text("에러: $err"));
        },
        loading: () => const Center(child: CircularProgressIndicator()),
      ),

      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const AddEditAlarmScreen()),
          );
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}
