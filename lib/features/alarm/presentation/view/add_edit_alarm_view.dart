import 'package:alarm_app/features/alarm/presentation/provider/alarm_controller.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class AddEditAlarmScreen extends ConsumerStatefulWidget {
  const AddEditAlarmScreen({super.key});

  @override
  ConsumerState<AddEditAlarmScreen> createState() => _AddEditAlarmScreenState();
}

class _AddEditAlarmScreenState extends ConsumerState<AddEditAlarmScreen> {
  late DateTime selectedTime;
  final TextEditingController _textController = TextEditingController(
    text: "기상 시간입니다!",
  );

  // 선택된 요일 관리 (Set으로 중복 방지)
  final Set<int> _selectedDays = {};

  @override
  void initState() {
    super.initState();
    // 초기 시간은 현재 시간의 다음 분으로 셋팅 (편의성)
    final now = DateTime.now();
    selectedTime = DateTime(
      now.year,
      now.month,
      now.day,
      now.hour,
      now.minute + 1,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("알람 추가"),
        actions: [
          TextButton(
            onPressed: _onSave,
            child: const Text("저장", style: TextStyle(fontSize: 16)),
          ),
        ],
      ),
      body: Column(
        children: [
          // 1. 시간 선택 (iOS 스타일 휠)
          SizedBox(
            height: 200,
            child: CupertinoDatePicker(
              mode: CupertinoDatePickerMode.time,
              initialDateTime: selectedTime,
              use24hFormat: false, // 오전/오후 표시
              onDateTimeChanged: (DateTime newTime) {
                setState(() {
                  selectedTime = newTime;
                });
              },
            ),
          ),

          const Divider(),

          // 2. 요일 선택
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "반복 요일",
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 10),
                _buildWeekdaySelector(),
              ],
            ),
          ),

          const Divider(),

          // 3. TTS 메시지 입력
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _textController,
              decoration: const InputDecoration(
                labelText: "TTS 음성 메모",
                hintText: "예: 점심시간입니다.",
                border: OutlineInputBorder(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // 요일 선택 위젯 빌더
  Widget _buildWeekdaySelector() {
    const days = ["월", "화", "수", "목", "금", "토", "일"];
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: List.generate(7, (index) {
        final dayIndex = index + 1; // 1(월) ~ 7(일)
        final isSelected = _selectedDays.contains(dayIndex);

        return GestureDetector(
          onTap: () {
            setState(() {
              if (isSelected) {
                _selectedDays.remove(dayIndex);
              } else {
                _selectedDays.add(dayIndex);
              }
            });
          },
          child: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isSelected ? Colors.deepPurple : Colors.grey[200],
            ),
            alignment: Alignment.center,
            child: Text(
              days[index],
              style: TextStyle(
                color: isSelected ? Colors.white : Colors.black,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ),
        );
      }),
    );
  }

  void _onSave() {
    ref
        .read(alarmControllerProvider.notifier)
        .addAlarm(
          time: selectedTime,
          message: _textController.text,
          activeDays: _selectedDays.toList(),
        );
    Navigator.pop(context); // 화면 닫기
  }
}
