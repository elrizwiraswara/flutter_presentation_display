package com.elriztechnology.flutter_presentation_display

import android.app.Presentation
import android.content.Context
import android.os.Bundle
import android.util.Log
import android.view.Display
import android.view.ViewGroup
import android.widget.FrameLayout
import io.flutter.embedding.android.FlutterView
import io.flutter.embedding.engine.FlutterEngineCache
import io.flutter.plugin.common.MethodChannel


class PresentationDisplay(
        context: Context,
        private val tag: String,
        display: Display,
        private val callBack: (Any?) -> Unit
) : Presentation(context, display) {

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)

        // Create FrameLayout container
        val flContainer = FrameLayout(context)
        val params = FrameLayout.LayoutParams(
                ViewGroup.LayoutParams.MATCH_PARENT,
                ViewGroup.LayoutParams.MATCH_PARENT
        )
        flContainer.layoutParams = params

        setContentView(flContainer)

        // Initialize FlutterView and attach it to the FrameLayout
        val flutterView = FlutterView(context)
        flContainer.addView(flutterView, params)

        // Retrieve FlutterEngine from cache
        val flutterEngine = FlutterEngineCache.getInstance().get(tag)
        if (flutterEngine != null) {
            flutterView.attachToFlutterEngine(flutterEngine)

            // Set up MethodChannel communication
            MethodChannel(
                    flutterEngine.dartExecutor.binaryMessenger,
                    "main_display_channel"
            ).setMethodCallHandler { call, result ->
                Log.i("PresentationDisplay", "Method: ${call.method}, Arguments: ${call.arguments}, Callback: $callBack")
                if (call.method == "transferDataToMain") {
                    callBack(call.arguments) // Invoke the callback
                } else {
                    result.notImplemented()
                }
            }
        } else {
            Log.e("PresentationDisplay", "Can't find the FlutterEngine with cache name $tag")
        }
    }
}
