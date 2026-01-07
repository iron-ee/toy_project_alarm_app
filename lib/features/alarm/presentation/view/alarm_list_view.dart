import 'package:alarm_app/features/alarm/presentation/provider/alarm_controller.dart';
import 'package:alarm_app/features/alarm/presentation/view/add_edit_alarm_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class AlarmListScreen extends ConsumerWidget {
  const AlarmListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final alarmListState = ref.watch(alarmControllerProvider);

    return Scaffold(
      appBar: AppBar(title: const Text("알림딩동")),
      body: alarmListState.when(
        data: (alarms) {
          if (alarms.isEmpty) {
            return const Center(
              child: Text(
                "등록된 알람이 없습니다.\n+ 버튼을 눌러 추가해보세요!",
                textAlign: TextAlign.center,
              ),
            );
          }

          // 시간 순서대로 정렬 (오전 -> 오후)
          // 원본 리스트를 건드리지 않기 위해 복사본을 만들어 정렬
          final sortedAlarms = List.of(alarms);
          sortedAlarms.sort((a, b) {
            // 시간 * 60 + 분 = 하루 중 흐른 시간(분)
            final aMinutes = a.time.hour * 60 + a.time.minute;
            final bMinutes = b.time.hour * 60 + b.time.minute;
            return aMinutes.compareTo(bMinutes);
          });

          return ListView.builder(
            itemCount: sortedAlarms.length,
            itemBuilder: (context, index) {
              final alarm = sortedAlarms[index];

              return Dismissible(
                key: Key(alarm.id),
                direction: DismissDirection.endToStart,
                background: Container(
                  color: Colors.red,
                  alignment: Alignment.centerRight,
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: const Icon(Icons.delete, color: Colors.white),
                ),
                onDismissed: (direction) {
                  ref
                      .read(alarmControllerProvider.notifier)
                      .deleteAlarm(alarm.id);

                  ScaffoldMessenger.of(
                    context,
                  ).showSnackBar(const SnackBar(content: Text("알람이 삭제되었습니다.")));
                },
                child: ListTile(
                  title: Row(
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    children: [
                      Text(
                        "${alarm.time.hour.toString().padLeft(2, '0')}:${alarm.time.minute.toString().padLeft(2, '0')}",
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: alarm.isEnabled ? Colors.black : Colors.grey,
                        ),
                      ),
                      const SizedBox(width: 8),
                      // 오전/오후 표시
                      Text(
                        alarm.time.hour < 12 ? "AM" : "PM",
                        style: TextStyle(
                          fontSize: 14,
                          color: alarm.isEnabled ? Colors.black54 : Colors.grey,
                        ),
                      ),
                    ],
                  ),
                  subtitle: Padding(
                    padding: const EdgeInsets.only(top: 4.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // 요일 표기
                        Text(
                          _getDaysText(alarm.activeDays),
                          style: TextStyle(
                            color: alarm.isEnabled
                                ? Colors.deepPurple
                                : Colors.grey,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          "메모: ${alarm.ttsMessage ?? '없음'}",
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  trailing: Switch(
                    value: alarm.isEnabled,
                    activeColor: Colors.deepPurple,
                    onChanged: (bool value) {
                      ref
                          .read(alarmControllerProvider.notifier)
                          .toggleAlarm(alarm);
                    },
                  ),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => AddEditAlarmScreen(alarm: alarm),
                      ),
                    );
                  },
                ),
              );
            },
          );
        },
        error: (err, stack) => Center(child: Text("에러: $err")),
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

  // 요일 텍스트 변환
  String _getDaysText(List<int>? activeDays) {
    // 1. 데이터가 없거나 비어있으면 "한 번 실행"
    if (activeDays == null || activeDays.isEmpty) {
      return "한 번 실행";
    }

    // 2. 비교를 위해 정렬 및 Set 변환
    final sortedDays = List<int>.from(activeDays)..sort();
    final daySet = sortedDays.toSet();

    // 3. 패턴 매칭
    // 매일 (월~일, 7개)
    if (daySet.length == 7) {
      return "매일";
    }

    // 평일 (월~금, [1,2,3,4,5])
    // containsAll을 사용하여 1~5가 모두 포함되고 길이가 5인지 확인
    if (daySet.length == 5 && daySet.containsAll([1, 2, 3, 4, 5])) {
      return "평일";
    }

    // 주말 (토~일, [6,7])
    if (daySet.length == 2 && daySet.containsAll([6, 7])) {
      return "주말";
    }

    // 4. 그 외: 요일 나열 (예: 월, 수, 금)
    const days = ["월", "화", "수", "목", "금", "토", "일"];
    return sortedDays.map((d) => days[d - 1]).join(", ");
  }
}
