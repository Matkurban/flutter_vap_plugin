package com.kurban.flutter_vap_plugin

import android.content.Context
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.StandardMessageCodec
import io.flutter.plugin.platform.PlatformView
import io.flutter.plugin.platform.PlatformViewFactory

/**
 *
 * @author matkurban
 * @contact QQ 3496354336
 * @date 2025/5/27 16:08
 */
class FlutterVapViewFactory(private val messenger: BinaryMessenger) : PlatformViewFactory(
    StandardMessageCodec.INSTANCE) {
    override fun create(context: Context, viewId: Int, args: Any?): PlatformView {
        return FlutterVapView(context, messenger, viewId,args)
    }
}