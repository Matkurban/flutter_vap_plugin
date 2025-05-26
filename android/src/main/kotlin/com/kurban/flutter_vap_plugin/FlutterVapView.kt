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
import io.flutter.FlutterInjector
import java.io.IOException

class FlutterVapView(
    private val context: Context,
    private val messenger: BinaryMessenger,
    private val viewId: Int,
    private val params: Map<String, Any>?
) : PlatformView, IAnimListener {

    private var animView: AnimView = AnimView(context)
    private val methodChannel: MethodChannel = MethodChannel(messenger, "flutter_vap_plugin_$viewId")
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
                else -> result.notImplemented()
            }
        }
    }

    private fun loadAsset(assetPath: String): File? {
        try {
            // 获取 Flutter 的 asset 加载器
            val loader = FlutterInjector.instance().flutterLoader()
            // 获取资源的完整路径
            val key = loader.getLookupKeyForAsset(assetPath)
            // 打开资源文件
            context.assets.open(key).use { inputStream ->
                // 创建临时文件
                val tempFile = File.createTempFile("vap_", null, context.cacheDir)
                // 将资源写入临时文件
                FileOutputStream(tempFile).use { outputStream ->
                    inputStream.copyTo(outputStream)
                }
                return tempFile
            }
        } catch (e: Exception) {
            Log.e("FlutterVapView", "Failed to load asset: $assetPath", e)
            mainHandler.post {
                methodChannel.invokeMethod("onFailed", mapOf(
                    "errorType" to -1,
                    "errorMsg" to "Failed to load asset: ${e.message}"
                ))
            }
            return null
        }
    }

    private fun startPlay(file: File) {
        animView.startPlay(file)
        lastPlayedFile = file
    }

    private fun playWithParams(path: String, sourceType: String, repeatCount: Int) {
        try {
            when (sourceType) {
                "file" -> {
                    val file = File(path)
                    if (file.exists()) {
                        animView.setLoop(repeatCount)
                        animView.startPlay(file)
                        lastPlayedFile = file
                    } else {
                        onFailed(-1, "File does not exist: $path")
                    }
                }
                "asset" -> {
                    loadAsset(path)?.let { file ->
                        try {
                            animView.setLoop(repeatCount)
                            animView.startPlay(file)
                            file.deleteOnExit() // 确保临时文件会被清理
                        } catch (e: Exception) {
                            onFailed(-1, "Failed to play asset: ${e.message}")
                            file.delete() // 出错时立即删除临时文件
                        }
                    }
                }
                else -> {
                    onFailed(-1, "Unsupported source type: $sourceType")
                }
            }
        } catch (e: Exception) {
            onFailed(-1, "Playback error: ${e.message}")
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
        try {
            animView.stopPlay()
            methodChannel.setMethodCallHandler(null)
            lastPlayedFile?.delete() // 清理最后播放的临时文件
        } catch (e: Exception) {
            Log.e("FlutterVapView", "Error during dispose", e)
        }
    }

    override fun onVideoStart() {
        if (!destroyed) {
            mainHandler.post {
                methodChannel.invokeMethod("onVideoStart", null)
            }
        }
    }

    override fun onVideoRender(frameIndex: Int, config: com.tencent.qgame.animplayer.AnimConfig?) {
        if (!destroyed) {
            mainHandler.post {
                methodChannel.invokeMethod("onVideoRender", mapOf("frameIndex" to frameIndex))
            }
        }
    }

    override fun onVideoComplete() {
        if (!destroyed) {
            mainHandler.post {
                methodChannel.invokeMethod("onVideoFinish", null)
            }
        }
    }

    override fun onVideoDestroy() {
        mainHandler.post {
            methodChannel.invokeMethod("onVideoStop", null)
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
