package com.elriztechnology.flutter_presentation_display

import android.content.Context
import android.hardware.display.DisplayManager
import android.os.Handler
import android.os.Looper
import android.util.Log
import androidx.annotation.NonNull
import com.google.gson.Gson
import io.flutter.FlutterInjector
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.embedding.engine.FlutterEngineCache
import io.flutter.embedding.engine.dart.DartExecutor
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.embedding.engine.plugins.activity.ActivityAware
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import org.json.JSONObject

class FlutterPresentationDisplayPlugin : FlutterPlugin, ActivityAware, MethodChannel.MethodCallHandler {

    private lateinit var channel: MethodChannel
    private lateinit var eventChannel: EventChannel
    private var flutterEngineChannel: MethodChannel? = null
    private var context: Context? = null
    private var presentation: PresentationDisplay? = null
    private var flutterBinding: FlutterPlugin.FlutterPluginBinding? = null
    private var displayManager: DisplayManager? = null

    companion object {
        private const val VIEW_TYPE_EVENTS_ID = "presentation_display_channel_events"
        private const val SECONDARY_VIEW_TYPE_ID = "presentation_display_channel"
        private const val MAIN_VIEW_TYPE_ID = "main_display_channel"
        private const val TAG = "PresentationPlugin"
    }

    override fun onAttachedToEngine(@NonNull flutterPluginBinding: FlutterPlugin.FlutterPluginBinding) {
        channel = MethodChannel(flutterPluginBinding.binaryMessenger, SECONDARY_VIEW_TYPE_ID)
        channel.setMethodCallHandler(this)

        displayManager = flutterPluginBinding.applicationContext
            .getSystemService(Context.DISPLAY_SERVICE) as? DisplayManager

        eventChannel = EventChannel(flutterPluginBinding.binaryMessenger, VIEW_TYPE_EVENTS_ID)
        eventChannel.setStreamHandler(DisplayConnectedStreamHandler(displayManager))
        
        flutterBinding = flutterPluginBinding
    }

    override fun onDetachedFromEngine(@NonNull binding: FlutterPlugin.FlutterPluginBinding) {
        channel.setMethodCallHandler(null)
        eventChannel.setStreamHandler(null)
        flutterBinding = null
    }

    override fun onMethodCall(@NonNull call: MethodCall, @NonNull result: MethodChannel.Result) {
        when (call.method) {
            "showPresentation" -> showPresentation(call, result)
            "hidePresentation" -> hidePresentation(result)
            "listDisplay" -> listDisplays(call, result)
            "transferDataToPresentation" -> transferDataToPresentation(call, result)
            else -> result.notImplemented()
        }
    }

    private fun showPresentation(call: MethodCall, result: MethodChannel.Result) {
        try {
            val json = JSONObject(call.arguments as String)
            Log.i(TAG, "Method: ${call.method}, Arguments: ${call.arguments}")
            
            val displayId = json.getInt("displayId")
            val tag = json.getString("routerName")
            val display = displayManager?.getDisplay(displayId)

            if (display == null) {
                result.error("DISPLAY_NOT_FOUND", "Can't find display with displayId $displayId", null)
                return
            }

            val currentContext = context
            if (currentContext == null) {
                result.error("CONTEXT_NULL", "Activity context is not available", null)
                return
            }

            val dataToMainCallback: (Any?) -> Unit = { argument ->
                flutterBinding?.let {
                    MethodChannel(it.binaryMessenger, MAIN_VIEW_TYPE_ID).invokeMethod("transferDataToMain", argument)
                }
            }

            val flutterEngine = createFlutterEngine(currentContext, tag)
            if (flutterEngine == null) {
                result.error("ENGINE_ERROR", "Failed to create FlutterEngine", null)
                return
            }

            flutterEngineChannel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, SECONDARY_VIEW_TYPE_ID)
            presentation = PresentationDisplay(currentContext, tag, display, dataToMainCallback)
            presentation?.show()
            
            result.success(true)
        } catch (e: Exception) {
            Log.e(TAG, "Error showing presentation: ${e.message}", e)
            result.error("SHOW_ERROR", e.message, null)
        }
    }

    private fun hidePresentation(result: MethodChannel.Result) {
        try {
            presentation?.dismiss()
            presentation = null
            result.success(true)
        } catch (e: Exception) {
            Log.e(TAG, "Error hiding presentation: ${e.message}", e)
            result.error("HIDE_ERROR", e.message, null)
        }
    }

    private fun listDisplays(call: MethodCall, result: MethodChannel.Result) {
        try {
            val category = call.arguments as? String
            val displays = displayManager?.getDisplays(category) ?: emptyArray()
            
            val displayList = displays.map { display ->
                DisplayModel(
                    displayId = display.displayId,
                    flags = display.flags,
                    rotation = display.rotation,
                    name = display.name
                )
            }
            
            result.success(Gson().toJson(displayList))
        } catch (e: Exception) {
            Log.e(TAG, "Error listing displays: ${e.message}", e)
            result.error("LIST_ERROR", e.message, null)
        }
    }


    private fun transferDataToPresentation(call: MethodCall, result: MethodChannel.Result) {
        try {
            flutterEngineChannel?.invokeMethod("transferDataToPresentation", call.arguments)
            result.success(true)
        } catch (e: Exception) {
            Log.e(TAG, "Error transferring data: ${e.message}", e)
            result.error("TRANSFER_ERROR", e.message, null)
        }
    }

    private fun createFlutterEngine(context: Context, tag: String): FlutterEngine? {
        var flutterEngine = FlutterEngineCache.getInstance().get(tag)
        
        if (flutterEngine == null) {
            flutterEngine = FlutterEngine(context)
            flutterEngine.navigationChannel.setInitialRoute(tag)
            
            FlutterInjector.instance().flutterLoader().startInitialization(context)
            val path = FlutterInjector.instance().flutterLoader().findAppBundlePath()
            val entrypoint = DartExecutor.DartEntrypoint(path, "secondaryDisplayMain")
            
            flutterEngine.dartExecutor.executeDartEntrypoint(entrypoint)
            flutterEngine.lifecycleChannel.appIsResumed()
            
            FlutterEngineCache.getInstance().put(tag, flutterEngine)
        }
        
        return flutterEngine
    }

    override fun onAttachedToActivity(binding: ActivityPluginBinding) {
        context = binding.activity
        displayManager = context?.getSystemService(Context.DISPLAY_SERVICE) as? DisplayManager
    }

    override fun onDetachedFromActivity() {
        context = null
    }

    override fun onReattachedToActivityForConfigChanges(binding: ActivityPluginBinding) {
        context = binding.activity
        displayManager = context?.getSystemService(Context.DISPLAY_SERVICE) as? DisplayManager
    }

    override fun onDetachedFromActivityForConfigChanges() {
        context = null
    }
}

class DisplayConnectedStreamHandler(
    private val displayManager: DisplayManager?
) : EventChannel.StreamHandler {

    private var sink: EventChannel.EventSink? = null
    
    private val displayListener = object : DisplayManager.DisplayListener {
        override fun onDisplayAdded(displayId: Int) {
            sink?.success(1)
        }

        override fun onDisplayRemoved(displayId: Int) {
            sink?.success(0)
        }

        override fun onDisplayChanged(displayId: Int) {
            // No action needed
        }
    }

    override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
        sink = events
        displayManager?.registerDisplayListener(displayListener, Handler(Looper.getMainLooper()))
    }

    override fun onCancel(arguments: Any?) {
        displayManager?.unregisterDisplayListener(displayListener)
        sink = null
    }
}