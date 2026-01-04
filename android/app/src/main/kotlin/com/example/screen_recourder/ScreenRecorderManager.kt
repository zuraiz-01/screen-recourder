package com.example.screen_recourder

import android.content.Context
import android.content.Intent
import android.hardware.display.DisplayManager
import android.hardware.display.VirtualDisplay
import android.media.MediaRecorder
import android.media.projection.MediaProjection
import android.media.projection.MediaProjectionManager
import android.os.Build
import android.util.DisplayMetrics
import android.view.WindowManager
import java.io.File

class ScreenRecorderManager(private val context: Context) {
  private val mediaProjectionManager: MediaProjectionManager =
    context.getSystemService(Context.MEDIA_PROJECTION_SERVICE) as MediaProjectionManager

  private var mediaProjection: MediaProjection? = null
  private var mediaRecorder: MediaRecorder? = null
  private var virtualDisplay: VirtualDisplay? = null

  private var outputFile: File? = null
  private var state: String = "idle"

  fun createScreenCaptureIntent(): Intent = mediaProjectionManager.createScreenCaptureIntent()

  fun getStatus(): String = state

  fun startFromResult(
    resultCode: Int,
    data: Intent,
    includeMicrophoneAudio: Boolean,
    width: Int?,
    height: Int?,
    fps: Int?,
    bitrate: Int?
  ) {
    if (state != "idle") {
      throw IllegalStateException("Already recording")
    }

    val projection = mediaProjectionManager.getMediaProjection(resultCode, data)
      ?: throw IllegalStateException("Failed to get MediaProjection")
    mediaProjection = projection

    val (w, h, densityDpi) = getRecordingMetrics(width, height)

    val file = createOutputFile()
    outputFile = file

    val recorder = MediaRecorder()
    if (includeMicrophoneAudio) {
      recorder.setAudioSource(MediaRecorder.AudioSource.MIC)
    }
    recorder.setVideoSource(MediaRecorder.VideoSource.SURFACE)
    recorder.setOutputFormat(MediaRecorder.OutputFormat.MPEG_4)
    recorder.setOutputFile(file.absolutePath)

    recorder.setVideoEncoder(MediaRecorder.VideoEncoder.H264)
    recorder.setVideoSize(w, h)
    recorder.setVideoFrameRate(fps ?: 30)
    recorder.setVideoEncodingBitRate(bitrate ?: (8 * 1000 * 1000))

    if (includeMicrophoneAudio) {
      recorder.setAudioEncoder(MediaRecorder.AudioEncoder.AAC)
      recorder.setAudioEncodingBitRate(128000)
      recorder.setAudioSamplingRate(44100)
    }

    recorder.prepare()

    val surface = recorder.surface
    val vd = projection.createVirtualDisplay(
      "EasyRecRecorder",
      w,
      h,
      densityDpi,
      DisplayManager.VIRTUAL_DISPLAY_FLAG_AUTO_MIRROR,
      surface,
      null,
      null
    )

    virtualDisplay = vd
    mediaRecorder = recorder

    recorder.start()
    state = "recording"
  }

  fun pause() {
    if (state != "recording") return
    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.N) {
      mediaRecorder?.pause()
      state = "paused"
    } else {
      throw UnsupportedOperationException("Pause is not supported on this Android version")
    }
  }

  fun resume() {
    if (state != "paused") return
    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.N) {
      mediaRecorder?.resume()
      state = "recording"
    } else {
      throw UnsupportedOperationException("Resume is not supported on this Android version")
    }
  }

  fun stop(): String? {
    if (state == "idle") return null

    try {
      mediaRecorder?.stop()
    } finally {
      mediaRecorder?.reset()
      mediaRecorder?.release()
      mediaRecorder = null

      virtualDisplay?.release()
      virtualDisplay = null

      mediaProjection?.stop()
      mediaProjection = null

      state = "idle"
    }

    return outputFile?.absolutePath
  }

  private fun getRecordingMetrics(width: Int?, height: Int?): Triple<Int, Int, Int> {
    val wm = context.getSystemService(Context.WINDOW_SERVICE) as WindowManager
    val dm = DisplayMetrics()
    @Suppress("DEPRECATION")
    wm.defaultDisplay.getRealMetrics(dm)

    val densityDpi = dm.densityDpi
    val w = width ?: dm.widthPixels
    val h = height ?: dm.heightPixels
    return Triple(w, h, densityDpi)
  }

  private fun createOutputFile(): File {
    val dir = context.getExternalFilesDir(null) ?: context.filesDir
    val outDir = File(dir, "recordings")
    if (!outDir.exists()) {
      outDir.mkdirs()
    }
    val fileName = "easyrec_${System.currentTimeMillis()}.mp4"
    return File(outDir, fileName)
  }
}
