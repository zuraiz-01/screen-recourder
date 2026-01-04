package com.example.screen_recourder

import android.app.Activity
import android.content.Intent
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
  private val channelName = "easyrec/screen_recorder"
  private val screenCaptureRequestCode = 4932

  private lateinit var recorderManager: ScreenRecorderManager

  private var pendingStartResult: MethodChannel.Result? = null
  private var pendingIncludeMic: Boolean = true
  private var pendingWidth: Int? = null
  private var pendingHeight: Int? = null
  private var pendingFps: Int? = null
  private var pendingBitrate: Int? = null

  override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
    super.configureFlutterEngine(flutterEngine)

    recorderManager = ScreenRecorderManager(this)

    MethodChannel(flutterEngine.dartExecutor.binaryMessenger, channelName)
      .setMethodCallHandler { call, result ->
        when (call.method) {
          "startRecording" -> {
            if (pendingStartResult != null) {
              result.error("IN_PROGRESS", "A startRecording request is already in progress", null)
              return@setMethodCallHandler
            }

            @Suppress("UNCHECKED_CAST")
            val args = call.arguments as? Map<String, Any?>

            pendingIncludeMic = (args?.get("includeMicrophoneAudio") as? Boolean) ?: true
            pendingWidth = (args?.get("width") as? Int)
            pendingHeight = (args?.get("height") as? Int)
            pendingFps = (args?.get("fps") as? Int)
            pendingBitrate = (args?.get("bitrate") as? Int)

            pendingStartResult = result
            try {
              val intent = recorderManager.createScreenCaptureIntent()
              startActivityForResult(intent, screenCaptureRequestCode)
            } catch (e: Exception) {
              pendingStartResult = null
              result.error("START_FAILED", e.message, null)
            }
          }

          "stopRecording" -> {
            try {
              val path = recorderManager.stop()
              result.success(path)
            } catch (e: Exception) {
              result.error("STOP_FAILED", e.message, null)
            }
          }

          "pauseRecording" -> {
            try {
              recorderManager.pause()
              result.success(null)
            } catch (e: Exception) {
              result.error("PAUSE_FAILED", e.message, null)
            }
          }

          "resumeRecording" -> {
            try {
              recorderManager.resume()
              result.success(null)
            } catch (e: Exception) {
              result.error("RESUME_FAILED", e.message, null)
            }
          }

          "getStatus" -> {
            result.success(recorderManager.getStatus())
          }

          else -> result.notImplemented()
        }
      }
  }

  @Deprecated("Deprecated in Java")
  override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
    super.onActivityResult(requestCode, resultCode, data)

    if (requestCode != screenCaptureRequestCode) return

    val pending = pendingStartResult ?: return
    pendingStartResult = null

    if (resultCode != Activity.RESULT_OK || data == null) {
      pending.error("USER_CANCELLED", "Screen capture permission was denied", null)
      return
    }

    try {
      recorderManager.startFromResult(
        resultCode = resultCode,
        data = data,
        includeMicrophoneAudio = pendingIncludeMic,
        width = pendingWidth,
        height = pendingHeight,
        fps = pendingFps,
        bitrate = pendingBitrate
      )
      pending.success(null)
    } catch (e: Exception) {
      pending.error("START_FAILED", e.message, null)
    }
  }
}
