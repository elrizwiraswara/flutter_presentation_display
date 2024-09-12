import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_presentation_display/display.dart';

/// Constant method names for communication between Flutter and platform (native code)
const _listDisplay = "listDisplay";
const _showPresentation = "showPresentation";
const _hidePresentation = "hidePresentation";
const _transferDataToPresentation = "transferDataToPresentation";
const _transferDataToMain = "transferDataToMain";

/// Constant for Android presentation display category
const String DISPLAY_CATEGORY_PRESENTATION =
    "android.hardware.display.category.PRESENTATION";

class FlutterPresentationDisplay {
  /// Event and method channel identifiers
  final String _displayEventChannelId = "presentation_display_channel_events";
  final String _presentationDisplayMethodChannelId =
      "presentation_display_channel";
  final String _mainDisplayMethodChannelId = "main_display_channel";

  /// EventChannel to receive display connection events
  late EventChannel _displayEventChannel;

  /// MethodChannel for managing the presentation display (secondary display)
  late MethodChannel _presentationMethodChannel;

  /// MethodChannel for communicating with the main display
  late MethodChannel _mainDisplayMethodChannel;

  /// Constructor to initialize event and method channels
  FlutterPresentationDisplay() {
    _displayEventChannel = EventChannel(_displayEventChannelId);
    _presentationMethodChannel =
        MethodChannel(_presentationDisplayMethodChannelId);
    _mainDisplayMethodChannel = MethodChannel(_mainDisplayMethodChannelId);
  }

  /// Retrieves a list of available displays, optionally filtered by category
  Future<List<Display>?> getDisplays({String? category}) async {
    /// Invoke the native method to list displays and decode the response
    final listDisplays =
        await _presentationMethodChannel.invokeMethod(_listDisplay, category);

    /// Decode the list of displays from JSON format
    List<dynamic> origins = jsonDecode(listDisplays) ?? [];

    /// Convert each element into a Display object
    return origins.map((element) {
      final map = jsonDecode(jsonEncode(element));
      return Display.fromJson(map as Map<String, dynamic>);
    }).toList();
  }

  /// Gets the name of a display by its ID, optionally filtered by category
  Future<String?> getNameByDisplayId(int displayId, {String? category}) async {
    List<Display> displays = await getDisplays(category: category) ?? [];

    /// Find and return the name of the display with the specified ID
    return displays
        .firstWhere((element) => element.displayId == displayId)
        .name;
  }

  /// Gets the name of a display by its index in the list of displays
  Future<String?> getNameByIndex(int index, {String? category}) async {
    List<Display>? displays = await getDisplays(category: category);

    /// Return the name at the specified index, or null if the index is out of range
    return (index >= 0 && index < displays!.length)
        ? displays[index].name
        : null;
  }

  /// Shows the secondary display (presentation) with the given display ID and router name
  Future<bool?> showSecondaryDisplay(
      {required int displayId, required String routerName}) async {
    return await _presentationMethodChannel.invokeMethod<bool?>(
      _showPresentation,
      jsonEncode({"displayId": displayId, "routerName": routerName}),
    );
  }

  /// Hides the secondary display (presentation) for the given display ID
  Future<bool?> hideSecondaryDisplay({required int displayId}) async {
    return await _presentationMethodChannel.invokeMethod<bool?>(
      _hidePresentation,
      jsonEncode({"displayId": displayId}),
    );
  }

  /// Stream to listen for changes in connected displays (events from native side)
  Stream<int?> get connectedDisplaysChangedStream {
    return _displayEventChannel.receiveBroadcastStream().cast<int?>();
  }

  /// Transfers data to the secondary display (presentation) through the native platform
  Future<bool?> transferDataToPresentation(dynamic arguments) async {
    return await _presentationMethodChannel.invokeMethod<bool?>(
        _transferDataToPresentation, arguments);
  }

  /// Transfers data to the main display through the native platform
  Future<bool?> transferDataToMain(dynamic arguments) async {
    return await _mainDisplayMethodChannel.invokeMethod<bool?>(
        _transferDataToMain, arguments);
  }

  /// Listens for data sent from the secondary display (presentation)
  /// Calls the provided callback function when data is received
  void listenDataFromPresentationDisplay(Function(dynamic) onDataReceived) {
    _mainDisplayMethodChannel.setMethodCallHandler((call) async {
      debugPrint('Data from Presentation Display: ${call.arguments}');
      onDataReceived(call.arguments);
    });
  }

  /// Listens for data sent from the main display
  /// Calls the provided callback function when data is received
  void listenDataFromMainDisplay(Function(dynamic) onDataReceived) {
    _presentationMethodChannel.setMethodCallHandler((call) async {
      debugPrint('Data from Main Display: ${call.arguments}');
      onDataReceived(call.arguments);
    });
  }
}
