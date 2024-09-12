# Flutter Presentation Display

`Flutter Presentation Display` is a Flutter plugin designed to run on multiple displays, including handling secondary (presentation) display. It provides methods to interact with connected displays, transfer data, and respond to display connection changes. Tested on SUNMI T2s.

## Features

- Retrieve a list of connected displays
- Show and hide secondary (presentation) display
- Transfer data from the main display to the secondary display or vice versa
- Listen to display connection changes

## Installation

Add `flutter_presentation_display` to your `pubspec.yaml` file:

```yaml
dependencies:
  flutter:
    sdk: flutter
  flutter_presentation_display: any  # Replace with the latest version
```

## Usage
### Import the Package
```
import 'package:flutter_presentation_display/flutter_presentation_display.dart';
```

### Initialize FlutterPresentationDisplay
Create an instance of FlutterPresentationDisplay:
```
final display = FlutterPresentationDisplay();
```

### Retrieve Displays
Get a list of connected displays:
```
List<Display>? displays = await display.getDisplays();
```
Get Display Name by ID
Retrieve the name of a display using its ID:
```
String? displayName = await display.getNameByDisplayId(1);
```
Get Display Name by Index
Retrieve the name of a display using its index in the list:
```
String? displayName = await display.getNameByIndex(0);
```

### Show and Hide Secondary Display
Show a secondary display with a specific ID and router name:
```
bool? result = await display.showSecondaryDisplay(
  displayId: 1,
  routerName: "presentation",
);
```
Hide a secondary display using its ID:
```
bool? result = await display.hideSecondaryDisplay(displayId: 1);
```

###  Transfer Data to and from Displays
Transfer data to the secondary (presentation) display:
```
bool? result = await display.transferDataToPresentation({"key": "value"});
```
Transfer data to the main display:
```
bool? result = await display.transferDataToMain({"key": "value"});
```

### Listen to Display Connection Changes
Listen to changes in connected displays:
```
display.connectedDisplaysChangedStream.listen((int? displayId) {
  print('Connected display ID: $displayId');
});
```

### Listen for Data from Displays
Listen for data sent from the secondary (presentation) display:
```
display.listenDataFromPresentationDisplay((dynamic data) {
  print('Data from Presentation Display: $data');
});
```
Listen for data sent from the main display:
```
display.listenDataFromMainDisplay((dynamic data) {
  print('Data from Main Display: $data');
});
```


## Example
Check out the [example](example) directory for a complete sample app demonstrating the use of the `flutter_presentation_display` package.

## License
This package is based on [presentation_displays](https://github.com/VNAPNIC/presentation-displays) which is licensed under the BSD 2-Clause License.<br/>
[flutter_presentation_display](https://github.com/elrizwiraswara/flutter_presentation_display)  is a modified version of the original version.


## Support

<a href="https://trakteer.id/elrizwiraswara/tip" target="_blank"><img id="wse-buttons-preview" src="https://cdn.trakteer.id/images/embed/trbtn-red-6.png?date=18-11-2023" height="40" style="border:0px;height:40px;margin-top:14px" alt="Trakteer Saya"></a>
