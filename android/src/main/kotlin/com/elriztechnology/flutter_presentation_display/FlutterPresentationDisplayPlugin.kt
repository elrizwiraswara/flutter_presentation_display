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
import io.flutter.plugin.common.PluginRegistry
import org.json.JSONObject

class FlutterPresentationDisplayPlugin : FlutterPlugin, ActivityAware, MethodChannel.MethodCallHandler {

  private lateinit var channel: MethodChannel
  private lateinit var eventChannel: EventChannel
  private var flutterEngineChannel: MethodChannel? = null
  private var context: Context? = null
  private var presentation: PresentationDisplay? = null
  private var flutterBinding: FlutterPlugin.FlutterPluginBinding? = null

  override fun onAttachedToEngine(
          @NonNull flutterPluginBinding: FlutterPlugin.FlutterPluginBinding
  ) {
    channel = MethodChannel(flutterPluginBinding.binaryMessenger, secondaryViewTypeId)
    channel.setMethodCallHandler(this)

    eventChannel = EventChannel(flutterPluginBinding.binaryMessenger, viewTypeEventsId)
    displayManager = flutterPluginBinding.applicationContext.getSystemService(Context.DISPLAY_SERVICE) as DisplayManager
    val displayConnectedStreamHandler = DisplayConnectedStreamHandler(displayManager)
    eventChannel.setStreamHandler(displayConnectedStreamHandler)
    flutterBinding = flutterPluginBinding
  }

  companion object {
    private const val viewTypeEventsId = "presentation_display_channel_events"
    private const val secondaryViewTypeId = "presentation_display_channel"
    private const val mainViewTypeId = "main_display_channel"

    private var displayManager: DisplayManager? = null

    @JvmStatic
    fun registerWith(registrar: PluginRegistry.Registrar) {
      val channel = MethodChannel(registrar.messenger(), secondaryViewTypeId)
      channel.setMethodCallHandler(FlutterPresentationDisplayPlugin())

      val eventChannel = EventChannel(registrar.messenger(), viewTypeEventsId)
      displayManager = registrar.activity()?.getSystemService(Context.DISPLAY_SERVICE) as DisplayManager
      val displayConnectedStreamHandler = DisplayConnectedStreamHandler(displayManager)
      eventChannel.setStreamHandler(displayConnectedStreamHandler)
    }
  }

  override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
    channel.setMethodCallHandler(null)
    eventChannel.setStreamHandler(null)
  }

  override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
    when (call.method) {
      "showPresentation" -> {
        try {
          val obj = JSONObject(call.arguments as String)
          Log.i("Plugin", "Method: ${call.method}, Arguments: ${call.arguments}")
          val displayId: Int = obj.getInt("displayId")
          val tag: String = obj.getString("routerName")
          val display = displayManager?.getDisplay(displayId)
          if (display != null) {
            val dataToMainCallback: (Any?) -> Unit = { argument ->
              flutterBinding?.let {
                MethodChannel(it.binaryMessenger, mainViewTypeId).invokeMethod("transferDataToMain", argument)
              }
            }

            val flutterEngine = createFlutterEngine(tag)
            flutterEngine?.let {
              flutterEngineChannel = MethodChannel(it.dartExecutor.binaryMessenger, secondaryViewTypeId)
              presentation = context?.let { context ->
                PresentationDisplay(context, tag, display, dataToMainCallback)
              }
              presentation?.show()
              result.success(true)
            } ?: run {
              result.error("404", "Can't find FlutterEngine", null)
            }
          } else {
            result.error("404", "Can't find display with displayId $displayId", null)
          }
        } catch (e: Exception) {
          result.error(call.method, e.message, null)
        }
      }

      "hidePresentation" -> {
        try {
          presentation?.dismiss()
          presentation = null
          result.success(true)
        } catch (e: Exception) {
          result.error(call.method, e.message, null)
        }
      }

      "listDisplay" -> {
        val displays = displayManager?.getDisplays(call.arguments as? String)
        val listJson = displays?.map { display ->
          DisplayModel(display.displayId, display.flags, display.rotation, display.name)
        }
        result.success(Gson().toJson(listJson))
      }

      "transferDataToPresentation" -> {
        try {
          flutterEngineChannel?.invokeMethod("transferDataToPresentation", call.arguments)
          result.success(true)
        } catch (e: Exception) {
          result.error("Error transferring data", e.message, null)
        }
      }

      else -> result.notImplemented()
    }
  }

  private fun createFlutterEngine(tag: String): FlutterEngine? {
    return context?.let {
      var flutterEngine = FlutterEngineCache.getInstance().get(tag)
      if (flutterEngine == null) {
        flutterEngine = FlutterEngine(it)
        flutterEngine.navigationChannel.setInitialRoute(tag)
        FlutterInjector.instance().flutterLoader().startInitialization(it)
        val path = FlutterInjector.instance().flutterLoader().findAppBundlePath()
        val entrypoint = DartExecutor.DartEntrypoint(path, "secondaryDisplayMain")
        flutterEngine.dartExecutor.executeDartEntrypoint(entrypoint)
        flutterEngine.lifecycleChannel.appIsResumed()
        FlutterEngineCache.getInstance().put(tag, flutterEngine)
      }
      flutterEngine
    }
  }

  override fun onAttachedToActivity(binding: ActivityPluginBinding) {
    context = binding.activity
    displayManager = context?.getSystemService(Context.DISPLAY_SERVICE) as DisplayManager
  }

  override fun onDetachedFromActivity() {
    context = null
  }

  override fun onReattachedToActivityForConfigChanges(binding: ActivityPluginBinding) {
    context = binding.activity
  }

  override fun onDetachedFromActivityForConfigChanges() {
    context = null
  }
}

class DisplayConnectedStreamHandler(private val displayManager: DisplayManager?) : EventChannel.StreamHandler {

  private var sink: EventChannel.EventSink? = null
  private val displayListener = object : DisplayManager.DisplayListener {
    override fun onDisplayAdded(displayId: Int) {
      sink?.success(1)
    }

    override fun onDisplayRemoved(displayId: Int) {
      sink?.success(0)
    }

    override fun onDisplayChanged(displayId: Int) {}
  }

  override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
    sink = events
    displayManager?.registerDisplayListener(displayListener, Handler(Looper.getMainLooper()))
  }

  override fun onCancel(arguments: Any?) {
    sink = null
    displayManager?.unregisterDisplayListener(displayListener)
  }
}
