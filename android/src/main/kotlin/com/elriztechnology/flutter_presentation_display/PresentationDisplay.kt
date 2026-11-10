package com.elriztechnology.flutter_presentation_display

import android.app.Presentation
import android.content.Context
import android.os.Build
import android.os.Bundle
import android.util.Log
import android.view.Display
import android.view.View
import android.view.ViewGroup
import android.view.WindowInsets
import android.view.WindowInsetsController
import android.view.WindowManager
import android.widget.FrameLayout
import io.flutter.embedding.android.FlutterView
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.embedding.engine.FlutterEngineCache
import io.flutter.plugin.common.MethodChannel

class PresentationDisplay(
    context: Context,
    private val tag: String,
    display: Display,
    private val fullscreen: Boolean,
    private val dataCallback: (Any?) -> Unit
) : Presentation(context, display) {

    private var flutterView: FlutterView? = null
    private var methodChannel: MethodChannel? = null

    companion object {
        private const val TAG = "PresentationDisplay"
        private const val CHANNEL_NAME = "main_display_channel"
        private const val METHOD_TRANSFER_DATA = "transferDataToMain"
    }

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)

        val container = FrameLayout(context).apply {
            layoutParams = FrameLayout.LayoutParams(
                ViewGroup.LayoutParams.MATCH_PARENT,
                ViewGroup.LayoutParams.MATCH_PARENT
            )
        }

        setContentView(container)

        if (fullscreen) hideSystemBars()

        val flutterEngine = FlutterEngineCache.getInstance().get(tag)
        if (flutterEngine == null) {
            Log.e(TAG, "FlutterEngine not found in cache with tag: $tag")
            return
        }

        setupFlutterView(container, flutterEngine)
        setupMethodChannel(flutterEngine)
    }

    /// Hides the system bars the secondary display may show, such as a
    /// navigation bar or a desktop-style taskbar, and draws under any cutout.
    private fun hideSystemBars() {
        val window = window ?: return

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.P) {
            window.attributes = window.attributes.apply {
                layoutInDisplayCutoutMode = WindowManager.LayoutParams.LAYOUT_IN_DISPLAY_CUTOUT_MODE_SHORT_EDGES
            }
        }

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.R) {
            window.setDecorFitsSystemWindows(false)
            window.insetsController?.let {
                it.hide(WindowInsets.Type.systemBars())
                it.systemBarsBehavior = WindowInsetsController.BEHAVIOR_SHOW_TRANSIENT_BARS_BY_SWIPE
            }
        } else {
            @Suppress("DEPRECATION")
            window.addFlags(WindowManager.LayoutParams.FLAG_FULLSCREEN)
            @Suppress("DEPRECATION")
            window.decorView.systemUiVisibility = (
                View.SYSTEM_UI_FLAG_FULLSCREEN
                    or View.SYSTEM_UI_FLAG_HIDE_NAVIGATION
                    or View.SYSTEM_UI_FLAG_IMMERSIVE_STICKY
                    or View.SYSTEM_UI_FLAG_LAYOUT_STABLE
                    or View.SYSTEM_UI_FLAG_LAYOUT_HIDE_NAVIGATION
                    or View.SYSTEM_UI_FLAG_LAYOUT_FULLSCREEN
            )
        }
    }

    private fun setupFlutterView(container: FrameLayout, flutterEngine: FlutterEngine) {
        flutterView = FlutterView(context).apply {
            val params = FrameLayout.LayoutParams(
                ViewGroup.LayoutParams.MATCH_PARENT,
                ViewGroup.LayoutParams.MATCH_PARENT
            )
            container.addView(this, params)
            attachToFlutterEngine(flutterEngine)
        }
    }

    private fun setupMethodChannel(flutterEngine: FlutterEngine) {
        methodChannel = MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            CHANNEL_NAME
        ).apply {
            setMethodCallHandler { call, result ->
                when (call.method) {
                    METHOD_TRANSFER_DATA -> {
                        Log.d(TAG, "Transferring data to main: ${call.arguments}")
                        dataCallback(call.arguments)
                        result.success(null)
                    }
                    else -> {
                        Log.w(TAG, "Unhandled method: ${call.method}")
                        result.notImplemented()
                    }
                }
            }
        }
    }

    override fun onStop() {
        super.onStop()
        cleanup()
    }

    override fun dismiss() {
        cleanup()
        super.dismiss()
    }

    private fun cleanup() {
        methodChannel?.setMethodCallHandler(null)
        methodChannel = null
        
        flutterView?.detachFromFlutterEngine()
        flutterView = null
    }
}