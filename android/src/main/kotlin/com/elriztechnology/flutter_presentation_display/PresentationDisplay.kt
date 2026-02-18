package com.elriztechnology.flutter_presentation_display

import android.app.Presentation
import android.content.Context
import android.os.Bundle
import android.util.Log
import android.view.Display
import android.view.ViewGroup
import android.widget.FrameLayout
import io.flutter.embedding.android.FlutterView
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.embedding.engine.FlutterEngineCache
import io.flutter.plugin.common.MethodChannel
import android.view.WindowManager
import android.os.Build

class PresentationDisplay(
    context: Context,
    private val tag: String,
    display: Display,
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
        val windowType = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            WindowManager.LayoutParams.TYPE_APPLICATION_OVERLAY
        } else {
            @Suppress("DEPRECATION")
            WindowManager.LayoutParams.TYPE_SYSTEM_OVERLAY
        }
        
        window?.setType(windowType)
        
        super.onCreate(savedInstanceState)

        val container = FrameLayout(context).apply {
            layoutParams = FrameLayout.LayoutParams(
                ViewGroup.LayoutParams.MATCH_PARENT,
                ViewGroup.LayoutParams.MATCH_PARENT
            )
        }

        setContentView(container)

        val flutterEngine = FlutterEngineCache.getInstance().get(tag)
        if (flutterEngine == null) {
            Log.e(TAG, "FlutterEngine not found in cache with tag: $tag")
            return
        }

        setupFlutterView(container, flutterEngine)
        setupMethodChannel(flutterEngine)
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