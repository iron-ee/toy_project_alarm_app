class AlarmModel {
  final String id;
  final DateTime time;
  final bool isEnabled;
  final String? ttsMessage;
  final List<int>? activeDays;

  AlarmModel({
    required this.id,
    required this.time,
    this.isEnabled = true,
    this.ttsMessage,
    this.activeDays,
  });

  AlarmModel copyWith({
    String? id,
    DateTime? time,
    bool? isEnabled,
    String? ttsMessage,
    List<int>? activeDays,
  }) {
    return AlarmModel(
      id: id ?? this.id,
      time: time ?? this.time,
      isEnabled: isEnabled ?? this.isEnabled,
      ttsMessage: ttsMessage ?? this.ttsMessage,
      activeDays: activeDays ?? this.activeDays,
    );
  }
}
