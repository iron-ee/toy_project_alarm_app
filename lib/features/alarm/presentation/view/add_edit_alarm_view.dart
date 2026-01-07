import 'package:alarm_app/core/constants/app_constants.dart';
import 'package:alarm_app/features/alarm/data/model/alarm_model.dart';
import 'package:alarm_app/features/alarm/presentation/provider/alarm_controller.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class AddEditAlarmScreen extends ConsumerStatefulWidget {
  final AlarmModel? alarm;

  const AddEditAlarmScreen({super.key, this.alarm});

  @override
  ConsumerState<AddEditAlarmScreen> createState() => _AddEditAlarmScreenState();
}

class _AddEditAlarmScreenState extends ConsumerState<AddEditAlarmScreen> {
  late DateTime selectedTime;
  late TextEditingController _titleController; // 제목 컨트롤러
  late TextEditingController _ttsController; // TTS 컨트롤러
  final Set<int> _selectedDays = {};

  // 선택된 알림음 (null이면 기본음)
  String? _selectedSound;

  // 사용할 알림음 리스트 (파일 이름은 확장자 제외하고 작성)
  // 실제 파일: android/app/src/main/res/raw/launch_comment_bgm.wav
  final Map<String, String> _soundOptions = {
    '기본음': '', // 빈 문자열이나 null로 처리
    '점심 BGM': AppConstants.soundLaunchBgm,
    // '경쾌한 알람': 'bright_alarm', // 추가 파일이 있다면 여기에
  };

  @override
  void initState() {
    super.initState();

    if (widget.alarm != null) {
      // [수정 모드]
      selectedTime = widget.alarm!.time;
      _titleController = TextEditingController(text: widget.alarm!.title);
      _ttsController = TextEditingController(text: widget.alarm!.ttsMessage);
      _selectedSound = widget.alarm!.soundName;

      if (widget.alarm!.activeDays != null) {
        _selectedDays.addAll(widget.alarm!.activeDays!);
      }
    } else {
      // [추가 모드]
      final now = DateTime.now();
      selectedTime = DateTime(
        now.year,
        now.month,
        now.day,
        now.hour,
        now.minute + 1,
      );
      _titleController = TextEditingController(text: "알람");
      _ttsController = TextEditingController(text: "점심 시간입니다!");
      _selectedSound = null;
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _ttsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.alarm != null ? "알람 수정" : "알람 추가"),
        actions: [
          TextButton(
            onPressed: _onSave,
            child: const Text("저장", style: TextStyle(fontSize: 16)),
          ),
        ],
      ),
      // [해결] 키보드 오버플로우 방지
      body: SingleChildScrollView(
        child: Column(
          children: [
            // 1. 시간 선택
            SizedBox(
              height: 200,
              child: CupertinoDatePicker(
                mode: CupertinoDatePickerMode.time,
                initialDateTime: selectedTime,
                use24hFormat: false,
                onDateTimeChanged: (DateTime newTime) {
                  setState(() => selectedTime = newTime);
                },
              ),
            ),
            const Divider(),

            // 2. 제목 입력 (추가됨)
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 16.0,
                vertical: 8.0,
              ),
              child: TextField(
                controller: _titleController,
                decoration: const InputDecoration(
                  labelText: "알람 제목",
                  hintText: "예: 기상, 약 먹기",
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.label),
                ),
              ),
            ),

            // 3. 요일 선택
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

            // 4. 알림음 선택 (추가됨)
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 16.0,
                vertical: 8.0,
              ),
              child: DropdownButtonFormField<String?>(
                value: _selectedSound,
                decoration: const InputDecoration(
                  labelText: "알림음 설정",
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.music_note),
                ),
                items: _soundOptions.entries.map((entry) {
                  return DropdownMenuItem<String?>(
                    // value가 빈 문자열이면 null로 처리
                    value: entry.value.isEmpty ? null : entry.value,
                    child: Text(entry.key),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedSound = value;
                  });
                },
              ),
            ),

            // 5. TTS 메시지 입력
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 16.0,
                vertical: 8.0,
              ),
              child: TextField(
                controller: _ttsController,
                decoration: const InputDecoration(
                  labelText: "TTS 음성 메모",
                  hintText: "알림 내용을 읽어줍니다.",
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.record_voice_over),
                ),
                // 키보드 엔터 시 다음 동작 등 설정 가능
                textInputAction: TextInputAction.done,
              ),
            ),

            // 키보드가 올라왔을 때 하단 여백 확보
            SizedBox(height: MediaQuery.of(context).viewInsets.bottom + 20),
          ],
        ),
      ),
    );
  }

  // 요일 선택 위젯
  Widget _buildWeekdaySelector() {
    const days = ["월", "화", "수", "목", "금", "토", "일"];
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: List.generate(7, (index) {
        final dayIndex = index + 1;
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
    if (widget.alarm != null) {
      final updatedAlarm = widget.alarm!.copyWith(
        time: selectedTime,
        title: _titleController.text.isEmpty ? "알람" : _titleController.text,
        ttsMessage: _ttsController.text,
        activeDays: _selectedDays.toList(),
        soundName: _selectedSound,
      );
      ref.read(alarmControllerProvider.notifier).editAlarm(alarm: updatedAlarm);
    } else {
      ref
          .read(alarmControllerProvider.notifier)
          .addAlarm(
            time: selectedTime,
            title: _titleController.text.isEmpty ? "알람" : _titleController.text,
            message: _ttsController.text,
            activeDays: _selectedDays.toList(),
            soundName: _selectedSound,
          );
    }
    Navigator.pop(context);
  }
}
