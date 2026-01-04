import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:share_plus/share_plus.dart';
import 'package:video_player/video_player.dart';

import 'screen_recorder_channel.dart';

class RecorderScreen extends StatefulWidget {
  const RecorderScreen({super.key});

  @override
  State<RecorderScreen> createState() => _RecorderScreenState();
}

class _RecorderScreenState extends State<RecorderScreen> {
  final _recorder = ScreenRecorderChannel();

  RecordingState _state = RecordingState.idle;
  String? _lastFilePath;

  Timer? _timer;
  Duration _elapsed = Duration.zero;

  VideoPlayerController? _videoController;

  @override
  void dispose() {
    _timer?.cancel();
    _videoController?.dispose();
    super.dispose();
  }

  Future<void> _ensurePermissions() async {
    final mic = await Permission.microphone.request();
    if (!mic.isGranted) {
      throw Exception('Microphone permission denied');
    }
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      setState(() {
        _elapsed += const Duration(seconds: 1);
      });
    });
  }

  void _stopTimer() {
    _timer?.cancel();
    _timer = null;
  }

  String _format(Duration d) {
    String two(int n) => n.toString().padLeft(2, '0');
    final h = d.inHours;
    final m = d.inMinutes.remainder(60);
    final s = d.inSeconds.remainder(60);
    return h > 0 ? '${two(h)}:${two(m)}:${two(s)}' : '${two(m)}:${two(s)}';
  }

  Future<void> _start() async {
    await _ensurePermissions();

    await _recorder.startRecording(
      const StartRecordingOptions(
        includeMicrophoneAudio: true,
        width: 1280,
        height: 720,
        fps: 30,
        bitrate: 8 * 1000 * 1000,
      ),
    );

    setState(() {
      _state = RecordingState.recording;
      _elapsed = Duration.zero;
      _lastFilePath = null;
    });
    _videoController?.dispose();
    _videoController = null;
    _startTimer();
  }

  Future<void> _stop() async {
    final path = await _recorder.stopRecording();

    _stopTimer();

    setState(() {
      _state = RecordingState.idle;
      _lastFilePath = path;
    });

    if (path != null && mounted) {
      final file = File(path);
      if (await file.exists()) {
        final controller = VideoPlayerController.file(file);
        await controller.initialize();
        setState(() {
          _videoController?.dispose();
          _videoController = controller;
        });
      }
    }
  }

  Future<void> _pause() async {
    await _recorder.pauseRecording();
    _stopTimer();
    setState(() {
      _state = RecordingState.paused;
    });
  }

  Future<void> _resume() async {
    await _recorder.resumeRecording();
    setState(() {
      _state = RecordingState.recording;
    });
    _startTimer();
  }

  Future<void> _share() async {
    final path = _lastFilePath;
    if (path == null) return;
    await Share.shareXFiles([XFile(path)]);
  }

  @override
  Widget build(BuildContext context) {
    final isRecording = _state == RecordingState.recording;
    final isPaused = _state == RecordingState.paused;

    return Scaffold(
      appBar: AppBar(title: const Text('EasyRec')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              _format(_elapsed),
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.displaySmall,
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: isRecording || isPaused
                        ? null
                        : () async {
                            try {
                              await _start();
                            } catch (e) {
                              if (!context.mounted) return;
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text(e.toString())),
                              );
                            }
                          },
                    child: const Text('Start'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: isRecording || isPaused
                        ? () async {
                            try {
                              await _stop();
                            } catch (e) {
                              if (!context.mounted) return;
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text(e.toString())),
                              );
                            }
                          }
                        : null,
                    child: const Text('Stop'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: isRecording
                        ? () async {
                            try {
                              await _pause();
                            } catch (e) {
                              if (!context.mounted) return;
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text(e.toString())),
                              );
                            }
                          }
                        : null,
                    child: const Text('Pause'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton(
                    onPressed: isPaused
                        ? () async {
                            try {
                              await _resume();
                            } catch (e) {
                              if (!context.mounted) return;
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text(e.toString())),
                              );
                            }
                          }
                        : null,
                    child: const Text('Resume'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (_lastFilePath != null) ...[
              Text(
                'Saved: ${_lastFilePath!}',
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(height: 8),
              FilledButton(onPressed: _share, child: const Text('Share')),
              const SizedBox(height: 16),
            ],
            if (_videoController != null) ...[
              AspectRatio(
                aspectRatio: _videoController!.value.aspectRatio,
                child: VideoPlayer(_videoController!),
              ),
              const SizedBox(height: 8),
              FilledButton(
                onPressed: () {
                  final vc = _videoController!;
                  if (vc.value.isPlaying) {
                    vc.pause();
                  } else {
                    vc.play();
                  }
                  setState(() {});
                },
                child: Text(
                  _videoController!.value.isPlaying
                      ? 'Pause Preview'
                      : 'Play Preview',
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
