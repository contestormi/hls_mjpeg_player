package com.example.hls_mjpeg_player

import android.annotation.SuppressLint
import android.content.Context
import android.graphics.Bitmap
import android.graphics.Canvas
import android.view.MotionEvent
import android.view.View
import android.webkit.WebResourceError
import android.webkit.WebResourceRequest
import android.webkit.WebView
import android.webkit.WebViewClient
import android.widget.FrameLayout
import android.widget.ImageView
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result
import io.flutter.plugin.common.StandardMessageCodec
import io.flutter.plugin.platform.PlatformView
import io.flutter.plugin.platform.PlatformViewFactory
import android.util.Log

class HlsMjpegPlayerPlugin : FlutterPlugin {
    override fun onAttachedToEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        binding
            .platformViewRegistry
            .registerViewFactory(
                "HlsMjpegPlayer",
                HlsMjpegPlayerFactory(binding)
            )
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {}
}

class HlsMjpegPlayerFactory(private val binding: FlutterPlugin.FlutterPluginBinding) :
    PlatformViewFactory(StandardMessageCodec.INSTANCE) {
    override fun create(
        context: Context,
        viewId: Int,
        args: Any?
    ): PlatformView {
        val creationParams = args as Map<String?, Any?>?
        return HlsMjpegPlayerView(context, binding, creationParams)
    }
}

@SuppressLint("ClickableViewAccessibility")
internal class HlsMjpegPlayerView(
    context: Context,
    binding: FlutterPlugin.FlutterPluginBinding,
    params: Map<String?, Any?>?
) : PlatformView, MethodCallHandler, WebViewClient() {
    private var mChannel: MethodChannel
    private var mainView: FrameLayout
    private var imageView: ImageView
    private var webView: WebView
    private var myResult: MethodChannel.Result? = null

    override fun getView(): View {
        return mainView
    }

    override fun dispose() {
        mChannel.setMethodCallHandler(null)
        webView.stopLoading()
        webView.clearCache(true)
        webView.clearHistory()
    }

    init {
        mChannel = MethodChannel(
            binding.binaryMessenger,
            "com.example.hls_mjpeg_player"
        )
        mChannel.setMethodCallHandler(this)
        webView = WebView(context)
        webView.webViewClient = this
        webView.settings.loadWithOverviewMode = true;
        webView.settings.useWideViewPort = true
        webView.setOnTouchListener { _, event -> event.action == MotionEvent.ACTION_MOVE }
        imageView = ImageView(context)
        mainView = FrameLayout(context)
        mainView.addView(webView)
        mainView.addView(imageView)
        loadUrl(params)
    }

    override fun onReceivedError(
        view: WebView?,
        request: WebResourceRequest?,
        error: WebResourceError?
    ) {
        super.onReceivedError(view, request, error)
        val isBlank = webView.url?.contains("blank") ?: false
        if (isBlank) {
            return
        }
        val arg = mapOf("status" to "Error")
        mChannel.invokeMethod("onStatusChange", arg)
    }

    override fun onPageCommitVisible(view: WebView?, url: String?) {
        super.onPageCommitVisible(view, url)
        val isBlank = webView.url?.contains("blank") ?: false
        val arg = mapOf("status" to if (isBlank) "Pause" else "Play")
        mChannel.invokeMethod("onStatusChange", arg)
        imageView.visibility = if (isBlank) View.VISIBLE else View.INVISIBLE
        myResult?.success("$url Loaded")
    }

    override fun onMethodCall(call: MethodCall, result: Result) {
        myResult = result
        when (call.method) {
            "play" -> loadUrl(call.arguments())
            "pause" -> pause()
            else -> result.notImplemented()
        }
    }

    private fun loadUrl(
        params: Map<String?, Any?>?,
    ) {
        val arg = mapOf("status" to "Loading")
        mChannel.invokeMethod("onStatusChange", arg)

        val initialUrl = params?.get("url") as String? ?: ""

        if (initialUrl.isNotEmpty()) {
            webView.loadUrl(initialUrl)
        }
    }

    private fun pause() {
        val isBlank = webView.url?.contains("blank") ?: false
        if (isBlank) {
            return
        }

        val bitmap = Bitmap.createBitmap(
            webView.width,
            webView.height,
            Bitmap.Config.ARGB_8888
        )
        val canvas = Canvas(bitmap)
        webView.draw(canvas)
        imageView.setImageBitmap(bitmap)

        webView.stopLoading()
        webView.loadUrl("about:blank")
    }
}