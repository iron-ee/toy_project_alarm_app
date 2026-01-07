class AlarmModel {
  final String id;
  final DateTime time;
  final bool isEnabled;
  final String? ttsMessage;
  final List<int>? activeDays;
  final String title;
  final String? soundName;

  AlarmModel({
    required this.id,
    required this.time,
    this.isEnabled = true,
    this.ttsMessage,
    this.activeDays,
    this.title = "알람",
    this.soundName,
  });

  AlarmModel copyWith({
    String? id,
    DateTime? time,
    bool? isEnabled,
    String? ttsMessage,
    List<int>? activeDays,
    String? title,
    String? soundName,
  }) {
    return AlarmModel(
      id: id ?? this.id,
      time: time ?? this.time,
      isEnabled: isEnabled ?? this.isEnabled,
      ttsMessage: ttsMessage ?? this.ttsMessage,
      activeDays: activeDays ?? this.activeDays,
      title: title ?? this.title,
      soundName: soundName ?? this.soundName,
    );
  }
}
