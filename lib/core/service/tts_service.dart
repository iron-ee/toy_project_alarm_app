import 'package:flutter_tts/flutter_tts.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'tts_service.g.dart';

@riverpod
TtsService ttsService(Ref ref) {
  return TtsService();
}

class TtsService {
  final FlutterTts _flutterTts = FlutterTts();

  TtsService() {
    _initTts();
  }

  Future<void> _initTts() async {
    // 1. 언어 설정 (한국어)
    await _flutterTts.setLanguage("ko-KR");

    // 2. 목소리 톤/속도 설정 (자연스럽게 조절)
    await _flutterTts.setSpeechRate(0.5); // 0.0 ~ 1.0
    await _flutterTts.setVolume(1.0);
    await _flutterTts.setPitch(1.0);

    // iOS의 경우 무음 모드에서도 소리가 나도록 설정
    await _flutterTts
        .setIosAudioCategory(IosTextToSpeechAudioCategory.playback, [
          IosTextToSpeechAudioCategoryOptions.allowBluetooth,
          IosTextToSpeechAudioCategoryOptions.allowBluetoothA2DP,
          IosTextToSpeechAudioCategoryOptions.mixWithOthers,
          IosTextToSpeechAudioCategoryOptions.defaultToSpeaker,
        ]);
  }

  // 텍스트 읽기
  Future<void> speak(String text) async {
    if (text.isNotEmpty) {
      await _flutterTts.speak(text);
    }
  }

  // 멈추기 (알람 해제 시 사용)
  Future<void> stop() async {
    await _flutterTts.stop();
  }
}
