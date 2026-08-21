import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';

class AudioService {
  static final AudioService _instance = AudioService._internal();
  factory AudioService() => _instance;
  AudioService._internal();

  AudioPlayer? _player;
  bool _isPlaying = false;

  bool get isPlaying => _isPlaying;

  AudioPlayer _getPlayer() {
    _player ??= AudioPlayer();
    return _player!;
  }

  // Reliable high-quality online fallback sound CDN URIs
  static const String _newOrderAlarmUrl =
      'https://actions.google.com/sounds/v1/alarms/alarm_clock.ogg';
  static const String _deliveryRequestUrl =
      'https://actions.google.com/sounds/v1/cartoon/pop.ogg';
  static const String _orderSuccessUrl =
      'https://actions.google.com/sounds/v1/cartoon/clang_and_wobble.ogg';
  static const String _chimeNotificationUrl =
      'https://actions.google.com/sounds/v1/cartoon/concussive_drum_hit.ogg';

  /// Plays a continuous or single chime for incoming orders (Dealers / Vendors)
  Future<void> playNewOrderAlert({bool loop = true, double volume = 1.0}) async {
    try {
      final player = _getPlayer();
      await player.stop();
      await player.setVolume(volume);
      if (loop) {
        await player.setReleaseMode(ReleaseMode.loop);
      } else {
        await player.setReleaseMode(ReleaseMode.release);
      }
      await player.play(UrlSource(_newOrderAlarmUrl));
      _isPlaying = true;
      debugPrint('🔔 [AudioService] Playing New Order Alert (loop: $loop)');
    } catch (e) {
      debugPrint('⚠️ [AudioService] Failed to play order alert: $e');
    }
  }

  /// Plays an alert for delivery requests (Delivery Partners / Riders)
  Future<void> playDeliveryRequestAlert({bool loop = false, double volume = 1.0}) async {
    try {
      final player = _getPlayer();
      await player.stop();
      await player.setVolume(volume);
      await player.setReleaseMode(loop ? ReleaseMode.loop : ReleaseMode.release);
      await player.play(UrlSource(_deliveryRequestUrl));
      _isPlaying = true;
      debugPrint('🛵 [AudioService] Playing Delivery Request Alert');
    } catch (e) {
      debugPrint('⚠️ [AudioService] Failed to play delivery alert: $e');
    }
  }

  /// Plays a success chime on successful checkout
  Future<void> playOrderSuccessSound() async {
    try {
      final player = _getPlayer();
      await player.stop();
      await player.setReleaseMode(ReleaseMode.release);
      await player.setVolume(0.9);
      await player.play(UrlSource(_orderSuccessUrl));
      debugPrint('🎉 [AudioService] Playing Order Success Sound');
    } catch (e) {
      debugPrint('⚠️ [AudioService] Failed to play success sound: $e');
    }
  }

  /// Plays a subtle notification chime
  Future<void> playNotificationChime() async {
    try {
      final player = _getPlayer();
      await player.stop();
      await player.setReleaseMode(ReleaseMode.release);
      await player.setVolume(0.8);
      await player.play(UrlSource(_chimeNotificationUrl));
    } catch (e) {
      debugPrint('⚠️ [AudioService] Failed to play notification chime: $e');
    }
  }

  /// Stops any currently playing audio
  Future<void> stop() async {
    try {
      if (_player != null) {
        await _player!.stop();
      }
      _isPlaying = false;
      debugPrint('⏹️ [AudioService] Audio stopped');
    } catch (e) {
      debugPrint('⚠️ [AudioService] Failed to stop audio: $e');
    }
  }

  /// Dispose player
  void dispose() {
    _player?.dispose();
    _player = null;
    _isPlaying = false;
  }
}
