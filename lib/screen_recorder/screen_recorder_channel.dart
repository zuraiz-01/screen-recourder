import 'dart:async';

import 'package:flutter/services.dart';

enum RecordingState { idle, recording, paused }

class StartRecordingOptions {
  const StartRecordingOptions({
    this.includeMicrophoneAudio = true,
    this.width,
    this.height,
    this.fps,
    this.bitrate,
  });

  final bool includeMicrophoneAudio;
  final int? width;
  final int? height;
  final int? fps;
  final int? bitrate;

  Map<String, Object?> toMap() => {
    'includeMicrophoneAudio': includeMicrophoneAudio,
    'width': width,
    'height': height,
    'fps': fps,
    'bitrate': bitrate,
  };
}

class ScreenRecorderChannel {
  static const MethodChannel _channel = MethodChannel(
    'easyrec/screen_recorder',
  );

  Future<void> startRecording(StartRecordingOptions options) async {
    await _channel.invokeMethod<void>('startRecording', options.toMap());
  }

  Future<String?> stopRecording() async {
    return _channel.invokeMethod<String>('stopRecording');
  }

  Future<void> pauseRecording() async {
    await _channel.invokeMethod<void>('pauseRecording');
  }

  Future<void> resumeRecording() async {
    await _channel.invokeMethod<void>('resumeRecording');
  }

  Future<String> getStatus() async {
    return (await _channel.invokeMethod<String>('getStatus')) ?? 'idle';
  }
}
