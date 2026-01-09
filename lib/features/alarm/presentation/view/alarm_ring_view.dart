import 'package:alarm/alarm.dart';
import 'package:alarm_app/features/alarm/presentation/provider/ringing_state_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

class AlarmRingView extends ConsumerWidget {
  const AlarmRingView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 현재 울리고 있는 알람 정보 가져오기
    final ringingAlarm = ref.watch(ringingStateProvider);

    // 혹시라도 알람 정보가 없으면 빈 화면 반환 (방어 코드)
    if (ringingAlarm == null) return const SizedBox.shrink();

    return Scaffold(
      // 배경을 강조색(DeepPurple)으로 채워 알람임을 강조
      body: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.deepPurple.shade800, Colors.deepPurple.shade400],
          ),
        ),
        child: SafeArea(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              // 1. 알람 제목 및 아이콘
              Column(
                children: [
                  const Icon(Icons.alarm_on, color: Colors.white, size: 80),
                  const SizedBox(height: 10),
                  Text(
                    ringingAlarm.notificationSettings.title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),

              // 2. 현재 시간 표시 (매우 크게)
              Text(
                DateFormat("HH:mm").format(ringingAlarm.dateTime),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 100,
                  fontWeight: FontWeight.w900,
                ),
              ),

              // 3. TTS 메모 내용
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 40),
                child: Text(
                  ringingAlarm.notificationSettings.body,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.white, fontSize: 22),
                ),
              ),

              // 4. 알람 해제 버튼
              // 실수로 눌리는 것을 방지하기 위해 '길게 누르기' 또는 '버튼' 배치
              ElevatedButton(
                onPressed: () async {
                  // 알람 중지 (alarm 패키지 함수 호출)
                  await Alarm.stop(ringingAlarm.id);
                  // 알람이 멈추면 ringingStateProvider는 서비스의 listen에 의해
                  // 자동으로 null이 되며 화면이 닫힙니다.
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: Colors.deepPurple,
                  minimumSize: const Size(200, 70),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(35),
                  ),
                ),
                child: const Text(
                  "알람 끄기",
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
