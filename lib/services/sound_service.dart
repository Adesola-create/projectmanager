import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/services.dart';

class SoundService {
  static final AudioPlayer _audioPlayer = AudioPlayer();

  static Future<void> playSuccessSound() async {
    try {
      await _audioPlayer.play(AssetSource('sounds/success.mp3'));
    } catch (e) {
      print('Could not play success sound: $e');
      HapticFeedback.lightImpact();
    }
  }

  static Future<void> playClockInSound() async {
    try {
      await _audioPlayer.play(AssetSource('sounds/clock_in.mp3'));
    } catch (e) {
      print('Could not play clock in sound: $e');
      HapticFeedback.lightImpact();
    }
  }

  static Future<void> playClockOutSound() async {
    try {
      await _audioPlayer.play(AssetSource('sounds/clock_out.mp3'));
    } catch (e) {
      print('Could not play clock out sound: $e');
      HapticFeedback.lightImpact();
    }
  }

  static Future<void> playErrorSound() async {
    try {
      await _audioPlayer.play(AssetSource('sounds/error.mp3'));
    } catch (e) {
      print('Could not play error sound: $e');
      HapticFeedback.heavyImpact();
    }
  }

  static void dispose() {
    _audioPlayer.dispose();
  }
}
