package com.kurban.flutter_vap_plugin

import android.content.Context
import android.view.View
import com.tencent.qgame.animplayer.AnimView
import com.tencent.qgame.animplayer.inter.IAnimListener
import com.tencent.qgame.animplayer.util.ScaleType
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.StandardMessageCodec
import io.flutter.plugin.platform.PlatformView
import io.flutter.plugin.platform.PlatformViewFactory
import java.io.File
import android.net.Uri
import android.util.Log
import java.io.FileOutputStream
import java.net.URL

class FlutterVapView(
    private val context: Context,
    private val messenger: BinaryMessenger,
    private val viewId: Int,
    private val params: Map<String, Any>?
) : PlatformView, IAnimListener {

    private var animView: AnimView = AnimView(context)
    private val methodChannel: MethodChannel = MethodChannel(messenger, "flutter_vap_plugin_$viewId")
    private val autoPlay: Boolean = params?.get("autoPlay") as? Boolean ?: true
    private val mainHandler = android.os.Handler(android.os.Looper.getMainLooper())
    private var lastPlayedFile: File? = null
    private var destroyed = false

    init {
        // 设置视图布局参数，使其撑满父容器
        val layoutParams = android.widget.FrameLayout.LayoutParams(
            android.widget.FrameLayout.LayoutParams.MATCH_PARENT,
            android.widget.FrameLayout.LayoutParams.MATCH_PARENT
        )
        animView.layoutParams = layoutParams

        // 设置缩放类型为FIT_XY以撑满容器
        animView.setScaleType(ScaleType.FIT_XY)
        animView.setAnimListener(this)
        methodChannel.setMethodCallHandler { call, result ->
            when (call.method) {
                "stop" -> {
                    animView.stopPlay()
                    result.success(null)
                }
                "play" -> {
                    val path = (call.argument<String>("path"))
                    val sourceType = (call.argument<String>("sourceType"))
                    val repeatCount = call.argument<Int>("repeatCount") ?: 1
                    if (path != null && sourceType != null) {
                        playWithParams(path, sourceType, repeatCount)
                    }
                    result.success(null)
                }
                "destroy" -> {
                    destroyInstance()
                    result.success(null)
                }
                else -> result.notImplemented()
            }
        }
        if (autoPlay) {
            loadAndPlay()
        } else {
            loadOnly()
        }
    }

    private fun loadAndPlay() {
        val path = params?.get("path") as? String ?: return
        val sourceType = params?.get("sourceType") as? String ?: return

        when (sourceType) {
            "network" -> {
                Thread {
                    try {
                        val url = URL(path)
                        val connection = url.openConnection()
                        val tempFile = File(context.cacheDir, "temp_vap.mp4")

                        connection.getInputStream().use { input ->
                            FileOutputStream(tempFile).use { output ->
                                input.copyTo(output)
                            }
                        }

                        animView.post {
                            startPlay(tempFile)
                        }
                    } catch (e: Exception) {
                        Log.e("FlutterVapView", "Failed to load video", e)
                    }
                }.start()
            }
            "file" -> {
                val file = File(path)
                if (file.exists()) {
                    startPlay(file)
                }
            }
            "asset" -> {
                // TODO: Implement asset loading
            }
        }
    }

    private fun loadOnly() {
        val path = params?.get("path") as? String ?: return
        val sourceType = params?.get("sourceType") as? String ?: return

        when (sourceType) {
            "network" -> {
                Thread {
                    try {
                        val url = URL(path)
                        val connection = url.openConnection()
                        val tempFile = File(context.cacheDir, "temp_vap.mp4")

                        connection.getInputStream().use { input ->
                            FileOutputStream(tempFile).use { output ->
                                input.copyTo(output)
                            }
                        }

                        animView.post {
                            lastPlayedFile = tempFile
                        }
                    } catch (e: Exception) {
                        Log.e("FlutterVapView", "Failed to load video", e)
                    }
                }.start()
            }
            "file" -> {
                val file = File(path)
                if (file.exists()) {
                    lastPlayedFile = file
                }
            }
            "asset" -> {
                // TODO: Implement asset loading
            }
        }
    }

    private fun startPlay(file: File) {
        animView.startPlay(file)
        lastPlayedFile = file
    }

    private fun playWithParams(path: String, sourceType: String, repeatCount: Int) {
        when (sourceType) {
            "network" -> {
                Thread {
                    try {
                        val url = URL(path)
                        val connection = url.openConnection()
                        val tempFile = File(context.cacheDir, "temp_vap.mp4")
                        connection.getInputStream().use { input ->
                            FileOutputStream(tempFile).use { output ->
                                input.copyTo(output)
                            }
                        }
                        animView.post {
                            animView.startPlay(tempFile)
                            lastPlayedFile = tempFile
                        }
                    } catch (e: Exception) {
                        Log.e("FlutterVapView", "Failed to load video", e)
                    }
                }.start()
            }
            "file" -> {
                val file = File(path)
                if (file.exists()) {
                    animView.startPlay(file)
                    lastPlayedFile = file
                }
            }
            "asset" -> {
                // TODO: Implement asset loading
            }
        }
    }

    private fun destroyInstance() {
        if (!destroyed) {
            animView.stopPlay()
            destroyed = true
        }
    }

    override fun getView(): View {
        return animView
    }

    override fun dispose() {
        methodChannel.setMethodCallHandler(null)
    }

    // IAnimListener implementations
    override fun onVideoConfigReady(config: com.tencent.qgame.animplayer.AnimConfig): Boolean {
        mainHandler.post {
            methodChannel.invokeMethod("onVideoConfigReady", null)
        }
        return true
    }

    override fun onVideoStart() {
        mainHandler.post {
            methodChannel.invokeMethod("onVideoStart", null)
        }
    }

    override fun onVideoRender(frameIndex: Int, config: com.tencent.qgame.animplayer.AnimConfig?) {
        mainHandler.post {
            methodChannel.invokeMethod("onVideoRender", mapOf("frameIndex" to frameIndex))
        }
    }

    override fun onVideoComplete() {
        mainHandler.post {
            methodChannel.invokeMethod("onVideoComplete", null)
        }
    }

    override fun onVideoDestroy() {
        mainHandler.post {
            methodChannel.invokeMethod("onVideoDestroy", null)
        }
    }

    override fun onFailed(errorType: Int, errorMsg: String?) {
        mainHandler.post {
            methodChannel.invokeMethod("onFailed", mapOf(
                "errorType" to errorType,
                "errorMsg" to (errorMsg ?: "")
            ))
        }
    }
}

class FlutterVapViewFactory(
    private val context: Context,
    private val messenger: BinaryMessenger
) : PlatformViewFactory(StandardMessageCodec.INSTANCE) {
    override fun create(context: Context, viewId: Int, args: Any?): PlatformView {
        val params = args as? Map<String, Any>
        return FlutterVapView(context, messenger, viewId, params)
    }
}
